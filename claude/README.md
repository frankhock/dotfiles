# Claude Code Workflows

A structured workflow system for Claude Code that guides software development
through collaborative planning, thorough research, and verified implementation.

## Overview

This plugin provides a **B-R-P-I pipeline** — four sequential stages that turn
ideas into shipped code:

```
Brainstorm → Research → Plan → Implement
```

Each stage produces an artifact that feeds the next:

| Stage | Command | Output | Purpose |
|-------|---------|--------|---------|
| **Brainstorm** | `/workflows:brainstorm` | `spec.md` | Clarify what to build and why |
| **Research** | `/workflows:research` | `research.md` | Validate assumptions against the codebase |
| **Plan** | `/workflows:plan` | `plan.md` | Design the implementation approach |
| **Implement** | `/workflows:implement` | Working code | Execute the plan with verification |

Additional commands support iteration and autonomous execution:

| Command | Purpose |
|---------|---------|
| `/workflows:iterate` | Refine an existing plan based on feedback |
| `/workflows:plan-ralph` | Create plans for autonomous parallel execution |

All artifacts are stored in project folders under `~/brain/dev/projects`:

```
~/brain/dev/projects/
└── YYYY-MM-DD-ENG-XXXX-feature-name/
    ├── spec.md          # From brainstorm
    ├── research.md      # From research
    ├── plan.md          # From plan
    ├── ralph-tasks.json # For autonomous execution (optional)
    └── ralph-prompt.md  # Shared context for Ralph (optional)
```

---

## Workflow Commands

### `/workflows:brainstorm` — Clarify Ideas Into Requirements

An interactive thought partner that turns vague ideas into clear product
requirements through structured dialogue.

**When to use:** At the start of any non-trivial feature or change, before
writing code or diving into the codebase.

**What it does:**

1. **Initial Setup** — Detects recent project folders in `~/brain/dev/projects`
   and offers to resume an existing spec or start fresh. Pass a folder name as
   an argument to skip detection:
   ```
   /workflows:brainstorm 2025-01-30-ENG-123-feature
   ```

2. **Clarity Gate** — Assesses whether your requirements are already detailed
   enough. If so, offers to skip exploration and jump straight to writing the
   spec.

3. **Lightweight Repo Research** — Scans the codebase for patterns, conventions,
   and existing features related to your topic. Uses findings to ask more
   informed questions.

4. **Understand the Idea** — Asks questions one at a time using multiple-choice
   when natural alternatives exist. Explores purpose, users, constraints,
   must-haves vs nice-to-haves, and what's out of scope.

5. **Explore Approaches** — Proposes 2-3 concrete solution approaches with pros,
   cons, and a recommendation. Prefers simpler solutions (YAGNI).

6. **Present Requirements** — Writes the spec in sections of 200-300 words,
   checking after each section whether it looks right.

