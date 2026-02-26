---
name: linear-issue-ai-ready
description: Write Linear issues optimized for Claude Code and Ralph. Includes file paths, verification steps, and success signals.
---

Write issues that Claude Code and Ralph can execute without clarification.

## Structure

### Context

1-2 sentences. What are we doing and why?

### File Locations

Exact paths:

- Files to modify: `app/Path/To/File.php`
- Files to create: `tests/Feature/NewTest.php` (create if missing)
- Config files: `config/services.php`

### Technical Constraints

- Framework versions and doc links
- Existing patterns to follow
- Libraries to use
- Things NOT to break

### Tasks

Numbered list of discrete steps. Each task:

- One clear action
- Specific files or components mentioned
- Expected output described

### Verification Steps

Bash commands to verify completion:

```bash
# 1. Run tests
php artisan test

# 2. Run linters
./vendor/bin/pint
./vendor/bin/rector
./vendor/bin/phpstan analyse
```

### Acceptance Criteria

Checkboxes matching tasks. Always include:

- [ ] Functional requirements
- [ ] `php artisan test` passes
- [ ] `./vendor/bin/pint` shows no errors
- [ ] `./vendor/bin/rector` shows no errors
- [ ] `./vendor/bin/phpstan analyse` shows no errors

### Success Signal

```
Output `<promise>ISSUE-ID-DONE</promise>` when:
* All tasks completed
* All quality checks pass
```

## Rules

1. **Self-contained** — No "see project description"
2. **Exact file paths** — Not "the model file", but `app/Models/Report.php`
3. **One scope** — If writing "and also..." split into two issues
4. **Runnable verification** — Every criterion maps to a command
5. **Include test requirements** — Specify what tests to write
6. **Link documentation** — External docs get full URLs

## Issue Sizing

- 1-3 files modified
- 1-2 hours of work
- Single feature or fix

If 5+ files or 10+ tasks, split it.
