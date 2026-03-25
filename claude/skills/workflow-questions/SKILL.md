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

1. **Resolve project folder** per `workflow-cache/SKILL.md`. If a folder is resolved, read `spec.md` if it exists (resuming).

2. If the user's input already has clear, detailed requirements, offer to skip the interview and go straight to writing the spec.

## Interview

Scan the repo first (CLAUDE.md, related code, recent commits) to ask informed questions.

Walk down each branch of the requirements tree one at a time. When an answer opens new branches or constrains later decisions, name the dependency ("that affects how we'd think about X, so let me ask about X next") and follow it before moving on. The goal is to resolve every requirements-level fork — who uses it, what triggers it, what are the boundaries, what's out of scope — without crossing into how it gets built.

One question at a time. Prefer multiple choice when natural alternatives exist. Push back on unnecessary requirements — YAGNI.

Before wrapping up, do an exhaustiveness check: "Are there branches we haven't covered?" (e.g., edge-case user types, adjacent features, rollout concerns, success measurement).

Stop when all branches are resolved, or the user says "proceed."

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
