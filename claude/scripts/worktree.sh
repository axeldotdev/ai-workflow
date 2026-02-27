#!/usr/bin/env bash
set -euo pipefail

# Create or remove a git worktree for PR review.
# Usage: worktree.sh create|remove <PR_NUMBER>

ACTION="${1:?Usage: worktree.sh create|remove <PR_NUMBER>}"
PR="${2:?Usage: worktree.sh create|remove <PR_NUMBER>}"

if ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "Error: PR number must be a positive integer" >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository" >&2
  exit 1
}

WORKTREE_DIR="$REPO_ROOT/.claude/worktrees/review-$PR"
REF_NAME="refs/review/pr-$PR"

case "$ACTION" in
  create)
    # Clean stale worktree if it exists
    if [ -d "$WORKTREE_DIR" ]; then
      echo "Removing stale worktree at $WORKTREE_DIR" >&2
      git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || true
      git update-ref -d "$REF_NAME" 2>/dev/null || true
    fi

    # Fetch the PR head SHA
    HEAD_SHA=$(gh api "repos/{owner}/{repo}/pulls/$PR" --jq '.head.sha' 2>&1) || {
      echo "Error: failed to fetch PR #$PR head SHA" >&2
      echo "$HEAD_SHA" >&2
      exit 1
    }

    # Fetch that commit
    git fetch origin "$HEAD_SHA" --quiet 2>/dev/null || {
      echo "Error: failed to fetch commit $HEAD_SHA" >&2
      exit 1
    }

    # Create a named ref so the worktree has a stable anchor
    git update-ref "$REF_NAME" "$HEAD_SHA"

    # Create worktree in detached HEAD state
    mkdir -p "$(dirname "$WORKTREE_DIR")"
    git worktree add --detach "$WORKTREE_DIR" "$HEAD_SHA" --quiet 2>/dev/null || {
      echo "Error: failed to create worktree" >&2
      exit 1
    }

    echo "$WORKTREE_DIR"
    ;;

  remove)
    if [ -d "$WORKTREE_DIR" ]; then
      git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || true
    fi
    git update-ref -d "$REF_NAME" 2>/dev/null || true
    git worktree prune 2>/dev/null || true
    echo "Removed worktree for PR #$PR" >&2
    ;;

  *)
    echo "Error: unknown action '$ACTION'. Use 'create' or 'remove'." >&2
    exit 1
    ;;
esac
