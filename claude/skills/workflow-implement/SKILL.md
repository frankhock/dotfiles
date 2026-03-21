---
name: workflow:implement
description: "Implement features via TDD tracer bullets from contract.md. RED/GREEN/REFACTOR per behavior."
argument-hint: "[project-folder]"
disable-model-invocation: true
---

# Implement

## Initial Setup

1. **Locate project folder** — from argument or auto-detect recent folders in `~/brain/dev/projects/` via **AskUserQuestion tool**
2. **Read context**: `contract.md` (required), `research.md`, `design.md`
   - If no `contract.md` → stop, tell the user to run `/workflow:contract` first

## TDD Cycle

Read `contract.md`. Parse the `## Behaviors` section for `[ ]` (pending) and `[x]` (done) checkboxes.

**If any behaviors are already `[x]`**: Show "Resuming: N/M behaviors complete. Next: [first unchecked behavior name]." Start from the first `[ ]` behavior. If all are `[x]`, skip to REFACTOR.

For each unchecked behavior in order:

### RED
Write one failing test that verifies the behavior through its public interface. Run it — confirm it fails for the right reason. Show the failure.

### GREEN
Implement minimally until the test passes. Run full suite — no regressions.

### Checkpoint
Use **AskUserQuestion tool**: "Behavior N green. Continue to next behavior?"

After user confirms, edit `contract.md` to flip that behavior's `[ ]` to `[x]`. Match on the behavior text to find the correct line. Write to disk immediately — this is crash-safe progress tracking that survives `/clear`.

After all behaviors pass:

### REFACTOR
Extract duplication, apply SOLID, clean up. Tests must stay green. Run full suite.

### Constraints
- Tests verify behavior through public interfaces, not implementation details
- Do NOT write all tests first — that's horizontal slicing
- Each test must fail for the right reason before implementing
- Discover file structure from the codebase and `research.md` — the contract doesn't dictate where code goes

## Mismatch Handling

If reality doesn't match the artifact:
```
Issue:
Expected: [what the artifact says]
Found: [actual situation]
Why this matters: [explanation]
```
Use **AskUserQuestion tool** to ask how to proceed.

## After Implementation Complete

Present next steps via **AskUserQuestion tool**:
- Create PR: `/pr-create`
- Iterate: `/workflow:iterate [folder-name]`
- Done for now
