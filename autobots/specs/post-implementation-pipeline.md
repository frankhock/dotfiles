# Post-Implementation Pipeline: Detailed Spec

> **Status**: Draft
> **Date**: 2026-02-27
> **Parent**: [Vision PRD](../vision-prd.md) — Feature Areas #4 (QA Pipeline) and #9 (Self-Reflection)

---

## 1. Overview

When an implementing agent completes a task, the code should not go directly to the human. Raw agent output is a rough draft — functional but often over-engineered, inconsistently styled, or missing edge cases. The post-implementation pipeline refines that output through two sequential services before it reaches human eyes (or merges autonomously, depending on trust tier).

```
Implementing Agent
  → Simplification Service
    → Review Service
      → Human Review / Auto-Merge (based on trust tier)
```

The goal: **every piece of code the human sees has already been simplified and reviewed by specialized agents.** Human attention is the scarcest resource in the factory. Don't waste it on rough drafts.

---

## 2. Pipeline Architecture

### 2.1 Execution Model

Both services run as **Claude Code sub-agents** — separate sessions with specialized system prompts, scoped tool access, and their own context windows. They operate in the same git worktree as the implementing agent, on the same branch.

```
┌──────────────────────────────────────────────────────────┐
│  WORKTREE (feature branch)                               │
│                                                          │
│  1. Implementing agent commits its work                  │
│  2. Simplification sub-agent runs against that commit    │
│  3. If changes made → new commit → test gate             │
│  4. Review sub-agent runs against current HEAD            │
│  5. If auto-fixes → new commit → test gate               │
│  6. Pipeline produces final artifact for human/merge      │
└──────────────────────────────────────────────────────────┘
```

### 2.2 Stage Transitions

Every transition between stages is gated by **relevant tests passing** — only tests corresponding to the modified files, not the full suite. Full suite runs are too slow to use as pipeline gates.

Relevant test identification:
- Find test files corresponding to changed source files (e.g., `foo.ts` → `foo.test.ts`)
- Use targeted runners when available (`jest --findRelatedTests`, `pytest <files>`, `vitest run <files>`)
- Fall back to module/directory-level test runs if file-level targeting isn't possible

| Transition | Gate | On Failure |
|---|---|---|
| Implementation → Simplification | Quality gates pass (lint, type check, related tests) on implementing agent's commit | Pipeline halts. Implementing agent must fix. |
| Simplification → Review | Quality gates pass (lint, type check, related tests) after simplification changes | Simplification rolls back all changes. Original diff passes to review. Reflection logged: "simplification broke tests." |
| Review (auto-fix) → Output | Quality gates pass (lint, type check, related tests) after review auto-fixes | Auto-fix rolls back. Issue reclassified as "significant" and flagged for human. Reflection logged. |

### 2.3 Data Flow

Each stage receives and produces a structured artifact:

```
PipelineArtifact {
  task_id: string              // originating task
  branch: string               // git branch
  base_commit: string          // commit before implementing agent's work
  current_commit: string       // HEAD after this stage
  diff: string                 // cumulative diff from base_commit to current_commit
  test_results: TestResults    // full suite results at this stage
  stage: "implementation" | "simplification" | "review"
  reflection: Reflection       // structured self-reflection from this stage
  annotations: Annotation[]    // review findings (review stage only)
}
```

---

## 3. Simplification Service

### 3.1 Purpose

Reduce complexity and improve clarity of the implementing agent's output **without changing behavior**. The simplifier is a copy editor, not a co-author.

### 3.2 Scope

**Diff-only.** The simplifier may only modify lines that were added or changed by the implementing agent. It reads surrounding code for context but does not touch it.

