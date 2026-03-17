# Claude Code Workflows

A structured workflow system for Claude Code that guides software development
through collaborative planning, thorough research, and verified implementation.

## Overview

This plugin provides a **QRSPI pipeline** — focused stages that turn ideas into
shipped code, each producing one artifact that feeds the next:

```
Questions → Research → Design → Structure → Plan → Worktree → Implement → PR
```

| Stage | Command | Output | Purpose |
|-------|---------|--------|---------|
| **Questions** | `/workflow:questions` | `spec.md` | Clarify what to build and why |
| **Research** | `/workflow:research` | `research.md` | Objective codebase facts |
| **Design** | `/workflow:design` | `design.md` | Iterative design conversation |
| **Structure** | `/workflow:structure` | `structure.md` | Vertical slice decomposition |
| **Plan** | `/workflow:plan` | `plan/` | Tactical implementation steps |
| **Worktree** | `/workflow:worktree` | branch + worktree | Isolated workspace |
| **Implement** | `/workflow:implement` | Working code | Execute the plan with verification |
| **PR** | `/pr-create` | Pull request | Ship it |

Additional commands:

| Command | Purpose |
|---------|---------|
| `/workflow:iterate` | Edit any workflow artifact (design, structure, plan) |
| `/workflow:plan-ralph` | Create plans for autonomous parallel execution |

All artifacts are stored in project folders under `~/brain/dev/projects`:

```
~/brain/dev/projects/
└── YYYY-MM-DD-ENG-XXXX-feature-name/
    ├── spec.md          # From questions
    ├── research.md      # From research
    ├── design.md        # From design
    ├── structure.md     # From structure
    ├── plan/            # From plan (split format)
    │   ├── index.md
    │   └── phases/
    ├── ralph-tasks.json # For autonomous execution (optional)
    └── ralph-prompt.md  # Shared context for Ralph (optional)
```

---

## Workflow Commands

### `/workflow:questions` — Clarify Ideas Into Requirements

An interactive thought partner that turns vague ideas into clear product
requirements through structured dialogue. Asks one question at a time,
YAGNI-focused.

**Output:** `spec.md` — **Next step:** `/workflow:research [folder-name]`

---

### `/workflow:research` — Comprehensive Codebase Research

Spawns parallel research agents to gather objective codebase facts. Surfaces
competing patterns without picking a winner — that's Design's job. All agents
are pure documentarians.

**Output:** `research.md` — **Next step:** `/workflow:design [folder-name]`

---

### `/workflow:design` — Iterative Design Conversation

Builds a shared design concept through iterative grilling. Surfaces AI
understanding so the human can correct thinking. Decides which competing
patterns to use. The quality of this conversation predicts everything downstream.

**Output:** `design.md` — **Next step:** `/workflow:structure [folder-name]`

---

### `/workflow:structure` — Vertical Slice Decomposition

Decomposes the approved design into independently testable vertical slices.
Each phase touches all layers (db → services → api → frontend) with LOC budgets
of 200-400 lines.

**Output:** `structure.md` — **Next step:** `/workflow:plan [folder-name]`

---

### `/workflow:plan` — Write Tactical Plan

Mechanical plan writing — takes approved design + structure, writes tactical
plan files with file-level changes and success criteria. No discovery, no
design discussion.

**Output:** `plan/` directory — **Next step:** `/workflow:worktree [folder-name]` or `/workflow:implement [folder-name]`

---

### `/workflow:worktree` — Create Implementation Worktree

Creates an isolated git worktree for implementation — a clean workspace on
its own branch. Runs workspace setup automatically.

**Output:** branch + worktree — **Next step:** `/workflow:implement [folder-name]`

---

### `/workflow:implement` — Execute Plans With Verification

Implements an approved plan phase by phase, pausing for manual verification
between phases. Reads design.md and structure.md for context alongside the plan.

**Output:** Working code — **Next step:** `/pr-create`

---

### `/workflow:iterate` — Edit Workflow Artifacts

Surgical edits to any workflow artifact (design.md, structure.md, plan/).
Routes large changes back to the appropriate upstream skill instead of
trying to do discovery here.

**Output:** Modified artifact

---

### `/workflow:plan-ralph` — Plans for Autonomous Execution

Creates structured task definitions for the Ralph autonomous execution engine,
which runs multiple Claude instances in parallel.

**When to use:** When you want to execute a plan autonomously without
interactive oversight, or when work can be parallelized across independent
tasks.

**What it does:**

Same planning process as `/workflow:plan`, but outputs two files optimized
for autonomous execution:

- **`ralph-tasks.json`** — Task definitions with IDs, descriptions, and
  acceptance criteria
- **`ralph-prompt.md`** — Shared context and instructions for all tasks

**Task constraints for autonomous execution:**
- Each task must be completable in one Claude context window
- Acceptance criteria must be specific and mechanically verifiable
- Execution order is strictly enforced (no forward dependencies)
- Tasks are scoped tightly to prevent scope creep during autonomous runs

**ralph-tasks.json structure:**

