# Skill Format Reference

## Directory Structure

```
skill-name/
├── SKILL.md           # Required entrypoint
├── references/        # Detail docs loaded on demand
├── scripts/           # Executable scripts
├── agents/            # Sub-agent definitions
└── templates/         # Output templates
```

## SKILL.md Format

YAML frontmatter (between `---`) + markdown body.

## Frontmatter Fields

| Field | Required | Description |
|---|---|---|
| `name` | No (defaults to dir name) | Lowercase, hyphens only, max 64 chars. Becomes the `/slash-command`. |
| `description` | Recommended | What it does + when to use it. Drives auto-invocation decisions. Include specific trigger keywords. |
| `argument-hint` | No | Autocomplete hint shown to user: `[issue-number]`, `[filename] [format]` |
| `disable-model-invocation` | No | `true` = only user can invoke. Use for side-effect skills (deploy, commit, send messages). |
| `user-invocable` | No | `false` = hidden from `/` menu. Use for background knowledge Claude should auto-load. |
| `allowed-tools` | No | Tools allowed without per-use approval when skill is active. |
| `model` | No | Override model: `sonnet`, `haiku`, `opus`. |
| `context` | No | `fork` = run in isolated subagent (no conversation history). |
| `agent` | No | Subagent type when `context: fork`: `Explore`, `Plan`, `general-purpose`, or custom agent name. |

## String Substitutions

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All arguments passed to the skill |
| `$ARGUMENTS[N]` or `$N` | Specific argument (0-indexed) |
| `${CLAUDE_SESSION_ID}` | Current session ID |

## Dynamic Context Injection

`!` followed by a backtick-wrapped command runs at skill load time, injecting output into the prompt:

```
Current branch: !`git branch --show-current`
Recent changes: !`git log --oneline -5`
```

Claude sees only the rendered output, not the command.

## Invocation Control Matrix

| Config | User invokes | Claude invokes | When loaded |
|---|---|---|---|
| (default) | Yes | Yes | Description always in context; body on invocation |
| `disable-model-invocation: true` | Yes | No | Description NOT in context |
| `user-invocable: false` | No | Yes | Description always in context |

## Storage Locations

| Location | Path | Scope |
|---|---|---|
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |

Priority: enterprise > personal > project.

## Progressive Disclosure

- **Metadata** (~100 words): name + description — always in context for invocation decisions
- **SKILL.md body**: loaded only on invocation — target under 200 lines
- **Supporting files**: loaded on demand when referenced — unlimited size

## Skill Content Categories

**Reference content** — knowledge applied inline alongside conversation:
```yaml
---
name: api-conventions
description: API design patterns for this codebase. Referenced when writing or reviewing API endpoints.
user-invocable: false
---
When writing API endpoints:
- RESTful resource naming (plural nouns)
- Return `{ data, error, meta }` envelope
- Validate input at the boundary
```

**Task content** — step-by-step instructions, usually manually invoked:
```yaml
---
name: deploy
description: Deploy the app to production. Use when the user says deploy, ship, or release.
disable-model-invocation: true
argument-hint: "[environment]"
---
Deploy to the specified environment (default: staging).
1. Run tests — abort if failing
2. Build the application
3. Deploy with `npm run deploy -- --env $0`

Never deploy to production without explicit user confirmation.
```

## Design Principles (Block's Three Principles)

### 1. Determine what agents should NOT decide
Lock deterministic elements into scripts or explicit rules. If something needs to be consistent across runs, remove it from the model's decision space. Examples: CLI sequences, SQL structures, naming conventions, scoring rubrics, output formats.

### 2. Know what agents SHOULD decide
Leverage reasoning for: interpreting results, generating tailored content, prioritizing recommendations based on context, adapting to user constraints.

### 3. Write a constitution, not a suggestion
SKILL.md is a contract. Anticipate ways the model might "helpfully" deviate and explicitly prohibit each one. But only for real failure modes — don't over-constrain.

## Quality Signals

Good skills:
- Description has specific trigger keywords
- Body is under 200 lines
- Constitutional constraints are specific and earned
- Heavy detail lives in reference files
- Side-effect skills are locked to user invocation

Bad skills:
- Vague description ("helps with things")
- Over-specified obvious behavior ("when the user asks a question, answer it")
- Generic constraints ("always be helpful and accurate")
- Everything crammed into SKILL.md
- No invocation control on destructive operations
