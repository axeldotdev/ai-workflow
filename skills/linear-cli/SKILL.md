---
name: linear-cli
description: Guide for using the Linear CLI to interact with Linear from the command line. Use when the user asks about listing, creating, starting, or managing Linear issues, teams, projects, milestones, initiatives, labels, or documents via CLI.
---

# Linear CLI Usage Guide

Help users interact with Linear from the command line using the `linear` CLI (v1.10.0).

## Related Skills

- **linear** - Use MCP tools for programmatic Linear access (fetch issue details, update status)
- **linear-issue** - Write Linear issues optimized for Claude Code
- **linear-project** - Write PRDs for Linear projects
- **github** - GitHub CLI for PRs, issues, and repo operations
- **git-workflow** - Use `./ship` and `./pr` for git workflow automation

## When to Use What

### Use `linear api` for:

- **Preferred approach for querying/retrieving data** — request exactly the fields you need
- Fetching issues, projects, milestones, or any Linear data with custom field selection
- Complex filtering and querying that CLI subcommands don't support
- Getting raw JSON for further processing or scripting
- Accessing any part of the Linear GraphQL schema

### Use `linear` CLI subcommands for:

- Starting work on an issue (creates branch + sets status)
- Creating issues with full details (title, description, labels, priority)
- Creating GitHub PRs linked to Linear issues
- Managing documents, labels, initiatives
- Quick lookups without leaving the terminal

### Use Linear MCP tools for:

- Fetching issue details programmatically within a workflow
- Updating issue status as part of an automated process
- Searching/filtering issues with complex criteria
- Adding comments programmatically

## CarJudge Context

- **Organization**: dotworld-sarl
- **Team prefix**: `DOTO`
- **Configuration**: Run `linear config` to generate `.linear.toml` with your team ID

## Prerequisites

### Installation

```bash
# Install via Homebrew
brew install schpet/tap/linear-cli

# Or install via cargo
cargo install linear-cli
```

### Authentication

```bash
# Login (opens browser for OAuth)
linear auth login

# Check who you're logged in as
linear auth whoami

# List configured workspaces
linear auth list

# Set default workspace
linear auth default <workspace-slug>

# Logout
linear auth logout
```

## Configuration

Run `linear config` to interactively generate a `.linear.toml` file in your project root. This sets the default team for commands.

Environment variables:
- `LINEAR_DEBUG=1` - Show full error details including stack traces

## Available Commands

### Issue

#### `linear issue list`

List your issues (defaults to unstarted issues assigned to you).

**Flags:**
- `-s, --state <state>` - Filter by state: `triage`, `backlog`, `unstarted`, `started`, `completed`, `canceled` (repeatable)
- `--all-states` - Show issues from all states
- `--assignee <username>` - Filter by assignee
- `-A, --all-assignees` - Show issues for all assignees
- `-U, --unassigned` - Show only unassigned issues
- `--team <team>` - Team to list issues for
- `--project <project>` - Filter by project name
- `--sort <sort>` - Sort by: `manual`, `priority`
- `--limit <limit>` - Max issues to fetch (default: 50, 0 for unlimited)
- `-w, --web` - Open in browser
- `--no-pager` - Disable paging

**Examples:**

```bash
# List your unstarted issues
linear issue list

# List started issues
linear issue list -s started

# List all states for all assignees
linear issue list --all-states -A

# List issues for a specific project
linear issue list --project "My Project"
```

#### `linear issue view [issueId]`

View issue details. Defaults to current branch's issue.

**Flags:**
- `-w, --web` - Open in browser
- `-a, --app` - Open in Linear.app
- `-j, --json` - Output as JSON
- `--no-comments` - Exclude comments
- `--no-download` - Keep remote URLs instead of downloading files
- `--no-pager` - Disable paging

**Examples:**

```bash
# View current branch's issue
linear issue view

# View by issue ID
linear issue view DOTO-123

# Open in browser
linear issue view DOTO-123 -w

# JSON output
linear issue view DOTO-123 --json
```