How this works in practice:
- The simplifier receives the diff (from `base_commit` to the implementing agent's commit)
- It can only edit within the bounds of that diff
- If it sees an opportunity to improve surrounding code, it logs it as a reflection ("consider queuing a cleanup task for X") but does not act on it

### 3.3 Operations

The simplifier performs the following, in priority order:

| Operation | Description | Example |
|---|---|---|
| **Remove dead code** | Delete unused imports, variables, functions introduced by the implementing agent | Agent imported `lodash` but never used it |
| **Collapse unnecessary abstraction** | Inline single-use helpers, unwrap trivial wrappers, flatten needless class hierarchies | Agent wrote a `formatDate()` helper called exactly once |
| **Simplify control flow** | Reduce nesting, convert complex conditionals to early returns, simplify boolean logic | `if (x) { if (y) { ... } }` → `if (x && y) { ... }` |
| **Normalize naming** | Rename variables/functions to match codebase conventions | Agent used `camelCase` in a `snake_case` codebase |
| **Remove redundant comments** | Strip comments that restate the code | `// increment counter` above `counter += 1` |
| **Normalize style** | Formatting, import ordering, consistent patterns | Following the repo's established conventions |

### 3.4 Constraints

The simplifier **must not**:
- Change the behavior of the code (any observable difference in output, side effects, or error handling)
- Add new functionality or features
- Refactor code outside the diff boundary
- Add comments, documentation, or type annotations unless the codebase convention demands them and they're missing
- Introduce new dependencies
- Modify test files (tests are the invariant, not the subject)

### 3.5 Sub-Agent Configuration

```yaml
simplification_agent:
  model: claude-sonnet  # fast, capable enough for mechanical transforms
  system_prompt: simplification-system.md
  tools:
    - Read
    - Edit
    - Grep
    - Glob
    - Bash (restricted: test runners only)
  context:
    - CLAUDE.md hierarchy (repo conventions)
    - The implementing agent's diff
    - File-level context for all modified files
  max_turns: 20
  timeout: 10 minutes
```

**Why Sonnet, not Opus?** Simplification is mechanical and well-scoped. It doesn't need the deepest reasoning — it needs speed and reliability. Save Opus cycles for review and implementation.

### 3.6 Output

The simplifier produces:
1. **A commit** (if changes were made) with message: `simplify: <brief description of changes>`
2. **A diff summary** — what it changed and why, structured for the review service to consume
3. **A reflection** (see Section 5)

If the simplifier determines no changes are needed, it passes the artifact through unchanged and logs a reflection noting the implementing agent produced clean output (positive signal for trust).

---

## 4. Review Service

### 4.1 Purpose

Evaluate the simplified code for correctness, security, architecture adherence, and completeness. The reviewer is the factory's last automated quality gate.

### 4.2 Scope

The reviewer reads the **full diff** (implementation + simplification) with **full file context**. Unlike the simplifier, the reviewer needs to understand the broader system to judge whether the change is correct and well-integrated.

### 4.3 Review Dimensions

| Dimension | What it checks | Examples |
|---|---|---|
| **Correctness** | Does this do what the task asked? Does the logic handle all cases? | Off-by-one errors, missing return statements, wrong operator |
| **Security** | OWASP top 10, injection vectors, leaked secrets, unsafe patterns | Unsanitized user input, hardcoded credentials, SQL injection |
| **Edge cases** | Null/empty/zero, concurrent access, large inputs, boundary conditions | Missing null check, no rate limit, unbounded array growth |
| **Architecture** | Module boundaries, dependency direction, separation of concerns | Reaching across module boundaries, circular dependencies |
| **Test quality** | Are tests meaningful? Do they test behavior or just chase coverage? | Tests that assert on implementation details, missing failure cases |
| **Consistency** | Does this follow the patterns established elsewhere in the codebase? | Using a different error handling pattern than the rest of the module |
| **Completeness** | Is anything missing that the task implicitly requires? | Task says "add validation" but only the happy path is implemented |

### 4.4 Finding Classification (Tiered Response)

Every finding is classified into one of two tiers:

#### Minor Findings → Auto-Fix

Issues where the fix is unambiguous and low-risk. The review agent fixes them directly.

- Naming inconsistencies the simplifier missed
- Missing error handling for obvious cases (e.g., null check on a nullable parameter)
- Incorrect or misleading comments
- Minor style violations
- Missing type annotations (if codebase convention requires them)

**Auto-fix rules:**
- Each auto-fix must be individually small (< 10 lines changed)
- Tests must pass after each auto-fix
- Maximum **3 auto-fix rounds**. If still finding minor issues after 3 rounds, batch remaining as annotations for the human.

#### Significant Findings → Flag for Human

Issues where the fix requires judgment, has multiple valid approaches, or carries meaningful risk.

- Logic errors or incorrect behavior
- Security vulnerabilities
- Architectural violations
- Missing functionality
- Design decisions that could go multiple ways
- Performance concerns with real-world impact

**Annotation format:**

```
ReviewAnnotation {
  file: string
  line_start: number
  line_end: number
  severity: "warning" | "error"
  dimension: "correctness" | "security" | "edge_case" | "architecture" | "test_quality" | "consistency" | "completeness"
  finding: string          // what the issue is
  reasoning: string        // why it matters
  suggestion: string       // what the reviewer would do (not applied)
  confidence: float        // 0-1, how confident the reviewer is this is a real issue
}
```

### 4.5 Sub-Agent Configuration

```yaml
review_agent:
  model: claude-opus  # review requires deep reasoning
  system_prompt: review-system.md
  tools:
    - Read
    - Edit (for auto-fixes only)
    - Grep
    - Glob
    - Bash (restricted: test runners only)
  context:
    - CLAUDE.md hierarchy
    - Full diff (implementation + simplification)
    - Full file content for all modified files
    - Simplification summary (what the simplifier changed and why)
    - Task description (what was the implementing agent trying to do?)
    - Related code (callers/callees of modified functions)
  max_turns: 30
  timeout: 15 minutes
```

**Why Opus?** Review is the highest-judgment task in the pipeline. Missing a security issue or flagging a false positive both waste human time and erode trust. This is where you spend the cycles.

### 4.6 Output

The reviewer produces:
1. **Auto-fix commits** (if any), each with message: `review-fix: <description>`
2. **Annotations** for significant findings
3. **A review summary** — overall assessment, key findings, confidence level
4. **A pass/fail signal**:
   - **Pass (clean)**: no significant findings. Ready for auto-merge or lightweight human review.
   - **Pass (with annotations)**: significant findings exist but none are blockers. Human should review.
   - **Fail**: blocking issues found. Should not merge without human resolution.
5. **A reflection** (see Section 5)

---

## 5. Self-Reflection Integration

Both services produce structured reflections after every run. This is where Feature Area #9 lives inside the pipeline.

### 5.1 Reflection Schema

```
Reflection {
  task_id: string
  stage: "simplification" | "review"
  timestamp: ISO-8601
  duration_seconds: number

  // What happened
  changes_made: number           // count of modifications
  issues_found: number           // count of findings (review only)
  auto_fixes_applied: number     // count of auto-fixes (review only)
  rollbacks: number              // count of test-gate failures

  // What was learned
  patterns_observed: Pattern[]   // recurring things worth noting
  agent_feedback: string         // freeform observation about the implementing agent's output
  context_gaps: string[]         // what context was missing or would have helped
  harness_suggestions: string[]   // proposed improvements to prompts, CLAUDE.md, skills, or agent config
  codebase_suggestions: string[]  // proposed improvements to the target codebase (shared utilities, refactoring, cleanup)

  // Meta
  confidence: float              // how confident this agent is in its own work
  difficulty: "trivial" | "routine" | "challenging" | "at_limits"
}

Pattern {
  type: "strength" | "weakness" | "recurring_issue"
  scope: string       // e.g., "payments module", "test generation", "error handling"
  description: string
  frequency: number   // how many times seen in this run (or across runs if available)
}
```

### 5.2 Reflection Examples

**Simplifier reflection:**
```json
{
  "agent_feedback": "Implementing agent introduced 4 single-use wrapper functions. This is the 3rd consecutive task where over-abstraction was the primary simplification target.",
  "patterns_observed": [
    {
      "type": "recurring_issue",
      "scope": "implementing agent prompt",
      "description": "Agent consistently wraps simple operations in unnecessary helper functions",
      "frequency": 3
    }
  ],
  "harness_suggestions": [
    "Add explicit instruction to implementing agent prompt: 'Do not create helper functions for operations used fewer than 3 times'"
  ]
}
```

**Reviewer reflection:**
```json
{
  "agent_feedback": "Clean implementation overall. One missing null check on the API response — this is the same pattern as TASK-142 last week in the same module.",
  "patterns_observed": [
    {
      "type": "recurring_issue",
      "scope": "api-client module",
      "description": "Null checks consistently missing on external API response bodies",
      "frequency": 2
    }
  ],
  "harness_suggestions": [
    "Update CLAUDE.md for api-client module: 'All external API responses must be null-checked before field access'"
  ],
  "codebase_suggestions": [
    "Consider adding a shared utility for safe API response unwrapping"
  ],
  "context_gaps": [
    "No documentation on which API endpoints can return null bodies vs. empty objects"
  ]
}
```

### 5.3 Feedback Loop

Reflections are stored and aggregated. When patterns reach a threshold (configurable, default: 3 occurrences of the same pattern), the autobot surfaces proposals to the developer. The two suggestion types are surfaced differently:

**Harness improvement proposals** change the autobot itself — prompts, CLAUDE.md, skills, agent config:

```
Autobot: I've noticed a recurring pattern across 4 recent tasks:

  "Implementing agent consistently over-abstracts in the payments module,
   creating single-use helpers that the simplifier then inlines."

  Proposed fix: Add to payments module CLAUDE.md:
    "Prefer inline code over helper functions unless the logic is
     used 3+ times or is complex enough to warrant a named concept."

  This would reduce simplification work by ~30% in this module.

  [Apply] [Modify] [Dismiss]
```

**Codebase improvement proposals** are refactoring opportunities in the target repo — shared utilities, code promotion, cleanup. These are surfaced as follow-up tasks rather than config changes:

```
Autobot: Across 3 recent tasks in the payments module, the same
  Math.round(dollars * 100) pattern appears. Consider queuing a
  cleanup task to extract a shared dollarsToCents utility.

  [Queue Task] [Dismiss]
```

The developer approves, modifies, or dismisses. The autobot learns either way.

---

## 6. Pipeline Configuration

### 6.1 Per-Repository Config

Stored in `.autobots/pipeline.yaml` at the repo root (or in the factory's own config if we don't want to pollute the repo):

```yaml
post_implementation_pipeline:
  simplification:
    enabled: true
    model: claude-sonnet
    scope: diff_only              # diff_only | diff_and_context (future)
    max_turns: 20
    timeout_minutes: 10
    skip_if:
      - task_type: "documentation"  # no simplification on docs-only changes
      - task_type: "config"         # no simplification on config changes

  review:
    enabled: true
    model: claude-opus
    max_turns: 30
    timeout_minutes: 15
    auto_fix:
      enabled: true
      max_rounds: 3
      max_lines_per_fix: 10
    dimensions:                     # enable/disable review dimensions
      correctness: true
      security: true
      edge_cases: true
      architecture: true
      test_quality: true
      consistency: true
      completeness: true

  quality_gates:
    lint:
      enabled: true
      command: "./bin/lintbot"     # lints changed files only
      autofix_command: "./bin/lintbot -f"
      # Fallbacks if bin/lintbot not present:
      #   Ruby: bundle exec rubocop
      #   JS/TS: yarn lint
    type_check:
      enabled: true
      command: "yarn tsc"          # auto-disabled for non-TS projects
    tests:
      strategy: related            # related | module | full
      # "related" (default): only tests for modified files (e.g., jest --findRelatedTests)
      # "module": tests for the directory/module containing changes
      # "full": entire suite (not recommended — too slow for pipeline gates)
    timeout_minutes: 5
    required: true                 # if false, pipeline continues on gate failure (not recommended)

  reflection:
    enabled: true
    pattern_threshold: 3            # occurrences before surfacing a harness improvement
    store: ".autobots/reflections/"  # where reflections are persisted
```

### 6.2 Per-Task Overrides

A developer can override pipeline behavior when queueing a task:

```bash
# Skip simplification (I want raw output fast)
autobot queue "fix the login bug" --skip-simplify

# Skip review (I trust this is trivial)
autobot queue "update copyright year in footer" --skip-review

# Skip both (just implement, I'll review myself)
autobot queue "prototype the new search API" --raw
```

Overrides are logged. If a `--skip-review` task later causes a revert, that's signal for the trust system.

---

## 7. Error Handling & Edge Cases

| Scenario | Behavior |
|---|---|
| Simplifier times out | Pass original diff to reviewer unchanged. Log reflection. |
| Reviewer times out | Flag for human review with note: "review incomplete due to timeout." Log reflection. |
| Simplifier breaks a quality gate | Roll back simplification. Pass original diff to reviewer. Log reflection with which gate failed and why. |
| Review auto-fix breaks a quality gate | Roll back that auto-fix. Reclassify as significant finding. Continue with remaining auto-fixes. |
| Auto-fix loop (3 rounds exhausted) | Stop auto-fixing. Batch remaining minor issues as annotations. |
| Quality gates already failing before pipeline | Pipeline does not start. Implementing agent must fix first. |
| No test suite exists | Pipeline runs type check gate. Test gate skipped. Reviewer gets extra instruction to be more thorough on correctness. Reflection flags: "no test suite — high risk." |
| Non-TypeScript project | Type check gate auto-disabled. Test gate still runs. |
| Diff is empty (agent made no changes) | Pipeline skips both services. Task is flagged as "completed with no code changes" for human review. |
| Diff is massive (>500 lines) | Pipeline runs but reviewer gets extra context budget and time. Reflection flags large diffs as a potential decomposition issue. |

---

## 8. Metrics & Observability

The pipeline itself is measured. These metrics feed into Feature Area #8 (Observability) and Feature Area #9 (Self-Reflection):

| Metric | What it tells us |
|---|---|
| **Simplification change rate** | % of diffs that the simplifier modifies. High rate = implementing agents are producing rough code. Trending down = autobots are improving. |
| **Review pass rate** | % of diffs that pass review with no significant findings. Trending up = quality is improving. |
| **Auto-fix rate** | % of review findings auto-fixed vs. flagged for human. High auto-fix rate = most issues are minor. |
| **Rollback rate** | % of simplifications or auto-fixes that break tests. Should be very low. If trending up, something is wrong. |
| **Human override rate** | % of review annotations the human dismisses as false positives. High rate = reviewer is too aggressive; tune it. |
| **Pipeline duration** | End-to-end time from implementation complete to human-ready. Target: < 10 minutes for task-level, < 30 minutes for feature-level. |
| **Reflection action rate** | % of harness improvement proposals the developer accepts. Signal for how useful the self-reflection system is. |

---

## 9. Implementation Sequence

What to build, in what order:

### Step 1: Simplification sub-agent (standalone)
- System prompt for simplification
- Diff-scoped editing logic
- Test gate (run tests, roll back on failure)
- Can be tested independently against any branch with changes

### Step 2: Review sub-agent (standalone)
- System prompt for review
- Finding classification (minor vs. significant)
- Auto-fix loop with test gate
- Annotation output format
- Can be tested independently against any branch with changes

### Step 3: Pipeline orchestrator
- Wires simplification → review in sequence
- Manages the artifact handoff between stages
- Handles stage transition gates
- Handles error/timeout/rollback scenarios

### Step 4: Reflection capture
- Structured reflection output from both services
- Reflection store (file-based initially)
- Pattern aggregation

### Step 5: CLI integration
- Pipeline runs automatically after task completion
- `autobot review` shows annotated output from the pipeline
- `autobot config` exposes pipeline settings

### Step 6: Feedback loop
- Pattern threshold surfacing
- Harness improvement proposals
- Developer approve/modify/dismiss flow
