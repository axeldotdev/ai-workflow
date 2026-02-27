---
name: daily
description: Generates a daily standup summary from GitHub PRs and Linear issues. Use when the user asks for a daily report or standup.
---

# Daily Standup

Generate a daily standup summary for the whole team. All output in English.

## Config

- **GitHub Repo**: `mus-inn/carjudge-api`
- **Linear Team**: `CarJudge`

## Steps

### Step 1: Get Merged PRs

Run the following to get PRs merged since yesterday:

```bash
gh pr list --repo mus-inn/carjudge-api --state merged --search "merged:>=YESTERDAY" --json number,title,url,author,headRefName,mergedAt --limit 50
```

Replace `YESTERDAY` with yesterday's date in `YYYY-MM-DD` format.

### Step 2: Get Completed Linear Issues

Use Linear MCP tools to list issues completed for the CarJudge team. Filter to issues whose completion date is yesterday.

If Linear MCP is not available, fall back to:

```bash
linear issue list --team CarJudge --state completed --all-assignees --no-pager
```

Then filter results to yesterday's date.

### Step 3: Cross-Reference

Match PRs to Linear issues using the branch name format: `type/ISSUE-ID` (e.g., `feat/CAR-123`, `fix/CAR-456`).

Extract the issue ID from `headRefName` and link it to the corresponding Linear issue.

## Output Format

```markdown
# Daily — YYYY-MM-DD

## PRs Merged
- [#123 PR title](url) by @author — linked to CAR-123
- [#124 PR title](url) by @author — no linked issue

## Issues Completed
- [CAR-123: Issue title](url) — @assignee — label
- [CAR-124: Issue title](url) — @assignee — label

## Summary
- X PRs merged, Y issues completed
- Key themes: brief summary of what was accomplished
```

## Guidelines

- Scope is the whole team, not just the current user
- If no PRs or issues are found, say so explicitly
- Group related PRs and issues together when possible
- Keep the summary concise — this is for a standup, not a report
