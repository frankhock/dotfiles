---
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(git merge-base:*), Bash(git remote:*), Bash(git fetch:*), Bash(gh pr create:*)
description: Generate PR description and create GitHub pull request
model: sonnet
---

## Context

### Ensure Fresh State
- Fetch latest: !`git fetch origin main`

### Branch Information
- Current branch: !`git branch --show-current`
- Base branch: main

### Change Analysis
- Branch point: !`git merge-base HEAD origin/main`
- Commits since branch point: !`git log origin/main..HEAD --oneline`
- Commit messages: !`git log origin/main..HEAD --format="%s"`
- File changes summary: !`git diff origin/main..HEAD --stat`
- Changed files by type: !`git diff origin/main..HEAD --name-only`

## Task

Use [shared analysis guidelines](../shared/analysis-guidelines.md) for change classification.

1. Analyze the changes and generate a PR title and description using the template from `docs/pull_request_template.md`
2. Show the proposed PR and ask "Ready to create this PR?"
3. On confirmation, run:
   ```bash
   gh pr create --title "YOUR_TITLE" --body "YOUR_DESCRIPTION" --base main
   ```
4. Report the PR URL
