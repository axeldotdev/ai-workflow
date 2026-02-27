#!/usr/bin/env bash
set -euo pipefail

# Find or create a Linear issue for a Sentry error.
# Usage: fix-linear.sh find|create <SENTRY_SHORT_ID> [--title "..."] [--description "..."]

SESSION_FILE="/tmp/fixer-session.json"

ACTION="${1:?Usage: fix-linear.sh find|create <SENTRY_SHORT_ID> [--title \"...\"] [--description \"...\"]}"
SHORT_ID="${2:?Usage: fix-linear.sh find|create <SENTRY_SHORT_ID>}"
shift 2

TITLE=""
DESCRIPTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    *) echo "Error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

case "$ACTION" in
  find)
    # Search for existing Linear issue matching this Sentry ID
    ESCAPED_ID=$(echo "$SHORT_ID" | sed 's/"/\\"/g')
    RAW=$(linear api "{ searchIssues(term: \"$ESCAPED_ID\", first: 5) { nodes { identifier title url state { name type } } } }" 2>&1) || {
      echo "Error: Linear search failed" >&2
      echo "$RAW" >&2
      exit 1
    }

    # Filter: only issues whose title contains the exact short ID
    MATCH=$(echo "$RAW" | jq -c --arg sid "$SHORT_ID" '
      [.data.searchIssues.nodes[] | select(.title | contains($sid))] | first // null
    ')

    if [ "$MATCH" = "null" ] || [ -z "$MATCH" ]; then
      echo '{"found": false}'
    else
      echo "$MATCH" | jq -c '{
        found: true,
        identifier: .identifier,
        url: .url,
        state: .state.name
      }'
    fi
    ;;

  create)
    if [ -z "$TITLE" ]; then
      echo "Error: --title is required for create" >&2
      exit 1
    fi

    if [ -z "$DESCRIPTION" ]; then
      echo "Error: --description is required for create" >&2
      exit 1
    fi

    if [ ! -f "$SESSION_FILE" ]; then
      echo "Error: session file not found — run fix-preflight.sh first" >&2
      exit 1
    fi

    TEAM_ID=$(jq -r '.linear_team_id' "$SESSION_FILE")
    TRIAGE_STATE_ID=$(jq -r '.linear_triage_state_id' "$SESSION_FILE")
    BUG_LABEL_ID=$(jq -r '.linear_bug_label_id' "$SESSION_FILE")
    VIEWER_ID=$(jq -r '.linear_viewer_id' "$SESSION_FILE")

    # Build label array
    LABEL_ARRAY="[]"
    if [ -n "$BUG_LABEL_ID" ] && [ "$BUG_LABEL_ID" != "" ]; then
      LABEL_ARRAY="[\"$BUG_LABEL_ID\"]"
    fi

    ESCAPED_TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')
    ESCAPED_DESC=$(echo "$DESCRIPTION" | sed 's/"/\\"/g')

    MUTATION="mutation {
      issueCreate(input: {
        teamId: \"$TEAM_ID\"
        title: \"$ESCAPED_TITLE\"
        description: \"$ESCAPED_DESC\"
        stateId: \"$TRIAGE_STATE_ID\"
        assigneeId: \"$VIEWER_ID\"
        priority: 2
        labelIds: $LABEL_ARRAY
      }) {
        success
        issue {
          identifier
          url
        }
      }
    }"

    RAW=$(linear api "$MUTATION" 2>&1) || {
      echo "Error: failed to create Linear issue" >&2
      echo "$RAW" >&2
      exit 1
    }

    SUCCESS=$(echo "$RAW" | jq -r '.data.issueCreate.success // false')
    if [ "$SUCCESS" != "true" ]; then
      echo "Error: Linear issue creation returned success=false" >&2
      echo "$RAW" >&2
      exit 1
    fi

    echo "$RAW" | jq -c '{
      identifier: .data.issueCreate.issue.identifier,
      url: .data.issueCreate.issue.url
    }'
    ;;

  *)
    echo "Error: unknown action '$ACTION'. Use 'find' or 'create'." >&2
    exit 1
    ;;
esac
