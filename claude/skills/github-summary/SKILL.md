---
name: github-summary
description: Generate a 6-month GitHub activity summary for peer reviews. Triggers on "github summary for [username]" or "github activity for [username]". Uses the gh CLI to fetch PRs merged, code reviews given from the current repo, then produces a standalone markdown summary organized by work themes.
---

# GitHub Summary for Peer Reviews

Generate a comprehensive 6-month activity summary for a GitHub user in the current repository.

## Prerequisites

- `gh` CLI installed and authenticated
- Run from within a git repository

## Workflow

### 1. Validate Environment

```bash
# Verify gh CLI is available and authenticated
gh auth status

# Get repo info
gh repo view --json nameWithOwner -q .nameWithOwner
```

### 2. Fetch Activity (Last 6 Months)

Calculate the date 6 months ago for filtering:

```bash
# macOS
START_DATE=$(date -v-6m +%Y-%m-%d)

# Linux
START_DATE=$(date -d '6 months ago' +%Y-%m-%d)
```

#### PRs Authored (Merged)

```bash
gh pr list --author USERNAME --state merged --search "merged:>=$START_DATE" --json number,title,body,mergedAt,additions,deletions,files --limit 200
```

#### Code Reviews Given

```bash
gh api "repos/{owner}/{repo}/pulls?state=all&per_page=100" --paginate | \
  jq '[.[] | select(.merged_at >= "'$START_DATE'")] | 
      .[].number' | \
  xargs -I {} gh api "repos/{owner}/{repo}/pulls/{}/reviews" | \
  jq '[.[] | select(.user.login == "USERNAME")]'
```

Or use search for review comments:

```bash
gh api "search/issues?q=repo:{owner}/{repo}+reviewed-by:USERNAME+is:pr+merged:>=$START_DATE" --paginate
```

### 3. Analyze and Summarize

After fetching the data, analyze it to produce:

1. **Work Buckets**: Group PRs by theme/area (infer from titles, file paths, PR bodies)
2. **Key Contributions**: Highlight significant PRs by size, impact, or complexity
3. **Review Activity**: Summarize volume and pattern of code reviews given
5. **Patterns**: Identify collaboration patterns, areas of ownership, throughput

### 4. Output Format

Produce a markdown summary with this structure:

```markdown
# GitHub Activity Summary: [Username]
**Period**: [Start Date] – [Today]
**Repository**: [repo name]

## Work Themes

### [Theme 1: e.g., Billing System]
- Brief description of the body of work
- Key PRs: #123, #456, #789
- Impact/scope notes

### [Theme 2: e.g., CI/CD Improvements]
...

## Key Contributions

| PR | Title | Merged | Scope |
|----|-------|--------|-------|
| #123 | Title here | 2024-08-15 | +500/-200, 12 files |
...

## Code Reviews

- **Reviews given**: X PRs reviewed
- **Review style**: [observations about depth, areas reviewed]
- **Notable reviews**: PRs where they provided significant feedback

## Patterns & Observations

- Areas of ownership
- Collaboration patterns
- Throughput/velocity notes
- Notable contributions worth highlighting in a peer review
```

## Notes

- If `gh` commands fail due to rate limits, wait and retry or reduce `--limit`
- For large repos, the review data may require multiple API calls
- Focus on quality over completeness—highlight what matters for a peer review
