#!/usr/bin/env bash
set -euo pipefail

# Fetch full Sentry issue details including stacktrace from latest event.
# Usage: sentry-issue.sh <ISSUE_ID>

ISSUE_ID="${1:?Usage: sentry-issue.sh <ISSUE_ID>}"

# Fetch issue details and latest event in parallel
ISSUE_TMP=$(mktemp)
EVENT_TMP=$(mktemp)
trap 'rm -f "$ISSUE_TMP" "$EVENT_TMP"' EXIT

sentry api "issues/$ISSUE_ID/" > "$ISSUE_TMP" 2>/dev/null &
PID_ISSUE=$!

sentry api "issues/$ISSUE_ID/events/latest/" > "$EVENT_TMP" 2>/dev/null &
PID_EVENT=$!

wait "$PID_ISSUE" || { echo "Error: failed to fetch issue $ISSUE_ID" >&2; exit 1; }
wait "$PID_EVENT" || { echo "Error: failed to fetch latest event for issue $ISSUE_ID" >&2; exit 1; }

# Extract in-app stacktrace frames from latest event
STACKTRACE=$(jq -c '[
  .entries[]?
  | select(.type == "exception")
  | .data.values[]?
  | .stacktrace.frames[]?
  | select(.inApp == true)
  | {filename, lineNo, function: .function}
]' "$EVENT_TMP" 2>/dev/null || echo '[]')

# Extract useful tags from event
TAGS=$(jq -c '{
  environment: ([.tags[]? | select(.key == "environment") | .value] | first // null),
  browser: ([.tags[]? | select(.key == "browser") | .value] | first // null),
  os: ([.tags[]? | select(.key == "os") | .value] | first // null),
  release: ([.tags[]? | select(.key == "release") | .value] | first // null)
}' "$EVENT_TMP" 2>/dev/null || echo '{}')

# Combine into output
jq -c --argjson stacktrace "$STACKTRACE" --argjson tags "$TAGS" '{
  id: .id,
  shortId: .shortId,
  title: .title,
  type: (.metadata.type // null),
  message: (.metadata.value // .title),
  filename: (.metadata.filename // null),
  function: (.metadata.function // null),
  count: (.count | tonumber),
  firstSeen,
  lastSeen,
  priority: (.priority // null),
  permalink: .permalink,
  stacktrace: $stacktrace,
  tags: $tags
}' "$ISSUE_TMP"
