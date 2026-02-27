#!/usr/bin/env bash
set -euo pipefail

# One-shot session setup for fixer agents.
# Validates CLIs, auth, env, git state. Resolves Linear IDs.
# Writes config to /tmp/fixer-session.json AND stdout.
# Usage: fix-preflight.sh

ENV_FILE="$HOME/.claude/agents/.env"
SESSION_FILE="/tmp/fixer-session.json"

# --- Validate env file ---
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: env file not found at $ENV_FILE" >&2
  exit 1
fi

SENTRY_ORG=$(grep '^SENTRY_ORG=' "$ENV_FILE" | cut -d= -f2-)
SENTRY_PROJECT=$(grep '^SENTRY_PROJECT=' "$ENV_FILE" | cut -d= -f2-)
LINEAR_TEAM=$(grep '^LINEAR_TEAM=' "$ENV_FILE" | cut -d= -f2-)
LINEAR_ORG_URL=$(grep '^LINEAR_ORG_URL=' "$ENV_FILE" | cut -d= -f2-)
LINEAR_TITLE_FORMAT=$(grep '^LINEAR_TITLE_FORMAT=' "$ENV_FILE" | cut -d= -f2-)

for VAR_NAME in SENTRY_ORG SENTRY_PROJECT LINEAR_TEAM LINEAR_ORG_URL LINEAR_TITLE_FORMAT; do
  VAR_VALUE="${!VAR_NAME}"
  if [ -z "$VAR_VALUE" ]; then
    echo "Error: $VAR_NAME is missing or empty in $ENV_FILE" >&2
    exit 1
  fi
done

# --- Validate required CLIs ---
for CMD in sentry linear gh jq; do
  if ! command -v "$CMD" >/dev/null 2>&1; then
    echo "Error: required command '$CMD' not found" >&2
    exit 1
  fi
done

# --- Validate auth ---
sentry auth status >/dev/null 2>&1 || {
  echo "Error: sentry auth failed — run 'sentry login'" >&2
  exit 1
}

gh auth status >/dev/null 2>&1 || {
  echo "Error: gh auth failed — run 'gh auth login'" >&2
  exit 1
}

# --- Validate git state ---
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: not inside a git repository" >&2
  exit 1
}

# Detect default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@') || {
  DEFAULT_BRANCH="main"
}

# Stash if dirty
GIT_STASHED=false
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "Working tree dirty — stashing changes" >&2
  git stash push -m "fixer-preflight-autostash" --quiet
  GIT_STASHED=true
fi

# Pull latest
git checkout "$DEFAULT_BRANCH" --quiet 2>/dev/null || true
git pull --quiet 2>/dev/null || {
  echo "Warning: git pull failed, continuing with local state" >&2
}

# Detect repo name
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null) || {
  echo "Error: failed to determine repository" >&2
  exit 1
}

# --- Resolve Linear IDs (parallel) ---
TEAM_TMP=$(mktemp)
VIEWER_TMP=$(mktemp)
trap 'rm -f "$TEAM_TMP" "$VIEWER_TMP"' EXIT

linear api "{ teams(filter: { key: { eq: \"$LINEAR_TEAM\" } }) { nodes { id states { nodes { id name type } } labels { nodes { id name } } } } }" > "$TEAM_TMP" 2>/dev/null &
PID_TEAM=$!

linear api "{ viewer { id } }" > "$VIEWER_TMP" 2>/dev/null &
PID_VIEWER=$!

wait "$PID_TEAM" || { echo "Error: failed to fetch Linear team data" >&2; exit 1; }
wait "$PID_VIEWER" || { echo "Error: failed to fetch Linear viewer" >&2; exit 1; }

TEAM_ID=$(jq -r '.data.teams.nodes[0].id // empty' "$TEAM_TMP")
if [ -z "$TEAM_ID" ]; then
  echo "Error: Linear team '$LINEAR_TEAM' not found" >&2
  exit 1
fi

TRIAGE_STATE_ID=$(jq -r '.data.teams.nodes[0].states.nodes[] | select(.type == "triage") | .id' "$TEAM_TMP" | head -1)
if [ -z "$TRIAGE_STATE_ID" ]; then
  echo "Error: no triage state found for team '$LINEAR_TEAM'" >&2
  exit 1
fi

BUG_LABEL_ID=$(jq -r '.data.teams.nodes[0].labels.nodes[] | select(.name == "Bug") | .id' "$TEAM_TMP" | head -1)
if [ -z "$BUG_LABEL_ID" ]; then
  echo "Warning: no 'Bug' label found for team '$LINEAR_TEAM'" >&2
  BUG_LABEL_ID=""
fi

VIEWER_ID=$(jq -r '.data.viewer.id // empty' "$VIEWER_TMP")
if [ -z "$VIEWER_ID" ]; then
  echo "Error: failed to resolve Linear viewer ID" >&2
  exit 1
fi

# --- Write session config ---
CONFIG=$(jq -n \
  --arg sentry_org "$SENTRY_ORG" \
  --arg sentry_project "$SENTRY_PROJECT" \
  --arg linear_team "$LINEAR_TEAM" \
  --arg linear_team_id "$TEAM_ID" \
  --arg linear_triage_state_id "$TRIAGE_STATE_ID" \
  --arg linear_bug_label_id "$BUG_LABEL_ID" \
  --arg linear_viewer_id "$VIEWER_ID" \
  --arg linear_title_format "$LINEAR_TITLE_FORMAT" \
  --arg git_default_branch "$DEFAULT_BRANCH" \
  --argjson git_stashed "$GIT_STASHED" \
  --arg repo "$REPO" \
  '{
    sentry_org: $sentry_org,
    sentry_project: $sentry_project,
    linear_team: $linear_team,
    linear_team_id: $linear_team_id,
    linear_triage_state_id: $linear_triage_state_id,
    linear_bug_label_id: $linear_bug_label_id,
    linear_viewer_id: $linear_viewer_id,
    linear_title_format: $linear_title_format,
    git_default_branch: $git_default_branch,
    git_stashed: $git_stashed,
    repo: $repo
  }')

echo "$CONFIG" > "$SESSION_FILE"
echo "$CONFIG"