**Output:** `spec.md` saved to the project folder with sections for Problem
Statement, Goals, Approach, Requirements (Must/Should/Won't Have), Success
Criteria, Constraints, and Open Questions.

**Next step:** `/workflows:research [folder-name]`

---

### `/workflows:research` — Comprehensive Codebase Research

Spawns parallel research agents to validate assumptions from the spec and
gather implementation details from the actual codebase.

**When to use:** After brainstorming, to ground your spec in reality before
planning. Also useful standalone when you need deep understanding of how
something works in the codebase.

**What it does:**

1. **Read Context** — Loads the spec and any files you mention. Always reads
   complete files before spawning agents.

2. **Classify Risk** — Determines research depth based on the topic:
   - **High-risk:** Security, auth, payments, encryption, external APIs,
     infrastructure — triggers additional web research
   - **Standard:** Feature additions, UI changes, refactoring, bug fixes
   - **Low-risk:** Copy changes, config tweaks, simple CRUD, docs updates

3. **Spawn Parallel Agents** — Launches specialized sub-agents concurrently:
   - **Codebase Locator** — Finds WHERE relevant code lives (files, directories,
     entry points)
   - **Codebase Analyzer** — Understands HOW the code works (data flow, logic,
     patterns)
   - **Codebase Pattern Finder** — Finds existing code examples to model after
   - **Web Search Researcher** — Fetches external documentation and best
     practices (high-risk topics only)

4. **Synthesize Findings** — Combines all agent results into a structured
   document with `file:line` references throughout.

**Important:** All research agents are pure documentarians. They describe what
exists without suggesting improvements or identifying problems.

**Output:** `research.md` with Summary, Detailed Findings, Code References,
Architecture Notes, External Sources (if applicable), and Next Steps.

**Next step:** `/workflows:plan [folder-name]`

---

### `/workflows:plan` — Create Detailed Implementation Plans

Interactive technical planning that combines codebase research with structured
phasing and verification criteria.

**When to use:** After research is complete, to design the implementation
approach before writing code.

**What it does:**

1. **Load Context** — Reads the spec, research, and any existing plan from the
   project folder.

2. **Codebase Research** — Runs a full research pass (same parallel agents as
   `/workflows:research`) focused on implementation concerns.

3. **Classify Tier** — Selects the appropriate plan detail level:
   - **Focused** — 1-3 files, single component, bug fixes, established patterns.
     Minimal ceremony.
   - **Standard** (default) — Multiple files, 2+ systems, moderate complexity.
     Full phased plan.
   - **Comprehensive** — Architectural changes, new systems, high-risk work,
     migrations. Maximum detail with migration notes and performance
     considerations.

4. **Interactive Planning** — Presents the plan in stages, validating with you
   at each step. Resolves all open questions before finalizing.

**Plan structure (Standard tier):**

```
# [Feature Name] Implementation Plan
├── Overview
├── Current State Analysis
├── Desired End State + Key Discoveries
├── What We're NOT Doing
├── Implementation Approach
├── Phase 1-N
│   ├── Overview
│   ├── Changes Required (with file:line references)
│   └── Success Criteria
│       ├── Automated (tests, linting, type checks)
│       └── Manual (visual verification, user flows)
├── Testing Strategy
├── Performance Considerations (Comprehensive tier)
├── Migration Notes (Comprehensive tier)
└── References
```

**Output:** `plan.md` saved to the project folder.

**Next step:** `/workflows:implement [folder-name]` or
`/workflows:plan-ralph [folder-name]`

---

### `/workflows:implement` — Execute Plans With Verification

Implements an approved plan phase by phase, running automated checks and
pausing for manual verification between phases.

**When to use:** After a plan is approved, to execute it with guardrails.

**What it does:**

1. **Load Plan** — Reads the full plan and creates a task list to track
   progress.

2. **Execute Phases** — Works through each phase sequentially:
   - Makes the code changes described in the plan
   - Adapts to real codebase conditions while maintaining plan intent
   - Updates plan checkboxes as work completes

3. **Verify After Each Phase:**
   - Runs automated success criteria (tests, linting, type checks)
   - Reports results and pauses
   - Asks you to perform manual testing
   - Only proceeds to the next phase after you confirm

4. **Handle Mismatches** — When the codebase doesn't match the plan's
   assumptions, communicates clearly and proposes adjustments rather than
   silently deviating.

**Output:** Working code with all plan checkboxes completed.

---

### `/workflows:iterate` — Refine Existing Plans

Makes targeted updates to an existing plan based on feedback, without
rewriting from scratch.

**When to use:** When a plan needs adjustments — scope changes, new
requirements, feedback from review, or discoveries during implementation.

**What it does:**

1. **Read Existing Plan** — Loads the complete current plan.
2. **Understand Changes** — Confirms what you want to change and why.
3. **Research If Needed** — Only spawns agents if changes require new technical
   understanding.
4. **Surgical Edits** — Makes focused changes while preserving the rest of the
   plan. Maintains quality standards and resolves any new open questions.
5. **Show Changes** — Presents what changed and offers further adjustments.

**Output:** Updated `plan.md` in the project folder.

---

### `/workflows:plan-ralph` — Plans for Autonomous Execution

Creates structured task definitions for the Ralph autonomous execution engine,
which runs multiple Claude instances in parallel.

**When to use:** When you want to execute a plan autonomously without
interactive oversight, or when work can be parallelized across independent
tasks.

**What it does:**

Same planning process as `/workflows:plan`, but outputs two files optimized
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
`/workflows:research` and `/workflows:plan`.

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
