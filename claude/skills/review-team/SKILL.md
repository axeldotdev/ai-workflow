---
name: review-team
description: Parallel PR code review with an agent team. Lists reviewable PRs, spawns deep reviewer agents, posts findings.
disable-model-invocation: true
argument-hint: "[max-prs=5]"
---

You are the **team leader** for a parallel PR review session. Your job is to identify reviewable PRs, then spawn one reviewer teammate per PR (up to **$ARGUMENTS** PRs, default **5**).

## Step 1 — List reviewable PRs

```bash
gh pr list --state open --json number,title,author,isDraft,statusCheckRollup,additions,deletions,changedFiles,baseRefName --limit 20
```

If empty, report "No PRs ready for review" and **stop**.

## Step 2 — Filter PRs

From the list, **skip** PRs that are:
- Drafts (`isDraft: true`)
- Authored by bots
- CI not passing — check `statusCheckRollup` for all checks in `SUCCESS` state. Skip PRs with `PENDING` or `FAILURE` checks.
- More than 30 changed files (`changedFiles > 30`) — too large for automated review

Select up to **$ARGUMENTS** (default **5**) qualifying PRs. If fewer qualify, use what's available.

Note skipped PRs and reasons for the summary.

## Step 3 — Create team

```
TeamCreate: team_name="review-team", description="Parallel PR code review"
```

## Step 4 — Create tasks

For each qualifying PR, create a task:

```
TaskCreate:
  subject: "Review PR #<NUMBER>: <title>"
  description: "PR number: <NUMBER>\nTitle: <TITLE>\nAuthor: <AUTHOR>\nBase: <BASE_BRANCH>\nFiles changed: <FILE_COUNT>\nAdditions: <ADDITIONS>, Deletions: <DELETIONS>"
  activeForm: "Reviewing PR #<NUMBER>"
```

## Step 5 — Spawn teammates

For each task, spawn one teammate. The full reviewer workflow is inlined in the prompt:

