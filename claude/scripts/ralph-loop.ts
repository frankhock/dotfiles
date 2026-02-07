#!/usr/bin/env bun

// Ralph Wiggum Loop - Parallel Claude runner using JSON state
// TypeScript/Bun reimplementation of ralph-loop.rb
//
// Usage: ralph-loop [options]
//   -p, --prd FILE          Path to ralph-tasks.json (or uses ./ralph-tasks.json if present)
//   -m, --prompt FILE       Path to prompt.md (overrides promptFile in prd.json)
//   -j, --jobs N            Max parallel jobs (default: from prd.json or 5)
//   -d, --delay N           Delay between checks in seconds (default: from prd.json or 15)
//   -k, --kill              Kill all ralph-loop and claude processes
//   -h, --help              Show this help message

import { existsSync, mkdirSync, readFileSync, writeFileSync, unlinkSync } from "fs";
import { join, basename, resolve } from "path";

// ─── Types ──────────────────────────────────────────────────────────────────

interface Task {
  id: string;
  title?: string;
  status?: string;
  [key: string]: unknown;
}

interface PrdConfig {
  project?: string;
  maxParallel?: number;
  checkInterval?: number;
  promptFile?: string;
  completedAt?: string;
  tasks: Task[];
  [key: string]: unknown;
}

// ─── Constants ──────────────────────────────────────────────────────────────

const MASTER_PID_FILE = "/tmp/ralph-loop-master.pid";

const COLORS = {
  red: "\x1b[0;31m",
  green: "\x1b[0;32m",
  yellow: "\x1b[1;33m",
  blue: "\x1b[0;34m",
  cyan: "\x1b[0;36m",
  brightCyan: "\x1b[1;96m",
  gray: "\x1b[0;90m",
  reset: "\x1b[0m",
} as const;

type Color = keyof typeof COLORS;

// ─── Helpers ────────────────────────────────────────────────────────────────

export function colorize(color: Color, text: string): string {
  return `${COLORS[color]}${text}${COLORS.reset}`;
}

function error(msg: string): void {
  console.log(colorize("red", `Error: ${msg}`));
}

function warnMsg(msg: string): void {
  console.log(colorize("yellow", msg));
}

function success(msg: string): void {
  console.log(colorize("green", msg));
}

export function hyperlink(path: string, text: string): string {
  return `\x1b]8;;file://${path}\x1b\\${text}\x1b]8;;\x1b\\`;
}

