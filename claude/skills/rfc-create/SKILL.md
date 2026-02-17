---
name: workflows:rfc-create
description: Transform workflow artifacts (spec.md, research.md, plan.md) into team RFC format. Use when the user wants to create an RFC, generate an RFC, or convert project artifacts into an RFC for team review.
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion, Write, Edit, Task
argument-hint: "[project-folder]"
---

# Create RFC from Workflow Artifacts

Generate a team-ready RFC by transforming existing project artifacts (spec.md, research.md, plan.md) into the team's RFC template. Adapts to whatever artifacts are available — uses what exists, asks the user for anything it can't derive.

## Initial Setup

1. **Check for project folder argument**
   - If argument provided (e.g., `/rfc-create 2026-02-10-ENG-123-feature`):
     - Verify folder exists at `~/brain/dev/projects/[argument]/`
     - If folder doesn't exist, inform user and stop
     - Inform user: "Using project folder [name]."
   - If no argument, proceed to step 2

2. **Auto-detect recent project folders** (if no argument):
   - Find folders from last 30 days in `~/brain/dev/projects/`
   - Use **AskUserQuestion tool** to show options:
     - [folder-1] (spec: yes/no, research: yes/no, plan: yes/no)
     - [folder-2] (spec: yes/no, research: yes/no, plan: yes/no)
     - Provide folder name manually

3. **Read all available artifacts** in the project folder:
   - Read `spec.md` FULLY if it exists (no limit/offset)
   - Read `research.md` FULLY if it exists (no limit/offset)
   - Read `plan.md` FULLY if it exists (no limit/offset)
   - Note which artifacts are missing — these create gaps that require user input

## Artifact → RFC Mapping

Use this mapping to transform artifact content into RFC sections. Sections marked with * are **required** — they must be filled before saving.

| RFC Section | Primary Source | Notes |
|---|---|---|
| **Executive Summary*** | spec.md: Problem Statement + Goals + Approach | Concise 2-4 sentence summary of the whole RFC |
| **Motivation & Business Case** | spec.md: Problem Statement + Goals | Why this matters — business/user impact |
| **Domain Model** | research.md: domain terms + spec.md: business rules | Terms, entity relationships, business rules, bounded contexts |
| **Design Criteria** | spec.md: Requirements + plan.md: behavioral contracts, SLAs | Design constraints, key behavioral contracts, and performance expectations |
| **Associated Links & Alternative Approaches*** | plan.md: Alternative Approaches + References; spec.md: Approach rationale | Include links to tickets, docs, prior art |
| **Implementation Plan*** | plan.md: Phases → Milestones with cycle estimates | Each Phase becomes a Milestone |
| **Release Plan** | plan.md: Migration Notes, phased rollout details | How this ships to users |
| **Relevant Tech Debt** | research.md: findings about existing technical debt | Tech debt discovered during research |
| **Clean Up Plan** | plan.md: cleanup/migration/rollback notes | Post-release cleanup work |
| **Potential Impact & Dependencies** | spec.md: Constraints + plan.md: Risk Analysis | Cross-team or system-wide effects |
| **Drawbacks** | plan.md: cons from alternative approaches, Risk Analysis | Honest assessment of downsides |
| **Unresolved Questions** | spec.md: Open Questions + any remaining unknowns | Questions that need answers before or during implementation |
| **Reviews** | — | Leave empty. The team populates this during review cycles. |
| **Key Decisions*** | Decisions captured across all artifacts: chosen approach, rejected alternatives, key tradeoffs | Consolidate decisions made during brainstorm and planning |

## Workflow

### Step 1: Build the Draft

After reading all available artifacts, generate the **complete RFC** in one pass using the mapping above.

**For each section:**
- If the source artifact exists and contains relevant content → transform and populate the section
- If the source artifact is missing or doesn't cover that section → leave a `<!-- NEEDS INPUT -->` marker internally (do not show to user yet)

**Writing guidelines — use the L1-L4 layers as a quality lens:**

Each RFC section targets a specific level of abstraction. Use these layers to ensure the right depth and audience for each section:

- **L1 (Strategic — WHY):** Executive Summary, Motivation & Business Case. Write for stakeholders. Focus on the business problem, quantifiable impact, success metrics, and why now. Avoid technical details.
- **L2 (Domain — WHAT concepts):** Domain Model. Establish shared vocabulary. Define domain concepts, business rules, entity relationships, and bounded contexts. A reader should understand the problem space without knowing anything about the implementation.
- **L3 (Behavioral — HOW components interact):** Design Criteria. Capture key behavioral contracts, SLAs, and component interaction expectations. Should be technology-agnostic — someone could build a compatible system with different tech and still satisfy these criteria.
- **L4 (Implementation — SPECIFICALLY how):** Implementation Plan. Concrete milestones, deliverables, and technical steps. This is where technology choices, specific files, and code-level detail belong.

**General writing rules:**
- Match the tone and depth appropriate for a team review document
- Be specific — cite concrete files, components, and behaviors from the artifacts
- Implementation Plan milestones should include cycle estimates if the plan has them
- Executive Summary should stand alone — a reader should understand the full scope from it
- Domain Model entries should be concise: term + one-line meaning, rules as clear invariants
- Drawbacks should be honest, not dismissed
- Don't let layers bleed — keep business rationale out of Implementation Plan, keep code out of Design Criteria

### Step 2: Identify Gaps

After drafting, identify all sections that have `<!-- NEEDS INPUT -->` markers. These are sections that couldn't be derived from existing artifacts.

**For each gap**, use **AskUserQuestion tool** to ask the user to provide content. Ask about gaps **one at a time**. For each question:
- Name the section
- Explain what kind of content belongs there
- If you have a partial guess from context, offer it as a starting option

### Step 3: Present and Confirm

Once all gaps are filled, present a **summary** of the RFC to the user:
- List each section with a 1-line description of what's in it
- Flag any sections that feel thin or may need more detail
- Note which sections were derived from artifacts vs. provided by user

Use **AskUserQuestion tool** to ask:
- "Does this look right? Any sections you want to revise?"
- Options: "Looks good, save it" / "I want to revise sections"

If the user wants revisions, ask which section(s) and iterate until approved.

### Step 4: Save

Save the RFC to `~/brain/dev/projects/[folder]/rfc.md`.

If `rfc.md` already exists, use **AskUserQuestion tool** to confirm overwrite.

## RFC Template

The output must follow this exact structure:

```markdown
# [Title] (RFC)

## Executive Summary

[2-4 sentences covering what this is, why it matters, and the chosen approach]

## Motivation & Business Case

- [Business or user impact justification]

## Domain Model

| **Term** | **Meaning** |
| --- | --- |
| [Term] | [Definition] |

**Business Rules:**
- [Invariant or constraint that must always hold]

**Entity Relationships:**
- [How key domain concepts relate to each other]

## Design Criteria

- [Design constraint or requirement]
- [Behavioral contract: component X must do Y with Z guarantees]
- [Performance expectation or SLA]

## Associated Links & Alternative Approaches

- [Link or reference to related docs, tickets, prior art]
- **Alternative: [Name]** — [Why it was considered and why it was rejected]

## Implementation Plan

### Milestone 1 ([cycle estimate])

1. [Step or deliverable]

### Release Plan

1. [How this ships to users]

### Relevant Tech Debt to be Addressed

- [Tech debt items discovered during research]

### Clean Up Plan

1. [Post-release cleanup steps]

## Potential Impact and Dependencies

[Cross-team impacts, system dependencies, integration points]

## Drawbacks

[Honest assessment of downsides, risks, tradeoffs]

## Unresolved Questions

- [Question]

    Answer & links to any relevant documentation (meeting notes, solution card, etc.)

## Reviews

-

## Key Decisions

- [Decision: what was decided and why]
```

## Guidelines

- **Do NOT fabricate content.** If an artifact doesn't cover a section and the user hasn't provided input, leave it as a clear placeholder rather than inventing details.
- **Required sections (marked *)** must have real content before saving. If the user skips a required section, warn them that it's expected for team review.
- **Preserve the user's voice.** When transforming artifact content, keep the substance and intent. Don't over-polish or add corporate filler.
- **One question at a time** when filling gaps. Don't dump all missing sections at once.
- **Reviews section is always empty.** Never pre-populate it.
