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

Read `references/templates.md` for the template matching the selected tier, then write the plan files to `~/brain/dev/projects/[folder]/plan.md` (Focused) or `plan/` (Standard/Comprehensive).

## Step 4: Review

1. Present plan location and file list
2. Use **AskUserQuestion tool** to collect review feedback
3. Iterate until the user is satisfied — adjust phases, success criteria, scope, or technical details as needed

## Next Steps

After the user approves, present via **AskUserQuestion tool**:
- Create worktree: `/workflow:worktree [folder]`
- Iterate on plan: `/workflow:iterate [folder]`
- Implement plan: `/workflow:implement [folder]`
- Done for now

## Key Guidelines

- **No open questions in the final plan** — if you encounter unknowns, stop and ask. The plan must be complete and actionable.
- **Success criteria are always split** into Automated Verification (runnable commands) and Manual Verification (human checks)
- **Do not re-research or re-design** — translate the approved design and structure into tactical steps
- **Every interaction goes through AskUserQuestion tool**
