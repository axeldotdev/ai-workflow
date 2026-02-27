---
name: retro
description: Generates a bi-weekly retrospective from GitHub PRs and Linear issues over the last 14 days. Use when the user asks for a retro or sprint review.
---

# Retrospective

Generate a bi-weekly sprint retrospective for the whole team. All output in English.

## Config

- **GitHub Repo**: `mus-inn/carjudge-api`
- **Linear Team**: `CarJudge`

## Steps

### Step 1: Get Merged PRs (Last 14 Days)

```bash
gh pr list --repo mus-inn/carjudge-api --state merged --search "merged:>=DATE_14_DAYS_AGO" --json number,title,url,author,headRefName,mergedAt,labels --limit 100
```

Replace `DATE_14_DAYS_AGO` with the date 14 days ago in `YYYY-MM-DD` format.

### Step 2: Get Completed Linear Issues (Last 14 Days)

Use Linear MCP tools to list completed issues for the CarJudge team over the last 14 days.

If Linear MCP is not available, fall back to:

```bash
linear issue list --team CarJudge --state completed --all-assignees --limit 0 --no-pager
```

Then filter results to the last 14 days.

### Step 3: Cross-Reference & Categorize

Match PRs to Linear issues using branch name format: `type/ISSUE-ID`.

Categorize each item based on branch prefix, labels, or issue type:
- **feat/** or feature label → Features
- **fix/** or bug label → Bug Fixes
- **improve/** or enhancement label → Improvements
- Everything else → Other (chores, docs, refactors, CI)

### Step 4: Identify Contributors

Extract unique contributors from PR authors and issue assignees.

## Output Format

```markdown
# Retro — YYYY-MM-DD to YYYY-MM-DD

## Stats
- X PRs merged, Y issues completed, Z contributors

## Features
- [#123 PR title](url) by @author — CAR-123: Issue title
- ...

## Bug Fixes
- [#130 PR title](url) by @author — CAR-130: Issue title
- ...

## Improvements
- [#140 PR title](url) by @author — CAR-140: Issue title
- ...

## Other
- [#150 PR title](url) by @author — chore/docs/refactor description
- ...

## Highlights
- Biggest features or milestones shipped
- Notable bug fixes or performance improvements

## Notes
- Patterns observed (e.g., lots of bug fixes → possible tech debt)
- Velocity trends if previous retro data is available
- Suggestions for next sprint
```

## Guidelines

- Scope is the whole team
- If a category has no items, omit it
- Keep highlights to 3-5 bullet points max
- Be objective in stats, constructive in notes
- If items can't be categorized confidently, put them in Other
