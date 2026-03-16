---
name: workflow:design
description: "Iterative design conversation to build shared understanding before planning. Produces design.md."
argument-hint: "[project-folder]"
model: opus
disable-model-invocation: true
---

# Design Conversation

Build a shared design concept between AI and human through iterative grilling. Frederick P. Brooks' key insight: a shared "design concept" among all collaborators predicts the quality of everything downstream more than any single artifact. The quality of this conversation determines the quality of the plan, the structure, and the code.

Your job is to surface your understanding so the human can correct your thinking — not to present a polished proposal. Show your work. Be wrong out loud. Let the human steer.

## Artifacts

- **Reads**: `spec.md` (required), `research.md` (recommended)
- **Produces**: `design.md`

## Initial Setup

When this skill is invoked:

1. **Check for project folder argument**
   - If argument provided (e.g., `/workflow:design 2025-01-27-ENG-1234-feature`):
     - Verify folder exists at `~/brain/dev/projects/[argument]/`
     - Check for `spec.md` — if missing, warn: "No spec.md found. The design conversation works best with a spec. Continue anyway?" via **AskUserQuestion tool**
     - Check for `research.md` — if missing, warn: "No research.md found. Design without research may miss codebase constraints. Continue anyway?" via **AskUserQuestion tool**
     - Check for existing `design.md` — if exists, read it and inform user: "Resuming design for project [folder-name]."
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (spec: yes/no, research: yes/no, design: yes/no)
     - [folder-2] (spec: yes/no, research: yes/no, design: yes/no)
     - Provide folder name manually

3. **If no folders found or user provides folder name**: Verify folder exists and proceed.

## Step 1: Absorb Context

1. Read `spec.md` and `research.md` fully in main context — no sub-agents for reading
2. If research surfaced competing patterns, note them — Design is where we pick the winner
3. Spawn **codebase-analyzer** and **codebase-pattern-finder** agents in parallel to gather any additional context the research may have missed
4. Wait for agents to complete, read any newly identified files

## Step 2: Dump Understanding

Present a structured "brain dump" — this is NOT a proposal, it's showing your work so the human can correct your thinking:

```
Here's my current understanding:

**Problem:** [What we're solving and why, in your own words]

**Current State:** [What exists in the codebase today, from research]

**Key Constraints:** [What limits our options]

**Competing Patterns:** [Patterns found in research — which you'd lean toward and why]

**Uncertainties:** [What you're not sure about — be explicit]
```

Be honest about what you don't understand. The human should read this and think "they get it" or "no, that's wrong because..." — both outcomes are valuable.

## Step 3: Grill the Human

Ask pointed questions via **AskUserQuestion tool**, one at a time. Focus on decisions that affect multiple downstream phases:

- Pattern choices: "Research found both X and Y patterns in the codebase. Which should we follow?"
- Boundary definitions: "Should this include Z, or is that out of scope?"
- Tradeoffs: "We could do A (simpler, less flexible) or B (more complex, more extensible). Which matters more here?"
- Anti-goals: "What should this explicitly NOT do?"

Each question should present 2-4 options with tradeoffs, leading with your recommendation. The human should feel "grilled" — questions should surface assumptions and force explicit decisions.

**Exit condition:** Continue until the human says "that's enough" or all key decisions are made. Err on the side of asking one more question rather than one fewer.

## Step 4: Write design.md

Write the design document section by section. Present each section to the user for approval via **AskUserQuestion tool** before moving to the next.

Save to `~/brain/dev/projects/[folder]/design.md` using this template:

```markdown
# Design: [Feature/Task Name]

**Project:** [folder-name]
**Created:** YYYY-MM-DD

## Design Concept
[2-3 paragraph narrative of what we're building and the key insight/approach.
 This is the "one idea" that everyone working on this should have in their head.
 Write it so someone unfamiliar with the project could read just this section
 and understand the core approach.]

## Key Decisions
[Numbered list of decisions made during the design conversation.
 Each entry: the decision, the rationale, and alternatives considered.]

1. **[Decision]** — [rationale]. Considered [alternative] but rejected because [reason].

## Chosen Patterns
[Which existing codebase patterns we're following and why.
 Reference specific file:line examples from research.]

## Boundaries
[What this design explicitly does NOT cover.
 Where the boundaries are between this work and adjacent systems.]

## Open Risks
[Known unknowns that structure/plan phases should account for.]

## Next Steps
- [ ] Create structure: `/workflow:structure [folder-name]`
```

## Next Steps

After saving, suggest the user clear context with `/clear`, then use **AskUserQuestion tool** to present:
- Proceed to structure: `/workflow:structure [folder-name]`
- Refine design further
- Done for now

## Key Principles

- **Do not outsource the thinking** — surface your understanding, let the human correct it
- **Research surfaces facts, Design makes decisions** — never re-do research here
- **The design concept is the highest-leverage artifact** — get it right and everything downstream flows
- **One question at a time** — every question goes through AskUserQuestion tool
- **Lead with your recommendation** — but present alternatives honestly
- **Be wrong out loud** — it's better to state a wrong assumption and get corrected than to hide uncertainty