#### `linear issue create`

Create a new issue.

**Flags:**
- `-t, --title <title>` - Title
- `-d, --description <description>` - Description
- `--description-file <path>` - Read description from file (preferred for markdown)
- `-a, --assignee <assignee>` - Assign to `self` or username
- `-l, --label <label>` - Label (repeatable)
- `-s, --state <state>` - Workflow state
- `-p, --parent <parent>` - Parent issue (e.g., `DOTO-100`)
- `--priority <1-4>` - Priority (1=urgent, 4=low)
- `--estimate <points>` - Points estimate
- `--due-date <date>` - Due date
- `--team <team>` - Team (if not default)
- `--project <project>` - Project name
- `--start` - Start the issue after creation
- `--no-interactive` - Disable interactive prompts

**Examples:**

```bash
# Interactive creation
linear issue create

# Non-interactive with all details
linear issue create \
  -t "Add rate limiting to API" \
  -d "Implement rate limiting middleware" \
  -a self \
  -l "Feature" \
  --priority 2 \
  --no-interactive

# With description from file
linear issue create \
  -t "Refactor payment flow" \
  --description-file ./issue-description.md \
  --start
```

#### `linear issue start [issueId]`

Start working on an issue: assigns to you, sets status to "In Progress", creates a git branch.

**Flags:**
- `-f, --from-ref <ref>` - Git ref to create branch from
- `-b, --branch <name>` - Custom branch name
- `-A, --all-assignees` - Show issues for all assignees
- `-U, --unassigned` - Show only unassigned issues

**Examples:**

```bash
# Interactive: pick from your unstarted issues
linear issue start

# Start a specific issue
linear issue start DOTO-123

# Start from a specific branch
linear issue start DOTO-123 --from-ref main

# Use a custom branch name
linear issue start DOTO-123 --branch feat/my-feature
```

#### `linear issue update [issueId]`

Update an existing issue.

**Flags:**
- `-t, --title <title>` - Title
- `-d, --description <description>` - Description
- `--description-file <path>` - Read description from file
- `-a, --assignee <assignee>` - Assignee
- `-l, --label <label>` - Label (repeatable)
- `-s, --state <state>` - Workflow state
- `-p, --parent <parent>` - Parent issue
- `--priority <1-4>` - Priority
- `--estimate <points>` - Points estimate
- `--due-date <date>` - Due date
- `--team <team>` - Team
- `--project <project>` - Project

**Examples:**

```bash
# Update current branch's issue state
linear issue update -s "Done"

# Update a specific issue
linear issue update DOTO-123 -s "In Review" -a someone
```

#### `linear issue delete [issueId]`

Delete an issue.

**Flags:**
- `-y, --confirm` - Skip confirmation
- `--bulk <ids...>` - Delete multiple issues (e.g., `DOTO-123 DOTO-124`)
- `--bulk-file <file>` - Read issue IDs from file
- `--bulk-stdin` - Read issue IDs from stdin

#### `linear issue pr [issueId]`

Create a GitHub pull request linked to the Linear issue.

**Flags:**
- `--base <branch>` - Target branch for merge
- `--head <branch>` - Source branch
- `--draft` - Create as draft PR
- `-t, --title <title>` - PR title (issue ID auto-prefixed)
- `--web` - Open PR in browser after creation

**Examples:**

```bash
# Create PR for current branch's issue
linear issue pr

# Create draft PR with custom base
linear issue pr DOTO-123 --draft --base main

# Create and open in browser
linear issue pr --web
```

#### `linear issue comment`

Manage issue comments.

```bash
# Add a comment
linear issue comment add DOTO-123

# List comments
linear issue comment list DOTO-123

# Update a comment
linear issue comment update <commentId>
```

#### `linear issue id`

Print the issue ID based on the current git branch.

```bash
linear issue id
```

#### `linear issue url [issueId]`

Print the issue URL.

