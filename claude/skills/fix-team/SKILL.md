---
name: fix-team
description: Parallel Sentry bug fixing with an agent team. Triages unresolved issues, spawns fixer agents in worktrees, produces PRs.
disable-model-invocation: true
argument-hint: "[max-issues=5]"
---

You are the **team leader** for a parallel Sentry bug-fixing session. Your job is to triage unresolved Sentry issues, then spawn one fixer teammate per actionable bug (up to **$ARGUMENTS** issues, default **5**).

## Constants

- Sentry org: `dotworld-sarl-zv`
- Sentry project: `carjudge-api`
- Linear team: `DOTO`
- Linear title format: `fix: {error_type} in {location} ({sentry_id})`
- GitHub repo: `mus-inn/carjudge-api`

## Step 1 — Preflight

Verify all CLIs are authenticated by running these in parallel:

```bash
sentry auth status
linear auth whoami
gh auth status
```

If any fails, report the error and **stop**.

## Step 2 — List unresolved issues

```bash
sentry issue list dotworld-sarl-zv/carjudge-api --query "is:unresolved" --sort freq --limit 25 --json
```

If empty, report "No unresolved Sentry issues" and **stop**.

## Step 3 — Triage

For each issue, classify using **metadata only** (title, filename, function, type). Do NOT read source code.

**Actionable** (assign to a fixer):
- `filename` starts with `app/`, `routes/`, `resources/`, or other Laravel source paths
- Error type indicates application logic (TypeError, ValueError, BadMethodCallException, etc.)

**Not our code** (archive):
- `vendor/`, `node_modules/`, framework internals in filename
- Infrastructure errors: cURL timeouts, DB connection refused, Redis connection errors, DNS failures
- Third-party SDK or library errors

**Skip** (note in summary):
- No filename or stacktrace — cannot classify

Archive "not our code" issues immediately:

```bash
sentry api /issues/<ID>/ --method PUT --field status=ignored
```

Select up to **$ARGUMENTS** (default **5**) actionable issues. If fewer are actionable, use what's available.

## Step 4 — Create team

```
TeamCreate: team_name="fix-team", description="Parallel Sentry bug fixing"
```

## Step 5 — Create tasks

For each actionable issue, create a task:

```
TaskCreate:
  subject: "Fix <SHORT_ID>: <title>"
  description: "Sentry issue ID: <NUMERIC_ID>\nShort ID: <SHORT_ID>\nError: <TITLE>\nFile: <FILENAME>\nFunction: <FUNCTION>\nEvents: <COUNT>"
  activeForm: "Fixing <SHORT_ID>"
```

## Step 6 — Spawn teammates

For each task, spawn one teammate. The full fixer workflow is inlined in the prompt:

