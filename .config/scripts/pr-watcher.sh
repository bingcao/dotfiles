#!/usr/bin/env bash
# Watches a PR for CI results and author comments.
# Runs Claude agents interactively when action is needed.
#
# Usage: pr-watcher.sh <session-name> <pr-number> <branch>
#   Or to also run the implementor first:
#        pr-watcher.sh --implement <session-name> <task-name> <branch>
#   Or to resume watching (auto-detects PR from branch):
#        pr-watcher.sh --resume

set -u

# Parse mode
IMPLEMENT=false
RESUME=false
if [ "${1:-}" = "--implement" ]; then
  IMPLEMENT=true
  shift
elif [ "${1:-}" = "--resume" ]; then
  RESUME=true
fi

if [ "$RESUME" = true ]; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "")
  SESSION=$(basename "$PWD" | tr '.[/::' '-')
  TASK_OR_PR=""
else
  SESSION="$1"
  TASK_OR_PR="$2"
  BRANCH="${3:-}"
fi
STATUS_SCRIPT="$HOME/.config/scripts/workflow-status.sh"
CI_FIX_ATTEMPTS=0
MAX_CI_FIXES=3
LAST_COMMENT_CHECK="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PR_NUMBER=""
PR_URL=""
AUTHOR=""
REPO=""

log() {
  echo "[$(date '+%H:%M:%S')] $1"
}

wait_or_trigger() {
  local seconds="${1:-60}"
  read -t "$seconds" -n 1 -s -p "" trigger_key || true
  if [ -n "${trigger_key:-}" ]; then
    echo ""
    log "Agent menu (auto-resumes in 10s):"
    echo "  1) ci-fixer"
    echo "  2) comment-addresser"
    read -t 10 -n 1 -p "Choose [1/2]: " choice || true
    echo ""
    case "${choice:-}" in
      1) run_agent "ci-fixer" ;;
      2) run_agent "comment-addresser" ;;
      *) log "No selection, resuming..." ;;
    esac
  fi
}

update_status() {
  "$STATUS_SCRIPT" "$SESSION" "$1" "$PR_URL" "$BRANCH"
}

send_begin() {
  local pane="$1"
  for i in $(seq 1 30); do
    if tmux capture-pane -t "$pane" -p 2>/dev/null | grep -qE '❯|>'; then
      tmux send-keys -t "$pane" "begin" Enter
      return 0
    fi
    sleep 1
  done
  log "Timed out waiting for Claude prompt."
  return 1
}

run_agent() {
  local agent="$1"
  local pane="${TMUX_PANE:-}"
  log "Running $agent agent..."

  # Send "begin" after Claude starts, in background
  (sleep 2 && send_begin "$pane") &
  local begin_pid=$!

  claude --agent "$agent" --allowedTools 'Bash Read Write Edit Grep Glob Skill'
  local exit_code=$?

  wait $begin_pid 2>/dev/null || true

  if [ $exit_code -ne 0 ]; then
    log "Agent $agent exited with code $exit_code."
    return 1
  fi
  log "Agent $agent finished."
  return 0
}

detect_pr() {
  PR_NUMBER=$(gh pr list --head "$BRANCH" --json number -q '.[0].number' 2>/dev/null || echo "")
  if [ -n "$PR_NUMBER" ]; then
    PR_URL=$(gh pr view "$PR_NUMBER" --json url -q '.url' 2>/dev/null || echo "")
  fi
}

check_ci() {
  local result
  result=$(gh pr checks "$PR_NUMBER" 2>/dev/null)
  [ -z "$result" ] && return 2

  # Exclude review-gate checks that are always pending on draft PRs
  local filtered
  filtered=$(echo "$result" | grep -v "check-reviews\|id-stale-reviews")

  if echo "$filtered" | grep -q "fail\|FAILURE"; then
    return 1
  elif echo "$filtered" | grep -qE "pending|PENDING|queued|IN_PROGRESS|waiting"; then
    return 2
  else
    return 0
  fi
}

check_comments() {
  [ -z "$AUTHOR" ] || [ -z "$REPO" ] && return 1

  local review_comments issue_comments total
  review_comments=$(gh api "repos/$REPO/pulls/$PR_NUMBER/comments" --jq "[.[] | select(.user.login == \"$AUTHOR\") | select(.updated_at > \"$LAST_COMMENT_CHECK\")] | length" 2>/dev/null || echo "0")
  issue_comments=$(gh api "repos/$REPO/issues/$PR_NUMBER/comments" --jq "[.[] | select(.user.login == \"$AUTHOR\") | select(.updated_at > \"$LAST_COMMENT_CHECK\")] | length" 2>/dev/null || echo "0")
  total=$((review_comments + issue_comments))

  [ "$total" -gt 0 ]
}

