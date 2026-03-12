---
name: workflow:plan-ralph
description: "Create implementation plans for Ralph autonomous execution. Interactive planning with research agents, then outputs ralph-tasks.json and ralph-prompt.md. Use when the user wants to plan work for ralph, create ralph tasks, or prepare autonomous execution."
argument-hint: "[project-folder]"
model: opus
disable-model-invocation: true
---

# Create Ralph Plan

Plan work interactively, then output task definitions and an execution prompt for Ralph autonomous execution.

## Initial Setup

1. **Resolve project folder**:
   - If argument provided: verify `~/brain/dev/projects/[argument]/` exists with `spec.md`
   - If no argument: find folders from last 30 days in `~/brain/dev/projects/`, use **AskUserQuestion** to let user pick or provide a name
   - Stop if folder or `spec.md` is missing

2. **Read `spec.md` and `research.md` (if available) FULLY** — no partial reads, no limit/offset. Do this yourself in the main context before spawning any agents.

## Planning Workflow

### Step 1: Research the Codebase

Before asking the user anything, spawn parallel agents to build understanding:

- **codebase-locator**: find all files related to the spec
- **codebase-analyzer**: understand how the current implementation works

After agents complete, read ALL identified files fully into main context. Cross-reference spec requirements with actual code.

### Step 2: Present Understanding + Focused Questions

```
Based on the spec and my research, I understand we need to [summary].

I've found that:
- [Implementation detail with file:line reference]
- [Pattern or constraint discovered]
- [Potential complexity or edge case]

Questions my research couldn't answer:
- [Technical question requiring human judgment]
- [Business logic clarification]
```

Only ask questions you genuinely cannot answer through code investigation. Use **AskUserQuestion** one at a time, with multiple-choice options where natural alternatives exist.

### Step 3: Deeper Research (if needed)

If user corrects a misunderstanding, verify — don't just accept it. Spawn new agents:

- **codebase-locator** — find specific files mentioned
- **codebase-analyzer** — understand implementation details
- **codebase-pattern-finder** — find similar features to model after

Present findings and design options. Lead with your recommendation. Use **AskUserQuestion** for design choices.

### Step 4: Task Skeleton

Present a lightweight JSON skeleton — just ids, titles, one-line descriptions in execution order:

```json
{
  "project": "[Name]",
  "tasks": [
    { "id": "T-001", "title": "[Imperative verb phrase]", "description": "[One-liner]" }
  ]
}
```

Get approval via **AskUserQuestion** before investing in details:
- Is execution order correct?
- Should any tasks be split or merged?
- Is granularity right (each task = one Claude context window)?

### Step 5: Flesh Out Tasks

After structure approval, read `references/task-format.md` for the full schema and task rules. Develop complete descriptions, acceptance criteria, and config fields.

Present the full `ralph-tasks.json` inline for review. Use **AskUserQuestion** to iterate until approved.

### Step 6: Draft Execution Prompt

Read `references/prompt-guide.md` and the examples in `references/examples/` to understand what makes an effective ralph-prompt. Then draft `ralph-prompt.md` tailored to this specific project.

The prompt should give each Claude instance everything it needs after reading its task JSON — but nothing more. Present inline for review. Use **AskUserQuestion** to iterate until approved.

### Step 7: Write Files & Handoff

After both artifacts are approved:

1. Write `~/brain/dev/projects/[folder]/ralph-tasks.json`
2. Write `~/brain/dev/projects/[folder]/ralph-prompt.md`
3. Use **AskUserQuestion** for next steps:
   - Execute now: `ralph [folder-name]`
   - Review files first
   - Done for now

## Planning Principles

- **Be skeptical**: question vague requirements, identify issues early, verify with code
- **Be interactive**: get buy-in at each step, don't write everything in one shot
- **Be thorough**: use parallel agents for research, include file:line references
- **Be practical**: small independent tasks, correct dependency order, think about edge cases
- **No open questions in final output**: resolve everything before finalizing — stop and ask if uncertain
- **Track progress**: use TodoWrite to track planning tasks throughout
