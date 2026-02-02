---
name: brainstorm
description: "Interactive thought partner for exploring ideas and clarifying requirements. Use before implementation to understand what you're building and why."
---

# Brainstorming Ideas Into Requirements

## Overview

Help turn ideas into clear product requirements through natural collaborative dialogue. You are a thought partner, not an architect - focus on understanding the **what** and **why**, leaving the **how** to later stages.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what the user wants to build, present the requirements in small sections, checking after each whether it looks right.

## What This Skill Does

- Clarifies the problem being solved
- Explores user intent and goals
- Defines requirements and constraints
- Establishes success criteria (user-facing, not technical)
- Identifies what's explicitly out of scope

## What This Skill Does NOT Do

- Propose implementation approaches or architecture
- Design data models, APIs, or components
- Make technical decisions
- Cover error handling, testing strategies, or data flow

Those belong in `/create-plan` after codebase research.

## Initial Setup

When this skill is invoked:

1. **Check for project folder argument**
   - If argument provided (e.g., `/brainstorm 2025-01-30-ENG-123-feature`):
     - Verify folder exists at `~/brain/thoughts/shared/[argument]/`
     - Read `spec.md` if exists (for resuming)
     - Inform user: "Resuming spec for project [folder-name]."
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/thoughts/shared/`
   - Show user options:
     ```
     Recent project folders:
     
     1. [folder-1] (spec: yes - resume)
     2. [folder-2] (spec: no - add spec)
     3. Start fresh (new project folder)
     
     Select a number, or describe what you'd like to brainstorm:
     ```

3. **If no folders or user wants fresh**: Proceed with normal brainstorming

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, goals, constraints, success criteria

**Questions to explore:**
- What problem are we solving? Why does it matter?
- Who is this for? What's their current experience?
- What does success look like from the user's perspective?
- What are the must-haves vs nice-to-haves?
- What's explicitly out of scope?
- Are there constraints (timeline, budget, technical limitations)?
- Are there existing patterns or conventions we should follow?

**Presenting the requirements:**
- Once you believe you understand what they want, present the requirements
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Be ready to go back and clarify if something doesn't make sense

## After the Requirements

**Save location:**

1. **If working with a project folder** (from Initial Setup):
   - Save to `~/brain/thoughts/shared/[folder]/spec.md`

2. **If no project folder**, ask:
   ```
   Save this spec to a project folder?
   
   1. Create new folder (provide ticket + feature name)
   2. Use existing folder: [list recent without spec.md]
   3. Skip saving
   ```

**If creating new project folder:**
- Folder format: `YYYY-MM-DD-[ticket]-[feature-name]` (e.g., `2025-01-31-ENG-123-user-auth`)
- Create: `~/brain/thoughts/shared/[folder]/`
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
- [ ] Research codebase: `/research-codebase [folder-name]`
- [ ] Create plan: `/create-plan [folder-name]`
```

**Git commits:**
- Project folder saves (`~/brain/`): No commit (outside project repo)

## Context Integration

**Handoff:** After spec approval, next step is `/research-codebase [folder-name]` to validate assumptions and gather implementation details. The spec feeds into research, which feeds into planning.

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **Stay in your lane** - Requirements, not implementation
- **YAGNI ruthlessly** - Push back on unnecessary requirements
- **Incremental validation** - Present in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Capture uncertainty** - Open questions go in the spec for research to answer