```
Task:
  name: "fixer-<SHORT_ID>"
  subagent_type: general-purpose
  model: sonnet
  mode: bypassPermissions
  team_name: "fix-team"
  isolation: worktree
  prompt: |
    You are a **fixer agent**. Your job is to fix a single Sentry bug in an isolated worktree, create a PR, and link it to Sentry and Linear.

    ## Your assignment

    Sentry issue numeric ID: <NUMERIC_ID>
    Sentry short ID: <SHORT_ID>
    Sentry org: dotworld-sarl-zv
    Sentry project: carjudge-api
    Linear team: DOTO
    GitHub repo: mus-inn/carjudge-api

    ## Step 1 — Fetch the full issue

    ```bash
    sentry issue view <NUMERIC_ID> --json
    ```

    Read the stacktrace carefully. Identify the root-cause file(s) and line(s).

    ## Step 2 — Find or create Linear issue

    Search for an existing Linear issue:

    ```bash
    linear issue list --team DOTO --query "<SHORT_ID>"
    ```

    If no match, create one using the title format `fix: {error_type} in {location} ({sentry_id})`:

    ```bash
    linear issue create --team DOTO --title "<FORMATTED_TITLE>" --description "Sentry: https://sentry.io/organizations/dotworld-sarl-zv/issues/<NUMERIC_ID>/" --no-interaction
    ```

    Capture the Linear issue ID (e.g., `DOTO-123`).

    ## Step 3 — Understand the bug

    Read the stacktrace files in full. Understand the root cause before writing any code.

    ## Step 4 — Create branch and fix

    ```bash
    git checkout -B fix/<LINEAR_ID>
    ```

    Apply the **minimal fix** — fix the bug, nothing more. Do not refactor, add comments, or improve surrounding code.

    ## Step 5 — Format and test

    ```bash
    vendor/bin/pint --dirty --format agent
    php artisan test --compact --filter=<RelevantTestClass>
    ```

    If tests fail, investigate and fix. If you cannot make tests pass after 2 attempts, report the failure to the leader.

    ## Step 6 — Commit, push, and create PR

    Stage only the specific files you changed. Do **not** use `git add -A` or `git add .` — list each file explicitly.

    ```bash
    git add <only the files you modified>
    git commit -m "$(cat <<'EOF'
    fix(<LINEAR_ID>): <short description of the fix>

    Resolves <SHORT_ID>

    Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
    EOF
    )"
    git push -u origin fix/<LINEAR_ID>
    ```

    Create the PR:

    ```bash
    gh pr create --title "fix(<LINEAR_ID>): <short title>" --reviewer mus-inn/carjudge --body "$(cat <<'EOF'
    ## Résumé
    - Corrige l'issue Sentry <SHORT_ID>
    - <1-2 phrases décrivant la cause et le correctif>

    ## Linear
    Closes <LINEAR_ID>

    ## Plan de test
    - [ ] Les tests existants passent
    - [ ] Le correctif correspond à la stacktrace

    🤖 Generated with [Claude Code](https://claude.com/claude-code)
    EOF
    )"
    ```

    ## Step 7 — Link Sentry issue

    Post a comment on the Sentry issue linking to the PR:

    ```bash
    sentry api /issues/<NUMERIC_ID>/comments/ -X POST -F text="Fix PR: <PR_URL>"
    ```

    ## Step 8 — Move Linear issue to Review Tech

    ```bash
    linear issue update <LINEAR_ID> --state "Review Tech"
    ```

    ## Step 9 — Report result

    Send a message back to the leader with:
    - Sentry ID and error
    - What the root cause was
    - What was fixed
    - PR URL (or failure reason)
    - Linear issue ID

    ## Safety rules

    - **Never** merge any PR
    - **Never** force push
    - **Never** push to main/master directly
    - **Never** resolve, ignore, or change the status of a Sentry issue — issues are resolved manually after review and deploy
    - **Minimal fixes only** — fix the bug, nothing more
```

Assign the task to the teammate via `TaskUpdate` with `owner: "fixer-<SHORT_ID>"` and `status: "in_progress"`.

## Step 7 — Wait

Do **not** intervene unless a teammate explicitly asks for help. Let them work autonomously. You will be notified when each teammate finishes or goes idle.

When a teammate reports completion, mark their task as `completed`.

## Step 8 — Synthesize

Once all teammates have finished, output a summary table:

```
| Sentry ID | Error | Result |
|-----------|-------|--------|
| CARJUDGE-API-81 | TypeError in CarAdController | PR #1080 (DOTO-45) |
| CARJUDGE-API-79 | cURL timeout in HandleHistoryService | Archived (infra) |
| CARJUDGE-API-75 | BadMethodCallException in VinDecoder | Fixed but tests failed |
| CARJUDGE-API-70 | Redis connection refused | Archived (infra) |
| CARJUDGE-API-68 | Unknown error | Skipped (no filename) |
```

## Step 9 — Cleanup

1. Send `shutdown_request` to each teammate
2. After all teammates have shut down, call `TeamDelete`

## Safety Rules

- **Never** merge any PR
- **Never** force push
- **Never** push to main/master directly
- **Never** resolve Sentry issues that fixers worked on (issues are resolved manually after review and deploy)
- **Never** close Linear issues
- **Minimal fixes only** — fix the bug, nothing more
