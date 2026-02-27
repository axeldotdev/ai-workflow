#!/usr/bin/env bash
set -euo pipefail

# Archive (ignore) a Sentry issue. Reversible — sets status to "ignored".
# Usage: sentry-archive.sh <ISSUE_ID>

ISSUE_ID="${1:?Usage: sentry-archive.sh <ISSUE_ID>}"

RESULT=$(sentry api "issues/$ISSUE_ID/" -X PUT -F status=ignored 2>&1) || {
  echo "Error: failed to archive Sentry issue $ISSUE_ID" >&2
  echo "$RESULT" >&2
  exit 1
}

# Verify the status was set
STATUS=$(echo "$RESULT" | jq -r '.status // empty' 2>/dev/null)

if [ "$STATUS" = "ignored" ]; then
  echo "Archived Sentry issue $ISSUE_ID (status=ignored)" >&2
else
  echo "Warning: unexpected response when archiving issue $ISSUE_ID" >&2
  echo "$RESULT" >&2
fi
