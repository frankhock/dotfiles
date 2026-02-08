#!/usr/bin/env bun
/**
 * Protect Secrets - PreToolUse Hook for Read|Edit|Write|Bash
 * Prevents reading, modifying, or exfiltrating sensitive files.
 * Logs to: ~/.claude/hooks-logs/
 *
 * SAFETY_LEVEL: 'critical' | 'high' | 'strict'
 *   critical - SSH keys, AWS creds, .env files only
 *   high     - + secrets files, env dumps, exfiltration attempts
 *   strict   - + database configs, any config that might contain secrets
 *
 * Setup in .claude/settings.json:
 * {
 *   "hooks": {
 *     "PreToolUse": [{
 *       "matcher": "Read|Edit|Write|Bash",
 *       "hooks": [{ "type": "command", "command": "bun /path/to/protect-secrets.ts" }]
 *     }]
 *   }
 * }
 */

import fs from "node:fs";
import path from "node:path";

type SafetyLevel = "critical" | "high" | "strict";

interface Pattern {
  level: SafetyLevel;
  id: string;
  regex: RegExp;
  reason: string;
}

interface CheckResult {
  blocked: boolean;
  pattern: Pattern | null;
}

interface HookInput {
  tool_name: string;
  tool_input?: { command?: string; file_path?: string };
  session_id?: string;
  cwd?: string;
  permission_mode?: string;
}

const SAFETY_LEVEL: SafetyLevel = "high";

// Files explicitly safe to access (templates, examples)
const ALLOWLIST: RegExp[] = [
  /\.env\.example$/i,
  /\.env\.sample$/i,
  /\.env\.template$/i,
  /\.env\.schema$/i,
  /\.env\.defaults$/i,
  /env\.example$/i,
  /example\.env$/i,
];

// Sensitive file patterns for Read, Edit, Write tools
const SENSITIVE_FILES: Pattern[] = [
  // CRITICAL - SSH keys, cloud creds, .env, Rails keys
  {
    level: "critical",
    id: "rails-master-key",
    regex: /(?:^|\/)master\.key$/,
    reason: "Rails master key decrypts credentials",
  },
  {
    level: "critical",
    id: "rails-credentials-key",
    regex: /(?:^|\/)credentials\/[^/]+\.key$/,
    reason: "Rails per-environment key decrypts credentials",
  },
  {
    level: "critical",
    id: "env-file",
    regex: /(?:^|\/)\.env(?:\.[^/]*)?$/,
    reason: ".env file contains secrets",
  },
  {
    level: "critical",
    id: "envrc",
    regex: /(?:^|\/)\.envrc$/,
    reason: ".envrc (direnv) contains secrets",
  },
  {
    level: "critical",
    id: "ssh-private-key",
    regex: /(?:^|\/)\.ssh\/id_[^/]+$/,
    reason: "SSH private key",
  },
  {
    level: "critical",
    id: "ssh-private-key-2",
    regex: /(?:^|\/)(?:id_rsa|id_ed25519|id_ecdsa|id_dsa)$/,
    reason: "SSH private key",
  },
  {
    level: "critical",
    id: "ssh-authorized",
    regex: /(?:^|\/)\.ssh\/authorized_keys$/,
    reason: "SSH authorized_keys",
  },
  {
    level: "critical",
    id: "aws-credentials",
    regex: /(?:^|\/)\.aws\/credentials$/,
    reason: "AWS credentials file",
  },
  {
    level: "critical",
    id: "aws-config",
    regex: /(?:^|\/)\.aws\/config$/,
    reason: "AWS config may contain secrets",
  },
  {
    level: "critical",
    id: "kube-config",
    regex: /(?:^|\/)\.kube\/config$/,
    reason: "Kubernetes config contains credentials",
  },
  {
    level: "critical",
    id: "pem-key",
    regex: /\.pem$/i,
    reason: "PEM key file",
  },
  {
    level: "critical",
    id: "key-file",
    regex: /\.key$/i,
    reason: "Key file",
  },
  {
    level: "critical",
    id: "p12-key",
    regex: /\.(p12|pfx)$/i,
    reason: "PKCS12 key file",
  },

  // HIGH - Service credentials, auth tokens
  {
    level: "high",
    id: "credentials-json",
    regex: /(?:^|\/)credentials\.json$/i,
    reason: "Credentials file",
  },
  {
    level: "high",
    id: "secrets-file",
    regex: /(?:^|\/)(?:secrets?|credentials?)\.(json|ya?ml|toml)$/i,
    reason: "Secrets configuration file",
  },
  {
    level: "high",
    id: "service-account",
    regex: /service[_-]?account.*\.json$/i,
    reason: "GCP service account key",
  },
  {
    level: "high",
    id: "gcloud-creds",
    regex: /(?:^|\/)\.config\/gcloud\/.*(?:credentials|tokens)/i,
    reason: "GCloud credentials",
  },
  {
    level: "high",
    id: "azure-creds",
    regex: /(?:^|\/)\.azure\/(?:credentials|accessTokens)/i,
    reason: "Azure credentials",
  },
  {
    level: "high",
    id: "docker-config",
    regex: /(?:^|\/)\.docker\/config\.json$/,
    reason: "Docker config may contain registry auth",
  },
  {
    level: "high",
    id: "netrc",
    regex: /(?:^|\/)\.netrc$/,
    reason: ".netrc contains credentials",
  },
  {
    level: "high",
    id: "npmrc",
    regex: /(?:^|\/)\.npmrc$/,
    reason: ".npmrc may contain auth tokens",
  },
  {
    level: "high",
    id: "pypirc",
    regex: /(?:^|\/)\.pypirc$/,
    reason: ".pypirc contains PyPI credentials",
  },
  {
    level: "high",
    id: "gem-creds",
    regex: /(?:^|\/)\.gem\/credentials$/,
    reason: "RubyGems credentials",
  },
  {
    level: "high",
    id: "vault-token",
    regex: /(?:^|\/)?(?:\.vault-token|vault-token)$/,
    reason: "Vault token file",
  },
  {
    level: "high",
    id: "keystore",
    regex: /\.(keystore|jks)$/i,
    reason: "Java keystore",
  },
  {
    level: "high",
    id: "htpasswd",
    regex: /(?:^|\/)\.?htpasswd$/,
    reason: "htpasswd contains hashed passwords",
  },
  {
    level: "high",
    id: "pgpass",
    regex: /(?:^|\/)\.pgpass$/,
    reason: "PostgreSQL password file",
  },
  {
    level: "high",
    id: "my-cnf",
    regex: /(?:^|\/)\.my\.cnf$/,
    reason: "MySQL config may contain password",
  },

  // STRICT - Configs that might contain secrets
  {
    level: "strict",
    id: "database-config",
    regex: /(?:^|\/)?(?:config\/)?database\.(json|ya?ml)$/i,
    reason: "Database config may contain passwords",
  },
  {
    level: "strict",
    id: "ssh-known-hosts",
    regex: /(?:^|\/)\.ssh\/known_hosts$/,
    reason: "SSH known_hosts reveals infrastructure",
  },
  {
    level: "strict",
    id: "gitconfig",
    regex: /(?:^|\/)\.gitconfig$/,
    reason: ".gitconfig may contain credentials",
  },
  {
    level: "strict",
    id: "curlrc",
    regex: /(?:^|\/)\.curlrc$/,
    reason: ".curlrc may contain auth",
  },
];

