---
name: audit
description: Scans code for performance issues — N+1 queries, missing indexes, expensive patterns, and duplicate queries. Produces a structured report without modifying any files.
argument-hint: "<file-or-directory-or-route> (or blank for full scan)"
---

Run a **read-only** performance audit on **$ARGUMENTS** (or the full application if blank) for `mus-inn/carjudge-api`.

## Workflow

1. **Determine scope** — If a route, resolve via `php artisan route:list --json`. If a file/directory, scan directly. If blank, scan `app/Http/Controllers/`, `app/Services/`, `app/Livewire/`, `app/Jobs/`, `app/Console/Commands/`.
2. **Schema context** — Use `database-schema` MCP tool (summary first, then filtered details with indexes for referenced tables).
3. **Scan** for 5 categories:
   - **N+1 queries** (critical) — relation access in loops without eager loading
   - **Missing eager loading** (warning) — models loaded without `->with()` for relations used downstream
   - **Missing indexes** (warning) — columns in `where()`/`orderBy()` without indexes
   - **Expensive patterns** (warning) — `Model::all()`, in-memory `count()`, unbounded `get()`
   - **Duplicate queries** (info) — same model/relation queried multiple times per request
4. **Build findings** — Each finding: severity, category, file:line, description, suggestion, confidence.
5. **Output** — Structured markdown report with summary table, findings by severity, and prioritized recommendations.

## Rules

- **Read-only** — never modify or create files
- Never run state-changing commands (no migrations, seeds, or destructive operations)
- Discard low-confidence findings unless critical severity
