---
name: workflow:contract
description: "Define behavioral contracts from approved design. Produces contract.md with ordered behaviors, module boundaries, and testing decisions. Use after design is complete, before implementation."
argument-hint: "[project-folder]"
model: opus
disable-model-invocation: true
---

# Behavioral Contract

Turn the approved design into a behavioral contract — what the system must do, ordered by risk-reduction. Each behavior becomes one TDD tracer bullet during implementation. No file paths, no LOC, no code snippets.

## Artifacts

- **Reads**: `design.md` (required), `research.md` (recommended)
- **Produces**: `contract.md`

## Initial Setup

When this skill is invoked:

1. **Check for project folder argument**
   - If argument provided: verify folder exists at `~/brain/dev/projects/[argument]/`
   - Check for `design.md` — if missing, warn via **AskUserQuestion tool**
   - Check for `research.md` — if missing, warn via **AskUserQuestion tool**
   - Check for existing `contract.md` — if exists, output the Behaviors and Modules sections as text, then ask via **AskUserQuestion tool**: "Found an existing contract. Refine this, or start fresh?"
   - If no argument, auto-detect recent project folders and present via **AskUserQuestion tool**

## Step 1: Absorb Design + Research

1. Read `design.md` and `research.md` fully — no sub-agents for reading
2. Spawn `codebase-pattern-finder` to find examples of the chosen patterns in the codebase

## Step 2: Draft Behaviors

Propose an ordered list of behaviors. Each behavior = one user/caller-facing outcome. Order by risk-reduction: the first behavior is the smallest end-to-end proof of the riskiest assumption.

First, output the behaviors as regular text so markdown renders properly:

```
Proposed behaviors (risk-reduction order):

1. **[Short behavior name]**
   [One sentence: what outcome this proves and why it's ordered here]

2. **[Short behavior name]**
   [One sentence: what outcome this proves and why it's ordered here]
```

Then ask via **AskUserQuestion tool** with just the decision prompt: "Reorder, merge, split, or add?"

## Step 3: Define Module Boundaries

For each module, define responsibilities and interfaces using Ousterhout's "deep modules" — complex internals behind simple interfaces. Describe conceptually, not structurally.

## Step 4: Testing Decisions + Anti-Behaviors

Determine through conversation:
- What to test through public interfaces
- Mock/stub boundaries
- Integration vs unit split
- Prior art from `research.md`
- Anti-behaviors from design's Boundaries and spec's "Won't Have"

For each decision point, output your recommendation as text, then use **AskUserQuestion tool** with a short confirmation or choice prompt.

## Step 5: Write contract.md

Write the full contract and output it as text for review. Then ask via **AskUserQuestion tool**: "Save this contract, or revise?" Save to `~/brain/dev/projects/[folder]/contract.md`:

```markdown
# Contract: [Feature/Task Name]

**Project:** [folder-name]
**Created:** YYYY-MM-DD
**Design:** design.md

## Behaviors

Ordered by risk-reduction. Each is one TDD tracer bullet.

1. [ ] **[Behavior]** — [User/caller-facing outcome. No file paths. No code.]
2. [ ] **[Behavior]** — [description]

## Modules

### [Module name]
**Owns:** [responsibility]
**Interface:** [how callers interact — conceptual, not code]

## Testing Decisions

- [Public interface testing approach]
- [Mock/stub boundaries]
- [Prior art from research]

## Anti-Behaviors

- [Things this must NOT do]

## Next Steps
- [ ] `/workflow:implement [folder-name]`
```

## Next Steps

After saving, suggest `/clear`, then ask via **AskUserQuestion tool**: "Next: implement, refine, or done for now?"
