---
name: skill-editor
description: "Critical editing pass on a SKILL.md to cut bloat, remove over-explanation, and tighten prose. Use when a skill feels too long, wordy, or over-engineered — or after creating/updating any skill."
argument-hint: "[path to skill or skill name]"
---

# Skill Editor

Read the target SKILL.md, then cut it down. The model is smart — trust it. Your job is to remove everything that doesn't change the model's behavior.

## The Cuts

Apply these in order. For each, show what you'd remove and why.

**1. The model already knows this.** Delete instructions describing standard LLM behavior. "Ask clarifying questions", "be flexible", "validate assumptions" — the model does these by default. Only instruct when you want *non-default* behavior.

**2. Said it twice.** Find the same idea restated in different words or locations. Keep the strongest version, delete the rest.

**3. Hedging adds nothing.** Kill qualifiers: "when possible", "if appropriate", "consider whether", "you may want to". State the rule or don't.

**4. Scaffolding tax.** Question whether numbered phases, section headers, and process labels earn their keep. A terse paragraph often beats a 5-phase workflow. Phase labels are justified only when the model needs to skip or reorder steps conditionally.

**5. Over-specified behavior.** Look for detailed instructions on *how* to do something the model handles well with just the *what*. "Ask questions one at a time about purpose, goals, constraints, success criteria, scope, timeline, budget, existing patterns" can become "Interview the user until you understand the problem, who it's for, and what done looks like."

## Calibration

Before editing, read `references/pocock-examples.md` for examples of well-edited skills. Use these as a density target — not a style to copy, but a bar for "does this line earn its place?"

## Process

1. Read the skill
2. Count directives (any instruction the model must follow). Flag if over 40.
3. Apply the cuts. Present a before/after diff for each cut with a one-line rationale.
4. Show the full edited skill for approval
5. If the user approves, write the file

Preserve: output templates, artifact declarations (reads/produces), behavioral constraints that override model defaults, and the "does NOT do" section (boundary-setting is high-value).
