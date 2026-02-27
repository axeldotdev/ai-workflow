---
name: fix
description: Fixes a single Sentry issue. Reads the stacktrace, applies a minimal fix, runs tests, and creates a PR linked to Linear and Sentry.
argument-hint: "<sentry-issue-id>"
---

Fix the Sentry issue **$ARGUMENTS** for `dotworld-sarl-zv/carjudge-api`.

## Workflow

1. **Preflight** — Verify `sentry auth status`, `linear auth whoami`, `gh auth status`. Stop if any fails.
2. **Fetch issue** — `sentry issue view $ARGUMENTS --json`. Read the stacktrace, identify root-cause files.
3. **Linear** — Search `linear issue list --team DOTO --query "$ARGUMENTS"`. If no match, create with title format `fix: {error_type} in {location} ({sentry_id})`.
4. **Understand** — Read stacktrace files in full. Understand the root cause before writing code.
5. **Branch & fix** — `git checkout -B fix/<LINEAR_ID>`. Apply **minimal fix** only.
6. **Format & test** — `vendor/bin/pint --dirty --format agent`, then `php artisan test --compact --filter=<RelevantTest>`.
7. **Commit & push** — Stage only modified files (no `git add .`). Push with `-u`.
8. **Create PR** — `gh pr create` with French body, reviewer `mus-inn/carjudge`, `Closes <LINEAR_ID>`.
9. **Link Sentry** — Post PR URL as comment on Sentry issue.
10. **Linear status** — Move Linear issue to "Review Tech".

## Rules

- Never merge, force push, or push to main/master
- Never resolve or archive the Sentry issue
- Minimal fixes only — fix the bug, nothing more
