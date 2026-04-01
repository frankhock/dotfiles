---
name: workflow:implement
description: "Implement features via TDD tracer bullets from contract.md. RED/GREEN/REFACTOR per behavior."
argument-hint: "[project-folder]"
---

# Implement

## Setup

1. **Locate project folder** — from argument or auto-detect recent folders in `~/brain/dev/projects/`, ask if unclear
2. **Read context**: `contract.md` (required), `research.md`, `design.md`
   - If no `contract.md` → stop, tell the user to run `/workflow:contract` first

## TDD Cycle

Read `contract.md`. Parse `## Behaviors` for `[ ]` (pending) and `[x]` (done) checkboxes.

**Resuming**: If any behaviors are `[x]`, show "Resuming: N/M behaviors complete. Next: [first unchecked]." Start from first `[ ]`. If all `[x]`, skip to REFACTOR.

For each unchecked behavior in order:

### RED
Write one failing test that verifies the behavior through its public interface. Run it — confirm it fails for the right reason. Show: "❌ [behavior name]" with the failure reason.

### GREEN
Implement minimally until the test passes. Run full suite — no regressions.

### Checkpoint
Flip that behavior's `[ ]` to `[x]` in `contract.md` (this survives `/clear`). Then **stop** and present:
```
✅ [behavior name] complete (N/M behaviors done)

Next steps — tell me what you'd like:
- Continue to next behavior: [next behavior name]
- Commit first, then continue
- Commit and end session (re-invoke /workflow:implement to resume later)
```

**Do not proceed to the next behavior until the user explicitly says to.**

After all behaviors pass:

### REFACTOR
Extract duplication, clean up. Tests must stay green. Run full suite.

### Constraints
- Do NOT write all tests first — one RED/GREEN cycle at a time
- Each test must fail for the right reason before implementing
- Discover file structure from the codebase and `research.md` — the contract doesn't dictate where code goes

## Mismatch Handling

If reality contradicts `contract.md`, flag what you expected vs. what you found, explain why it matters, and ask how to proceed.

## After Implementation Complete

Present next steps:
- Create PR: `/pr-create`
- Iterate: `/workflow:iterate [folder-name]`
