---
name: implement-team
description: Parallel implementation with an agent team. Fetches Linear issues from "Todo", spawns implement agents in worktrees, produces PRs.
disable-model-invocation: true
argument-hint: "[linear-issue-ids=DOTO-1,DOTO-2 | max-issues=5]"
---

You are the **team leader** for a parallel implementation session. Your job is to fetch Linear issue specs, then spawn one implement teammate per actionable issue.

## Argument parsing

Parse `$ARGUMENTS`:
- If it contains comma-separated IDs (e.g., `DOTO-1,DOTO-2`): use those specific issues
- If it contains `max-issues=N`: list up to N "Todo" issues from Linear
- If empty or no args: default to `max-issues=5`

## Constants

- Linear team: `DOTO`
- GitHub repo: `mus-inn/carjudge-api`

## Step 1 — Preflight

Verify all CLIs are authenticated by running these in parallel:

```bash
linear auth whoami
gh auth status
```

If any fails, report the error and **stop**.

Capture the authenticated Linear username from `linear auth whoami` output — you'll use it to filter issues by assignee.

## Step 2 — Fetch issues

**Only fetch issues assigned to the authenticated user.**

If specific IDs were provided:

```bash
linear issue view <ID> --json
```

Verify each issue is assigned to the authenticated user. Skip any that are not — note them in the summary as "Skipped (not assigned to you)".

If using max-issues, list "Todo" issues assigned to the current user:

```bash
linear issue list --team DOTO --state "Todo" --assignee <USERNAME> --limit <MAX_ISSUES> --json
```

If no issues found, report "No Todo issues assigned to you in Linear" and **stop**.

## Step 3 — Triage

For each issue, read the description and acceptance criteria.

**Actionable** (assign to an implement agent):
- Has a clear description with enough context to implement
- Has acceptance criteria or a clear spec

**Skip** (note in summary):
- Title only, no description
- Vague or ambiguous requirements (e.g., "Improve performance")
- Blocked by other issues

Select up to the requested number of actionable issues.

## Step 4 — Create team

```
TeamCreate: team_name="implement-team", description="Parallel implementation"
```

## Step 5 — Create tasks

For each actionable issue, create a task:

```
TaskCreate:
  subject: "Implement <LINEAR_ID>: <title>"
  description: "Linear issue ID: <LINEAR_ID>\nTitle: <TITLE>\nDescription: <DESCRIPTION>\nAcceptance criteria: <CRITERIA>"
  activeForm: "Implementing <LINEAR_ID>"
```

## Step 6 — Spawn teammates

For each task, spawn one teammate. The full implement workflow is inlined in the prompt:

```
Task:
  name: "implement-<LINEAR_ID>"
  subagent_type: general-purpose
  model: sonnet
  mode: bypassPermissions
  team_name: "implement-team"
  isolation: worktree
  prompt: |
    You are an **implement agent**. Your job is to implement a single feature from a Linear issue spec in an isolated worktree, create a PR, and link it to Linear.

    ## Your assignment

    Linear issue ID: <LINEAR_ID>
    Linear team: DOTO
    GitHub repo: mus-inn/carjudge-api
    Title: <TITLE>
    Description: <DESCRIPTION>
    Acceptance criteria: <CRITERIA>

    ## Step 1 — Understand codebase context

    1. Read `CLAUDE.md` in the repo root to understand project conventions.
    2. Identify the area of the codebase affected by the feature.
    3. Read sibling files to understand existing patterns and conventions.
    4. Read related models, tests, and config files as needed.
    5. Use `search-docs` if working with Laravel ecosystem packages.

    ## Step 2 — Plan before coding

    List files to create, modify, and tests to write.

    ## Step 3 — Create branch and implement

    ```bash
    git checkout -B feat/<LINEAR_ID>
    ```

    - Use `php artisan make:` commands to create new files.
    - Follow sibling file conventions strictly.
    - Use existing components and helpers before creating new ones.

    ## Step 4 — Write tests

    ```bash
    php artisan make:test --pest <TestName>
    ```

    Use existing factories and their states. Follow sibling test conventions.

    ## Step 5 — Format and test

    ```bash
    vendor/bin/pint --dirty --format agent
    php artisan test --compact --filter=<RelevantTestClass>
    ```

    If tests fail, investigate and fix. If you cannot make tests pass after 2 attempts, report the failure to the leader.

    ## Step 6 — Commit, push, and create PR

    Stage only the specific files you changed or created. Do **not** use `git add -A` or `git add .` — list each file explicitly.

    ```bash
    git add <only the files you modified or created>
    git commit -m "$(cat <<'EOF'
    feat(<LINEAR_ID>): <short description of the feature>

    Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
    EOF
    )"
    git push -u origin feat/<LINEAR_ID>
    ```

    Create the PR:

    ```bash
    gh pr create --title "feat(<LINEAR_ID>): <short title>" --reviewer mus-inn/carjudge --body "$(cat <<'EOF'
    ## Résumé
    - Implémente <LINEAR_ID>: <titre de l'issue>
    - <1-3 phrases décrivant ce qui a été implémenté>

    ## Linear
    Closes <LINEAR_ID>

    ## Plan de test
    - [ ] Les tests unitaires/feature passent
    - [ ] La fonctionnalité correspond à la spec Linear
    - [ ] Aucune régression sur les tests existants

    🤖 Generated with [Claude Code](https://claude.com/claude-code)
    EOF
    )"
    ```

    ## Step 7 — Move Linear issue to Review Tech

    ```bash
    linear issue update <LINEAR_ID> --state "Review Tech"
    ```

    ## Step 8 — Report result

    Send a message back to the leader with:
    - Linear issue ID and title
    - What was implemented
    - Files created/modified
    - PR URL (or failure reason)

    ## Safety rules

    - **Never** merge any PR
    - **Never** force push
    - **Never** push to main/master directly
    - **Never** delete existing tests
    - **Never** close or archive Linear issues
```

Assign the task to the teammate via `TaskUpdate` with `owner: "implement-<LINEAR_ID>"` and `status: "in_progress"`.

## Step 7 — Wait

Do **not** intervene unless a teammate explicitly asks for help. Let them work autonomously. You will be notified when each teammate finishes or goes idle.

When a teammate reports completion, mark their task as `completed`.

## Step 8 — Synthesize

Once all teammates have finished, output a summary table:

```
| Linear ID | Feature | Result |
|-----------|---------|--------|
| DOTO-45 | Add payment webhook | PR #1082 |
| DOTO-46 | User profile page | PR #1083 |
| DOTO-47 | Improve search filters | Skipped (vague spec) |
| DOTO-48 | Add export endpoint | Tests failed |
```

## Step 9 — Cleanup

1. Send `shutdown_request` to each teammate
2. After all teammates have shut down, call `TeamDelete`

## Safety Rules

- **Never** merge any PR
- **Never** force push
- **Never** push to main/master directly
- **Never** delete existing tests
- **Never** close or archive Linear issues
