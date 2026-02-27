#!/usr/bin/env bash
set -euo pipefail

# List unresolved Sentry issues sorted by frequency.
# Usage: sentry-list.sh [--limit N]
# Default limit: 25

ENV_FILE="$HOME/.claude/agents/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: env file not found at $ENV_FILE" >&2
  exit 1
fi

ORG=$(grep '^SENTRY_ORG=' "$ENV_FILE" | cut -d= -f2-)
PROJECT=$(grep '^SENTRY_PROJECT=' "$ENV_FILE" | cut -d= -f2-)

if [ -z "$ORG" ] || [ -z "$PROJECT" ]; then
  echo "Error: SENTRY_ORG and SENTRY_PROJECT must be set in $ENV_FILE" >&2
  exit 1
fi

LIMIT=25
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    *) echo "Error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

RAW=$(sentry api "projects/$ORG/$PROJECT/issues/?query=is:unresolved&sort=freq&limit=$LIMIT" 2>&1) || {
  echo "Error: failed to fetch Sentry issues" >&2
  echo "$RAW" >&2
  exit 1
}

echo "$RAW" | jq -c '[.[] | {
  id: .id,
  shortId: .shortId,
  title: .title,
  type: (.metadata.type // null),
  filename: (.metadata.filename // null),
  function: (.metadata.function // null),
  count: (.count | tonumber),
  firstSeen,
  lastSeen,
  priority: (.priority // null),
  permalink: .permalink
}]'
