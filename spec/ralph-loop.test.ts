import { describe, it, expect } from "bun:test";
import { mkdtempSync, writeFileSync, readFileSync, existsSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { RalphLoop, colorize, hyperlink, processAlive } from "../claude/scripts/ralph-loop";

// ─── Test Helpers ───────────────────────────────────────────────────────────

/** Build a RalphLoop with pre-set internal state, bypassing run/parseOptions. */
function buildRalph(overrides: Record<string, unknown> = {}): RalphLoop {
  const instance = new RalphLoop() as any;

  // Override defaults that differ from constructor
  instance.prd = { tasks: [] };
  instance.promptFile = "ralph-prompt.md";
  instance.projectName = "Unknown";

  for (const [key, value] of Object.entries(overrides)) {
    instance[key] = value;
  }

  return instance;
}

/** Create a temp directory with ralph-tasks.json, prompt file, and CLAUDE.md. */
function createFixtures(
  opts: {
    tasks?: any[];
    project?: string;
    promptContent?: string;
    prdExtras?: Record<string, unknown>;
  } = {}
): { dir: string; prdPath: string; promptPath: string } {
  const dir = mkdtempSync(join(tmpdir(), "ralph-spec-"));

  const prd = {
    project: opts.project ?? "test-project",
    tasks: opts.tasks ?? [],
    ...opts.prdExtras,
  };
  const prdPath = join(dir, "ralph-tasks.json");
  writeFileSync(prdPath, JSON.stringify(prd, null, 2));

  const promptPath = join(dir, "ralph-prompt.md");
  writeFileSync(promptPath, opts.promptContent ?? "do the thing");

  writeFileSync(join(dir, "CLAUDE.md"), "# Test");

  return { dir, prdPath, promptPath };
}

/** Run fn with cwd temporarily changed to dir. */
function withDir<T>(dir: string, fn: () => T): T {
  const orig = process.cwd();
  process.chdir(dir);
  try {
    return fn();
  } finally {
    process.chdir(orig);
  }
}

/** Capture stdout during a callback. */
function captureStdout(fn: () => void): string {
  const origWrite = process.stdout.write;
  const origLog = console.log;
  let output = "";

  process.stdout.write = (chunk: any) => {
    output += typeof chunk === "string" ? chunk : chunk.toString();
    return true;
  };
  console.log = (...args: any[]) => {
    output += args.map(String).join(" ") + "\n";
  };

  try {
    fn();
  } finally {
    process.stdout.write = origWrite;
    console.log = origLog;
  }

  return output;
}

// ─── Pure rendering ─────────────────────────────────────────────────────────

describe("renderProgressBar", () => {
  it("shows empty bar when total is 0", () => {
    const ralph = buildRalph() as any;
    const result: string = ralph.renderProgressBar(0, 0);
    expect(result).toContain("0%");
    expect(result).toContain("0/0 completed");
  });

  it("shows 50% when half completed", () => {
    const ralph = buildRalph() as any;
    const result: string = ralph.renderProgressBar(3, 6);
    expect(result).toContain("50%");
    expect(result).toContain("3/6 completed");
  });

  it("shows 100% when all completed", () => {
    const ralph = buildRalph() as any;
    const result: string = ralph.renderProgressBar(4, 4);
    expect(result).toContain("100%");
    expect(result).toContain("4/4 completed");
  });

  it("respects custom width", () => {
    const ralph = buildRalph() as any;
    const result: string = ralph.renderProgressBar(5, 10, 10);
    expect(result).toContain("█".repeat(5) + "░".repeat(5));
  });
});

describe("renderStatusLine", () => {
  it("shows running, failed, and pending counts", () => {
    const ralph = buildRalph() as any;
    const result: string = ralph.renderStatusLine(2, 1, 3);
    expect(result).toContain("2 running");
    expect(result).toContain("1 failed");
    expect(result).toContain("3 pending");
  });

  it("omits zero-count statuses", () => {
    const ralph = buildRalph() as any;
    const result: string = ralph.renderStatusLine(0, 1, 0);
    expect(result).not.toContain("running");
    expect(result).toContain("1 failed");
    expect(result).not.toContain("pending");
  });

  it("returns empty string when all counts are zero", () => {
    const ralph = buildRalph() as any;
    const result: string = ralph.renderStatusLine(0, 0, 0);
    expect(result).toBe("");
  });
});

describe("colorize", () => {
  it("wraps text in ANSI escape codes", () => {
    expect(colorize("red", "hello")).toBe("\x1b[0;31mhello\x1b[0m");
  });

  it("handles different colors", () => {
    expect(colorize("green", "ok")).toBe("\x1b[0;32mok\x1b[0m");
  });
});

describe("hyperlink", () => {
  it("produces OSC 8 terminal hyperlink", () => {
    expect(hyperlink("/tmp/foo.json", "my file")).toBe(
      "\x1b]8;;file:///tmp/foo.json\x1b\\my file\x1b]8;;\x1b\\"
    );
  });
});

// ─── State queries ──────────────────────────────────────────────────────────

describe("tasksByStatus", () => {
  const tasks = [
    { id: "1", status: "pending" },
    { id: "2", status: "running" },
    { id: "3", status: "pending" },
    { id: "4", status: "completed" },
  ];

  it("returns tasks matching the given status", () => {
    const ralph = buildRalph({ prd: { tasks } }) as any;
    expect(ralph.tasksByStatus("pending").map((t: any) => t.id)).toEqual(["1", "3"]);
  });

  it("returns empty array for unmatched status", () => {
    const ralph = buildRalph({ prd: { tasks } }) as any;
    expect(ralph.tasksByStatus("failed")).toEqual([]);
  });

  it("returns empty array when tasks is not an array", () => {
    const ralph = buildRalph({ prd: { tasks: null } }) as any;
    expect(ralph.tasksByStatus("pending")).toEqual([]);
  });
});

describe("countByStatus", () => {
  const tasks = [
    { id: "1", status: "pending" },
    { id: "2", status: "pending" },
    { id: "3", status: "completed" },
  ];

  it("returns correct count", () => {
    const ralph = buildRalph({ prd: { tasks } }) as any;
    expect(ralph.countByStatus("pending")).toBe(2);
    expect(ralph.countByStatus("completed")).toBe(1);
    expect(ralph.countByStatus("failed")).toBe(0);
  });
});

// ─── Config loading ─────────────────────────────────────────────────────────

describe("loadConfig", () => {
  it("reads JSON and applies defaults", () => {
    const { dir, prdPath, promptPath } = createFixtures({
      tasks: [{ id: "1", status: "pending" }],
    });
    const ralph = buildRalph({ prdFile: prdPath, promptFile: promptPath }) as any;

    withDir(dir, () => ralph.loadConfig());

    expect(ralph.maxParallel).toBe(1);
    expect(ralph.checkDelay).toBe(15);
    expect(ralph.projectName).toBe("test-project");
  });

  it("uses values from JSON when present", () => {
    const { dir, prdPath, promptPath } = createFixtures({
      tasks: [],
      prdExtras: { maxParallel: 3, checkInterval: 5 },
    });
    const ralph = buildRalph({ prdFile: prdPath, promptFile: promptPath }) as any;

    withDir(dir, () => ralph.loadConfig());

    expect(ralph.maxParallel).toBe(3);
    expect(ralph.checkDelay).toBe(5);
  });

  it("CLI overrides take precedence", () => {
    const { dir, prdPath, promptPath } = createFixtures({
      tasks: [],
      prdExtras: { maxParallel: 3, checkInterval: 5 },
    });
    const ralph = buildRalph({
      prdFile: prdPath,
      promptFile: promptPath,
      maxParallel: 10,
      checkDelay: 2,
    }) as any;

    withDir(dir, () => ralph.loadConfig());

    expect(ralph.maxParallel).toBe(10);
    expect(ralph.checkDelay).toBe(2);
  });

  it("uses promptFileOverride when set", () => {
    const { dir, prdPath } = createFixtures({ tasks: [] });
    const customPrompt = join(dir, "custom.md");
    writeFileSync(customPrompt, "custom prompt");

    const ralph = buildRalph({
      prdFile: prdPath,
      promptFileOverride: customPrompt,
    }) as any;

    withDir(dir, () => ralph.loadConfig());

    expect(ralph.promptFile).toBe(customPrompt);
  });
});

describe("reloadPrd", () => {
  it("returns true and loads valid JSON", () => {
    const { prdPath } = createFixtures({
      tasks: [{ id: "x", status: "pending" }],
    });
    const ralph = buildRalph({ prdFile: prdPath }) as any;

    expect(ralph.reloadPrd()).toBe(true);
    expect(ralph.prd.tasks.length).toBe(1);
  });

  it("returns false on invalid JSON", () => {
    const dir = mkdtempSync(join(tmpdir(), "ralph-spec-"));
    const badPath = join(dir, "bad.json");
    writeFileSync(badPath, "not json {{{");

    const ralph = buildRalph({ prdFile: badPath }) as any;
    const output = captureStdout(() => {
      expect(ralph.reloadPrd()).toBe(false);
    });
    expect(output).toContain("Failed to parse");
  });
});

// ─── State mutation ─────────────────────────────────────────────────────────

describe("syncRunningStatus", () => {
  it("marks pending tasks as running when their PID is alive", async () => {
    const proc = Bun.spawn(["sleep", "60"]);
    const tasks = [{ id: "t1", status: "pending" }];
    const subprocesses = new Map([["t1", proc]]);
    const ralph = buildRalph({ prd: { tasks }, subprocesses }) as any;

    try {
      ralph.syncRunningStatus();
      expect(tasks[0].status).toBe("running");
    } finally {
      proc.kill();
      await proc.exited;
    }
  });

  it("does not overwrite completed status", async () => {
    const proc = Bun.spawn(["sleep", "60"]);
    const tasks = [{ id: "t1", status: "completed" }];
    const subprocesses = new Map([["t1", proc]]);
    const ralph = buildRalph({ prd: { tasks }, subprocesses }) as any;

    try {
      ralph.syncRunningStatus();
      expect(tasks[0].status).toBe("completed");
    } finally {
      proc.kill();
      await proc.exited;
    }
  });

  it("does not overwrite failed status", async () => {
    const proc = Bun.spawn(["sleep", "60"]);
    const tasks = [{ id: "t1", status: "failed" }];
    const subprocesses = new Map([["t1", proc]]);
    const ralph = buildRalph({ prd: { tasks }, subprocesses }) as any;

    try {
      ralph.syncRunningStatus();
      expect(tasks[0].status).toBe("failed");
    } finally {
      proc.kill();
      await proc.exited;
    }
  });
});

describe("processFinishedTask", () => {
  it("marks task as completed on exit code 0", () => {
    const { dir, prdPath, promptPath } = createFixtures({
      tasks: [{ id: "t1", status: "running" }],
    });
    const runDir = mkdtempSync(join(tmpdir(), "ralph-run-"));
    writeFileSync(join(runDir, "t1.log"), "some output");

    const subprocesses = new Map<string, any>([["t1", { pid: 999 }]]);
    const ralph = buildRalph({
      prdFile: prdPath,
      runDir,
      subprocesses,
      promptFile: promptPath,
    }) as any;

    withDir(dir, () => {
      ralph.loadConfig();
      ralph.processFinishedTask("t1", 0);
    });

    const saved = JSON.parse(readFileSync(prdPath, "utf-8"));
    expect(saved.tasks[0].status).toBe("completed");
    expect(ralph.subprocesses.has("t1")).toBe(false);
    expect(existsSync(join(runDir, "t1.log"))).toBe(true);
  });

  it("marks task as failed on non-zero exit code", () => {
    const { dir, prdPath, promptPath } = createFixtures({
      tasks: [{ id: "t1", status: "running" }],
    });
    const runDir = mkdtempSync(join(tmpdir(), "ralph-run-"));

    const subprocesses = new Map<string, any>([["t1", { pid: 999 }]]);
    const ralph = buildRalph({
      prdFile: prdPath,
      runDir,
      subprocesses,
      promptFile: promptPath,
    }) as any;

    withDir(dir, () => {
      ralph.loadConfig();
      ralph.processFinishedTask("t1", 1);
    });

    const saved = JSON.parse(readFileSync(prdPath, "utf-8"));
    expect(saved.tasks[0].status).toBe("failed");
  });
});

// ─── Process management ─────────────────────────────────────────────────────

describe("processAlive", () => {
  it("returns true for a living process", async () => {
    const proc = Bun.spawn(["sleep", "60"]);
    try {
      expect(processAlive(proc.pid)).toBe(true);
    } finally {
      proc.kill();
      await proc.exited;
    }
  });

  it("returns false for a dead PID", () => {
    expect(processAlive(2_000_000_000)).toBe(false);
  });
});

describe("checkRunningTasks", () => {
  it("reaps finished child processes and marks completed", async () => {
    const { dir, prdPath, promptPath } = createFixtures({
      tasks: [{ id: "t1", status: "running" }],
    });
    const runDir = mkdtempSync(join(tmpdir(), "ralph-run-"));

    const proc = Bun.spawn(["true"]);
    await proc.exited;

    const subprocesses = new Map([["t1", proc]]);
    const ralph = buildRalph({
      prdFile: prdPath,
      runDir,
      subprocesses,
      promptFile: promptPath,
    }) as any;

    withDir(dir, () => {
      ralph.loadConfig();
      ralph.checkRunningTasks();
    });

    const saved = JSON.parse(readFileSync(prdPath, "utf-8"));
    expect(saved.tasks[0].status).toBe("completed");
    expect(ralph.subprocesses.size).toBe(0);
  });

  it("marks failed for non-zero exit", async () => {
    const { dir, prdPath, promptPath } = createFixtures({
      tasks: [{ id: "t1", status: "running" }],
    });
    const runDir = mkdtempSync(join(tmpdir(), "ralph-run-"));

    const proc = Bun.spawn(["false"]);
    await proc.exited;

    const subprocesses = new Map([["t1", proc]]);
    const ralph = buildRalph({
      prdFile: prdPath,
      runDir,
      subprocesses,
      promptFile: promptPath,
    }) as any;

    withDir(dir, () => {
      ralph.loadConfig();
      ralph.checkRunningTasks();
    });

    const saved = JSON.parse(readFileSync(prdPath, "utf-8"));
    expect(saved.tasks[0].status).toBe("failed");
  });
});

// ─── Cleanup ────────────────────────────────────────────────────────────────

describe("resetRunningTasksToPending", () => {
  it("resets running tasks to pending in the JSON file", () => {
    const { prdPath } = createFixtures({
      tasks: [
        { id: "t1", status: "running" },
        { id: "t2", status: "completed" },
        { id: "t3", status: "running" },
      ],
    });

    const ralph = buildRalph({ prdFile: prdPath }) as any;
    ralph.resetRunningTasksToPending();

    const saved = JSON.parse(readFileSync(prdPath, "utf-8"));
    expect(saved.tasks[0].status).toBe("pending");
    expect(saved.tasks[1].status).toBe("completed");
    expect(saved.tasks[2].status).toBe("pending");
  });
});

// ─── Rendering: task list ───────────────────────────────────────────────────

describe("renderTaskList", () => {
  it("displays tasks in priority order: running, failed, pending", () => {
    const tasks = [
      { id: "t1", status: "pending", title: "Pending task" },
      { id: "t2", status: "failed", title: "Failed task" },
      { id: "t3", status: "running", title: "Running task" },
      { id: "t4", status: "completed", title: "Completed task" },
    ];
    const ralph = buildRalph({ prd: { tasks } }) as any;

    const output = captureStdout(() => ralph.renderTaskList());

    const runningPos = output.indexOf("Running task");
    const failedPos = output.indexOf("Failed task");
    const pendingPos = output.indexOf("Pending task");

    expect(runningPos).toBeLessThan(failedPos);
    expect(failedPos).toBeLessThan(pendingPos);
    expect(output).not.toContain("Completed task");
  });

  it("truncates long titles", () => {
    const tasks = [{ id: "t1", status: "pending", title: "A".repeat(50) }];
    const ralph = buildRalph({ prd: { tasks } }) as any;

    const output = captureStdout(() => ralph.renderTaskList());
    expect(output).toContain("...");
  });

  it("renders task IDs as OSC 8 hyperlinks to log files", () => {
    const tasks = [{ id: "T-001", status: "running", title: "Test task" }];
    const runDir = "/tmp/ralph-loop-test";
    // Provide a fake subprocess so PID renders
    const fakeProc = { pid: 123 } as any;
    const subprocesses = new Map([["T-001", fakeProc]]);
    const ralph = buildRalph({ prd: { tasks }, runDir, subprocesses }) as any;

    const output = captureStdout(() => ralph.renderTaskList());
    expect(output).toContain(
      "\x1b]8;;file:///tmp/ralph-loop-test/T-001.log\x1b\\T-001\x1b]8;;\x1b\\"
    );
  });

  it("respects maxDisplay limit", () => {
    const tasks = Array.from({ length: 10 }, (_, i) => ({
      id: `t${i + 1}`,
      status: "pending",
      title: `Task ${i + 1}`,
    }));
    const ralph = buildRalph({ prd: { tasks } }) as any;

    const output = captureStdout(() => ralph.renderTaskList(2));
    const pendingCount = (output.match(/pending/g) || []).length;
    expect(pendingCount).toBe(2);
  });
});
