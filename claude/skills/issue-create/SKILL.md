---
name: issue-create
description: Generate development issues for Linear. Use when the user asks to create an issue, write an issue, draft a dev task, or document work to be done. Produces structured issues with title, context, scope, acceptance criteria, and estimates.
---

# Dev Tickets

Generate Linear-ready development issues that are concise yet thorough, optimized for both human developers and AI agents.

## Before Writing
1. If the request references code, use **codebase-locator** to find relevant files
2. If implementation details are needed, use **codebase-analyzer** to understand how existing code works
3. If patterns/examples would help scope the work, use **codebase-pattern-finder**
4. Ask clarifying questions if the request is vague or ambiguous

## Workflow
4. Confirm understanding of the task with the user
5. Generate draft issue
6. Ask if refinements are needed before finalizing

## Multiple Issues
If the request spans multiple concerns or the scope grows complex, generate separate issues and note dependencies between them.

## Template

```markdown
## [Action verb] [thing] [context]

### Why
1-2 sentences. What problem are we solving or opportunity are we capturing?

### What
Brief description of the solution approach.

### Scope
- Deliverable 1
- Deliverable 2
- Deliverable 3

### Acceptance Criteria
- [ ] Testable criterion 1
- [ ] Testable criterion 2
- [ ] Testable criterion 3

### Technical Notes
Optional: file locations, edge cases, dependencies, gotchas

### Resources
Optional links:
- [Figma](#)
- [Related PR](#)
- [Spec doc](#)

### Estimate
X points (1 point = half-day)
```

## Guidelines

### Titles
Start with an action verb: Add, Fix, Refactor, Update, Remove, Implement, Migrate.

### Why
Answer: What's broken, missing, or suboptimal? Keep to 1-2 sentences.

### What
Answer: What are we building to address it? Stay high-level.

### Scope
List only what's in scope. Out of scope is implicit—if it's not listed, it's not included. Be specific enough to prevent scope creep.

### Acceptance Criteria
Each criterion must be independently testable. Write them as completion conditions, not implementation steps.

**Examples:**
- ❌ "Implement authentication middleware"
- ✅ "User is redirected to login when accessing protected routes without a session"

- ❌ "Add error handling"
- ✅ "System displays user-friendly error message when API request fails"

### Technical Notes
Optional. Include only when there's non-obvious context: specific files to modify, edge cases to handle, architectural decisions, or sequencing dependencies.

### Resources
Optional. Link to Figma designs, related PRs, spec docs, or relevant existing code.

### Estimate
Use wall clock time: 1 point = half-day of work.
- 1 point: half-day
- 2 points: full day
- 3 points: day and a half
- 4 points: two days

If estimate exceeds 4 points, suggest breaking into smaller tickets.
