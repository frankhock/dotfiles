---
name: resume-project
description: Resume work on an existing project folder. Takes a project name or partial match (ticket number, feature name), displays current state, and offers next steps. Use when user wants to continue or resume a project.
---

# Resume Project

Load and display the current state of a project folder, then offer next steps.

## Workflow

### 1. Identify Project Folder

**If full folder name provided** (e.g., `2025-01-27-ENG-1234-user-auth`):
- Verify folder exists at `$CLAUDE_PROJECTS_DIR/[name]/`
- Proceed to step 2

**If partial match provided** (e.g., `ENG-1234`, `user-auth`, `1234`):
- Search `$CLAUDE_PROJECTS_DIR/` for folders containing the partial match
- If exactly one match: use it
- If multiple matches: list them and ask user to clarify
- If no matches: inform user and suggest `/list-projects`

**If no argument provided**:
- Run `/list-projects` to show available projects
- Ask user which project to resume

### 2. Read Project State

- Read `research.md` if it exists (summarize key findings)
- Read `plan.md` if it exists (summarize phases and check completion status)
- Count completed vs total checkboxes in plan.md for progress percentage

### 3. Present Summary and Options

## Output Format

```markdown
# Project: 2025-01-27-ENG-1234-user-auth

## Research Status
**Status**: Complete
**Summary**: [First 2-3 sentences from research summary]

Key findings:
- [Bullet point from research]
- [Another key point]

## Plan Status
**Status**: In Progress (2/4 phases complete)
**Overview**: [Brief description from plan overview]

Phases:
- [x] Phase 1: Database schema
- [x] Phase 2: Backend API
- [ ] Phase 3: Frontend components
- [ ] Phase 4: Testing

## Next Steps

Based on the current state, you can:

1. **Continue Research** → `/workflows:research 2025-01-27-ENG-1234-user-auth`
2. **Update Plan** → `/workflows:iterate 2025-01-27-ENG-1234-user-auth`
3. **Continue Implementation** → `/workflows:implement 2025-01-27-ENG-1234-user-auth`

What would you like to do?
```

## Partial Match Examples

| User Input | Matches |
|------------|---------|
| `ENG-1234` | `2025-01-27-ENG-1234-user-auth` |
| `user-auth` | `2025-01-27-ENG-1234-user-auth` |
| `1234` | `2025-01-27-ENG-1234-user-auth` |
| `dashboard` | `2025-01-20-ENG-1150-dashboard` |

## Multiple Matches

If partial match returns multiple folders:

```markdown
I found multiple projects matching "auth":

1. `2025-01-27-ENG-1234-user-auth`
2. `2025-01-15-ENG-1098-oauth-integration`

Which project would you like to resume? (Enter number or full name)
```

## No Matches

If no folders match:

```markdown
No project folders found matching "[search term]".

Available projects:
[Run /list-projects output]

Or start a new project with `/workflows:research`.
```

## Notes

- Use case-insensitive matching for partial names
- Calculate completion percentage from plan.md checkboxes: `[x]` vs `[ ]`
- Show phase names from plan.md headers (## Phase N: Name)
- Keep research and plan summaries brief (2-3 sentences max)