// Bash patterns that expose or exfiltrate secrets
const BASH_PATTERNS: Pattern[] = [
  // CRITICAL - Direct secret file reads
  {
    level: "critical",
    id: "bash-cat-env",
    regex: /\b(?:cat|less|head|tail|more|bat|view)\s+[^|;]*\.env\b/i,
    reason: "reading .env file exposes secrets",
  },
  {
    level: "critical",
    id: "bash-cat-ssh-key",
    regex:
      /\b(?:cat|less|head|tail|more|bat)\s+[^|;]*(?:id_rsa|id_ed25519|id_ecdsa|id_dsa|\.pem|\.key)\b/i,
    reason: "reading private key",
  },
  {
    level: "critical",
    id: "bash-cat-aws-creds",
    regex: /\b(?:cat|less|head|tail|more)\s+[^|;]*\.aws\/credentials/i,
    reason: "reading AWS credentials",
  },

  // HIGH - Environment exposure
  {
    level: "high",
    id: "bash-env-dump",
    regex: /\bprintenv\b|(?:^|[;&])\s*env\s*(?:$|[;&])/,
    reason: "environment dump may expose secrets",
  },
  {
    level: "high",
    id: "bash-echo-secret",
    regex:
      /\becho\b[^;|&]*\$\{?[A-Za-z_]*(?:SECRET|KEY|TOKEN|PASSWORD|PASSW|CREDENTIAL|API_KEY|AUTH|PRIVATE)[A-Za-z_]*\}?/i,
    reason: "echoing secret variable",
  },
  {
    level: "high",
    id: "bash-printf-secret",
    regex:
      /\bprintf\b[^;|&]*\$\{?[A-Za-z_]*(?:SECRET|KEY|TOKEN|PASSWORD|CREDENTIAL|API_KEY|AUTH|PRIVATE)[A-Za-z_]*\}?/i,
    reason: "printing secret variable",
  },
  {
    level: "high",
    id: "bash-cat-secrets-file",
    regex:
      /\b(?:cat|less|head|tail|more)\s+[^|;]*(?:credentials?|secrets?)\.(json|ya?ml|toml)/i,
    reason: "reading secrets file",
  },
  {
    level: "high",
    id: "bash-cat-netrc",
    regex: /\b(?:cat|less|head|tail|more)\s+[^|;]*\.netrc/i,
    reason: "reading .netrc credentials",
  },
  {
    level: "high",
    id: "bash-source-env",
    regex:
      /\bsource\s+[^|;]*\.env\b|(?:^|[;&])\s*\.\s+[^|;]*\.env\b|^\.\s+[^|;]*\.env\b/i,
    reason: "sourcing .env loads secrets",
  },
  {
    level: "high",
    id: "bash-export-cat-env",
    regex: /export\s+.*\$\(cat\s+[^)]*\.env/i,
    reason: "exporting secrets from .env",
  },

  // HIGH - Exfiltration
  {
    level: "high",
    id: "bash-curl-upload",
    regex:
      /\bcurl\b[^;|&]*(?:-d\s*@|-F\s*[^=]+=@|--data[^=]*=@)[^;|&]*(?:\.env|credentials|secrets|id_rsa|\.pem|\.key)/i,
    reason: "uploading secrets via curl",
  },
  {
    level: "high",
    id: "bash-curl-post-secrets",
    regex:
      /\bcurl\b[^;|&]*-X\s*POST[^;|&]*[^;|&]*(?:\.env|credentials|secrets)/i,
    reason: "POSTing secrets via curl",
  },
  {
    level: "high",
    id: "bash-wget-post-secrets",
    regex:
      /\bwget\b[^;|&]*--post-file[^;|&]*(?:\.env|credentials|secrets)/i,
    reason: "POSTing secrets via wget",
  },
  {
    level: "high",
    id: "bash-scp-secrets",
    regex:
      /\bscp\b[^;|&]*(?:\.env|credentials|secrets|id_rsa|\.pem|\.key)[^;|&]+:/i,
    reason: "copying secrets via scp",
  },
  {
    level: "high",
    id: "bash-rsync-secrets",
    regex:
      /\brsync\b[^;|&]*(?:\.env|credentials|secrets|id_rsa)[^;|&]+:/i,
    reason: "syncing secrets via rsync",
  },
  {
    level: "high",
    id: "bash-nc-secrets",
    regex:
      /\bnc\b[^;|&]*<[^;|&]*(?:\.env|credentials|secrets|id_rsa)/i,
    reason: "exfiltrating secrets via netcat",
  },

  // HIGH - Copy/move/delete secrets
  {
    level: "high",
    id: "bash-cp-env",
    regex: /\bcp\b[^;|&]*\.env\b/i,
    reason: "copying .env file",
  },
  {
    level: "high",
    id: "bash-cp-ssh-key",
    regex: /\bcp\b[^;|&]*(?:id_rsa|id_ed25519|\.pem|\.key)\b/i,
    reason: "copying private key",
  },
  {
    level: "high",
    id: "bash-mv-env",
    regex: /\bmv\b[^;|&]*\.env\b/i,
    reason: "moving .env file",
  },
  {
    level: "high",
    id: "bash-rm-ssh-key",
    regex:
      /\brm\b[^;|&]*(?:id_rsa|id_ed25519|id_ecdsa|authorized_keys)/i,
    reason: "deleting SSH key",
  },
  {
    level: "high",
    id: "bash-rm-env",
    regex: /\brm\b.*\.env\b/i,
    reason: "deleting .env file",
  },
  {
    level: "high",
    id: "bash-rm-aws-creds",
    regex: /\brm\b[^;|&]*\.aws\/credentials/i,
    reason: "deleting AWS credentials",
  },
  {
    level: "high",
    id: "bash-truncate-secrets",
    regex: /\btruncate\b.*\.(?:env|pem|key)\b|(?:^|[;&])\s*>\s*\.env\b/i,
    reason: "truncating secrets file",
  },

  // HIGH - Process environ
  {
    level: "high",
    id: "bash-proc-environ",
    regex: /\/proc\/[^/]*\/environ/,
    reason: "reading process environment",
  },
  {
    level: "high",
    id: "bash-xargs-cat-env",
    regex: /xargs.*cat|\.env.*xargs/i,
    reason: "reading .env via xargs",
  },
  {
    level: "high",
    id: "bash-find-exec-cat-env",
    regex: /find\b.*\.env.*-exec|find\b.*-exec.*(?:cat|less)/i,
    reason: "finding and reading .env files",
  },

  // STRICT - Cautionary
  {
    level: "strict",
    id: "bash-grep-password",
    regex:
      /\bgrep\b[^|;]*(?:-r|--recursive)[^|;]*(?:password|secret|api.?key|token|credential)/i,
    reason: "grep for secrets may expose them",
  },
  {
    level: "strict",
    id: "bash-base64-secrets",
    regex:
      /\bbase64\b[^|;]*(?:\.env|credentials|secrets|id_rsa|\.pem)/i,
    reason: "base64 encoding secrets",
  },
];

