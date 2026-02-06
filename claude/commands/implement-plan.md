---
description: Implement technical plans from $CLAUDE_PROJECTS_DIR/plans with verification
---

# Implement Plan

You are tasked with implementing an approved technical plan from `$CLAUDE_PROJECTS_DIR/plans/`. These plans contain phases with specific changes and success criteria.

## Getting Started

When this command is invoked:

1. **Check for project folder argument**
   - If argument matches project folder pattern (e.g., `2025-01-27-ENG-1234-feature`):
     - Verify folder exists at `$CLAUDE_PROJECTS_DIR/[argument]/`
     - Read `research.md` for context (understand codebase findings)
     - Read `plan.md` for implementation instructions
     - Proceed with implementation
   - If argument is a direct plan path (legacy):
     - Read the plan at that path
   - If no argument, proceed to auto-detection

2. **Auto-detect recent project folders** (if no argument):
   - Find project folders with plan.md from last 30 days
   - If folders found, ask:
     ```
     I found project folders ready for implementation:
     
     1. [folder-name-1] (Research: ✓, Plan: ✓)
     2. [folder-name-2] (Research: ✓, Plan: ✓)
     
     Which project would you like to implement? Or provide a plan path:
     ```

3. **If no project folder selected**, ask for plan path.

4. **Load full context:**
   - Read the plan completely and check for any existing checkmarks (- [x])
   - Read the original ticket and all files mentioned in the plan
   - **Read files fully** - never use limit/offset parameters, you need complete context
   - Think deeply about how the pieces fit together
   - Create a `Task list` to track your progress
   - Start implementing if you understand what needs to be done

## Implementation Philosophy

Plans are carefully designed, but reality can be messy. Your job is to:
- Follow the plan's intent while adapting to what you find
- Implement each phase fully before moving to the next
- Verify your work makes sense in the broader codebase context
- Update checkboxes in the plan as you complete sections

When things don't match the plan exactly, think about why and communicate clearly. The plan is your guide, but your judgment matters too.

If you encounter a mismatch:
- STOP and think deeply about why the plan can't be followed
- Present the issue clearly:
  ```
  Issue in Phase [N]:
  Expected: [what the plan says]
  Found: [actual situation]
  Why this matters: [explanation]

  How should I proceed?
  ```

## Verification Approach

After implementing a phase:
- Run the success criteria checks
- Fix any issues before proceeding
- Update your progress in both the plan and your todos
- Check off completed items in the plan file itself using Edit
- **Pause for human verification**: After completing all automated verification for a phase, pause and inform the human that the phase is ready for manual testing. Use this format:
  ```
  Phase [N] Complete - Ready for Manual Verification

  Automated verification passed:
  - [List automated checks that passed]

  Please perform the manual verification steps listed in the plan:
  - [List manual verification items from the plan]

  Let me know when manual testing is complete so I can proceed to Phase [N+1].
  ```

If instructed to execute multiple phases consecutively, skip the pause until the last phase. Otherwise, assume you are just doing one phase.

do not check off items in the manual testing steps until confirmed by the user.


## If You Get Stuck

When something isn't working as expected:
- First, make sure you've read and understood all the relevant code
- Consider if the codebase has evolved since the plan was written
- If the plan's Overview/Problem Statement seems unclear or you're unsure WHY a step exists, ask the user rather than guessing or reading upstream documents
- Present the mismatch clearly and ask for guidance

Use sub-tasks sparingly - mainly for targeted debugging or exploring unfamiliar territory.

## Resuming Work

If the plan has existing checkmarks:
- Trust that completed work is done
- Pick up from the first unchecked item
- Verify previous work only if something seems off

Remember: You're implementing a solution, not just checking boxes. Keep the end goal in mind and maintain forward momentum.
