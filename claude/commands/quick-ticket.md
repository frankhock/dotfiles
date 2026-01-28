---
name: quick-ticket
description: Generate minimal Linear ticket outlines from git commits or feature branches. Use when the user mentions creating a quick ticket, documenting a PR, retroactive ticket, getting credit for completed work, or provides a commit hash or says they're on a feature branch. Examines git history to auto-generate the ticket.
model: sonnet
---

# Quick Ticket

Generate minimal ticket outlines from git commits. Examines the actual code changes to produce accurate descriptions.

## Workflow

1. Get commit info via one of:
   - `git show <commit-hash> --stat` if hash provided
   - `git log origin/main..HEAD --oneline` then `git diff origin/main..HEAD --stat` if on feature branch
2. Generate ticket from commit message and diff summary

## Template

```markdown
## [Action verb] [thing] [context]

[1-2 sentences: what was done and why, derived from commit]

PR: [link if available]
```

## Guidelines

- **Title**: Start with action verb (Fix, Add, Update, Refactor, Remove)
- **Description**: Past tense, brief. Summarize the change and its purpose.
- Infer the "why" from the code changes when commit message is terse
