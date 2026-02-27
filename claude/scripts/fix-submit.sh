#!/usr/bin/env bash
set -euo pipefail

# Push branch, create PR, link Sentry/Linear/PR, cleanup worktree.
# Usage: fix-submit.sh <LINEAR_ID> <SENTRY_ID>

SESSION_FILE="/tmp/fixer-session.json"

LINEAR_ID="${1:?Usage: fix-submit.sh <LINEAR_ID> <SENTRY_ID>}"
SENTRY_ID="${2:?Usage: fix-submit.sh <LINEAR_ID> <SENTRY_ID>}"

if [ ! -f "$SESSION_FILE" ]; then
  echo "Error: session file not found — run fix-preflight.sh first" >&2
  exit 1
fi

REPO=$(jq -r '.repo' "$SESSION_FILE")
LINEAR_TEAM=$(jq -r '.linear_team' "$SESSION_FILE")

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository" >&2
  exit 1
}

WORKTREE_DIR="$REPO_ROOT/.claude/worktrees/fix-$LINEAR_ID"
BRANCH_NAME="fix/$LINEAR_ID"

if [ ! -d "$WORKTREE_DIR" ]; then
  echo "Error: worktree not found at $WORKTREE_DIR" >&2
  exit 1
fi

# Get Sentry issue info for PR body
SENTRY_SHORT_ID=""
SENTRY_PERMALINK=""
SENTRY_COUNT=""
SENTRY_FIRST=""
SENTRY_LAST=""

SENTRY_INFO=$(sentry api "issues/$SENTRY_ID/" 2>/dev/null) || true
if [ -n "$SENTRY_INFO" ]; then
  SENTRY_SHORT_ID=$(echo "$SENTRY_INFO" | jq -r '.shortId // empty')
  SENTRY_PERMALINK=$(echo "$SENTRY_INFO" | jq -r '.permalink // empty')
  SENTRY_COUNT=$(echo "$SENTRY_INFO" | jq -r '.count // empty')
  SENTRY_FIRST=$(echo "$SENTRY_INFO" | jq -r '.firstSeen // empty')
  SENTRY_LAST=$(echo "$SENTRY_INFO" | jq -r '.lastSeen // empty')
fi

# Get Linear issue URL
LINEAR_URL=""
LINEAR_FIND=$(bash "$(dirname "$0")/fix-linear.sh" find "$SENTRY_SHORT_ID" 2>/dev/null) || true
if [ -n "$LINEAR_FIND" ]; then
  LINEAR_URL=$(echo "$LINEAR_FIND" | jq -r '.url // empty')
fi

# Read commit messages from the branch for PR context
DEFAULT_BRANCH=$(jq -r '.git_default_branch' "$SESSION_FILE")
COMMITS=$(git -C "$WORKTREE_DIR" log --oneline "$DEFAULT_BRANCH..$BRANCH_NAME" 2>/dev/null || echo "")

# PR title from latest commit
PR_TITLE=$(git -C "$WORKTREE_DIR" log -1 --format='%s' 2>/dev/null || echo "fix($LINEAR_ID): bug fix")

# Push
git -C "$WORKTREE_DIR" push -u origin "$BRANCH_NAME" 2>&1 || {
  echo "Error: failed to push branch $BRANCH_NAME" >&2
  exit 1
}

# Build PR body
PR_BODY="## Linear Issue
[$LINEAR_ID](${LINEAR_URL:-https://linear.app})

## Sentry Issue
[${SENTRY_SHORT_ID:-$SENTRY_ID}](${SENTRY_PERMALINK:-https://sentry.io})
- Events: ${SENTRY_COUNT:-unknown}
- First seen: ${SENTRY_FIRST:-unknown}
- Last seen: ${SENTRY_LAST:-unknown}

## Changes
${COMMITS:-No commit messages found}

---
*Automated fix by Fixer Agent*"

# Create PR
PR_URL=$(gh pr create \
  --repo "$REPO" \
  --head "$BRANCH_NAME" \
  --base "$DEFAULT_BRANCH" \
  --title "$PR_TITLE" \
  --body "$PR_BODY" 2>&1) || {
  echo "Error: failed to create PR" >&2
  echo "$PR_URL" >&2
  exit 1
}

# Try to comment on Sentry issue with PR link (best-effort)
sentry api "issues/$SENTRY_ID/comments/" -X POST -F text="Fix PR: $PR_URL" 2>/dev/null || true

# Move Linear issue to "In Progress"
linear issue start "$LINEAR_ID" 2>/dev/null || true

# Cleanup worktree
bash "$(dirname "$0")/fix-worktree.sh" remove "$LINEAR_ID" 2>/dev/null || true

echo "$PR_URL"
