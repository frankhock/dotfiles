---
name: workflow:worktree
description: "Create git branch and worktree for isolated implementation with workspace setup."
argument-hint: "[project-folder]"
disable-model-invocation: true
---

# Create Implementation Worktree

Create an isolated git worktree for implementing a plan — a clean workspace on its own branch where implementation won't interfere with your main working tree.

## Artifacts

- **Reads**: project folder (for naming context)
- **Produces**: git branch + worktree directory at `~/worktrees/[branch-name]`

## Initial Setup

When this skill is invoked:

1. **Check for project folder argument**
   - If argument provided: verify folder exists at `~/brain/dev/projects/[argument]/`
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/` that contain plan artifacts (`plan/` or `plan.md`)
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (plan: yes/no)
     - [folder-2] (plan: yes/no)
     - Provide folder name manually

3. **If no folders found or user provides folder name**: Verify folder exists and proceed.

## Step 1: Determine Branch Name

- Derive from project folder name: strip the date prefix, convert remaining slug to branch name
  - Example: `2026-03-16-workflow-qrspi-restructure` → `workflow-qrspi-restructure`
  - If the folder contains a ticket ID (e.g., `ENG-1234`), prefix it: `ENG-1234/description`
- Present the proposed branch name via **AskUserQuestion tool**: "Branch name: `[proposed]`. Confirm, or enter a custom name?"
- Also ask what base branch to use (default: current branch)

## Step 2: Create Branch + Worktree

- Create the worktree: `git worktree add ~/worktrees/[branch-name] -b [branch-name] [base-branch]`
- If `~/worktrees/` doesn't exist, create it first
- Report the worktree path to the user

## Step 3: Workspace Setup

- In the worktree directory, look for setup scripts: `bin/setup`, `script/setup`, `Makefile` (with `setup` target), `package.json` (run `npm install`), `Gemfile` (run `bundle install`), `go.mod` (run `go mod download`)
- Run the first match found
- If nothing detected, ask via **AskUserQuestion tool**: "No setup script found. Need to run anything to set up dependencies?"

## Next Steps

Present via **AskUserQuestion tool**:
- Implement contract: `/workflow:implement [folder-name]` (run from `~/worktrees/[branch-name]`)
- Done for now
