---
name: review-code
description: >
  Structured code review with 8 dimensions and auto-dispatched specialists.
  Use when user asks to review code, review a diff, review a PR, or says
  "what's wrong with this", "tear this apart", "review my changes".
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Review Code

Structured code review using 8 dimensions and auto-dispatched domain specialists.

## Review Process

1. **Gather the diff**: Run `git diff main...HEAD` (or the user-specified scope)
2. **Read full files**: Read every modified file in full — not just the diff
3. **Understand intent**: Read commit messages, PR description, or task context
4. **Read callers/callees**: Check how modified functions are used and what they call
5. **Evaluate all 8 dimensions** against the changes
6. **Dispatch specialists** based on files changed (see Specialist Dispatch)
7. **Produce findings** in the standard format
8. **Write the Review Summary**

## Review Dimensions

Evaluate every diff against these 8 dimensions. Not all apply to every change — use judgment, but always consider each one.

### 1. Correctness

- Does the code do what the task asked for?
- All code paths handled (happy path + error paths)?
- Return values correct in all cases?
- Boundary conditions (off-by-one, operator choice)?
- Async operations properly awaited?
- Resources cleaned up (connections, file handles, listeners)?
- **Principle of Least Surprise**: Does code behave as a reasonable developer would expect?

### 2. Security

- User input validated and sanitized?
- SQL injection, XSS, or command injection vectors?
- Secrets, API keys, or credentials hardcoded or logged?
- Authentication/authorization checks present where needed?
- Sensitive data exposed in error messages or logs?

### 3. Edge Cases

- Null, undefined, empty string, empty array, zero?
- Very large inputs or unbounded collections?
- Concurrent access or race conditions?
- External service unavailability?
- Timeouts configured for network operations?
- Retry safety (idempotent operations only)?
- Distributed failure modes: retry storms, cascading failures, partial failures?

### 4. Architecture

- Module boundaries respected?
- Dependency direction correct (no circular deps)?
- Abstraction level consistent within the module?
- New dependencies justified?
- Follows project's established patterns?
- **Named smells**: Feature envy, shotgun surgery, data clumps, primitive obsession, leaky abstraction?
- **LSP**: Can subtypes replace base types without surprising behavior?
- **YAGNI**: Complexity added "just in case" without a current need?

### 5. Test Quality

- Tests verify behavior, not implementation details?
- Failure cases tested, not just happy paths?
- Edge cases from dimension 3 covered?
- Tests independent (no shared mutable state)?
- Test names describe scenario and expected outcome?
- **Feedback loop speed**: Can a developer verify this change quickly?

### 6. Consistency

- Naming matches the rest of the codebase?
- Error handling pattern matches the module's convention?
- File organization follows project structure?
- Similar problems solved the same way as elsewhere?
- API endpoints follow existing conventions?
- **Explicit over implicit**: No magic behavior or hidden conventions?

### 7. Completeness

- Anything missing that the task implicitly requires?
- Database migrations included if schema changed?
- Environment variables documented if new ones added?
- Feature flags documented?
- Logging sufficient for production debugging?
- **PR scope**: Is this PR doing too much? Should it be split?
- **Commit quality**: Are commits atomic and well-described?

### 8. Observability

- New code paths emit metrics or structured logs?
- Trace context propagated correctly across service boundaries?
- Error states produce actionable alerts?
- Hidden complexity visible in monitoring? (retries, fallbacks, background work)
- Key business events instrumented?
- Performance-sensitive paths have timing metrics?

## Specialist Dispatch

After evaluating dimensions, auto-load relevant specialists from `references/` based on what files changed. Read the specialist file, then apply its detailed checklist.

| Files Changed | Specialist | Reference File |
|---|---|---|
| `db/migrate/`, `db/schema.rb` | Data Integrity | `references/data-integrity-specialist.md` |
| Files with auth, params, user input | Security | `references/security-specialist.md` |
| ActiveRecord queries, N+1 signals, loops over collections | Performance | `references/performance-specialist.md` |
| `app/controllers/`, `app/models/`, `app/services/`, `*.rb` | Rails | `references/rails-specialist.md` |
| `*.ts`, `*.tsx`, `*.js`, `*.jsx` | TypeScript/React | `references/typescript-specialist.md` |

Load 1-3 specialists per review. If the diff is small or single-concern, one specialist may suffice.

## Finding Format

For each issue found:

```
### [SEVERITY] [DIMENSION]

**File**: path/to/file:L42-L58
**Finding**: What the issue is
**Why it matters**: Specific reasoning — not generic
**Suggestion**: Concrete fix, with code if helpful
```

**Severity levels:**
- **error**: Blocking — incorrect behavior, security vulnerability, data loss risk
- **warning**: Non-blocking — code smell, missing test, suboptimal pattern
- **info**: Observation — style suggestion, minor improvement, question for the author

## Review Summary (Required)

After completing the review, output:

```
## Review Summary

**Verdict**: pass | pass-with-findings | fail
**Findings**: X errors, Y warnings, Z info
**Specialists consulted**: [list]

### Errors
[list if any]

### Warnings
[list if any]

### Overall Assessment
[2-3 sentences: change quality, key concerns, confidence level]
```

**Verdicts:**
- **pass**: No findings. Clean.
- **pass-with-findings**: No errors. Warnings/info worth noting.
- **fail**: Errors found. Should not merge without resolution.

## Constraints

- Never modify code. Report only.
- Cite specific files and line numbers for every finding.
- Do not flag issues in code you haven't read in full.
- Do not pad reviews with generic advice. Every finding must be specific and earned.
- If a dimension doesn't apply, skip it silently — don't say "N/A."
