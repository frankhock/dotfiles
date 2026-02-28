---
name: skill-creator
description: Create new Claude Code skills through an interactive interview. Use when the user wants to create a skill, make a new slash command, build a custom workflow, or scaffold a SKILL.md. Guides through purpose, triggers, design principles, and produces a complete skill directory.
argument-hint: "[skill-name]"
---

# Skill Creator

Create well-structured Claude Code skills through an interactive interview. Read `references/skill-format.md` before drafting any skill.

## Intake

If `$ARGUMENTS` provided, use as the skill name. Otherwise ask what skill the user wants to create.

## Clarity Gate

If the user provides detailed requirements (exact behavior, triggers, output format, constraints), use AskUserQuestion to offer: "Your requirements seem detailed enough to skip exploration. Should I draft the skill directly, or explore further?"

If skipping: read the format reference, then jump to Draft.

## Interview

Ask questions **one at a time** using AskUserQuestion. Prefer multiple choice when natural alternatives exist.

### Topics to Explore

1. **Purpose & trigger** — What does it do? When should it activate? What words would someone naturally say?
2. **Skill type** — Workflow task (user invokes, follows steps), reference knowledge (background context), or hybrid?
3. **Scope** — Personal (`~/.claude/skills/`) or project-local (`.claude/skills/`)?
4. **Deterministic elements** — What must be consistent every time? Fixed formats, CLI commands, templates, naming conventions? These become scripts or explicit rules, not LLM decisions.
5. **Agent reasoning** — Where should Claude use judgment? Interpretation, content generation, contextual decisions?
6. **Constitutional constraints** — What must the agent NEVER do? Only include constraints for concrete, anticipated failure modes. Don't over-specify.
7. **Supporting files** — Does this need reference docs, scripts, agents, or templates?
8. **Tools & model** — Any tool restrictions? Model override needed?

Continue until you have enough to draft, or user says "proceed."

## Draft

1. Read `references/skill-format.md` for format specification.
2. Generate the complete skill directory structure.
3. Present SKILL.md in sections (frontmatter first, then body) using AskUserQuestion after each to validate.

### Brevity Principle

Every instruction must earn its place. Over-specifying degrades performance.

- Prefer 1 clear sentence over 3 hedged ones
- SKILL.md body should target under 200 lines
- Move heavy detail to reference files
- Only add constitutional constraints for real failure modes
- Don't specify behavior the model would do by default

## Validate

Run this checklist against the draft. Flag issues, don't block:

1. **Description** — Trigger keywords present? States when to use? Under ~50 words?
2. **Brevity** — Body under 200 lines? No redundant or obvious instructions?
3. **Invocation control** — Side-effect skills: `disable-model-invocation: true`? Background knowledge: `user-invocable: false`?
4. **Progressive disclosure** — Heavy detail in reference files, not inline?
5. **Constraints** — Specific and necessary, not generic filler?
6. **Frontmatter** — All needed fields present? No unnecessary fields?

## Save

1. Scan target location for name collisions with existing skills.
2. Create the skill directory and write all files.
3. Confirm what was created and where.
