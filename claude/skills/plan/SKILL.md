---
name: plan
description: Turns ideas into Linear projects with AI-ready issues. Spawns parallel agents to explore codebase and Pencil designs, writes a PRD, and creates the full issue breakdown in Linear.
disable-model-invocation: true
argument-hint: "<idea or brainstorm output> [--design=<pencil-file.pen>]"
---

You are the **team leader** for a planning session. Your job is to turn an idea into a structured Linear project with AI-ready issues. You do this by spawning read-only agents to explore the codebase (and optionally Pencil designs), synthesizing a PRD, and creating everything in Linear via the CLI.

## Argument parsing

Parse `$ARGUMENTS`:
- Extract the idea/description (everything except flags)
- If `--design=<path>` is present, extract the Pencil file path
- If the idea is too vague (fewer than 10 words and no clear feature described), ask clarifying questions using `AskUserQuestion` before proceeding

## Constants

- Linear team: `DOTO`

## Step 1 — Preflight

Verify Linear CLI is authenticated:

```bash
linear auth whoami
```

If it fails, report the error and **stop**.

If `--design=` was provided, verify the Pencil file exists by calling `mcp__pencil__get_guidelines` with `topic: "design-system"`. If the MCP call fails, report "Pencil MCP is not available" and **stop**.

## Step 2 — Create team

```
TeamCreate: team_name="plan-team", description="Planning session"
```

## Step 3 — Create tasks & spawn teammates

Create tasks and spawn **read-only** teammates in parallel. No `isolation: worktree` — these agents don't modify code.

### Codebase explorer (always spawned)

```
TaskCreate:
  subject: "Explore codebase for planning context"
  description: "Explore the codebase architecture, patterns, models, routes, and schema relevant to the idea. Report: relevant files, existing patterns, DB context, technical constraints, estimated complexity."
  activeForm: "Exploring codebase"
```

```
Task:
  name: "codebase-explorer"
  subagent_type: general-purpose
  model: sonnet
  mode: bypassPermissions
  team_name: "plan-team"
  prompt: |
    You are a **codebase explorer**. Your job is to investigate the codebase and report findings relevant to a feature idea. You are READ-ONLY — do not modify any files.

    ## The idea

    <IDEA_TEXT>

    ## What to investigate

    1. Read `CLAUDE.md` in the repo root for project conventions.
    2. Use `mcp__laravel-boost__database-schema` (summary first, then filtered detail) to understand relevant tables.
    3. Use Grep and Glob to find related models, controllers, routes, services, and components.
    4. Read key files to understand existing patterns.
    5. Use `mcp__laravel-boost__list-routes` to find related API/web routes.
    6. Check for existing tests that cover related functionality.

    ## Your report

    Send a message back to the leader with a structured report:

    ### Relevant Files
    - Exact file paths grouped by type (models, controllers, services, views, tests)

    ### Existing Patterns
    - How similar features are implemented in this codebase
    - Naming conventions, directory structure

    ### Database Context
    - Relevant tables and their columns
    - Existing relationships that matter

    ### Technical Constraints
    - Framework versions or package limitations
    - Existing architecture to preserve
    - Integration points

    ### Estimated Complexity
    - Small (1-3 files), Medium (4-8 files), or Large (9+ files)
    - Key unknowns or risks

    ## Safety rules

    - **Never** modify any source code files
    - **Never** create branches or PRs
    - Read-only exploration only
```

Assign the task: `TaskUpdate` with `owner: "codebase-explorer"` and `status: "in_progress"`.

### Design reader (only if `--design=` provided)

```
TaskCreate:
  subject: "Read Pencil design for planning context"
  description: "Read the Pencil design file and report: screens, user flows, UI components, data fields, interactive states."
  activeForm: "Reading Pencil design"
```

```
Task:
  name: "design-reader"
  subagent_type: general-purpose
  model: sonnet
  mode: bypassPermissions
  team_name: "plan-team"
  prompt: |
    You are a **design reader**. Your job is to analyze a Pencil design file and report findings relevant to a feature idea. You are READ-ONLY — do not modify any files.

    ## The idea

    <IDEA_TEXT>

    ## The design file

    <DESIGN_FILE_PATH>

    ## How to read the design

    1. Call `mcp__pencil__get_guidelines` with topic "design-system" to understand design rules.
    2. Call `mcp__pencil__batch_get` with `filePath: "<DESIGN_FILE_PATH>"` and no patterns to get top-level frames.
    3. For each relevant screen/frame, call `mcp__pencil__batch_get` with the frame's nodeId to read its children (use `readDepth: 3`).
    4. Call `mcp__pencil__get_screenshot` for each screen to visually verify the layout.
    5. Call `mcp__pencil__get_variables` to understand design tokens.
    6. Call `mcp__pencil__search_all_unique_properties` to catalog typography, colors, and spacing.

    ## Your report

    Send a message back to the leader with a structured report:

    ### Screens
    - List each screen/frame with its name and purpose

    ### User Flows
    - How users navigate between screens
    - Entry points and exit points

    ### UI Components
    - Components used (buttons, forms, tables, cards, etc.)
    - Interactive states (hover, active, disabled, loading)

    ### Data Fields
    - Input fields and their types
    - Display fields and their data sources

    ### Design Tokens
    - Colors, typography, spacing specific to this design

    ## Safety rules

    - **Never** modify any design files
    - **Never** modify any source code files
    - Read-only analysis only
```

