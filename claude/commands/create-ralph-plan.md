---
name: create-ralph-plan
description: "Create implementation plans for Ralph autonomous execution. Interactive planning with research agents, then outputs ralph-tasks.json."
model: opus
user-invocable: true
---

# Create Ralph Plan

Create detailed implementation plans through interactive research, then output task definitions for Ralph autonomous execution.

## Initial Response

When this command is invoked:

**Require project folder argument**
- If no argument provided, respond with:
  ```
  /create-ralph-plan [project-folder]

  Please provide a project folder name (e.g., `2025-01-27-ENG-1234-feature`).
  ```
  STOP and wait for user input.

- If argument provided:
  - Verify folder exists at `~/brain/thoughts/shared/[argument]/`
  - If folder doesn't exist, inform user and stop
  - Verify `spec.md` exists
  - If file is missing, inform user and stop
  - Inform user: "Using project folder [name]. Spec/Research artifacts found."

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

   Only ask questions that you genuinely cannot answer through code investigation.

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

### Step 3: Task Structure Development

Once aligned on approach:

1. **Create initial task outline**:
   ```
   Here's my proposed task structure:

   ## Overview
   [1-2 sentence summary]

   ## Tasks:
   1. T-001: [Task name] - [what it accomplishes]
   2. T-002: [Task name] - [what it accomplishes]
   3. T-003: [Task name] - [what it accomplishes]

   Does this breakdown make sense? Should I adjust the order or granularity?
   ```

2. **Get feedback on structure** before writing details

### Step 4: Write Output Files

After structure approval:

1. **Write ralph-tasks.json** to `~/brain/thoughts/shared/[folder]/ralph-tasks.json`
2. **Write ralph-prompt.md** to `~/brain/thoughts/shared/[folder]/ralph-prompt.md`

### Step 5: Sync and Review

1. **Present the output file locations**:
   ```
   I've created the Ralph execution files at:
   - `~/brain/thoughts/shared/[folder]/ralph-tasks.json`
   - `~/brain/thoughts/shared/[folder]/ralph-prompt.md`

   Please review them and let me know:
   - Are the tasks properly scoped (one context window each)?
   - Are the acceptance criteria specific enough?
   - Any technical details that need adjustment?
   ```

2. **Iterate based on feedback** - be ready to:
   - Split tasks that are too large
   - Adjust acceptance criteria
   - Reorder by dependencies
   - Add/remove scope items

3. **Continue refining** until the user is satisfied

4. **End with handoff**:
   ```
   Ready to execute: `/ralph-loop`

   To start: cd to project root, then run:
   ralph-loop.rb -p ~/brain/thoughts/shared/[folder]/ralph-tasks.json -m ~/brain/thoughts/shared/[folder]/ralph-prompt.md
   ```

---

## ralph-tasks.json Format

```json
{
  "project": "[Project Name]",
  "description": "[Feature description]",
  "promptFile": "ralph-prompt.md",
  "maxParallel": 3,
  "checkInterval": 15,
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
      "priority": 1,
      "status": "pending"
    }
  ]
}
```

### Task Rules

**Size**: Each task must be completable in one Claude context window.
- If you can't describe the change in 2-3 sentences, it's too big
- Split large features: schema -> backend -> UI

**Order**: Tasks execute by priority. Earlier tasks must not depend on later ones.
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

This file provides shared context for all Claude instances. Each instance receives:
1. `# YOUR ASSIGNED TASK ID: T-XXX` (injected by ralph-loop.rb)
2. The contents of this file

Template:

```markdown
# [Feature Name] - Ralph Execution Context

## Overview

[Brief description of what we're implementing and why - 2-3 sentences]

## Current State

[What exists now, what's missing, key constraints discovered during planning]

### Key Files:
- `path/to/file.ext` - [what it does]
- `path/to/another.ext` - [what it does]

## Desired End State

[Specification of the desired end state after all tasks complete]

## What We're NOT Doing

[Explicitly list out-of-scope items to prevent scope creep]

## Implementation Notes

[Patterns to follow, conventions to use, gotchas to avoid]

## Your Task

Find your assigned task ID above. Look up that task in ralph-tasks.json to see:
- Task title and description
- Acceptance criteria to satisfy

Complete your assigned task. Exit normally (code 0) on success.
If you cannot complete the task, explain why and exit with a non-zero code.
```

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
User: /create-ralph-plan 2025-01-27-ENG-1478-task-status
Assistant: Using project folder 2025-01-27-ENG-1478-task-status. Spec/Research artifacts found.

Let me read the spec and research files completely...

[Reads spec.md and research.md fully]

Based on the spec, I understand we need to add task status tracking. I'm now spawning research tasks to understand the current implementation...

[Interactive process continues...]
```
