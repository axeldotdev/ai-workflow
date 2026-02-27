#!/usr/bin/env bash
set -euo pipefail

# List open PRs ready for review: not draft, CI passing, not self-authored,
# not already approved by current user.
# Usage: pr-list.sh

CURRENT_USER=$(gh api user --jq '.login' 2>/dev/null) || {
  echo "Error: failed to get current GitHub user" >&2
  exit 1
}

RAW=$(gh pr list \
  --state open \
  --json number,title,author,baseRefName,changedFiles,additions,deletions,url,isDraft,reviews,statusCheckRollup \
  --limit 50 2>&1) || {
  echo "Error: failed to list PRs" >&2
  echo "$RAW" >&2
  exit 1
}

if [ -z "$RAW" ] || [ "$RAW" = "[]" ]; then
  echo '[]'
  exit 0
fi

echo "$RAW" | jq -c --arg me "$CURRENT_USER" '[
  .[]
  | select(.isDraft == false)
  | select(.author.login != $me)
  # CI must be all passing (no fail or pending buckets)
  | select(
      (.statusCheckRollup | length) > 0
      and (.statusCheckRollup | map(select(.status != "COMPLETED" or .conclusion != "SUCCESS")) | length) == 0
    )
  # Not already approved by current user
  | select(
      [.reviews[] | select(.author.login == $me and .state == "APPROVED")] | length == 0
    )
  | {
      number,
      title,
      author: .author.login,
      base: .baseRefName,
      files_changed: .changedFiles,
      additions,
      deletions,
      url
    }
]'