```
Task:
  name: "reviewer-<NUMBER>"
  subagent_type: general-purpose
  model: sonnet
  team_name: "review-team"
  isolation: worktree
  mode: bypassPermissions
  prompt: |
    You are a **code reviewer agent**. Your job is to deeply review a single PR and post a formal GitHub review with inline comments. You do NOT modify any code.

    **IMPORTANT: All GitHub review comments and the review body MUST be written in French.** Use clear, professional French for all findings, suggestions, and summaries posted to GitHub. Only your internal report to the team leader can be in English.

    ## Your assignment

    PR number: <NUMBER>
    Repository: mus-inn/carjudge-api

    ## Step 1 — Fetch the PR (NO checkout)

    Do NOT use `gh pr checkout` — it affects the main repo's branch state even in worktrees.
    Instead, fetch the PR ref and work from the commit SHA:

    ```bash
    git fetch origin pull/<NUMBER>/head
    PR_SHA=$(git rev-parse FETCH_HEAD)
    ```

    To read any file from the PR, use:
    ```bash
    git show $PR_SHA:<file_path>
    ```

    Or use the Read tool after checking out in the worktree with a detached HEAD:
    ```bash
    git checkout --detach $PR_SHA
    ```

    This is safe because the worktree is isolated and detached HEAD won't create any tracking branches.

    ## Step 1.5 — Check for existing reviews

    ```bash
    gh api repos/mus-inn/carjudge-api/pulls/<NUMBER>/reviews --jq '.[].body'
    ```

    If any review body contains "🤖" or "Generated with Claude Code", this PR was already reviewed by an agent. **Skip it** — report "Already reviewed" to the leader.

    ## Step 2 — Gather context

    Read `CLAUDE.md` in the repo root to understand project conventions.

    Get the PR metadata:

    ```bash
    gh pr view <NUMBER> --json title,body,author,files,commits,baseRefName
    ```

    Get the diff:

    ```bash
    gh pr diff <NUMBER>
    ```

    ## Step 3 — Read changed files

    For each changed file, read the **full file** to understand the complete context. For files longer than 500 lines, read only the changed sections and ~50 lines of surrounding context. Also read related files (e.g., tests, parent classes, interfaces, config) as needed.

    ## Step 4 — Analyze

    Focus your review on these categories (in priority order):

    1. **Security** — SQL injection, XSS, auth bypass, secrets in code, mass assignment
    2. **Logic bugs** — off-by-one, null handling, race conditions, incorrect conditionals
    3. **Conventions** — deviations from patterns in CLAUDE.md or sibling files
    4. **Error handling** — unhandled exceptions, missing validation, silent failures
    5. **Test coverage** — new behavior without tests, tests that don't assert correctly
    6. **Migration safety** — destructive column changes, missing data backfill, no rollback

    **Skip** anything CI already catches: formatting (Pint), type errors (Larastan), linting (ESLint).

    ## Step 5 — Build findings

    For each finding, record:
    - `path`: file path relative to repo root
    - `line`: the line number in the **new version** of the file that falls within a diff hunk. Use `gh pr diff <NUMBER>` output to verify the line is inside a `@@` range. If a line falls outside any diff hunk, omit it from `comments` and include it in the review `body` instead.
    - `side`: always `RIGHT` (we comment on new code)
    - `body`: markdown comment explaining the issue and suggesting a fix
    - `severity`: `security`, `logic`, `convention`, `suggestion`

    ## Step 6 — Determine verdict

    - **REQUEST_CHANGES**: if any finding is `security` or `logic` severity AND you are >=90% confident it's a real bug
    - **COMMENT**: for all other cases (including "looks good")

    ## Step 7 — Submit the review

    If there are findings with specific line comments, build the JSON safely with `jq` to handle escaping:

    ```bash
    # Build comments array incrementally
    COMMENTS=$(jq -n '[]')
    COMMENTS=$(echo "$COMMENTS" | jq \
      --arg path "<FILE_PATH>" \
      --argjson line <LINE> \
      --arg side "RIGHT" \
      --arg body "<COMMENT_BODY>" \
      '. += [{path: $path, line: $line, side: $side, body: $body}]')
    # ... repeat for each finding

    # Submit the review
    jq -n \
      --arg event "<VERDICT>" \
      --arg body "<SUMMARY>" \
      --argjson comments "$COMMENTS" \
      '{event: $event, body: $body, comments: $comments}' \
    | gh api repos/mus-inn/carjudge-api/pulls/<NUMBER>/reviews -X POST --input -
    ```

    If no findings (looks good):

    ```bash
    jq -n \
      --arg event "COMMENT" \
      --arg body "Reviewed — no issues found. Code looks good. 🤖" \
      '{event: $event, body: $body}' \
    | gh api repos/mus-inn/carjudge-api/pulls/<NUMBER>/reviews -X POST --input -
    ```

    **If the API returns a 422 error**, one or more comment lines are outside diff hunks. Remove the offending comments from the array, move their content into the review `body`, and retry.

    ## Step 8 — Report result

    Send a message back to the leader with:
    - PR number and title
    - Verdict (COMMENT or REQUEST_CHANGES)
    - Number of findings by severity
    - Brief summary of key findings (if any)

    ## Safety rules

    - **Never** approve any PR
    - **Never** merge any PR
    - **Never** push code or modify source files
    - **COMMENT** or **REQUEST_CHANGES** verdicts only
```

Assign the task to the teammate via `TaskUpdate` with `owner: "reviewer-<NUMBER>"` and `status: "in_progress"`.

## Step 6 — Wait

Do **not** intervene unless a teammate explicitly asks for help. Let them work autonomously. You will be notified when each teammate finishes or goes idle.

When a teammate reports completion, mark their task as `completed`.

## Step 7 — Synthesize

Once all teammates have finished, output a summary table:

```
| PR | Title | Verdict | Findings |
|----|-------|---------|----------|
| #1074 | Feature dialog redesign | COMMENT | 2 findings (1 security, 1 logic) |
| #1072 | Navbar accessibility fixes | COMMENT | 0 findings (looks good) |
| #1070 | Payment flow refactor | REQUEST_CHANGES | 3 findings (1 security, 2 conventions) |
| #1068 | Update deps | Skipped | CI pending |
```

## Step 8 — Cleanup

1. Send `shutdown_request` to each teammate
2. After all teammates have shut down, call `TeamDelete`

## Safety Rules

- **Never** approve any PR
- **Never** merge any PR
- **Never** push code or modify source files
- **COMMENT** or **REQUEST_CHANGES** verdicts only
