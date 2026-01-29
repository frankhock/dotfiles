---
name: list-projects
description: List all project folders in ~/brain/thoughts/shared/. Shows folder name, date, and whether research.md/plan.md exist. Use when user asks to see projects, list projects, or show recent work.
---

# List Projects

Display all project folders from `~/brain/thoughts/shared/` with their status.

## Workflow

1. **Find project folders**
   - List directories in `~/brain/thoughts/shared/` matching pattern `YYYY-MM-DD-ENG-XXXX-*`
   - Sort by date (most recent first)

2. **Check each folder's contents**
   - For each folder, check if `research.md` exists
   - For each folder, check if `plan.md` exists

3. **Display results**

## Output Format

```markdown
# Project Folders

| Folder | Date | Ticket | Research | Plan |
|--------|------|--------|----------|------|
| `2025-01-27-ENG-1234-user-auth` | Jan 27 | ENG-1234 | ✓ | ✓ |
| `2025-01-25-ENG-1189-api-refactor` | Jan 25 | ENG-1189 | ✓ | - |
| `2025-01-20-ENG-1150-dashboard` | Jan 20 | ENG-1150 | ✓ | ✓ |

**Total**: 3 projects
```

## Empty State

If no project folders exist:

```markdown
# Project Folders

No project folders found in `~/brain/thoughts/shared/`.

To start a new project:
1. Run `/research-codebase` to research your feature
2. When prompted, save to a project folder
```

## Notes

- Only show folders matching the pattern `YYYY-MM-DD-ENG-XXXX-*`
- Use ✓ for files that exist, - for files that don't
- Sort by folder name descending (most recent date first)
