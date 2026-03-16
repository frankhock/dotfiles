---
name: workflow:plan
description: "Write tactical implementation plan from approved design and structure. Produces plan/ directory. Use when design and structure are approved and you're ready to write the detailed plan with file-level changes, success criteria, and phase ordering."
argument-hint: "[project-folder]"
model: opus
disable-model-invocation: true
---

# Write Implementation Plan

Take the approved `design.md` + `structure.md` and write a tactical implementation plan with file-level changes per phase. This is mechanical writing — no discovery, no design discussion. If you need to make design decisions, go back to `/workflow:design`. If you need to restructure phases, go back to `/workflow:structure`.

## Artifacts

- **Reads**: `design.md` (required), `structure.md` (required), `research.md` (recommended)
- **Produces**: `plan.md` (Focused tier) or `plan/index.md` + `plan/phases/phase-N.md` (Standard/Comprehensive tier)

## Initial Setup

When this skill is invoked:

1. **Check for project folder argument**
   - If argument provided (e.g., `/workflow:plan 2025-01-27-ENG-1234-feature`):
     - Verify folder exists at `~/brain/dev/projects/[argument]/`
     - Check for `design.md` — if missing, warn: "No design.md found. The plan needs an approved design. Continue anyway?" via **AskUserQuestion tool**
     - Check for `structure.md` — if missing, warn: "No structure.md found. The plan needs a structure to translate into phases. Continue anyway?" via **AskUserQuestion tool**
     - Check for `research.md` — if present, read it for codebase context
     - Check for existing `plan.md` or `plan/index.md` — if exists, ask via **AskUserQuestion tool**: "Found an existing plan. Want to refine this, or start fresh?"
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (design: yes/no, structure: yes/no, plan: yes/no)
     - [folder-2] (design: yes/no, structure: yes/no, plan: yes/no)
     - Provide folder name manually

3. **If no folders found or user provides folder name**: Verify folder exists and proceed.

## Step 1: Absorb Inputs

1. Read `design.md`, `structure.md`, and `research.md` fully in main context
2. Spawn `codebase-locator` agent to find exact file paths for all files mentioned in the structure
3. Map structure phases to specific file-level changes — each structure phase becomes a plan phase

## Step 2: Select Tier

Recommend a plan tier based on the structure's complexity:

**Tier definitions:**
- **Focused** — 1-3 files, one system, follows established patterns. Output: single `plan.md`.
- **Standard** — Multiple files, 2+ systems. Output: split format (`plan/index.md` + phase files).
- **Comprehensive** — Many files, multiple systems, migrations, high risk. Output: split format + Alternative Approaches, Risk Analysis, Rollback Strategy.

Use **AskUserQuestion tool** to present your recommendation with "(Recommended)" label and one-sentence reasoning. If the user overrides, briefly note the tradeoff.

## Step 3: Write Plan Files

Translate each structure phase into a detailed plan phase. For each phase, specify:
- Specific file paths and code changes
- Success criteria split into Automated Verification and Manual Verification
- Dependencies on prior phases

Use the template for the selected tier:

**If tier is Focused** — Single file `plan.md`:

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

**If tier is Standard** — Split format:

Create the directory structure:
```
~/brain/dev/projects/[folder]/plan/
├── index.md
└── phases/
    ├── phase-1.md
    ├── phase-2.md
    └── ...
```

**`plan/index.md` template:**

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

**Each `plan/phases/phase-N.md` template:**

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

**If tier is Comprehensive** — Same split format as Standard, but add these sections to `plan/index.md` after "Migration Notes" and before "References":

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

Save to `~/brain/dev/projects/[folder]/plan.md` or `plan/`.

## Step 4: Review

1. Present plan location and file list
2. Use **AskUserQuestion tool** to collect review feedback
3. Iterate until the user is satisfied — adjust phases, success criteria, scope, or technical details as needed

## Next Steps

After the user approves, present via **AskUserQuestion tool**:
- Iterate on plan: `/workflow:iterate [folder]`
- Implement plan: `/workflow:implement [folder]`
- Create Ralph tasks: `/workflow:plan-ralph [folder]`
- Done for now

## Key Guidelines

- **No open questions in the final plan** — if you encounter unknowns, stop and ask. The plan must be complete and actionable.
- **Success criteria are always split** into Automated Verification (runnable commands) and Manual Verification (human checks)
- **Do not re-research or re-design** — translate the approved design and structure into tactical steps
- **Every interaction goes through AskUserQuestion tool**