```json
{
  "project": "Feature Name",
  "description": "Brief description",
  "maxParallel": 1,
  "checkInterval": 15,
  "promptFile": "~/brain/dev/projects/[folder]/ralph-prompt.md",
  "tasks": [
    {
      "id": "T-001",
      "title": "Create user model",
      "description": "2-3 sentence description",
      "acceptanceCriteria": [
        "User model exists at src/models/user.ts",
        "All fields from spec are present",
        "Lint passes"
      ],
      "status": "pending"
    }
  ]
}
```

**Execution:** Run tasks with the Ralph loop script:

```bash
ralph-loop -p ralph-tasks.json -j 4 -d 15
```

Options:
- `-p` — Path to tasks file
- `-m` — Override prompt file
- `-j` — Max parallel jobs
- `-d` — Check interval in seconds
- `-k` — Kill all running processes

---

## Other Commands

### `/commit` — Git Commits

Creates git commits with your approval. Analyzes staged and unstaged changes,
drafts a commit message, and asks for confirmation before committing.

**Key behavior:** No Claude attribution or co-author lines — commits are
authored solely by you.

```
/commit
```

---

### `/pr-create` — Pull Requests

Analyzes your branch changes and creates a GitHub pull request with a
generated title and description.

```
/pr-create
```

---

### `/quick-ticket` — Minimal Ticket Outlines

Generates Linear ticket outlines from git commits or feature branches. Useful
for retroactive documentation of completed work.

```
/quick-ticket              # Uses current branch
/quick-ticket abc123f      # Uses specific commit
```

---

## Skills

### `review` — Persona-Driven Code Reviews

Provides code reviews from the perspective of renowned software engineers and
development philosophies. Choose a single reviewer or combine multiple
perspectives.

**Available personas:**

| Persona | Focus |
|---------|-------|
| AI Reviewer | Adaptive systems, emergent behavior, data-driven design |
| Anders Hejlsberg | Strong typing, language ergonomics, structured APIs |
| Kent Beck | TDD discipline, rapid feedback, adaptive design |
| Bjarne Stroustrup | Performance via abstraction, type safety |
| Brendan Eich | Rapid innovation, creative problem-solving |
| John Carmack | Low-level excellence, performance tuning, precision |
| Jeff Dean | Planet-scale systems, distributed reliability |
| DHH | Opinionated conventions, developer autonomy, simplicity |
| Martin Fowler | Refactoring, evolutionary architecture, intentional design |
| GitHub Generation | Collaboration, docs, CI/CD automation |
| Grace Hopper & Barbara Liskov | Abstraction, substitutability, modularity |
| Guido van Rossum | Readability, Pythonic simplicity |
| James Gosling | JVM portability, API stability, backward compatibility |
| Chris Lattner | Compiler/toolchain innovation, interoperability |
| Linus Torvalds | Kernel rigor, patch discipline, honest feedback |
| Matz (Yukihiro Matsumoto) | Ruby aesthetics, human-centric design |
| Brendan Gregg & Liz Rice | Observability, tracing, data-first performance |
| React Core Maintainer | Hooks, concurrent rendering, DX-focused patterns |
| Rob Pike | Go/Unix minimalism, concurrency, composable tooling |
| Unix Traditionalist | Small sharp tools, composability, text-first automation |

---

### `issue-create` — Development Issue Generation

Generates structured Linear-ready development issues with title, context,
scope, acceptance criteria, and effort estimates.

```
/issue-create
```

---

## Research Agents

The workflow commands spawn these specialized agents as parallel sub-tasks.
They are not invoked directly — they run behind the scenes during
`/workflow:research` and `/workflow:plan`.

| Agent | Tools | Purpose |
|-------|-------|---------|
| **Codebase Locator** | Grep, Glob, LS | Find WHERE code lives — files, directories, entry points |
| **Codebase Analyzer** | Read, Grep, Glob, LS | Understand HOW code works — data flow, logic, patterns |
| **Codebase Pattern Finder** | Grep, Glob, Read, LS | Find existing code examples to model after |
| **Web Search Researcher** | WebSearch, WebFetch, Read, Grep, Glob, LS | Fetch external docs and best practices (high-risk topics) |

All agents are **documentarians only** — they describe what exists without
suggesting improvements or identifying problems.

---

## Setup

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed

### Installation

Clone this repository and configure Claude Code to use it:

```bash
git clone <repo-url> ~/dotfiles
```

Add the plugin to your Claude Code settings (`.claude/settings.json`):

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  }
}
```

### Configuration

Project artifacts are stored at `~/brain/dev/projects/`. This path is
hardcoded in all workflow commands for reliability.

---

## Design Principles

- **Interactive at every step** — Every user-facing question uses structured
  prompts with multiple-choice options when possible
- **Research before planning** — Always understand the codebase before
  designing changes
- **Tiered complexity** — Match the level of ceremony to the actual complexity
  of the task
- **Verified implementation** — Separate automated and manual success criteria;
  pause between phases
- **Pure documentation** — Research agents describe what exists, never
  prescribe what should change
- **No open questions** — Resolve all uncertainties before finalizing any
  artifact
- **Explicit handoffs** — Each stage produces a clear artifact that feeds the
  next
