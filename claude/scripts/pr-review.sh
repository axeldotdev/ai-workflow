#!/usr/bin/env bash
set -euo pipefail

# Submit a PR review via GitHub REST API.
# Usage: pr-review.sh <PR_NUMBER> <VERDICT> <FINDINGS_FILE>
#
# VERDICT: COMMENT or REQUEST_CHANGES (APPROVE is rejected)
# FINDINGS_FILE: JSON file with shape:
#   { "summary": "markdown body", "comments": [{ "path": "...", "line": N, "side": "RIGHT", "body": "..." }] }

PR="${1:?Usage: pr-review.sh <PR_NUMBER> <VERDICT> <FINDINGS_FILE>}"
VERDICT="${2:?Usage: pr-review.sh <PR_NUMBER> <VERDICT> <FINDINGS_FILE>}"
FINDINGS="${3:?Usage: pr-review.sh <PR_NUMBER> <VERDICT> <FINDINGS_FILE>}"

# Validate inputs
if ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "Error: PR number must be a positive integer" >&2
  exit 1
fi

VERDICT_UPPER=$(echo "$VERDICT" | tr '[:lower:]' '[:upper:]')
if [ "$VERDICT_UPPER" = "APPROVE" ]; then
  echo "Error: APPROVE verdict is not allowed — reviews must be COMMENT or REQUEST_CHANGES" >&2
  exit 1
fi

if [ "$VERDICT_UPPER" != "COMMENT" ] && [ "$VERDICT_UPPER" != "REQUEST_CHANGES" ]; then
  echo "Error: VERDICT must be COMMENT or REQUEST_CHANGES, got '$VERDICT'" >&2
  exit 1
fi

if [ ! -f "$FINDINGS" ]; then
  echo "Error: findings file not found: $FINDINGS" >&2
  exit 1
fi

# Validate findings JSON structure
if ! jq -e '.summary' "$FINDINGS" >/dev/null 2>&1; then
  echo "Error: findings file must contain a 'summary' field" >&2
  exit 1
fi

# Get repo info
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null) || {
  echo "Error: failed to determine repository" >&2
  exit 1
}

# Read findings
SUMMARY=$(jq -r '.summary' "$FINDINGS")
COMMENTS=$(jq -c '.comments // []' "$FINDINGS")

# Function to fetch latest commit SHA
fetch_commit_sha() {
  gh api "repos/$REPO/pulls/$PR" --jq '.head.sha' 2>/dev/null
}

# Function to build and submit the review
submit_review() {
  local COMMIT_SHA="$1"

  # Build the payload
  local PAYLOAD
  PAYLOAD=$(jq -n \
    --arg body "$SUMMARY" \
    --arg event "$VERDICT_UPPER" \
    --arg sha "$COMMIT_SHA" \
    --argjson comments "$COMMENTS" \
    '{
      body: $body,
      event: $event,
      commit_id: $sha,
      comments: $comments
    }')

  gh api "repos/$REPO/pulls/$PR/reviews" \
    --method POST \
    --input - <<< "$PAYLOAD" 2>&1
}

# Fetch commit SHA
COMMIT_SHA=$(fetch_commit_sha) || {
  echo "Error: failed to fetch commit SHA for PR #$PR" >&2
  exit 1
}

# Attempt to submit review
RESULT=$(submit_review "$COMMIT_SHA" 2>&1)
STATUS=$?

# On 422 (stale SHA): re-fetch and retry once
if [ $STATUS -ne 0 ] && echo "$RESULT" | grep -q "422"; then
  echo "Got 422 (stale commit SHA), retrying with fresh SHA..." >&2
  COMMIT_SHA=$(fetch_commit_sha) || {
    echo "Error: failed to re-fetch commit SHA" >&2
    exit 1
  }
  RESULT=$(submit_review "$COMMIT_SHA" 2>&1)
  STATUS=$?
fi

# If REST API succeeded, extract and output the review URL
if [ $STATUS -eq 0 ] && echo "$RESULT" | jq -e '.html_url' >/dev/null 2>&1; then
  REVIEW_URL=$(echo "$RESULT" | jq -r '.html_url')
  echo "$REVIEW_URL"
  exit 0
fi

# Fallback: use gh pr review (body-only, no inline comments)
echo "Warning: REST API submission failed, falling back to gh pr review (no inline comments)" >&2
echo "$RESULT" >&2

FALLBACK_FLAG="--comment"
if [ "$VERDICT_UPPER" = "REQUEST_CHANGES" ]; then
  FALLBACK_FLAG="--request-changes"
fi

gh pr review "$PR" $FALLBACK_FLAG --body "$SUMMARY" 2>&1 || {
  echo "Error: fallback gh pr review also failed" >&2
  exit 1
}

echo "Review submitted via fallback (body-only, no inline comments)"
