---
name: workflow:design
description: "Iterative design conversation to build shared understanding before planning. Produces design.md. Use when the user wants to discuss architecture, make design decisions, choose between competing approaches, or align on a technical direction before writing a plan — especially after research is complete."
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
     - Check for existing `design.md` — if exists, read it, present the existing Design Concept and Key Decisions sections, then ask via **AskUserQuestion tool**: "Found an existing design. Want to continue refining this, or start fresh?"
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (spec: yes/no, research: yes/no, design: yes/no)
     - [folder-2] (spec: yes/no, research: yes/no, design: yes/no)
     - Provide folder name manually

3. **If no folders found or user provides folder name**: Verify folder exists and proceed.

## Step 1: Absorb Context

1. Read `spec.md` and `research.md` fully in main context — no sub-agents
2. If research surfaced competing patterns, note them — Design is where we pick the winner
3. If you discover a gap in the research during the conversation, tell the human: "This seems like a gap in the research. Want to run `/workflow:research` again, or proceed with what we have?" — do not re-research here

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

## Step 3: Grill the Human

Ask pointed questions via **AskUserQuestion tool**, one at a time. Each question should present 2-4 options with tradeoffs, leading with your recommendation. The human should feel "grilled" — questions should surface assumptions and force explicit decisions.

**Exit checklist** — you need decisions on at least these before moving to Step 4:
- Pattern choice (which codebase patterns to follow)
- Scope boundaries (what's in, what's explicitly out)
- Key tradeoffs (simplicity vs. flexibility, etc.)
- Anti-goals (what this should NOT do)

Continue until the human says "that's enough" or the checklist is covered. Err on the side of asking one more question rather than one fewer.

## Step 4: Write design.md

Write the full design document in one pass — the human already made decisions during the grilling. Present the complete draft to the user via **AskUserQuestion tool** for review. Iterate if they have feedback.

The Design Concept section is the highest-leverage part — downstream skills (structure, plan) will key off of it.

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

