---
name: workflows:plan-ralph
description: "Create implementation plans for Ralph autonomous execution. Interactive planning with research agents, then outputs ralph-tasks.json."
argument-hint: "[project-folder]"
model: opus
---

# Create Ralph Plan

Create detailed implementation plans through interactive research, then output task definitions for Ralph autonomous execution.

## Initial Setup

When this command is invoked:

1. **Check for project folder argument**
   - If argument provided (e.g., `/workflows:plan-ralph 2025-01-27-ENG-1234-feature`):
     - Verify folder exists at `~/brain/dev/projects/[argument]/`
     - If folder doesn't exist, inform user and stop
     - Verify `spec.md` exists
     - If file is missing, inform user and stop
     - Inform user: "Using project folder [name]. Spec/Research artifacts found."
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (spec: yes/no, research: yes/no)
     - [folder-2] (spec: yes/no, research: yes/no)
     - Provide folder name manually

3. **If no folders found or user provides folder name**: Verify folder exists and has `spec.md`, then proceed.

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read `spec.md` and `research.md` (if available) FULLY**:
   - Inform user you're reading the files
   - **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
   - **CRITICAL**: DO NOT spawn sub-tasks before reading these files yourself in the main context
   - **NEVER** read files partially, read it completely

2. **Spawn initial research tasks to gather context**:
   Before asking the user any questions, use specialized agents to research in parallel:

   - Use the **codebase-locator** agent to find all files related to the ticket/task
   - Use the **codebase-analyzer** agent to understand how the current implementation works

   These agents will:
   - Find relevant source files, configs, and tests
   - Identify the specific directories to focus on
   - Trace data flow and key functions
   - Return detailed explanations with file:line references

3. **Read all files identified by research tasks**:
   - After research tasks complete, read ALL files they identified as relevant
   - Read them FULLY into the main context
   - This ensures you have complete understanding before proceeding

4. **Analyze and verify understanding**:
   - Cross-reference the `spec.md` requirements with actual code
   - Identify any discrepancies or misunderstandings
   - Note assumptions that need verification
   - Determine true scope based on codebase reality

5. **Present informed understanding and focused questions**:
   ```
   Based on the spec and my research of the codebase, I understand we need to [accurate summary].

   I've found that:
   - [Current implementation detail with file:line reference]
   - [Relevant pattern or constraint discovered]
   - [Potential complexity or edge case identified]

   Questions that my research couldn't answer:
   - [Specific technical question that requires human judgment]
   - [Business logic clarification]
   - [Design preference that affects implementation]
   ```

   Only ask questions that you genuinely cannot answer through code investigation. Use **AskUserQuestion tool** to present each open question one at a time, with multiple-choice options where natural alternatives exist.

### Step 2: Research & Discovery

After getting initial clarifications:

1. **If the user corrects any misunderstanding**:
   - DO NOT just accept the correction
   - Spawn new research tasks to verify the correct information
   - Read the specific files/directories they mention
   - Only proceed once you've verified the facts yourself

2. **Create a research todo list** using TodoWrite to track exploration tasks

3. **Spawn parallel sub-tasks for comprehensive research**:
   - Create multiple Task agents to research different aspects concurrently
   - Use the right agent for each type of research:

   **For deeper investigation:**
   - **codebase-locator** - To find more specific files (e.g., "find all files that handle [specific component]")
   - **codebase-analyzer** - To understand implementation details (e.g., "analyze how [system] works")
   - **codebase-pattern-finder** - To find similar features we can model after

3. **Wait for ALL sub-tasks to complete** before proceeding

4. **Present findings and design options**:
   ```
   Based on my research, here's what I found:

   **Current State:**
   - [Key discovery about existing code]
   - [Pattern or convention to follow]

   **Design Options:**
   1. [Option A] - [pros/cons]
   2. [Option B] - [pros/cons]

   **Open Questions:**
   - [Technical uncertainty]
   - [Design decision needed]

   Which approach aligns best with your vision?
   ```

   Use **AskUserQuestion tool** to present design options as choices, leading with your recommendation.

### Step 3: Task Structure

Once aligned on approach, present a JSON task skeleton for approval. This is just the shape — ids, titles, one-line descriptions in execution order.

1. **Present task skeleton**:
   ```json
   {
     "project": "[Project Name]",
     "tasks": [
       { "id": "T-001", "title": "[Imperative verb phrase]", "description": "[One-liner]" },
       { "id": "T-002", "title": "[Imperative verb phrase]", "description": "[One-liner]" },
       { "id": "T-003", "title": "[Imperative verb phrase]", "description": "[One-liner]" }
     ]
   }
   ```
   ```
   Does this breakdown make sense?
   - Is the execution order correct (earlier tasks cannot depend on later ones)?
   - Should any tasks be split or merged?
   - Is the granularity right (each task = one Claude context window)?
   ```

