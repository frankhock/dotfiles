---
name: workflow:structure
description: "Decompose approved design into vertical implementation slices. Produces structure.md."
argument-hint: "[project-folder]"
model: opus
disable-model-invocation: true
---

# Structure Outline

Break the approved design into independently testable vertical slices with LOC guidelines. Each phase should touch a vertical slice (e.g., db → services → api → frontend) rather than a horizontal layer (all db first, then all API). The result is `structure.md` — a decomposition that the plan skill turns into detailed implementation phases.

## Artifacts

- **Reads**: `design.md` (required), `research.md` (recommended)
- **Produces**: `structure.md`

## Initial Setup

When this skill is invoked:

1. **Check for project folder argument**
   - If argument provided (e.g., `/workflow:structure 2025-01-27-ENG-1234-feature`):
     - Verify folder exists at `~/brain/dev/projects/[argument]/`
     - Check for `design.md` — if missing, warn: "No design.md found. Structure works best with an approved design. Continue anyway?" via **AskUserQuestion tool**
     - Check for `research.md` — if missing, warn: "No research.md found. Research provides codebase context for better slicing. Continue anyway?" via **AskUserQuestion tool**
     - Check for existing `structure.md` — if exists, read it, present the Decomposition Strategy and Phases sections, then ask via **AskUserQuestion tool**: "Found an existing structure. Want to refine this, or start fresh?"
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (spec: yes/no, research: yes/no, design: yes/no, structure: yes/no)
     - [folder-2] (spec: yes/no, research: yes/no, design: yes/no, structure: yes/no)
     - Provide folder name manually

3. **If no folders found or user provides folder name**: Verify folder exists and proceed.

## Step 1: Absorb Design + Research

1. Read `design.md` and `research.md` fully in main context — no sub-agents for reading
2. Identify the key decisions and chosen patterns from the design
3. Spawn `codebase-pattern-finder` to find examples of the chosen patterns in the codebase — these inform how to slice the work

## Step 2: Propose Vertical Slices

Decompose the design into phases. Each phase should be a vertical slice — touching multiple layers end-to-end — not a horizontal layer.

Guidelines for slicing:
- Each phase should be independently testable with mock/stub boundaries at the edges
- Target ~200-400 LOC per phase — flag phases that seem larger but don't hard-enforce
- Order phases so earlier ones reduce risk or unblock later ones
- The first phase should be the smallest possible end-to-end proof of concept

Present the proposed structure via **AskUserQuestion tool**:
```
Proposed phases:
1. [Phase name] — [what it touches] (~XXX LOC)
2. [Phase name] — [what it touches] (~XXX LOC)
...
Does this decomposition make sense? Any phases to merge, split, or reorder?
```

## Step 3: Refine with Human

Iterate on the structure based on feedback. Use **AskUserQuestion tool** for each refinement round, asking about:
- Phase ordering concerns
- Phases that should be merged or split
- Dependency issues between phases
- Missing phases or scope gaps

Continue until the human approves the decomposition.

## Step 4: Write structure.md

Write the full structure document and present via **AskUserQuestion tool** for final review. Save to `~/brain/dev/projects/[folder]/structure.md` using this template:

```markdown
# Structure: [Feature/Task Name]

**Project:** [folder-name]
**Created:** YYYY-MM-DD
**Design:** design.md

## Decomposition Strategy
[1-2 paragraphs on why the work was sliced this way.
 Reference the design concept and chosen patterns.]

## Phases

### Phase 1: [Name]
**Touches:** [components/layers this phase affects]
**LOC estimate:** ~XXX
**Dependencies:** None
**Testable via:** [how to verify this phase independently]
**Key files:**
- `path/to/file.ext` — [what changes]

### Phase 2: [Name]
**Touches:** [components/layers]
**LOC estimate:** ~XXX
**Dependencies:** Phase 1
**Testable via:** [verification approach]
**Key files:**
- `path/to/file.ext` — [what changes]

[... more phases ...]

## Phase Dependency Graph
[Simple text diagram showing which phases depend on which]

## Next Steps
- [ ] Create plan: `/workflow:plan [folder-name]`
```

## Next Steps

After saving, suggest the user clear context with `/clear`, then use **AskUserQuestion tool** to present:
- Proceed to plan: `/workflow:plan [folder-name]`
- Refine structure further
- Done for now

## Key Principles

- **Vertical slices over horizontal layers** — each phase should be end-to-end testable
- **LOC guidelines are soft targets** — flag outliers, don't hard-enforce
- **Reference design decisions, don't re-debate them** — the design is settled
- **One question at a time** — every interaction goes through AskUserQuestion tool
- **Lead with your recommendation** — present a concrete proposal, then let the human adjust
