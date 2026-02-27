#!/usr/bin/env bash
set -euo pipefail

# Create or remove a worktree with a fix/<LINEAR_ID> branch.
# Usage: fix-worktree.sh create|remove <LINEAR_ID>

SESSION_FILE="/tmp/fixer-session.json"

ACTION="${1:?Usage: fix-worktree.sh create|remove <LINEAR_ID>}"
LINEAR_ID="${2:?Usage: fix-worktree.sh create|remove <LINEAR_ID>}"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository" >&2
  exit 1
}

WORKTREE_DIR="$REPO_ROOT/.claude/worktrees/fix-$LINEAR_ID"
BRANCH_NAME="fix/$LINEAR_ID"

case "$ACTION" in
  create)
    if [ ! -f "$SESSION_FILE" ]; then
      echo "Error: session file not found — run fix-preflight.sh first" >&2
      exit 1
    fi

    DEFAULT_BRANCH=$(jq -r '.git_default_branch' "$SESSION_FILE")

    # Clean stale worktree if exists
    if [ -d "$WORKTREE_DIR" ]; then
      echo "Removing stale worktree at $WORKTREE_DIR" >&2
      git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || true
    fi

    # Delete stale branch if exists
    git branch -D "$BRANCH_NAME" 2>/dev/null || true

    # Create worktree with a real branch off default branch
    mkdir -p "$(dirname "$WORKTREE_DIR")"
    git worktree add "$WORKTREE_DIR" -b "$BRANCH_NAME" "$DEFAULT_BRANCH" --quiet 2>/dev/null || {
      echo "Error: failed to create worktree" >&2
      exit 1
    }

    echo "$WORKTREE_DIR"
    ;;

  remove)
    if [ -d "$WORKTREE_DIR" ]; then
      git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || true
    fi
    git worktree prune 2>/dev/null || true
    echo "Removed worktree for $LINEAR_ID" >&2
    ;;

  *)
    echo "Error: unknown action '$ACTION'. Use 'create' or 'remove'." >&2
    exit 1
    ;;
esac
