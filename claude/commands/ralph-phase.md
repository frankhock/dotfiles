---
description: Execute a single phase of an implementation plan (used by ralph-loop)
---

# Ralph Phase Executor

Execute a single phase of an implementation plan autonomously. This command is designed to be invoked by the ralph-loop orchestration script, not typically used directly.

## Arguments

- `project-folder`: The project folder name (e.g., `2025-02-04-feature-name`)
- `--phase N`: The phase number to execute (required)

## Behavior

1. **Load Context**
   - Read `~/brain/thoughts/shared/[project-folder]/plan.md`
   - Read `~/brain/thoughts/shared/[project-folder]/research.md` if exists
   - Locate `## Phase N:` section in the plan

2. **Check Phase State**
   - Find `#### Automated Verification:` section for this phase
   - If all automated checkboxes are already checked `[x]`, output success and exit
   - If any are unchecked `[ ]`, proceed with implementation

3. **Implement the Phase**
   - Follow the plan's instructions for this phase
   - Make the required code changes
   - Run each automated verification command

4. **Update Checkboxes**
   - For each automated verification that passes, update `[ ]` to `[x]` in plan.md
   - Use the Edit tool to update checkboxes

5. **Exit with Status**
   - If all automated verifications pass: exit normally (success)
   - If any verification fails after implementation: output failure message and exit

## Important Notes

- **Skip manual verification entirely** - do not pause or wait for human input
- **Resume from unchecked items** - if some checkboxes are checked, continue from first unchecked
- **Single phase only** - do not proceed to next phase even if current completes
- **No interactive prompts** - this runs headlessly via `claude -p`

## Output Format

On success:
```
Phase [N] complete. All automated verifications passed.
```

On failure:
```
Phase [N] failed. Verification failed: [command that failed]
```

On already complete:
```
Phase [N] already complete. All automated verifications checked.
```
