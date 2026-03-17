---
name: workflow:questions
description: "Interactive thought partner for exploring ideas and clarifying requirements. Produces spec.md."
argument-hint: "[feature idea or problem to explore]"
disable-model-invocation: true
---

# Turning Ideas Into Requirements

## Overview

Help turn ideas into clear product requirements through natural collaborative dialogue. You are a thought partner — focus on understanding the **what** and **why**, and leaving detailed implementation to later stages.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Present the requirements in small sections, checking after each whether it looks right.

## Artifacts

- **Reads**: user input, CLAUDE.md, git history
- **Produces**: `spec.md`

## What This Skill Does

- Clarifies the problem being solved
- Explores user intent and goals
- Defines requirements and constraints
- Establishes success criteria (user-facing, not technical)
- Identifies what's explicitly out of scope

## What This Skill Does NOT Do

- Design detailed implementation architecture, data models, APIs, or components
- Make low-level technical decisions (framework choices, data structures, etc.)
- Explore solution approaches or compare design alternatives
- Cover error handling, testing strategies, or data flow

Those belong in `/workflow:design` after codebase research.

## Initial Setup

When this skill is invoked:

1. **Check for project folder argument**
   - If argument provided (e.g., `/workflow:questions 2025-01-30-ENG-123-feature`):
     - Verify folder exists at `~/brain/dev/projects/[argument]/`
     - Read `spec.md` if exists (for resuming)
     - Inform user: "Resuming spec for project [folder-name]."
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (spec: yes - resume)
     - [folder-2] (spec: no - add spec)
     - Start fresh (new project folder)

3. **If no folders or user wants fresh**: Proceed to Clarity Gate

## Clarity Gate

Before diving into the full Q&A process, assess the user's input.

**Clear requirements indicators:**
- Specific acceptance criteria provided
- Referenced existing patterns to follow
- Described exact expected behavior
- Constrained, well-defined scope

**If requirements are already clear:**
Use **AskUserQuestion tool** to offer: "Your requirements seem detailed enough to skip the exploration questions. Should I go straight to writing the spec, or would you like to explore the idea further?"

If the user chooses to skip: run Phase 1 (Lightweight Repo Research) to ground the spec, then jump directly to Phase 3 (Present the Requirements), skipping Phase 2 (Understand the Idea).

**If requirements are unclear or ambiguous:** Proceed to The Process.

## The Process

### Phase 1: Lightweight Repo Research

If invoked inside a git repository, run a quick scan before asking questions:
- Check CLAUDE.md or similar project guidance files
- Look for features/patterns related to the topic
- Glance at recent relevant commits

Use findings to ask more informed, context-aware questions during the dialogue. If not in a repo (or the topic is greenfield), skip this step.

### Phase 2: Understand the Idea

Use the **AskUserQuestion tool** to ask questions **one at a time**.

**Guidelines:**
- Prefer multiple choice options when natural alternatives exist
- Start broad (purpose, users) then narrow (constraints, edge cases)
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, goals, constraints, success criteria
- Validate assumptions explicitly

**Questions to explore:**
- What problem are we solving? Why does it matter?
- Who is this for? What's their current experience?
- What does success look like from the user's perspective?
- What are the must-haves vs nice-to-haves?
- What's explicitly out of scope?
- Are there constraints (timeline, budget, technical limitations)?
- Are there existing patterns or conventions we should follow?

**Exit condition:** Continue until the idea is clear OR user says "proceed."

### Phase 3: Present the Requirements

- Once you understand what they want, present the requirements
- Break it into sections of 200-300 words
- Use **AskUserQuestion tool** after each section to check whether it looks right so far
- Be ready to go back and clarify if something doesn't make sense

## After the Requirements

**Save location:**

1. **If working with a project folder** (from Initial Setup):
   - Save to `~/brain/dev/projects/[folder]/spec.md`

2. **If no project folder**, use **AskUserQuestion tool** to ask:
   - Create new folder (provide ticket + feature name)
   - Use existing folder: [list recent without spec.md]
   - Skip saving

**If creating new project folder:**
- Folder format: `YYYY-MM-DD-[ticket]-[feature-name]` (e.g., `2025-01-31-ENG-123-user-auth`)
- Create: `~/brain/dev/projects/[folder]/`
- Save to: `[folder]/spec.md`

**spec.md format:**
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

**Git commits:**
- Project folder saves (`~/brain/dev/projects`): No commit (outside project repo)

**After saving**, suggest the user clear context with `/clear` to free up the context window, then use **AskUserQuestion tool** to present next steps:
- Proceed to research: `/workflow:research [folder-name]`
- Refine spec further
- Done for now

## Context Integration

**Handoff:** After spec approval, next step is `/workflow:research [folder-name]` to validate assumptions and gather implementation details. The spec feeds into research, which feeds into design.

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Always use AskUserQuestion tool** - Every question to the user goes through the tool
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **Stay in your lane** - Requirements yes, implementation architecture no
- **YAGNI ruthlessly** - Push back on unnecessary requirements, prefer simpler approaches
- **Incremental validation** - Present in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Capture uncertainty** - Open questions go in the spec for research to answer
