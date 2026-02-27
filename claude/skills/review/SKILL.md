---
name: review
description: Reviews a single GitHub pull request. Analyzes the diff against project conventions, security best practices, and logic correctness, then posts a formal review with inline comments.
argument-hint: "<pr-number>"
---

Review the pull request **#$ARGUMENTS** on `mus-inn/carjudge-api`.

## Workflow

1. **Fetch PR** — `gh pr view $ARGUMENTS`, `gh pr diff $ARGUMENTS`. Do NOT checkout the branch.
2. **Check existing reviews** — If an agent already reviewed (body contains "Generated with Claude Code"), stop.
3. **Read context** — Read `CLAUDE.md`, changed files in full, and related files (tests, parent classes, interfaces).
4. **Analyze** — Focus on (in priority order):
   - Security (SQL injection, XSS, auth bypass, secrets, mass assignment)
   - Logic bugs (null handling, race conditions, incorrect conditionals)
   - Conventions (deviations from CLAUDE.md or sibling patterns)
   - Error handling (unhandled exceptions, silent failures)
   - Test coverage (missing tests for new behavior)
   - Migration safety (destructive changes, missing rollback)
   - Skip anything CI catches (Pint, Larastan, ESLint).
5. **Build findings** — Each finding: path, line (within diff hunk), severity, body.
6. **Verdict** — `REQUEST_CHANGES` if security/logic finding with >=90% confidence; `COMMENT` otherwise.
7. **Submit** — Post review via `gh api repos/mus-inn/carjudge-api/pulls/$ARGUMENTS/reviews`. Use `jq` to build JSON safely. If 422 error (line outside hunk), move comment to body and retry.

## Rules

- All review content in **French**
- Never approve or merge
- `COMMENT` or `REQUEST_CHANGES` only