const LEVELS: Record<SafetyLevel, number> = { critical: 1, high: 2, strict: 3 };
const EMOJIS: Record<SafetyLevel, string> = {
  critical: "\u{1F510}",
  high: "\u{1F6E1}\uFE0F",
  strict: "\u26A0\uFE0F",
};
const LOG_DIR = path.join(process.env.HOME!, ".claude", "hooks-logs");

function log(data: Record<string, unknown>): void {
  try {
    if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });
    const file = path.join(
      LOG_DIR,
      `${new Date().toISOString().slice(0, 10)}.jsonl`,
    );
    fs.appendFileSync(
      file,
      JSON.stringify({ ts: new Date().toISOString(), hook: "protect-secrets", ...data }) + "\n",
    );
  } catch {}
}

function isAllowlisted(filePath: string): boolean {
  return ALLOWLIST.some((p) => p.test(filePath));
}

function checkFilePath(
  filePath: string,
  safetyLevel: string = SAFETY_LEVEL,
): CheckResult {
  if (!filePath || isAllowlisted(filePath)) {
    return { blocked: false, pattern: null };
  }
  const threshold = LEVELS[safetyLevel as SafetyLevel] || 2;
  for (const p of SENSITIVE_FILES) {
    if (LEVELS[p.level] <= threshold && p.regex.test(filePath)) {
      return { blocked: true, pattern: p };
    }
  }
  return { blocked: false, pattern: null };
}