check_draft() {
  local is_draft
  is_draft=$(gh pr view "$PR_NUMBER" --json isDraft -q '.isDraft' 2>/dev/null || echo "true")
  [ "$is_draft" = "true" ]
}

check_merged() {
  local state
  state=$(gh pr view "$PR_NUMBER" --json state -q '.state' 2>/dev/null || echo "OPEN")
  [ "$state" = "MERGED" ] || [ "$state" = "CLOSED" ]
}

# --- Main ---

log "PR watcher started for session=$SESSION branch=$BRANCH"

# Phase 0: Run implementor or detect existing PR
if [ "$IMPLEMENT" = true ]; then
  log "Starting implementor..."
  update_status "implementing"
  run_agent "implementor"

  detect_pr
  if [ -z "$PR_NUMBER" ]; then
    log "No PR found after implementor. Watcher exiting."
    update_status "error"
    exit 1
  fi
  log "PR #$PR_NUMBER detected."
elif [ "$RESUME" = true ]; then
  log "Resuming — detecting PR from branch $BRANCH..."
  detect_pr
  if [ -z "$PR_NUMBER" ]; then
    log "No PR found for branch $BRANCH. Watcher exiting."
    exit 1
  fi
  log "Resumed watching PR #$PR_NUMBER."
else
  PR_NUMBER="$TASK_OR_PR"
  detect_pr
fi

AUTHOR="$(gh api user -q '.login' 2>/dev/null || echo "")"
REPO="$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")"

update_status "waiting-ci"
log "Polling every 60s (pr=#$PR_NUMBER)..."
wait_or_trigger 60

CI_PASSED=false

while true; do
  # Check for buffered keypress before slow API calls
  read -t 0 -n 1 -s buffered_key 2>/dev/null || true
  if [ -n "${buffered_key:-}" ]; then
    log "Agent menu (auto-resumes in 10s):"
    echo "  1) ci-fixer"
    echo "  2) comment-addresser"
    read -t 10 -n 1 -p "Choose [1/2]: " choice || true
    echo ""
    case "${choice:-}" in
      1) run_agent "ci-fixer" ;;
      2) run_agent "comment-addresser" ;;
      *) log "No selection, resuming..." ;;
    esac
  fi

  # Check if PR was merged/closed
  if check_merged; then
    update_status "merged"
    log "PR merged/closed. Watcher exiting."
    exit 0
  fi

  # Check if PR is no longer draft
  if ! check_draft; then
    update_status "waiting-on-review"
    log "PR marked ready for review. Watcher exiting."
    exit 0
  fi

  # Check for comments (always, regardless of CI state)
  log "Checking for comments (since $LAST_COMMENT_CHECK)..."
  if check_comments; then
    log "Comments detected."
    LAST_COMMENT_CHECK="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    update_status "addressing-comments"

    run_agent "comment-addresser"

    CI_PASSED=false
    CI_FIX_ATTEMPTS=0
    update_status "waiting-ci"
    log "Comments addressed. Polling every 60s..."
    wait_or_trigger 60
    continue
  fi

  log "No new comments."

  # Check CI
  log "Checking CI..."
  check_ci
  ci_result=$?

  if [ $ci_result -eq 1 ]; then
    # CI failed
    CI_PASSED=false
    CI_FIX_ATTEMPTS=$((CI_FIX_ATTEMPTS + 1))
    if [ $CI_FIX_ATTEMPTS -gt $MAX_CI_FIXES ]; then
      update_status "ci-stuck"
      log "CI stuck after $MAX_CI_FIXES attempts. Watcher exiting."
      exit 1
    fi

    update_status "fixing-ci"
    log "CI failed (attempt $CI_FIX_ATTEMPTS/$MAX_CI_FIXES)."

    run_agent "ci-fixer"

    update_status "waiting-ci"
    log "CI fix pushed. Polling every 60s..."
    wait_or_trigger 60
    continue

  elif [ $ci_result -eq 0 ]; then
    # CI passed
    log "CI passed."
    if [ "$CI_PASSED" = false ]; then
      CI_PASSED=true
      CI_FIX_ATTEMPTS=0
      LAST_COMMENT_CHECK="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      update_status "waiting-author-comments"
      log "Watching for comments..."
    fi

  else
    # CI still pending
    log "CI still pending."
    if [ "$CI_PASSED" = false ]; then
      update_status "waiting-ci"
    fi
  fi

  log "Next check in 60s..."
  wait_or_trigger 60
done
