---
name: feature
description: Implements a feature from a Linear issue spec. Reads the spec, understands codebase context, implements the feature, runs tests, and creates a PR linked to Linear.
argument-hint: "<linear-issue-id>"
---

Implement the feature described in Linear issue **$ARGUMENTS** for `mus-inn/carjudge-api`.

## Workflow

1. **Preflight** — Verify `linear auth whoami`, `gh auth status`. Stop if any fails.
2. **Fetch spec** — `linear issue view $ARGUMENTS --json`. Read title, description, acceptance criteria. Stop if spec is too vague.
3. **Context** — Read `CLAUDE.md`, sibling files, related models/tests. Use `search-docs` for Laravel ecosystem packages.
4. **Plan** — List files to create, modify, and tests to write.
5. **Branch** — `git checkout -B feature/<LINEAR_ID>`.
6. **Implement** — Use `php artisan make:` commands. Follow sibling conventions strictly.
7. **Test** — Create Pest tests (`php artisan make:test --pest`). Use factories and existing states.
8. **Format & test** — `vendor/bin/pint --dirty --format agent`, then `php artisan test --compact --filter=<RelevantTest>`.
9. **Commit & push** — Stage only modified/created files (no `git add .`). Push with `-u`.
10. **Create PR** — `gh pr create` with French body, reviewer `mus-inn/carjudge`, `Closes <LINEAR_ID>`.
11. **Linear status** — Move issue to "Review Tech".

## Rules

- Never merge, force push, or push to main/master
- Never delete existing tests
- Never close or archive Linear issues
