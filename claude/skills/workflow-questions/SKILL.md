---
name: workflow:questions
description: "Interactive thought partner for exploring ideas and clarifying requirements. Produces spec.md."
argument-hint: "[feature idea or problem to explore]"
disable-model-invocation: true
---

# Turning Ideas Into Requirements

Interview the user to understand their idea, then write a `spec.md`. Focus on the **what** and **why** — leave implementation to later stages.

## Artifacts

- **Reads**: user input, CLAUDE.md, git history
- **Produces**: `spec.md`

## What This Skill Does NOT Do

- Design implementation architecture, data models, APIs, or components
- Make technical decisions (framework choices, data structures, etc.)
- Explore solution approaches or compare design alternatives
- Cover error handling, testing strategies, or data flow

Those belong in `/workflow:design` after codebase research.

## Setup

1. If argument provided (e.g., `/workflow:questions 2025-01-30-ENG-123-feature`):
   - Look for folder at `~/brain/dev/projects/[argument]/`
   - Read `spec.md` if it exists (resuming)

2. If no argument: find project folders from last 30 days in `~/brain/dev/projects/` and ask the user which to use, or start fresh.

3. If the user's input already has clear, detailed requirements, offer to skip the interview and go straight to writing the spec.

## Interview

Scan the repo first (CLAUDE.md, related code, recent commits) to ask informed questions.

Then interview the user one question at a time until the idea is clear. Prefer multiple choice when natural alternatives exist. Push back on unnecessary requirements — YAGNI.

Stop when you have enough to write the spec, or the user says "proceed."

## Write the Spec

Present the spec in sections, checking after each whether it looks right.

## Save

- If a project folder exists: save to `~/brain/dev/projects/[folder]/spec.md`
- If not: ask the user to pick an existing folder, create one (`YYYY-MM-DD-[ticket]-[feature-name]`), or skip saving
- Project folder saves are outside the repo — no git commit

## spec.md Template

```markdown
# Spec: [Topic]

**Project:** [folder-name]
**Created:** YYYY-MM-DD

## Problem Statement
[What problem we're solving and why it matters]

## Goals
[What we're trying to achieve - user-facing outcomes]

## Requirements

### Must Have
- [Critical requirements - the feature doesn't work without these]

### Should Have
- [Important but flexible - can adjust approach]

### Won't Have (Out of Scope)
- [Explicitly excluded to prevent scope creep]

## Success Criteria
[How we'll know we're done - from the user's perspective, not technical metrics]

## Constraints
[Timeline, budget, technical limitations, dependencies, etc.]

## Open Questions
[Things we need to validate during codebase research]

## Next Steps
- [ ] Research codebase: `/workflow:research [folder-name]`
```

## After Saving

Suggest `/clear`, then ask: proceed to `/workflow:research [folder-name]`, refine further, or done for now?

## Rules

- **Always use AskUserQuestion tool** for every question to the user
- **One question at a time** — never batch questions
- **YAGNI ruthlessly** — push back on unnecessary requirements
