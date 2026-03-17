---
name: workflow:iterate
description: "Edit existing workflow artifacts (design.md, structure.md, plan/) with surgical precision."
argument-hint: "[project-folder] [feedback]"
model: opus
disable-model-invocation: true
---

# Iterate on Workflow Artifacts

Make surgical edits to any workflow artifact. For changes that require new discovery or major design rethinking, route to the appropriate upstream skill instead of trying to do it all here.

## Artifacts

- **Reads**: any of `design.md`, `structure.md`, `plan/index.md`, `plan.md`
- **Produces**: modified version of the input artifact

## Initial Setup

When this skill is invoked:

1. **Check for project folder argument**
   - If argument provided: verify folder exists at `~/brain/dev/projects/[argument]/`
   - Detect all artifacts present: `design.md`, `structure.md`, `plan/index.md`, `plan.md`
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/` that contain any workflow artifact
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (design: yes/no, structure: yes/no, plan: split/mono/no)
     - [folder-2] (...)
     - Provide folder name manually

3. **If both folder and feedback provided**: proceed directly to Step 1. If folder but no feedback, ask via **AskUserQuestion tool** what changes the user wants to make.

## Step 1: Identify Target Artifact

- Based on user feedback, determine which artifact(s) need editing
- If unclear, ask via **AskUserQuestion tool** with detected artifacts as options
- Read the target artifact(s) fully

## Step 2: Assess Change Scope

Classify the change:

- **Small** (edit directly): typo fixes, adding detail, adjusting success criteria, splitting/merging phases, updating file paths, rewording sections
- **Medium** (edit with light research): adding a new phase based on existing patterns, changing implementation approach within the same design. Spawn a targeted `codebase-locator` or `codebase-analyzer` only if you need to understand new code.
- **Large** (route upstream): fundamental design decisions, new competing patterns to evaluate, scope changes that invalidate the design concept. Suggest the appropriate upstream skill:
  - Design-level changes → `/workflow:design [folder]`
  - New research needed → `/workflow:research [folder]`
  - Structure rethink → `/workflow:structure [folder]`

## Step 3: Confirm Approach + Edit

1. Present your understanding of the change and how you'll apply it via **AskUserQuestion tool**
2. Make surgical edits using the Edit tool — precise changes, not wholesale rewrites
3. Format-specific rules:
   - **Plan (split format)**: keep Phase Index table in `index.md` in sync with phase files. Maintain automated/manual success criteria split.
   - **Plan (monolithic)**: edit `plan.md` directly
   - **Design**: update Key Decisions and Chosen Patterns sections as needed
   - **Structure**: update LOC estimates and dependency graph as needed

## Step 4: Review + Next Steps

1. Present the changes made (files modified, what changed)
2. Ask if further adjustments are needed via **AskUserQuestion tool**
3. Once satisfied, present next-steps menu via **AskUserQuestion tool**:
   - Continue iterating
   - Proceed to next pipeline stage (context-dependent — e.g., `/workflow:plan` after design changes, `/workflow:implement` after plan changes)
   - Done for now

## Guidelines

- **Be skeptical**: question vague feedback, point out conflicts with existing content, verify feasibility
- **Be surgical**: preserve good content, only research what's necessary, don't over-engineer
- **No open questions**: if a change raises questions, ask immediately — don't leave unresolved items in artifacts
