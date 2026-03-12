---
name: workflow:implement
description: "Implement technical plans from ~/brain/dev/projects with verification"
argument-hint: "[project-folder]"
disable-model-invocation: true
---

# Implement Plan

You are tasked with implementing an approved technical plan from `~/brain/dev/projects/`. These plans contain phases with specific changes and success criteria.

## Initial Setup

When this command is invoked:

1. **Check for project folder argument**
   - If argument matches project folder pattern (e.g., `2025-01-27-ENG-1234-feature`):
     - Verify folder exists at `~/brain/dev/projects/[argument]/`
     - Read `research.md` for context (understand codebase findings)
     - **Detect plan format** (see below)
     - Proceed with implementation
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find project folders with plan.md or plan/index.md from last 30 days in `~/brain/dev/projects/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (Research: yes/no, Plan: yes/no, Format: split/monolithic)
     - [folder-2] (Research: yes/no, Plan: yes/no, Format: split/monolithic)
     - Provide folder name manually

3. **If no project folder selected**, use **AskUserQuestion tool** to ask for a plan path.

4. **Detect plan format and load context:**

   **Split format** (preferred — if `plan/index.md` exists):
   - Read `plan/index.md` fully — this gives you the overview, scope, approach, and phase status
   - Find the current phase from the Phase Index table (first phase with status `not_started` or `in_progress`)
   - Read ONLY the current phase file (e.g., `plan/phases/phase-3.md`)
   - If the phase file has some checkboxes already checked, pick up from the first unchecked item
   - Do NOT read other phase files unless you specifically need cross-phase context
   - Read all source files mentioned in the current phase
   - Create a `Task list` to track your progress

   **Monolithic format** (legacy — if only `plan.md` exists):
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
- **Split format**: Update the phase status in `plan/index.md` and check off items in the phase file
- **Monolithic format**: Update checkboxes in the plan as you complete sections

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

  Use **AskUserQuestion tool** to ask how to proceed, with options relevant to the mismatch.

## Phase Transitions (Split Format)

When completing a phase in split format:

1. Check off all automated success criteria items in the phase file as they pass
2. Pause for manual verification (see below)
3. After the human confirms ALL manual verification steps pass, check off the manual items in the phase file
4. **Only then** update `plan/index.md` Phase Index table:
   - Change the completed phase status from `in_progress` to `complete`
   - Change the next phase status from `not_started` to `in_progress`
5. Read the next phase file to continue

The index only updates at human-confirmed checkpoints, so it stays reliable as a quick-reference for progress.

## Verification Approach

After implementing a phase:
- Run the success criteria checks
- Fix any issues before proceeding
- Update your progress (phase file checkboxes + index status for split format, or plan checkboxes for monolithic)
- **Pause for human verification**: After completing all automated verification for a phase, pause and inform the human that the phase is ready for manual testing. Use this format:
  ```
  Phase [N] Complete - Ready for Manual Verification

  Automated verification passed:
  - [List automated checks that passed]

  Please perform the manual verification steps listed in the plan:
  - [List manual verification items from the plan]

  Let me know when manual testing is complete so I can proceed to Phase [N+1].
  ```

  Use **AskUserQuestion tool** to collect manual verification results before proceeding to the next phase.

If instructed to execute multiple phases consecutively, skip the pause until the last phase. Otherwise, assume you are just doing one phase.

Do not check off items in the manual testing steps until confirmed by the user.

## Cross-Phase Context (Split Format)

Sometimes you may need context from a previous phase (e.g., a model created in Phase 1 that Phase 3 references). When this happens:
- First, check if `plan/index.md` has enough context in the Overview or Implementation Approach sections
- If not, read the specific prior phase file you need
- Prefer reading the actual codebase over reading prior phase files — the code is the ground truth

## After Implementation Complete

Once all phases are implemented and verified, present next steps using **AskUserQuestion tool**:
- Create PR: `/pr-create`
- Iterate on plan: `/workflow:iterate [folder-name]`
- Done for now — resume later with `/resume-project [folder-name]`

## If You Get Stuck

When something isn't working as expected:
- First, make sure you've read and understood all the relevant code
- Consider if the codebase has evolved since the plan was written
- If the plan's Overview/Problem Statement seems unclear or you're unsure WHY a step exists, ask the user rather than guessing or reading upstream documents
- Present the mismatch clearly and ask for guidance

Use sub-tasks sparingly - mainly for targeted debugging or exploring unfamiliar territory.

## Resuming Work

**Split format**: Read `plan/index.md` — the Phase Index table shows exactly where you left off. The index only updates after human-verified phase completion, so it's always accurate. Read the current phase file (`in_progress` or first `not_started`) and continue from its first unchecked item.

**Monolithic format**: If the plan has existing checkmarks, trust that completed work is done. Pick up from the first unchecked item. Verify previous work only if something seems off.

Remember: You're implementing a solution, not just checking boxes. Keep the end goal in mind and maintain forward momentum.
