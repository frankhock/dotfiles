---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

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
     
     Select a number, or describe what you'd like to design:
     ```

3. **If no folders or user wants fresh**: Proceed with normal brainstorming

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Save location:**

1. **If working with a project folder** (from Initial Setup):
   - Save to `~/brain/thoughts/shared/[folder]/spec.md`

2. **If no project folder**, ask:
   ```
   Save this design to a project folder?
   
   1. Create new folder (provide ticket + feature name)
   2. Use existing folder: [list recent without spec.md]
   3. Save to docs/plans/ (legacy)
   4. Skip saving
   ```

**If creating new project folder:**
- Folder format: `YYYY-MM-DD-[ticket]-[feature-name]` (e.g., `2025-01-31-ENG-123-user-auth`)
- Create: `~/brain/thoughts/shared/[folder]/`
- Save to: `[folder]/spec.md`

**spec.md format:**
```markdown
# Design: [Topic]

**Project:** [folder-name]
**Created:** YYYY-MM-DD

## Problem Statement
[What we're solving]

## Design Summary
[Chosen approach]

## Detailed Design
[Full design]

## Alternatives Considered
[Other options and why not chosen]

## Next Steps
- [ ] Research codebase: `/research-codebase [folder-name]`
- [ ] Create plan: `/create-plan [folder-name]`
```

**Git commits:**
- Project folder saves (`~/brain/`): No commit (outside project repo)
- Legacy saves (`docs/plans/`): Commit with "Add design: <topic>"

## Context Integration

**Handoff:** After spec approval, next step is `/research-codebase [folder-name]` to validate assumptions and gather implementation details.

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
