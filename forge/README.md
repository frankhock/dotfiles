# Forge

A structured development pipeline for Claude Code. Turn ideas into shipped code through interactive planning with parallel research agents.

## Pipeline

```
Brainstorm → Research → Plan → Implement
```

Each stage produces artifacts that feed the next, stored in a shared project folder.

## Installation

```
/plugin marketplace add frankhock/dotfiles
/plugin install forge@forge-marketplace
```

## Setup

Forge stores project artifacts (specs, research, plans) in a project directory.

**Default**: `~/.claude/projects/`
**Override**: Set `$CLAUDE_PROJECTS_DIR` to use a custom location.

## Skills

| Skill | Description |
|-------|-------------|
| `/forge:brainstorm` | Interactive thought partner. Explores ideas, clarifies requirements, produces `spec.md` |
| `/forge:research` | Spawns parallel research agents to document the codebase. Produces `research.md` |
| `/forge:plan` | Creates tiered implementation plans (Focused/Standard/Comprehensive). Produces `plan.md` |
| `/forge:implement` | Executes plans phase-by-phase with automated + manual verification pauses |
| `/forge:ralph` | Creates task definitions for Ralph autonomous parallel execution |

All skills accept an optional project folder argument (e.g., `/forge:plan 2025-01-31-ENG-123-user-auth`).

## How It Works

### 1. Brainstorm (`/forge:brainstorm`)
Asks questions one at a time to clarify what you're building. Proposes 2-3 approaches, then writes a structured spec. Saves to `spec.md`.

### 2. Research (`/forge:research`)
Spawns 4 specialized agents in parallel to document the codebase:
- **codebase-locator** — finds WHERE relevant code lives
- **codebase-analyzer** — understands HOW code works
- **codebase-pattern-finder** — finds examples to model after
- **web-search-researcher** — fetches external docs (high-risk topics only)

All agents are documentarians — they describe what exists without suggesting changes. Saves to `research.md`.

### 3. Plan (`/forge:plan`)
Reads spec + research, then creates an implementation plan through interactive dialogue. Three tiers:
- **Focused** — bug fixes, single-component changes (1-3 files)
- **Standard** — most features, cross-component work
- **Comprehensive** — architectural changes, new systems, high-risk work

Saves to `plan.md`.

### 4. Implement (`/forge:implement`)
Executes the plan phase-by-phase:
- Makes code changes per plan
- Runs automated verification (tests, linting, type checks)
- Pauses for manual testing between phases
- Updates plan checkboxes as work completes

### 5. Ralph (`/forge:ralph`)
Creates task definitions for autonomous parallel execution using the Ralph runner. Produces `ralph-tasks.json` and `ralph-prompt.md`.

## Ralph (Autonomous Execution)

Ralph spawns multiple Claude instances in parallel, each working on an independent task. After planning with `/forge:ralph`:

```bash
# Run directly
ruby ~/.claude/plugins/forge/scripts/ralph-loop.rb -p path/to/ralph-tasks.json

# Or set up an alias
alias ralph='ruby ~/.claude/plugins/forge/scripts/ralph-loop.rb'
ralph -p path/to/ralph-tasks.json
```

## Project Folder Structure

```
$CLAUDE_PROJECTS_DIR/
└── 2025-01-31-ENG-123-user-auth/
    ├── spec.md              # From /forge:brainstorm
    ├── research.md          # From /forge:research
    ├── plan.md              # From /forge:plan
    ├── ralph-tasks.json     # From /forge:ralph (optional)
    └── ralph-prompt.md      # From /forge:ralph (optional)
```

## Local Development

Test the plugin locally without installing:

```bash
claude --plugin-dir ./forge
```

## License

MIT