2. Use **AskUserQuestion tool** to **get approval on structure** before investing in details. Iterate until the breakdown is right.

### Step 4: Flesh Out Tasks

After structure approval, develop the full `ralph-tasks.json` content (reference format below) — complete descriptions, acceptance criteria, and config fields.

1. **Fill in task details** for every task:
   - `description`: 2-3 sentences of what needs to be done
   - `acceptanceCriteria`: specific, verifiable criteria (see Task Rules below)
   - `status`: always `"pending"`

2. **Add config fields**:
   - `maxParallel`: how many tasks can run concurrently (default 1)
   - `checkInterval`: seconds between status checks (default 15)
   - `promptFile`: relative path to the prompt file (e.g., `"~/brain/dev/projects/[folder]/ralph-prompt.md"`)

3. **Present the complete `ralph-tasks.json` inline** for review:
   ```
   Here's the full ralph-tasks.json:

   [complete JSON]

   Review checklist:
   - Are descriptions clear enough for an autonomous Claude instance?
   - Are acceptance criteria specific and verifiable?
   - Is execution order still correct?
   ```

4. Use **AskUserQuestion tool** to **get approval** before proceeding. Iterate until the user is satisfied.

### Step 5: Draft Execution Prompt

Now that the tasks are finalized, draft `ralph-prompt.md` — the shared context every Claude instance receives.

1. **Use the ralph-prompt.md Format** (see reference section below) as a rigid scaffold. Fill in the project-specific slots:

   - **Context section**: Write 3-5 sentences of project context. Be minimal — only what a Claude instance needs to orient itself. Do NOT write lengthy overviews, current state descriptions, or desired end state narratives.
   - **Project-Specific Instructions section**: This is the core. Include:
     - The transformation or change pattern (with before/after examples if applicable)
     - Edge case rules and gotchas
     - Exact syntax or conventions to follow
     - Any project-specific DO NOT rules beyond the generic ones
   - **Step 3 (Make your changes)**: Replace the placeholder with project-specific instructions for what "making changes" means in this project.
   - **Step 4 (Verify your changes)**: Replace with the exact verification commands for this project (e.g., `bundle exec rubocop`, `npm run typecheck`, `bin/rspec`).
   - **Step 5 (Commit and EXIT)**: Fill in the commit message format and file staging guidance.

   **Do NOT modify** the Scope Constraint section, the generic step framework, or the exit conditions. Those are fixed.

2. **Present the complete `ralph-prompt.md` inline** for review:
   ```
   Here's the ralph-prompt.md:

   [complete markdown]

   This is the shared context every Claude instance receives (prepended with its assigned task JSON).
   Is the scope tight enough? Are the project-specific instructions clear?
   ```

3. Use **AskUserQuestion tool** to **get approval** before writing files. Iterate until the user is satisfied.

### Step 6: Write Files & Handoff

After both artifacts are approved:

1. **Write both files**:
   - `~/brain/dev/projects/[folder]/ralph-tasks.json`
   - `~/brain/dev/projects/[folder]/ralph-prompt.md`

2. **Present file locations and iterate if needed**:
   ```
   Written:
   - `~/brain/dev/projects/[folder]/ralph-tasks.json`
   - `~/brain/dev/projects/[folder]/ralph-prompt.md`

   Any final changes before execution?
   ```

   Use **AskUserQuestion tool** to confirm no final changes are needed.

3. **Present next steps using AskUserQuestion tool**:
   - Execute now: `ralph [folder-name]` (from project root)
   - Review files first
   - Done for now — resume later with `/resume-project [folder-name]`

---

## ralph-tasks.json Format

```json
{
  "project": "[Project Name]",
  "description": "[Feature description]",
  "maxParallel": 1,
  "checkInterval": 15,
  "promptFile": "~/brain/dev/projects/[folder]/ralph-prompt.md",
  "tasks": [
    {
      "id": "T-001",
      "title": "[Task title - imperative verb phrase]",
      "description": "[What needs to be done in 2-3 sentences]",
      "acceptanceCriteria": [
        "Specific verifiable criterion",
        "Another criterion",
        "Lint passes"
      ],
      "status": "pending"
    }
  ]
}
```

### Task Rules

