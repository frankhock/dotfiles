---
name: ralph-loop
description: "Execute Ralph task plans with parallel Claude instances."
---

# Ralph Loop

Execute tasks from a project folder using parallel Claude Code instances. Each instance works on one task independently.

## Usage

```
/ralph-loop <project-folder>
```

## Arguments

- `project-folder`: Name of project in `~/brain/thoughts/shared/` (required)

## Examples

```
/ralph-loop 2025-02-04-feature-name
```

## Project Folder Requirements

The project folder must contain:
- `ralph-tasks.json` - Task definitions
- `ralph-prompt.md` - Shared context for Claude instances

These files are created by `/create-ralph-plan [project-folder]`.

## ralph-tasks.json Schema

```json
{
  "project": "Project Name",
  "description": "Feature description",
  "promptFile": "ralph-prompt.md",
  "maxParallel": 3,
  "checkInterval": 15,
  "tasks": [
    {
      "id": "T-001",
      "title": "Task title",
      "description": "What to do",
      "acceptanceCriteria": ["..."],
      "priority": 1,
      "passes": false
    }
  ]
}
```

## How It Works

1. Reads task file to find tasks with `passes: false`
2. Spawns up to `maxParallel` Claude instances
3. Each instance receives: task ID + prompt file content
4. Monitors for `<promise>TASK_COMPLETE</promise>` in output
5. When task completes, marks `passes: true` in JSON
6. Continues until all tasks pass

## Task Completion

Claude instances signal completion by outputting:
```
<promise>TASK_COMPLETE</promise>
```

If this tag is not found, the task is considered incomplete.

## Stopping

- `Ctrl+C` - Graceful shutdown, kills spawned processes
- `ralph-loop.rb --kill` - Force kill all ralph processes

## Creating Task Plans

Use `/create-ralph-plan [project-folder]` to create `ralph-tasks.json` and `ralph-prompt.md` through interactive planning.

## Implementation

When this skill is invoked with `/ralph-loop <project-folder>`:

1. **Validate project folder**:
   - Check folder exists at `~/brain/thoughts/shared/[project-folder]/`
   - Check `ralph-tasks.json` exists in the folder
   - Check `ralph-prompt.md` exists in the folder
   - If validation fails, show error and exit

2. **Run the loop**:
   ```bash
   cd [project-root]
   $HOME/dotfiles/claude/scripts/ralph-loop.rb \
     -p ~/brain/thoughts/shared/[project-folder]/ralph-tasks.json \
     -m ~/brain/thoughts/shared/[project-folder]/ralph-prompt.md
   ```

3. **Example**:
   - `/ralph-loop 2025-02-04-task-status` runs:
     ```bash
     ralph-loop.rb \
       -p ~/brain/thoughts/shared/2025-02-04-task-status/ralph-tasks.json \
       -m ~/brain/thoughts/shared/2025-02-04-task-status/ralph-prompt.md
     ```