function checkBashCommand(
  cmd: string,
  safetyLevel: string = SAFETY_LEVEL,
): CheckResult {
  if (!cmd) return { blocked: false, pattern: null };
  for (const allow of ALLOWLIST) {
    if (allow.test(cmd)) return { blocked: false, pattern: null };
  }
  const threshold = LEVELS[safetyLevel as SafetyLevel] || 2;
  for (const p of BASH_PATTERNS) {
    if (LEVELS[p.level] <= threshold && p.regex.test(cmd)) {
      return { blocked: true, pattern: p };
    }
  }
  return { blocked: false, pattern: null };
}

function check(
  toolName: string,
  toolInput: HookInput["tool_input"],
  safetyLevel: string = SAFETY_LEVEL,
): CheckResult {
  if (["Read", "Edit", "Write"].includes(toolName)) {
    return checkFilePath(toolInput?.file_path || "", safetyLevel);
  }
  if (toolName === "Bash") {
    return checkBashCommand(toolInput?.command || "", safetyLevel);
  }
  return { blocked: false, pattern: null };
}

const TOOL_ACTIONS: Record<string, string> = {
  Read: "read",
  Edit: "modify",
  Write: "write to",
  Bash: "execute",
};

async function main(): Promise<void> {
  let input = "";
  for await (const chunk of process.stdin) input += chunk;

  try {
    const data: HookInput = JSON.parse(input);
    const { tool_name, tool_input, session_id, cwd, permission_mode } = data;

    if (!["Read", "Edit", "Write", "Bash"].includes(tool_name)) {
      return console.log("{}");
    }

    const result = check(tool_name, tool_input);

    if (result.blocked) {
      const p = result.pattern!;
      const target = tool_input?.file_path || tool_input?.command?.slice(0, 100);
      log({
        level: "BLOCKED",
        id: p.id,
        priority: p.level,
        tool: tool_name,
        target,
        session_id,
        cwd,
        permission_mode,
      });
      const action = TOOL_ACTIONS[tool_name] || "access";
      return console.log(
        JSON.stringify({
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: `${EMOJIS[p.level]} [${p.id}] Cannot ${action}: ${p.reason}`,
          },
        }),
      );
    }
    console.log("{}");
  } catch (e) {
    log({ level: "ERROR", error: (e as Error).message });
    console.log("{}");
  }
}

if (import.meta.main) {
  main();
}

export {
  ALLOWLIST,
  BASH_PATTERNS,
  LEVELS,
  SAFETY_LEVEL,
  SENSITIVE_FILES,
  check,
  checkBashCommand,
  checkFilePath,
  isAllowlisted,
};
export type { CheckResult, HookInput, Pattern, SafetyLevel };
