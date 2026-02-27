---
name: polish
description: >
  Run the post-implementation pipeline: simplification then review.
  Invoked manually after implementation is complete.
disable-model-invocation: true
argument-hint: "[--skip-simplify] [--skip-review] [--raw]"
---

# Post-Implementation Pipeline: Polish

You are orchestrating the factory's post-implementation pipeline. This pipeline
takes an implementing agent's output and refines it through two sequential stages
before presenting it to the developer.

**Pipeline**: Simplification → Review → Present Results

You run in the main conversation context because you need to spawn sub-agents
via the Task tool. Do NOT attempt to do the simplification or review yourself —
delegate to the specialized sub-agents.

## Arguments

Parse the arguments passed to this skill:
- `--skip-simplify` — skip the simplification stage, go straight to review
- `--skip-review` — skip the review stage, only simplify
- `--raw` — skip both stages, just report the current diff for manual review
- No arguments — run the full pipeline

## Pre-Flight Checks

Before starting the pipeline:

1. **Verify there are changes to process:**
   ```bash
   git diff main...HEAD --stat
   ```
   If no diff exists, report "Nothing to polish — no changes found" and stop.

2. **Run quality gates on the current state** (before any pipeline changes):
   - **Lint**: `./bin/lintbot` (or `bundle exec rubocop` / `yarn lint` as fallback)
   - **Type check**: `yarn tsc` (if TypeScript project)
   - **Related tests**: only tests for changed files (use `--findRelatedTests`, etc.)

   If any gate fails before the pipeline starts, report the failures and stop.
   The implementing agent must fix these first.

3. **Capture the starting commit** so we can roll back if needed:
   ```bash
   git rev-parse HEAD
   ```

## Stage 1: Simplification

Unless `--skip-simplify` or `--raw` was passed:

1. Spawn the `factory-simplifier` sub-agent using the Task tool:
   - **subagent_type**: `factory-simplifier`
   - **prompt**: Include:
     - The base branch to diff against (usually `main`)
     - The project's test command
     - Any project-specific conventions from CLAUDE.md
   - Run in **foreground** (you need the result before proceeding)

2. **Quality gates**: After the simplifier completes, verify lint (`./bin/lintbot`),
   type check (`yarn tsc`), and relevant tests still pass.
   - If any gate fails, the simplifier should have already rolled back.
   - If somehow gates are still failing, reset to the starting commit and
     proceed to review with the original diff. Log this as a pipeline incident.

3. Capture the simplifier's reflection output for the review stage and final report.

## Stage 2: Review

Unless `--skip-review` or `--raw` was passed:

1. Spawn the `factory-reviewer` sub-agent using the Task tool:
   - **subagent_type**: `factory-reviewer`
   - **prompt**: Include:
     - The base branch to diff against
     - The project's test command
     - The simplifier's summary (what was changed and why)
     - The original task description if available
   - Run in **foreground**

2. **Quality gates**: After the reviewer completes (including any auto-fixes),
   verify lint, type check, and relevant tests still pass.

3. Capture the reviewer's reflection and review summary.

## Present Results

After both stages complete, present a consolidated report to the developer:

```markdown
# Pipeline Results

## Diff Summary
[git diff --stat from base to current HEAD]

## Simplification
- Changes made: [count]
- [brief summary of what was simplified]

## Review
- Verdict: [pass-clean | pass-with-annotations | fail]
- Auto-fixes applied: [count]
- Significant findings: [count]

### Significant Findings (if any)
[reviewer's annotated findings — these need human attention]

## Reflections
### Simplifier observations
[key patterns/suggestions from simplifier]

### Reviewer observations
[key patterns/suggestions from reviewer]

### Harness improvement proposals (if any)
[actionable suggestions for improving the factory's prompts/skills/config]

### Codebase improvement proposals (if any)
[refactoring opportunities and shared utility suggestions for the target repo]
```

## Error Handling

| Scenario | Action |
|---|---|
| Simplifier times out | Skip simplification, proceed to review with original diff |
| Reviewer times out | Present what we have with note: "Review incomplete — timed out" |
| Simplifier breaks tests | Already handled by simplifier's rollback. Proceed with original diff. |
| Reviewer auto-fix breaks tests | Already handled by reviewer's rollback. Finding reclassified. |
| No test suite found | Warn developer. Run pipeline without test gates. Add extra note to reviewer: "No test suite — be extra thorough on correctness." |

## Important Notes

- Do NOT modify code yourself. You are the orchestrator, not a participant.
- Do NOT skip stages unless the developer passed the appropriate flag.
- Always present the full report at the end, even if a stage was skipped.
- If both stages produce harness or codebase suggestions, deduplicate them within each category.