**Size**: Each task must be completable in one Claude context window.
- If you can't describe the change in 2-3 sentences, it's too big
- Split large features: schema -> backend -> UI

**Order**: Tasks execute in array order. Earlier tasks must not depend on later ones.
- Correct: migration -> server action -> UI component
- Wrong: UI component -> migration it depends on

**Acceptance Criteria**:
- Must be verifiable (not vague like "works correctly")
- Always include "Lint passes"
- Include "Typecheck passes" for TypeScript tasks
- Include "Tests pass" for tasks with testable logic

**IDs**: Sequential T-001, T-002, etc.

**Initial State**: All tasks start with `"status": "pending"`

---

## ralph-prompt.md Format

This file provides shared context for all Claude instances. Each instance receives (via stdin, constructed by ralph-loop.rb):
1. `# YOUR ASSIGNED TASK` header followed by a fenced JSON block containing the task object (id, title, description, acceptanceCriteria, status)
2. The full contents of this file

Template:

````markdown
# [Feature Name] - Ralph Execution Context

## SCOPE CONSTRAINT — READ THIS FIRST

You have ONE job: complete YOUR assigned task. Nothing else.

**Rules:**
- ONLY do what your task's description and acceptance criteria ask for
- Do NOT fix unrelated issues you encounter (lint errors, refactoring opportunities, style inconsistencies, etc.)
- Do NOT explore or investigate beyond what is needed to complete your task
- Do NOT modify files or code unrelated to your task
- Do NOT continue working after committing — EXIT IMMEDIATELY with code 0
- If you catch yourself wanting to do anything outside your task — STOP. That is out of scope.

## Context

[Brief project context — 3-5 sentences max. What the project is, what matters for understanding the tasks. Keep it minimal.]

## Project-Specific Instructions

[Instructions specific to this project. This is where create-ralph-plan inserts:
- The transformation or change pattern to follow
- Before/After code examples (if applicable)
- Edge case rules and gotchas
- Exact syntax or conventions to use
- Verification commands specific to this project]

## Step-by-Step Execution

Follow these steps IN ORDER. Do not skip or reorder.

### Step 1: Read your assigned task

Your task is injected at the TOP of this prompt as a JSON block under `# YOUR ASSIGNED TASK`. Read it. Note your task's description and acceptance criteria — that is your entire scope.

### Step 2: Understand the relevant code

Read the files relevant to your task. Understand what exists before making changes.

### Step 3: Make your changes

[Project-specific: what to do. E.g., "Apply the transformation described above" or "Implement the feature as described in your task"]

### Step 4: Verify your changes

[Project-specific verification commands. E.g.:]
```bash
[verification command 1]
[verification command 2]
```

Must pass. If verification fails, fix the issue and re-verify.

### Step 5: Commit and EXIT

```bash
git add [your changed files — list them explicitly, never use git add . or git add -A]
git commit -m "[commit message format]"
```

**After committing, you are DONE. Exit with code 0. Do not continue working.**

## Your Task

Your assigned task details (id, title, description, acceptance criteria) are injected at the top of this prompt as a JSON block. Complete that task following the steps above, then exit.
````

---

## Important Guidelines

1. **Be Skeptical**:
   - Question vague requirements
   - Identify potential issues early
   - Ask "why" and "what about"
   - Don't assume - verify with code

2. **Be Interactive**:
   - Don't write all tasks in one shot
   - Get buy-in at each major step
   - Allow course corrections
   - Work collaboratively

3. **Be Thorough**:
   - Read all context files COMPLETELY before planning
   - Research actual code patterns using parallel sub-tasks
   - Include specific file paths and line numbers
   - Write measurable acceptance criteria

4. **Be Practical**:
   - Focus on small, independent tasks
   - Consider dependency order
   - Think about edge cases
   - Include "what we're NOT doing"

5. **Track Progress**:
   - Use TodoWrite to track planning tasks
   - Update todos as you complete research
   - Mark planning tasks complete when done

6. **No Open Questions in Final Output**:
   - If you encounter open questions during planning, STOP
   - Research or ask for clarification immediately
   - Do NOT write tasks with unresolved questions
   - Every decision must be made before finalizing

---

## Example Interaction Flow

```
User: /workflows:plan-ralph 2025-01-27-ENG-1478-task-status
Assistant: Using project folder 2025-01-27-ENG-1478-task-status. Spec/Research artifacts found.

Let me read the spec and research files completely...

[Reads spec.md and research.md fully]

Based on the spec, I understand we need to add task status tracking. I'm now spawning research tasks to understand the current implementation...

[Interactive process continues...]
```
