#!/usr/bin/env bash
set -euo pipefail

# Fetch CI check status for a PR and output structured JSON.
# Usage: pr-checks.sh <PR_NUMBER>

PR="${1:?Usage: pr-checks.sh <PR_NUMBER>}"

if ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "Error: PR number must be a positive integer" >&2
  exit 1
fi

RAW=$(gh pr checks "$PR" --json name,bucket 2>&1) || {
  echo "Error: failed to fetch checks for PR #$PR" >&2
  echo "$RAW" >&2
  exit 1
}

# If no checks exist, gh returns empty array
if [ -z "$RAW" ] || [ "$RAW" = "[]" ]; then
  echo '{"status":"pass","passed":0,"failed":0,"pending":0,"failed_names":[]}'
  exit 0
fi

echo "$RAW" | jq -c '{
  status: (
    if (map(select(.bucket == "fail")) | length) > 0 then "fail"
    elif (map(select(.bucket == "pending")) | length) > 0 then "pending"
    else "pass"
    end
  ),
  passed: (map(select(.bucket == "pass")) | length),
  failed: (map(select(.bucket == "fail")) | length),
  pending: (map(select(.bucket == "pending")) | length),
  failed_names: [.[] | select(.bucket == "fail") | .name]
}'
