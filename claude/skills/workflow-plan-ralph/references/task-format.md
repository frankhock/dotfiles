# ralph-tasks.json Format

## Schema

```json
{
  "project": "[Project Name]",
  "description": "[Feature description]",
  "maxParallel": 1,
  "checkInterval": 5,
  "promptFile": "~/brain/dev/projects/[folder]/ralph-prompt.md",
  "tasks": [
    {
      "id": "T-001",
      "title": "[Imperative verb phrase]",
      "description": "[What needs to be done in 2-3 sentences]",
      "acceptanceCriteria": [
        "Specific verifiable criterion",
        "Another criterion",
        "Lint passes"
      ],
      "status": "pending"
    }
  ]
}
```

## Config Fields

| Field | Default | Purpose |
|-------|---------|---------|
| `maxParallel` | `1` | Concurrent tasks. Keep at 1 unless tasks are truly independent |
| `checkInterval` | `15` | Seconds between status polls |
| `promptFile` | `"ralph-prompt.md"` | Path to shared execution prompt |
| `staleTimeout` | `600` | Seconds before a silent task is killed |

## Task Rules

**Size**: Each task should use no more than 40-50% of an Opus context window (~200k tokens). Model performance degrades as context fills — instructions get missed, edits get sloppier, and the instance is more likely to drift out of scope. The remaining headroom also gets consumed by the prompt itself, tool results from file reads, and back-and-forth during execution. Smaller tasks produce better results.
- If you can't describe the change in 2-3 sentences, it's too big
- Split large features: schema -> backend -> UI

**Order**: Tasks execute in array order. Earlier tasks must not depend on later ones.
- Correct: migration -> server action -> UI component
- Wrong: UI component -> migration it depends on

**Acceptance Criteria**:
- Must be verifiable (not vague like "works correctly")
- Always include "Lint passes"
- Include "Typecheck passes" for TypeScript tasks
- Include "Tests pass" for tasks with testable logic

**IDs**: Sequential T-001, T-002, etc.

**Initial State**: All tasks start with `"status": "pending"`

## What ralph-loop provides automatically

Each Claude instance receives (via stdin):
1. `# YOUR ASSIGNED TASK` header with the full task JSON object
2. The full contents of `ralph-prompt.md`

The task JSON includes id, title, description, acceptanceCriteria, and status. You don't need to repeat this structure in the prompt — the instance already has it.