Assign the task: `TaskUpdate` with `owner: "design-reader"` and `status: "in_progress"`.

## Step 4 — Wait for reports

Do **not** intervene unless a teammate explicitly asks for help. Let them work autonomously. You will be notified when each teammate finishes or goes idle.

When a teammate reports completion, mark their task as `completed`.

## Step 5 — Write PRD

Once all teammates have reported, synthesize all inputs (idea + codebase report + design report if available) into a PRD following the `linear-project` format:

### PRD Structure

```markdown
## Context

2-3 sentences explaining WHY this project exists. What problem are we solving?

## Goals

1. Concrete outcome 1
2. Concrete outcome 2
3. Concrete outcome 3
(3-5 goals max)

## Technical Constraints

- Existing architecture to preserve (from codebase explorer)
- Tech stack specifics
- Integration points
- Data sources

## File Locations

- `path/to/file.php` — what it does
- `path/to/folder/` — what lives there
(exact paths from codebase explorer)

## Requirements

Detailed breakdown by feature area. If design was provided, organize by screen/flow. Use tables for structured data (fields, endpoints, components). Include:
- Field names, types, constraints
- Data sources and calculations
- UI components and their behavior

## Acceptance Criteria

- [ ] Specific, testable statement
- [ ] Another specific outcome
(checkboxes, one per verifiable outcome)

## Out of Scope

- Explicit list of what this project does NOT include
```

### PRD Rules

1. **Be specific** — reference real file paths, table names, column types
2. **300-600 words** — concise but complete
3. **Describe WHAT, not HOW** — issues handle the how
4. **Include data shapes** — tables, JSON structures, database columns

## Step 6 — Present PRD for approval

Show the PRD to the user via `AskUserQuestion`:

- **Create** — Proceed to create the Linear project and issues
- **Adjust** — Let me refine the PRD (ask what to change)
- **Cancel** — Stop without creating anything

If the user chooses **Adjust**, update the PRD based on feedback and present again. If **Cancel**, clean up the team and stop.

## Step 7 — Create Linear project

Write the PRD to a temp file and create the project:

```bash
cat > /tmp/prd.md <<'EOF'
<PRD content>
EOF

linear project create --name "<project title>" --team DOTO --lead @me --status planned --description-file /tmp/prd.md --no-interactive
```

Capture the project name from the output.

## Step 8 — Break PRD into issues

Decompose the PRD into AI-ready issues following the `linear-issue` format. Each issue must be:

- **Self-contained** — no "see project description"
- **1-3 files** modified, single scope
- **Includes**: Context, File Locations, Technical Constraints, Tasks (numbered), Verification Steps, Acceptance Criteria (checkboxes), Success Signal

Order by dependency:
1. Migrations and models first
2. Backend logic (services, controllers, routes)
3. Frontend (pages, components)
4. Tests and integration

**Cap at 12 issues maximum.** If more are needed, note "Phase 2" items in the PRD's Out of Scope section.

### Issue template

```markdown
## Context

1-2 sentences. What are we doing and why?

## File Locations

- Files to modify: `app/Path/To/File.php`
- Files to create: `tests/Feature/NewTest.php`

## Technical Constraints

- Existing patterns to follow
- Libraries to use

## Tasks

1. First discrete step
2. Second discrete step
3. ...

## Verification Steps

```bash
php artisan test --compact --filter=RelevantTest
vendor/bin/pint --dirty --format agent
```

## Acceptance Criteria

- [ ] Functional requirement
- [ ] `php artisan test` passes
- [ ] `./vendor/bin/pint` shows no errors

## Success Signal

```
Output `<promise>ISSUE-ID-DONE</promise>` when:
* All tasks completed
* All quality checks pass
```
```

## Step 9 — Create issues in Linear

For each issue, write to a temp file and create:

```bash
cat > /tmp/issue-N.md <<'EOF'
<issue body>
EOF

linear issue create --title "<issue title>" --team DOTO --description-file /tmp/issue-N.md --project "<project name>" --no-interactive
```

Capture each issue ID from the output.

## Step 10 — Output summary & cleanup

Output a summary table:

```
| # | Issue ID | Title | Dependencies |
|---|----------|-------|--------------|
| 1 | DOTO-XXX | Create migration and model | — |
| 2 | DOTO-XXX | Add API endpoint | DOTO-XXX |
| ... | ... | ... | ... |
```

Then clean up:

1. Send `shutdown_request` to each teammate
2. After all teammates have shut down, call `TeamDelete`

End with:

**Next steps**: Run `/implement-team linear-issue-ids=<comma-separated IDs>`

## Safety Rules

- **Never** modify source code files
- **Never** create branches or PRs
- **Never** close or archive Linear issues or projects
- Planning-only: create projects and issues, nothing more
