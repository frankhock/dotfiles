---
description: Create git commits with user approval and no Claude attribution
---

# Commit Changes

You are tasked with creating git commits for the changes made during this session.

## Process:

1. **Think about what changed:**
   - Review the conversation history and understand what was accomplished
   - Run `git status` to see current changes
   - Run `git diff` to understand the modifications
   - Consider whether changes should be one commit or multiple logical commits

2. **Plan your commit(s):**
   - Identify which files belong together
   - Draft clear, descriptive commit messages
   - Use imperative mood in commit messages
   - Focus on why the changes were made, not just what
   - **Grade your confidence in the commit strategy from 0-100**, considering: how cleanly changes group, how clear the intent is, whether messages accurately describe the diff, and whether splits/groupings are obvious vs judgment calls

3. **Present your plan (and proceed based on confidence):**
   - List the files you plan to add for each commit
   - Show the commit message(s) you'll use
   - State your confidence score and one-line rationale
   - **If confidence >= 90:** proceed directly to step 4 without asking (announce: "Confidence [N]/100 — auto-committing.")
   - **If confidence < 90:** ask "Confidence [N]/100. I plan to create [N] commit(s) with these changes. Shall I proceed?" and wait for approval

4. **Execute (upon confirmation, or auto if confidence >= 90):**
   - Use `git add` with specific files (never use `-A` or `.`)
   - Create commits with your planned messages
   - Show the result with `git log --oneline -n [number]`

## Important:
- **NEVER add co-author information or Claude attribution**
- Commits should be authored solely by the user
- Do not include any "Generated with Claude" messages
- Do not add "Co-Authored-By" lines
- Write commit messages as if the user wrote them

## Remember:
- You have the full context of what was done in this session
- Group related changes together
- Keep commits focused and atomic when possible
- The user trusts your judgment - they asked you to commit
