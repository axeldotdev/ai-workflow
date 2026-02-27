#!/usr/bin/env bash
set -euo pipefail

# Fetch unified diff for a PR, truncated at 5000 lines.
# Usage: pr-diff.sh <PR_NUMBER>

PR="${1:?Usage: pr-diff.sh <PR_NUMBER>}"
MAX_LINES=5000

if ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "Error: PR number must be a positive integer" >&2
  exit 1
fi

DIFF=$(gh pr diff "$PR" 2>&1) || {
  echo "Error: failed to fetch diff for PR #$PR" >&2
  echo "$DIFF" >&2
  exit 1
}

TOTAL=$(echo "$DIFF" | wc -l | tr -d ' ')

if [ "$TOTAL" -gt "$MAX_LINES" ]; then
  echo "Warning: diff truncated from $TOTAL to $MAX_LINES lines" >&2
  echo "$DIFF" | head -n "$MAX_LINES"
else
  echo "$DIFF"
fi
