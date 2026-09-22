---
name: sync-status
description: Check and update workflow status for the current session or all sessions. Detects actual state from git, PR, and CI status.
---

# Sync Status

Determine the actual workflow status of session(s) by inspecting git state, PR state, and CI status, then update the status file(s) to match reality.

## Workflow

### Single session (default — uses current session or a named one)

Resolve: `WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/worktrees}"`.

1. **Determine the session** — if in a worktree under `$WORKTREE_ROOT`, use `basename "$PWD"`. Otherwise ask which session to check.
2. **Detect actual state** by running the checks below in order (first match wins):
   - No commits ahead of base branch → `implementing` (work hasn't started or was reset)
   - Commits exist but no PR → `pushing` (code written but not pushed)
   - PR exists and merged → `merged`
   - PR exists and closed → `merged`
   - PR exists, open, `reviewDecision` is `CHANGES_REQUESTED` → `has-comments`
   - PR exists, open, CI checks failing (any `FAILURE` in statusCheckRollup) → `fixing-ci`
   - PR exists, open, CI checks pending (no failures, some not `SUCCESS`) → `waiting-ci`
   - PR exists, open, CI checks all pass → `waiting-on-review`
3. **Compare** detected state with current status file at `/tmp/claude-workflow-status/<session-name>`
4. **Update** the status file if they differ, reporting what changed

### All sessions (when user says "all" or "sync all")

1. **List all workflow status files** in `/tmp/claude-workflow-status/`
2. **Also scan `$WORKTREE_ROOT/`** for worktrees that might not have a status file yet
3. **Run the single-session detection** for each
4. **Report** a summary table of all sessions and any status changes made

## Detection Commands

```bash
# Get branch name
git -C $WORKTREE_ROOT/<name> branch --show-current

# Check commits ahead
BASE=origin/dev  # or the plan's base branch
git -C $WORKTREE_ROOT/<name> log --oneline $(git -C $WORKTREE_ROOT/<name> merge-base HEAD $BASE)..HEAD

# Find PR for branch
gh pr list --head <branch> --json number,state,url -q '.[0]'

# Check PR state + CI in one call
gh pr view <number> --json state,reviewDecision,statusCheckRollup \
  -q '{state: .state, review: .reviewDecision, checks: [.statusCheckRollup[] | .conclusion] | {pass: map(select(. == "SUCCESS")) | length, fail: map(select(. == "FAILURE")) | length, pending: map(select(. == "" or . == null)) | length}}'
```

## Rules

- Always use `workflow-status` to write updates (the command is on PATH)
- If a worktree no longer exists but a status file does, remove the status file
- If no PR exists and no commits exist AND no worktree exists, remove the status file (orphaned)
- If no PR exists and no commits exist BUT the worktree exists, skip it (fresh session, not yet started)
- Report changes concisely: `session-name: fixing-ci → waiting-on-review`
