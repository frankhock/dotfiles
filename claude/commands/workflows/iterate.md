---
name: workflows:iterate
description: "Iterate on existing implementation plans with thorough research and updates"
argument-hint: "[project-folder] [feedback]"
model: opus
---

# Iterate Implementation Plan

You are tasked with updating existing implementation plans based on user feedback. You should be skeptical, thorough, and ensure changes are grounded in actual codebase reality.

## Initial Setup

When this command is invoked:

1. **Check for project folder argument**
   - If argument matches project folder pattern (e.g., `2025-01-27-ENG-1234-feature`):
     - Verify folder exists at `$CLAUDE_PROJECTS_DIR/[argument]/`
     - Read `plan.md` from folder
     - Proceed with iteration
   - If argument is a direct plan path (legacy):
     - Read the plan at that path
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find project folders with plan.md from last 30 days in `$CLAUDE_PROJECTS_DIR/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (plan: yes)
     - [folder-2] (plan: yes)
     - Provide folder or plan path manually

3. **Handle different input scenarios**:

   **If NO plan file provided and no auto-detection matches**:
   Use **AskUserQuestion tool** to ask which plan to update, with options for recently modified plan files if any are found.

   **If plan file provided but NO feedback**:
   Use **AskUserQuestion tool** to ask what changes the user would like to make, with common options:
   - Add a new phase
   - Update success criteria
   - Adjust scope
   - Split/merge phases

   Wait for user input.

   **If BOTH plan file AND feedback provided**:
   - Proceed immediately to Step 1
   - No preliminary questions needed

## Process Steps

### Step 1: Read and Understand Current Plan

1. **Read the existing plan file COMPLETELY**:
   - Use the Read tool WITHOUT limit/offset parameters
   - Understand the current structure, phases, and scope
   - Note the success criteria and implementation approach

2. **Understand the requested changes**:
   - Parse what the user wants to add/modify/remove
   - Identify if changes require codebase research
   - Determine scope of the update

### Step 2: Research If Needed

**Only spawn research tasks if the changes require new technical understanding.**

If the user's feedback requires understanding new code patterns or validating assumptions:

1. **Create a research todo list** using TodoWrite

2. **Spawn parallel sub-tasks for research**:
   Use the right agent for each type of research:

   **For code investigation:**
   - **codebase-locator** - To find relevant files
   - **codebase-analyzer** - To understand implementation details
   - **codebase-pattern-finder** - To find similar patterns

   **Be EXTREMELY specific about directories**:
   - Include full path context in prompts

3. **Read any new files identified by research**:
   - Read them FULLY into the main context
   - Cross-reference with the plan requirements

4. **Wait for ALL sub-tasks to complete** before proceeding

### Step 3: Present Understanding and Approach

Before making changes, confirm your understanding:

```
Based on your feedback, I understand you want to:
- [Change 1 with specific detail]
- [Change 2 with specific detail]

My research found:
- [Relevant code pattern or constraint]
- [Important discovery that affects the change]

I plan to update the plan by:
1. [Specific modification to make]
2. [Another modification]

Does this align with your intent?
```

Get user confirmation before proceeding.

### Step 4: Update the Plan

1. **Make focused, precise edits** to the existing plan:
   - If working with project folder: edit `$CLAUDE_PROJECTS_DIR/[folder]/plan.md`
   - If working with legacy path: edit at that path
   - Use the Edit tool for surgical changes
   - Maintain the existing structure unless explicitly changing it
   - Keep all file:line references accurate
   - Update success criteria if needed

2. **Ensure consistency**:
   - If adding a new phase, ensure it follows the existing pattern
   - If modifying scope, update "What We're NOT Doing" section
   - If changing approach, update "Implementation Approach" section
   - Maintain the distinction between automated vs manual success criteria

3. **Preserve quality standards**:
   - Include specific file paths and line numbers for new content
   - Write measurable success criteria
   - Keep language clear and actionable

### Step 5: Sync and Review

1. **Present the changes made**:
   ```
   I've updated the plan at `$CLAUDE_PROJECTS_DIR/[folder]/plan.md`

   Changes made:
   - [Specific change 1]
   - [Specific change 2]

   The updated plan now:
   - [Key improvement]
   - [Another improvement]

   Would you like any further adjustments?
   ```

2. **Be ready to iterate further** based on feedback

3. **Once the user is satisfied**, present next steps using **AskUserQuestion tool**:
   - Implement plan: `/workflows:implement [folder-name]`
   - Iterate more (continue refining)
   - Create Ralph tasks: `/workflows:plan-ralph [folder-name]`
   - Done for now — resume later with `/resume-project [folder-name]`

## Important Guidelines

1. **Be Skeptical**:
   - Don't blindly accept change requests that seem problematic
   - Question vague feedback - ask for clarification
   - Verify technical feasibility with code research
   - Point out potential conflicts with existing plan phases

2. **Be Surgical**:
   - Make precise edits, not wholesale rewrites
   - Preserve good content that doesn't need changing
   - Only research what's necessary for the specific changes
   - Don't over-engineer the updates

3. **Be Thorough**:
   - Read the entire existing plan before making changes
   - Research code patterns if changes require new technical understanding
   - Ensure updated sections maintain quality standards
   - Verify success criteria are still measurable

4. **Be Interactive**:
   - Confirm understanding before making changes
   - Show what you plan to change before doing it
   - Allow course corrections
   - Don't disappear into research without communicating

5. **Track Progress**:
   - Use TodoWrite to track update tasks if complex
   - Update todos as you complete research
   - Mark tasks complete when done

6. **No Open Questions**:
   - If the requested change raises questions, ASK
   - Research or get clarification immediately
   - Do NOT update the plan with unresolved questions
   - Every change must be complete and actionable

## Success Criteria Guidelines

When updating success criteria, always maintain the two-category structure:

1. **Automated Verification** (can be run by execution agents):
   - Commands that can be run: `bin/rspec`, `bin/lintbot`, etc.
   - Specific files that should exist
   - Code compilation/type checking
   - Automated test suites

2. **Manual Verification** (requires human testing):
   - UI/UX functionality
   - Performance under real conditions
   - Edge cases that are hard to automate
   - User acceptance criteria

## Sub-task Spawning Best Practices

When spawning research sub-tasks:

1. **Only spawn if truly needed** - don't research for simple changes
2. **Spawn multiple tasks in parallel** for efficiency
3. **Each task should be focused** on a specific area
4. **Provide detailed instructions** including:
   - Exactly what to search for
   - Which directories to focus on
   - What information to extract
   - Expected output format
5. **Request specific file:line references** in responses
6. **Wait for all tasks to complete** before synthesizing
7. **Verify sub-task results** - if something seems off, spawn follow-up tasks