```bash
linear issue url DOTO-123
```

#### `linear issue title [issueId]`

Print the issue title.

```bash
linear issue title DOTO-123
```

#### `linear issue attach <issueId> <filepath>`

Attach a file to an issue.

**Flags:**
- `-t, --title <title>` - Custom attachment title
- `-c, --comment <body>` - Add a comment linked to the attachment

#### `linear issue relation`

Manage issue relations (dependencies).

```bash
# Add a relation
linear issue relation add DOTO-123 blocks DOTO-456

# List relations
linear issue relation list DOTO-123

# Delete a relation
linear issue relation delete DOTO-123 blocks DOTO-456
```

### Team

```bash
# List teams
linear team list

# Get configured team ID
linear team id

# List team members
linear team members
linear team members DOTO

# Create a team
linear team create

# Delete a team
linear team delete DOTO

# Set up GitHub autolinks for Linear issues
linear team autolinks
```

### Project

```bash
# List projects
linear project list

# View project details
linear project view <projectId>

# Create a new project
linear project create
```

### Project Updates

```bash
# List status updates for a project
linear project-update list <projectId>

# Create a status update
linear project-update create <projectId>
```

### Milestone

```bash
# List milestones for a project
linear milestone list

# View milestone details
linear milestone view <milestoneId>

# Create a milestone
linear milestone create

# Update a milestone
linear milestone update <id>

# Delete a milestone
linear milestone delete <id>
```

### Initiative

```bash
# List initiatives
linear initiative list

# View initiative details
linear initiative view <initiativeId>

# Create an initiative
linear initiative create

# Update an initiative
linear initiative update <initiativeId>

# Archive / unarchive
linear initiative archive <initiativeId>
linear initiative unarchive <initiativeId>

# Link/unlink projects
linear initiative add-project <initiative> <project>
linear initiative remove-project <initiative> <project>

# Delete an initiative
linear initiative delete <initiativeId>
```

### Label

```bash
# List issue labels
linear label list

# Create a label
linear label create

# Delete a label
linear label delete <nameOrId>
```

### Document

```bash
# List documents
linear document list

# View a document
linear document view <id>

# Create a document
linear document create

# Update a document
linear document update <documentId>

# Delete a document (moves to trash)
linear document delete <documentId>
```

### Config & Auth

```bash
# Generate .linear.toml configuration
linear config

# Auth commands (see Prerequisites above)
linear auth login
linear auth logout
linear auth list
linear auth default <workspace>
linear auth whoami
linear auth token

# Generate shell completions
linear completions

# Print GraphQL schema
linear schema
```

### API (Raw GraphQL)

Make raw GraphQL requests to the Linear API.

**Flags:**
- `--variable <key=value>` - Variable (repeatable)
- `--variables-json <json>` - JSON object of variables
- `--paginate` - Auto-paginate cursor-based results
- `--silent` - Suppress response output

**Examples:**

```bash
# Run a GraphQL query
linear api '{ viewer { id name email } }'

# Query with variables
linear api '{ issue(id: $id) { title state { name } } }' --variable id=DOTO-123

# Paginate through results
linear api '{ issues { nodes { id title } } }' --paginate
```

## Workflow Examples

### Starting Work on a Linear Issue

```bash
# 1. List your unstarted issues
linear issue list

# 2. Start the issue (assigns, sets "In Progress", creates branch)
linear issue start DOTO-123

# 3. Do your work...

# 4. Create a PR linked to the issue
linear issue pr

# 5. Or use ./ship for the full workflow
./ship feat DOTO-123 "Add rate limiting"
```

### Quick Issue Lookup from Current Branch

```bash
# View the issue for your current branch
linear issue view

# Get just the issue ID
linear issue id

# Get just the title
linear issue title

# Open in browser
linear issue view -w
```

## Global Flags

All commands support:
- `-h, --help` - Show help
- `-V, --version` - Show version
- `-w, --workspace <slug>` - Target a specific workspace
