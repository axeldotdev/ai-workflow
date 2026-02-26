---
name: document
description: Generates GitHub wiki documentation for a feature or hotfix. Use when the user wants to document something, providing a file name, PR number, or Linear issue ID.
---

# Document

Generate GitHub wiki documentation for a feature, hotfix, or change. All output in English.

## Input

Accept one or more of the following as input:
- **File paths**: paths to relevant source code files
- **PR number or URL**: a GitHub pull request to document
- **Linear issue ID**: a Linear issue to document (e.g., `CAR-123`)

## Data Gathering

### From Code Files
- Read each provided file to understand the implementation
- Identify key classes, methods, patterns, and data flows

### From GitHub PR
If a PR number or URL is provided:
```bash
gh pr view <PR> --repo mus-inn/carjudge-api --json title,body,author,url,labels,baseRefName,headRefName,additions,deletions,files
```
```bash
gh pr diff <PR> --repo mus-inn/carjudge-api
```

### From Linear Issue
If a Linear issue ID is provided, use Linear MCP tools to get issue details.

If Linear MCP is not available, fall back to:
```bash
linear issue view <ISSUE-ID>
```

## Output Format

Generate a markdown document with the following sections:

```markdown
# [Feature/Fix Name]

## Overview
One-paragraph summary of what this change does and why it exists.

## Context
Why this was needed. Pull from:
- Linear issue description (the problem, user impact)
- PR description (motivation, background)
- Any related issues or discussions

## Solution
What was done to address the problem:
- High-level approach
- Key decisions made and why
- What was considered but not done (if relevant)

## Technical Details
Implementation specifics:
- Key files modified and their roles
- Patterns or abstractions used
- Database changes (migrations, schema)
- API changes (new endpoints, modified responses)
- Configuration changes

## Testing
- How to test this change manually
- Key edge cases to verify
- Automated test coverage (if any)

## Related
- PR: [#123 PR title](url)
- Linear: [CAR-123: Issue title](url)
- Files: list of key files involved
```

## Guidelines

- Write for a developer who is new to the codebase
- Be specific — reference actual file names, method names, and line numbers
- Keep it concise but complete — aim for 1-2 pages
- Don't repeat the full code — summarize and reference
- Output should be ready to paste directly into a GitHub wiki page
- If information is missing (no PR, no issue), work with what's available and note gaps