function clearScreen(): void {
  process.stdout.write("\x1b[2J\x1b[H");
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function processAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

// ─── RalphLoop ──────────────────────────────────────────────────────────────

export class RalphLoop {
  private prdFile: string | null = null;
  private promptFileOverride: string | null = null;
  private maxParallel: number | null = null;
  private checkDelay: number | null = null;
  private runDir: string;
  private runningPids = new Map<string, number>(); // task_id => pid
  private processGroups = new Map<string, number>(); // task_id => pgid
  private subprocesses = new Map<string, Bun.Subprocess>(); // task_id => subprocess
  private shouldExit = false;
  private cleaningUp = false;
  private prd!: PrdConfig;
  private promptFile!: string;
  private projectName!: string;

  constructor() {
    this.runDir = `/tmp/ralph-loop-${process.pid}`;
  }

  async run(): Promise<void> {
    this.parseOptions();
    this.validateEnvironment();
    this.loadConfig();
    this.setupRunDir();
    this.setupSignalHandlers();
    this.writeMasterPid();
    this.displayBanner();
    await this.mainLoop();
  }

  // ─── CLI Parsing ────────────────────────────────────────────────────────

  private parseOptions(): void {
    const args = process.argv.slice(2);

    // Manual parse to match Ruby's OptionParser behavior
    let i = 0;
    while (i < args.length) {
      const arg = args[i];
      switch (arg) {
        case "-p":
        case "--prd":
          this.prdFile = args[++i];
          break;
        case "-m":
        case "--prompt":
          this.promptFileOverride = args[++i];
          break;
        case "-j":
        case "--jobs":
          this.maxParallel = parseInt(args[++i], 10);
          break;
        case "-d":
        case "--delay":
          this.checkDelay = parseInt(args[++i], 10);
          break;
        case "-k":
        case "--kill":
          this.killAllProcesses();
          process.exit(0);
        case "-h":
        case "--help":
          this.printHelp();
          process.exit(0);
        default:
          error(`Unknown option: ${arg}`);
          this.printHelp();
          process.exit(1);
      }
      i++;
    }

    // Try default prd file if not specified
    if (this.prdFile === null) {
      if (existsSync("ralph-tasks.json")) {
        this.prdFile = "ralph-tasks.json";
      } else if (existsSync(".claude/tasks/prd.json")) {
        this.prdFile = ".claude/tasks/prd.json";
      } else {
        error("No task file found. Looked for:");
        error("  - ralph-tasks.json (current directory)");
        error("  - .claude/tasks/prd.json");
        error("Use: ralph-loop -p /path/to/tasks.json");
        process.exit(1);
      }
    }
  }

  private printHelp(): void {
    console.log("Ralph Wiggum Loop - Parallel Claude runner");
    console.log("");
    console.log("Usage: ralph-loop [options]");
    console.log("");
    console.log("Options:");
    console.log(
      "  -p, --prd FILE     Path to ralph-tasks.json (or uses ./ralph-tasks.json if present)"
    );
    console.log(
      "  -m, --prompt FILE  Path to prompt.md (overrides promptFile in prd.json)"
    );
    console.log("  -j, --jobs N       Max parallel jobs");
    console.log("  -d, --delay N      Check interval in seconds");
    console.log("  -k, --kill         Kill all ralph-loop and claude processes");
    console.log("  -h, --help         Show this help message");
  }

  // ─── Validation & Config ────────────────────────────────────────────────

  private validateEnvironment(): void {
    if (!existsSync("CLAUDE.md")) {
      error("Must run from project root (CLAUDE.md not found)");
      error("cd to your project directory first");
      process.exit(1);
    }

    const which = Bun.spawnSync(["which", "claude"]);
    if (which.exitCode !== 0) {
      error("claude CLI not found");
      process.exit(1);
    }

    if (!existsSync(this.prdFile!)) {
      error(`PRD file not found: ${this.prdFile}`);
      process.exit(1);
    }
  }

  private loadConfig(): void {
    this.prd = JSON.parse(readFileSync(this.prdFile!, "utf-8"));

    this.maxParallel ??= this.prd.maxParallel ?? 1;
    this.checkDelay ??= this.prd.checkInterval ?? 15;
    this.promptFile =
      this.promptFileOverride ?? this.prd.promptFile ?? "ralph-prompt.md";
    this.projectName = this.prd.project ?? "Unknown";

    if (!existsSync(this.promptFile)) {
      error(`Prompt file not found: ${this.promptFile}`);
      error("Set 'promptFile' in prd.json, use --prompt, or create the file");
      process.exit(1);
    }
  }

  private setupRunDir(): void {
    mkdirSync(this.runDir, { recursive: true });
  }

  // ─── Signal Handling ────────────────────────────────────────────────────

  private setupSignalHandlers(): void {
    const handler = () => {
      this.shouldExit = true;
      this.cleanup();
      process.exit(1);
    };

    process.on("SIGINT", handler);
    process.on("SIGTERM", handler);
    process.on("exit", () => this.cleanup());
  }

  private writeMasterPid(): void {
    writeFileSync(MASTER_PID_FILE, process.pid.toString());
  }

  // ─── Banner & TUI ──────────────────────────────────────────────────────

  private displayBanner(): void {
    const y = COLORS.yellow;
    const bc = COLORS.brightCyan;
    const x = COLORS.reset;

    // Head (yellow)
    console.log(
      `${y} ⠀⠀⠀⠀⠀⠀⣀⣤⣶⡶⢛⠟⡿⠻⢻⢿⢶⢦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${y} ⠀⠀⠀⢀⣠⡾⡫⢊⠌⡐⢡⠊⢰⠁⡎⠘⡄⢢⠙⡛⡷⢤⡀⠀⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${y} ⠀⠀⢠⢪⢋⡞⢠⠃⡜⠀⠎⠀⠉⠀⠃⠀⠃⠀⠃⠙⠘⠊⢻⠦⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${y} ⠀⠀⢇⡇⡜⠀⠜⠀⠁⠀⢀⠔⠉⠉⠑⠄⠀⠀⡰⠊⠉⠑⡄⡇⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${y} ⠀⠀⡸⠧⠄⠀⠀⠀⠀⠀⠘⡀⠾⠀⠀⣸⠀⠀⢧⠀⠛⠀⠌⡇⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${y} ⠀⠘⡇⠀⠀⠀⠀⠀⠀⠀⠀⠙⠒⠒⠚⠁⠈⠉⠲⡍⠒⠈⠀⡇⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${y} ⠀⠀⠈⠲⣆⠀⠀⠀⠀⠀⠀⠀⠀⣠⠖⠉⡹⠤⠶⠁⠀⠀⠀⠈⢦⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${y} ⠀⠀⠀⠀⠈⣦⡀⠀⠀⠀⠀⠧⣴⠁⠀⠘⠓⢲⣄⣀⣀⣀⡤⠔⠃⠀⠀⠀⠀⠀${x}`
    );
    // Body/shirt (bright cyan)
    console.log(
      `${bc} ⠀⠀⠀⠀⣜⠀⠈⠓⠦⢄⣀⣀⣸⠀⠀⠀⠀⠁⢈⢇⣼⡁⠀⠀⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${bc} ⠀⠀⢠⠒⠛⠲⣄⠀⠀⠀⣠⠏⠀⠉⠲⣤⠀⢸⠋⢻⣤⡛⣄⠀⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${bc} ⠀⠀⢡⠀⠀⠀⠀⠉⢲⠾⠁⠀⠀⠀⠀⠈⢳⡾⣤⠟⠁⠹⣿⢆⠀⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${bc} ⠀⢀⠼⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠃⠀⠀⠀⠀⠀⠈⣧⠀⠀⠀⠀⠀${x}`
    );
    console.log(
      `${bc} ⠀⡏⠀⠘⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠀⠀⠀${x}`
    );
    console.log();
    console.log(`${colorize("yellow", "Ralph Loop")} | ${this.projectName}`);
  }

  // ─── Rendering ──────────────────────────────────────────────────────────

  private renderProgressBar(
    completed: number,
    total: number,
    width = 30
  ): string {
    if (total === 0) {
      return "[" + "░".repeat(width) + "] 0% (0/0 completed)";
    }

    const percent = Math.round((completed / total) * 100);
    const filled = Math.round((completed / total) * width);
    const empty = width - filled;

    const bar = "█".repeat(filled) + "░".repeat(empty);
    return `[${bar}] ${percent}% (${completed}/${total} completed)`;
  }

  private renderStatusLine(
    running: number,
    failed: number,
    pending: number
  ): string {
    const parts: string[] = [];
    if (running > 0) parts.push(colorize("cyan", `${running} running`));
    if (failed > 0) parts.push(colorize("red", `${failed} failed`));
    if (pending > 0) parts.push(colorize("gray", `${pending} pending`));
    return parts.join(" | ");
  }

  private renderTaskList(maxDisplay = 3): void {
    const running = this.tasksByStatus("running");
    const failed = this.tasksByStatus("failed");
    const pending = this.tasksByStatus("pending");

    const displayTasks = [...running, ...failed, ...pending].slice(
      0,
      maxDisplay
    );

    console.log("Tasks:");
    for (const task of displayTasks) {
      const id = task.id;
      let title = task.title ?? "Untitled";
      const status = task.status ?? "pending";

      const maxTitle = 40;
      if (title.length > maxTitle) {
        title = title.slice(0, maxTitle - 3) + "...";
      }

      let statusStr: string;
      let pidStr = "";

      switch (status) {
        case "completed":
          statusStr = colorize("green", "completed");
          break;
        case "running": {
          const pid = this.runningPids.get(id);
          statusStr = colorize("cyan", "running");
          pidStr = pid ? `  (PID ${pid})` : "";
          break;
        }
        case "failed":
          statusStr = colorize("red", "failed ");
          break;
        default:
          statusStr = colorize("gray", "pending");
          break;
      }

      const logPath = join(this.runDir, `${id}.log`);
      const idDisplay = hyperlink(logPath, id);
      console.log(`  ${idDisplay}  ${statusStr}  ${title}${pidStr}`);
    }
  }

  // ─── Task Helpers ───────────────────────────────────────────────────────

  private tasksByStatus(statusValue: string): Task[] {
    if (!Array.isArray(this.prd.tasks)) return [];
    return this.prd.tasks.filter((t) => t.status === statusValue);
  }

  private countByStatus(statusValue: string): number {
    return this.tasksByStatus(statusValue).length;
  }

  // ─── PRD I/O ────────────────────────────────────────────────────────────

  private reloadPrd(): boolean {
    try {
      this.prd = JSON.parse(readFileSync(this.prdFile!, "utf-8"));
      return true;
    } catch (e) {
      error(
        `Failed to parse prd.json: ${e instanceof Error ? e.message : e} (skipping iteration)`
      );
      return false;
    }
  }

  private savePrd(): void {
    writeFileSync(this.prdFile!, JSON.stringify(this.prd, null, 2));
  }

  private syncRunningStatus(): void {
    for (const task of this.prd.tasks) {
      const pid = this.runningPids.get(task.id);
      if (pid !== undefined && processAlive(pid)) {
        if (task.status !== "completed" && task.status !== "failed") {
          task.status = "running";
        }
      }
    }
  }

  // ─── Task Execution ─────────────────────────────────────────────────────

  private startTask(taskId: string): void {
    const logFile = join(this.runDir, `${taskId}.log`);
    const promptFilePath = join(this.runDir, `${taskId}-prompt.txt`);

    // Build prompt with task details injected inline
    const promptContent = readFileSync(this.promptFile, "utf-8");
    const task = this.prd.tasks.find((t) => t.id === taskId);
    if (!task) return;

    const taskJson = JSON.stringify(task, null, 2);
    const taskPrompt = `# YOUR ASSIGNED TASK\n\n\`\`\`json\n${taskJson}\n\`\`\`\n\n${promptContent}`;
    writeFileSync(promptFilePath, taskPrompt);

    // Spawn claude via bash, reading prompt from file via stdin
    const logOutput = Bun.file(logFile);
    const proc = Bun.spawn(
      [
        "/bin/bash",
        "-c",
        `claude --print --dangerously-skip-permissions --model sonnet < ${this.shellEscape(promptFilePath)}`,
      ],
      {
        stdout: logOutput,
        stderr: logOutput,
      }
    );

    const pid = proc.pid;
    this.runningPids.set(taskId, pid);
    this.processGroups.set(taskId, pid);
    this.subprocesses.set(taskId, proc);

    // Update status in JSON
    task.status = "running";
    this.savePrd();
  }

  private async checkRunningTasks(): Promise<void> {
    const finished: Array<{ taskId: string; pid: number; exitCode: number }> =
      [];

    for (const [taskId, proc] of this.subprocesses) {
      // Check if the process has exited by looking at exitCode
      // Bun's Subprocess.exited is a promise that resolves when the process exits
      if (proc.exitCode !== null) {
        finished.push({
          taskId,
          pid: proc.pid,
          exitCode: proc.exitCode ?? 0,
        });
      }
    }

    for (const { taskId, pid, exitCode } of finished) {
      this.processFinishedTask(taskId, pid, exitCode);
    }
  }

  private processFinishedTask(
    taskId: string,
    _pid: number,
    exitCode: number
  ): void {
    const task = this.prd.tasks.find((t) => t.id === taskId);

    if (task) {
      task.status = exitCode === 0 ? "completed" : "failed";
      this.savePrd();
    }

    this.runningPids.delete(taskId);
    this.processGroups.delete(taskId);
    this.subprocesses.delete(taskId);
  }

  // ─── Main Loop ──────────────────────────────────────────────────────────

  private async mainLoop(): Promise<void> {
    while (!this.shouldExit) {
      // Reload PRD to get latest status
      if (!this.reloadPrd()) {
        await sleep(1000);
        continue;
      }

      // Validate tasks array exists
      if (!Array.isArray(this.prd.tasks)) {
        error("ralph-tasks.json missing 'tasks' array");
        await sleep(1000);
        continue;
      }

      // Update running task statuses in JSON
      this.syncRunningStatus();

      // Check on running tasks (reap finished processes)
      await this.checkRunningTasks();

      // Get current counts
      const passedCount = this.countByStatus("completed");
      const runningCount = this.countByStatus("running");
      const failedCount = this.countByStatus("failed");
      const pendingCount = this.countByStatus("pending");
      const total = this.prd.tasks.length;

      // Render full TUI
      clearScreen();
      console.log();
      this.displayBanner();

      console.log(colorize("blue", "━".repeat(64)));
      const prdLink = hyperlink(
        resolve(this.prdFile!),
        `PRD: ${basename(this.prdFile!)}`
      );
      const promptLink = hyperlink(
        resolve(this.promptFile),
        `Prompt: ${basename(this.promptFile)}`
      );
      console.log(colorize("gray", `${prdLink} | ${promptLink}`));
      console.log();
      console.log(this.renderProgressBar(passedCount, total));
      console.log();
      console.log(this.renderStatusLine(runningCount, failedCount, pendingCount));
      console.log();

      this.renderTaskList();

      // Check if all done (completed or failed, none pending/running)
      if (pendingCount === 0 && runningCount === 0 && total > 0) {
        console.log();

        if (failedCount === 0) {
          success("All tasks completed!");
          console.log();
          success('🚌 "I\'m a helper!" - Ralph Wiggum');
        } else {
          warnMsg(`Finished with ${failedCount} failed task(s)`);
        }

        this.prd.completedAt = new Date().toISOString();
        this.savePrd();
        process.exit(failedCount > 0 ? 1 : 0);
      }

      // Start new tasks if we have capacity
      let actualRunning = 0;
      for (const [, pid] of this.runningPids) {
        if (processAlive(pid)) actualRunning++;
      }
      let available = this.maxParallel! - actualRunning;

      if (available > 0) {
        const pendingTasks = this.tasksByStatus("pending");

        for (const task of pendingTasks) {
          if (available <= 0) break;
          this.startTask(task.id);
          available--;
          await sleep(500); // Small delay between spawns
        }
      }

      // Countdown with refresh each second
      console.log();
      for (let i = 0; i < this.checkDelay!; i++) {
        if (this.shouldExit) break;

        const remaining = this.checkDelay! - i;
        process.stdout.write(
          `\r${" ".repeat(80)}\rNext check in ${remaining}s... (Ctrl+C to stop)`
        );

        await sleep(1000);
      }
    }
  }

  // ─── Cleanup ────────────────────────────────────────────────────────────

  private cleanup(): void {
    if (this.cleaningUp) return;
    this.cleaningUp = true;

    const pgids = [...new Set(this.processGroups.values())];

    if (pgids.length > 0) {
      process.stderr.write(
        `\nCleaning up ${pgids.length} Claude process group(s)...\n`
      );

      // TERM the entire process group (negative PID = kill group)
      for (const pgid of pgids) {
        try {
          process.kill(-pgid, "SIGTERM");
        } catch {
          // Already dead or no permission
        }
      }

      // Give processes a moment to exit gracefully (synchronous for cleanup)
      Bun.sleepSync(2000);

      // Force kill any survivors
      for (const pgid of pgids) {
        try {
          process.kill(-pgid, "SIGKILL");
        } catch {
          // Already dead or no permission
        }
      }
    }

    // Fallback: pkill any claude --print processes we may have missed
    try {
      Bun.spawnSync(["pkill", "-TERM", "-f", "claude --print"]);
    } catch {
      // ignore
    }
    Bun.sleepSync(500);
    try {
      Bun.spawnSync(["pkill", "-9", "-f", "claude --print"]);
    } catch {
      // ignore
    }

    // Reset any "running" tasks back to "pending" so they retry on next run
    this.resetRunningTasksToPending();

    // Clean up master PID file
    try {
      unlinkSync(MASTER_PID_FILE);
    } catch {
      // ignore
    }
  }

  private resetRunningTasksToPending(): void {
    if (!this.prdFile || !existsSync(this.prdFile)) return;

    try {
      const prd: PrdConfig = JSON.parse(readFileSync(this.prdFile, "utf-8"));
      if (!Array.isArray(prd.tasks)) return;

      let changed = false;
      for (const task of prd.tasks) {
        if (task.status === "running") {
          task.status = "pending";
          changed = true;
        }
      }

      if (changed) {
        writeFileSync(this.prdFile, JSON.stringify(prd, null, 2));
      }
    } catch {
      // Best-effort — don't let JSON errors prevent the rest of cleanup
    }
  }

  // ─── Kill Mode ──────────────────────────────────────────────────────────

  private killAllProcesses(): void {
    console.log("Killing all ralph-loop and claude processes...");

    // Kill master if running
    if (existsSync(MASTER_PID_FILE)) {
      const masterPid = parseInt(readFileSync(MASTER_PID_FILE, "utf-8"), 10);
      if (processAlive(masterPid)) {
        console.log(`  Killing master loop (PID: ${masterPid})`);
        try {
          process.kill(masterPid, "SIGTERM");
          Bun.sleepSync(1000);
          if (processAlive(masterPid)) {
            process.kill(masterPid, "SIGKILL");
          }
        } catch {
          // Already dead or no permission
        }
      }
      try {
        unlinkSync(MASTER_PID_FILE);
      } catch {
        // ignore
      }
    }

    // Kill all claude --print processes
    console.log("  Killing all claude --print processes...");
    Bun.spawnSync(["pkill", "-TERM", "-f", "claude --print"]);
    Bun.sleepSync(1000);
    Bun.spawnSync(["pkill", "-9", "-f", "claude --print"]);

    console.log("Done.");
  }

  // ─── Utilities ──────────────────────────────────────────────────────────

  private shellEscape(str: string): string {
    return "'" + str.replace(/'/g, "'\\''") + "'";
  }
}

// ─── Entry Point ────────────────────────────────────────────────────────────

if (import.meta.main) {
  const ralph = new RalphLoop();
  ralph.run().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
