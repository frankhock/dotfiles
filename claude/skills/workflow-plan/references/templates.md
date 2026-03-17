# Plan Templates

Use the template matching the selected tier.

## Focused Tier

Single file `plan.md`:

````markdown
# [Feature/Task Name] Implementation Plan

**Tier:** Focused

## Overview

[2-3 sentence description of what we're implementing and why]

## What We're NOT Doing

[Explicitly list out-of-scope items to prevent scope creep]

## Changes Required:

#### 1. [Component/File Group]
**File**: `path/to/file.ext`
**Changes**: [Summary of changes]

```[language]
// Specific code to add/modify
```

## Success Criteria:

#### Automated Verification:
- [ ] [Relevant checks for this task]

#### Manual Verification:
- [ ] [Relevant manual checks]

**Implementation Note**: After automated verification passes, pause for manual confirmation before considering this complete.
````

## Standard Tier

Split format. Create the directory structure:
```
~/brain/dev/projects/[folder]/plan/
├── index.md
└── phases/
    ├── phase-1.md
    ├── phase-2.md
    └── ...
```

### `plan/index.md`

````markdown
# [Feature/Task Name] Implementation Plan

**Tier:** Standard

## Overview

[Brief description of what we're implementing and why]

## Current State Analysis

[What exists now, what's missing, key constraints discovered]

### Key Discoveries:
- [Important finding with file:line reference]
- [Pattern to follow]
- [Constraint to work within]

## Desired End State

[A Specification of the desired end state after this plan is complete, and how to verify it]

## What We're NOT Doing

[Explicitly list out-of-scope items to prevent scope creep]

## Implementation Approach

[High-level strategy and reasoning]

## Phase Index

| # | Phase | Status | File |
|---|-------|--------|------|
| 1 | [Phase Name] | not_started | phases/phase-1.md |
| 2 | [Phase Name] | not_started | phases/phase-2.md |
| 3 | [Phase Name] | not_started | phases/phase-3.md |

## Testing Strategy

### Unit Tests:
- [What to test]
- [Key edge cases]

### Integration Tests:
- [End-to-end scenarios]

### Manual Testing Steps:
1. [Specific step to verify feature]
2. [Another verification step]
3. [Edge case to test manually]

## Performance Considerations

[Any performance implications or optimizations needed]

## Migration Notes

[If applicable, how to handle existing data/systems]

## References

- Original ticket: `thoughts/allison/tickets/eng_XXXX.md`
- Related research: `~/brain/dev/projects/research/[relevant].md`
- Similar implementation: `[file:line]`

## Next Steps

- [ ] Implement plan: `/workflow:implement [folder-name]`
````

### `plan/phases/phase-N.md`

````markdown
# Phase N: [Descriptive Name]

## Overview
[What this phase accomplishes and why it comes at this point in the sequence]

## Dependencies
[What must be complete before this phase. Reference prior phases if applicable.]

## Changes Required:

#### 1. [Component/File Group]
**File**: `path/to/file.ext`
**Changes**: [Summary of changes]

```[language]
// Specific code to add/modify
```

#### 2. [Component/File Group]
**File**: `path/to/file.ext`
**Changes**: [Summary of changes]

```[language]
// Specific code to add/modify
```

## Success Criteria:

#### Automated Verification:
- [ ] Migration applies cleanly: `make migrate`
- [ ] Unit tests pass: `make test-component`
- [ ] Type checking passes: `npm run typecheck`
- [ ] Linting passes: `bin/lintbot`
- [ ] Integration tests pass: `make test-integration`

#### Manual Verification:
- [ ] Feature works as expected when tested via UI
- [ ] Performance is acceptable under load
- [ ] Edge case handling verified manually
- [ ] No regressions in related features

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase.
````

## Comprehensive Tier

Same split format as Standard, but add these sections to `plan/index.md` after "Migration Notes" and before "References":

````markdown
## Alternative Approaches Considered

### [Approach A]
- **Description**: [What this approach would look like]
- **Why rejected**: [Specific reason]

### [Approach B]
- **Description**: [What this approach would look like]
- **Why rejected**: [Specific reason]

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [Risk 1] | [Low/Med/High] | [Low/Med/High] | [Strategy] |
| [Risk 2] | [Low/Med/High] | [Low/Med/High] | [Strategy] |

## Rollback Strategy

[How to safely revert these changes if something goes wrong. Include specific steps.]
````
