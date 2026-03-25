# Workflow Project Cache Protocol

Non-invocable. Referenced by workflow skills to resolve the project folder.

## Resolve Project Folder

Run this sequence. Stop at the first step that produces a folder name.

### 1. Explicit argument

If the skill was invoked with a project argument, use it. Write it to the cache (step 4).

### 2. Read cache

```bash
SHELL_PID=$(ps -o ppid= -p $PPID | tr -d ' ')
```

If the command fails or `SHELL_PID` is empty, skip to step 3.

Read `~/.claude/workflow-context/$SHELL_PID`.

- **File doesn't exist** (fresh terminal, first invocation): continue to step 3.
- **File exists but `~/brain/dev/projects/[value]/` doesn't exist on disk** (stale cache): ignore the cache, continue to step 3.
- **File exists and folder exists on disk**: use that value. Announce "Using project: [value]" and proceed — do NOT ask for confirmation.

### 3. Ask the user

Use **AskUserQuestion tool** to ask for the project folder name.

### 4. Write cache

After resolving a folder (from argument, cache, or user input), write the folder name to the cache:

```bash
SHELL_PID=$(ps -o ppid= -p $PPID | tr -d ' ')
```

If `SHELL_PID` is non-empty:
- Create `~/.claude/workflow-context/` if it doesn't exist
- Write the folder name (just the name, no path) to `~/.claude/workflow-context/$SHELL_PID`
