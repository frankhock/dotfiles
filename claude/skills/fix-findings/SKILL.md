---
name: fix-findings
description: >
  Validate and fix autobot reviewer findings. Parses review output,
  independently verifies each finding against the actual code, rejects
  false positives, and implements valid fixes. Use when you have reviewer
  output to act on, or say "fix findings", "triage findings",
  "process review output".
disable-model-invocation: true
argument-hint: "[paste reviewer findings]"
allowed-tools: Read, Edit, Grep, Glob, Bash, Agent
---

# Fix Findings

Validate autobot reviewer findings against actual code, reject false positives,
and implement valid fixes.

## Input

Parse `$ARGUMENTS` as reviewer output. Extract each finding by matching the
annotation format:

- `### [SEVERITY: ...] [DIMENSION: ...]` blocks from autobot-reviewer
- `### [SEVERITY] [DIMENSION]` blocks from review-code

Each finding has: file, line range, severity, dimension, finding text,
reasoning, suggestion, and confidence.

## Process

### Phase 1: Independent Validation

For each finding, validate it independently — do NOT trust the reviewer's
conclusion. For every finding:

1. **Read the cited file in full** — not just the lines mentioned
2. **Understand the surrounding context** — read callers, callees, tests, and
   related code
3. **Evaluate the claim** — is the finding actually true in context?
4. **Check the suggestion** — would the proposed fix actually help, or
   introduce new issues?

Classify each finding as:

- **valid** — the issue is real and the suggestion (or a variant) should be applied
- **valid-different-fix** — the issue is real but the suggested fix is wrong;
  you have a better approach
- **false-positive** — the issue doesn't exist or is irrelevant in context
- **already-handled** — the code already addresses this concern elsewhere

Use parallel Agent calls to validate multiple findings concurrently when there
are 3+ findings.

### Phase 2: Triage Report

Present a summary before making any changes:

```
## Findings Triage

| # | Severity | Dimension | File | Verdict | Reason |
|---|----------|-----------|------|---------|--------|
| 1 | warning  | security  | ... | valid | ... |
| 2 | error    | correctness | ... | false-positive | ... |
...

**Will fix**: X findings
**Rejected**: Y findings (Z false positives, W already handled)
```

For each rejected finding, explain specifically why it's wrong — cite the code
that disproves it.

### Phase 3: Implement Fixes

For each valid finding, in order of severity (errors first):

1. Implement the fix (use the reviewer's suggestion as a starting point, but
   adapt based on your own understanding)
2. Verify the fix doesn't break surrounding logic by reading affected code paths

After all fixes are applied, run tests for modified files to verify correctness.
If a test fails, investigate whether your fix caused it. If so, revise the fix
or revert it and report.

## Constraints

- NEVER apply a fix you haven't independently verified. Reading the reviewer's
  reasoning is not sufficient — you must read the actual code.
- NEVER fix a finding you've classified as false-positive or already-handled.
- Do not refactor, clean up, or "improve" code beyond what the finding requires.
- If a suggestion would change behavior beyond fixing the stated issue, flag it
  and skip.
- If you're uncertain whether a finding is valid (genuinely 50/50), classify it
  as valid and note your uncertainty — let the fix + tests decide.

## Output

After completion:

```
## Fix Findings Summary

**Processed**: X findings
**Fixed**: Y
**Rejected**: Z (with reasons above)
**Tests**: pass | fail (details if fail)

### Fixes Applied
- [file:line] [dimension] — what was changed

### Rejected Findings
- [file:line] [dimension] — why it was rejected
```
