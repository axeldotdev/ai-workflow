---
name: github
description: Work with GitHub issues, PRs, releases, and repository data using gh CLI
---

# GitHub CLI Integration

Use `gh` CLI for GitHub operations beyond what `./pr` and `./ship` provide.

## Related Skills

- **git-workflow** - Use `./ship` and `./pr` for common PR workflows
- **code-review** - Review PRs using `./pr switch`

## When to Use What

### Use `./ship` and `./pr` for:

- Creating branches and PRs → `./ship`
- Checking PR status → `./pr check`
- Merging PRs → `./pr merge`
- Switching branches → `./pr switch`
- Marking ready/draft → `./pr ready` / `./pr draft`

### Use `gh` CLI for:

- Viewing PR details and comments
- Creating/managing GitHub issues
- Searching code across repository
- Working with releases
- Viewing workflow runs
- Operations not covered by `./pr` and `./ship`

## CarJudge Context

- **Repository**: `mus-inn/carjudge-api`
- **Default branch**: `main`
- **Team**: `mus-inn/carjudge`

## Common `gh` Commands

### Pull Requests

```bash
# View PR details
gh pr view 123

# View PR diff
gh pr diff 123

# List PR comments
gh api repos/mus-inn/carjudge-api/pulls/123/comments

# List open PRs
gh pr list

# View PR checks/CI status
gh pr checks 123
```

### Issues

```bash
# List issues
gh issue list

# View issue details
gh issue view 456

# Create issue
gh issue create --title "Bug: ..." --body "Description"

# Close issue
gh issue close 456
```

### Code Search

```bash
# Search code in repository
gh search code "RecurlyService" --repo mus-inn/carjudge-api

# Search with file filter
gh search code "implements ShouldQueue" --repo mus-inn/carjudge-api --filename "*.php"
```

### Releases

```bash
# List releases
gh release list

# View latest release
gh release view --latest

# Create release
gh release create v1.2.3 --title "Release v1.2.3" --notes "## Changes\n- Feature X"
```

### Workflow Runs (CI/CD)

```bash
# List recent workflow runs
gh run list

# View specific run
gh run view 12345

# Watch a running workflow
gh run watch 12345
```

### Repository Info

```bash
# View repo info
gh repo view

# Clone a repo
gh repo clone mus-inn/carjudge-api
```

## API Access

For advanced operations, use `gh api`:

```bash
# Get file contents from another branch
gh api repos/mus-inn/carjudge-api/contents/path/to/file.php?ref=feat/branch

# Get PR review comments
gh api repos/mus-inn/carjudge-api/pulls/123/comments

# Get commit details
gh api repos/mus-inn/carjudge-api/commits/abc123
```

## Workflow Examples

### Reviewing a PR in Detail

```bash
# 1. View PR summary
gh pr view 123

# 2. See the diff
gh pr diff 123

# 3. Check CI status
gh pr checks 123

# 4. Or checkout locally for deeper review
./pr switch feat/branch-name
```

### Finding How Something is Implemented

```bash
gh search code "class RecurlyService" --repo mus-inn/carjudge-api
```

### Checking CI Failures

```bash
# List failed runs
gh run list --status failure

# View failed run details
gh run view 12345 --log-failed
```

## Notes

- Prefer `./ship` and `./pr` for daily PR workflows - they handle team conventions
- Use `gh` for operations those scripts don't cover
- `gh api` gives access to the full GitHub API when needed
- Always use `--repo mus-inn/carjudge-api` when not in the repo directory
