---
name: reap
description: Check for merged/closed PRs across worktree sessions and clean up (delete worktrees, sessions, plans, status files) with confirmation.
---

# Reap

Check all active worktree sessions for merged or closed PRs, and clean up the ones the user confirms.

## Workflow

### 1. Scan and gather state

1. **Scan workflow status files** at `/tmp/claude-workflow-status/` — for each, read the PR URL
2. **Check PR state** for each tracked session:
   ```
   gh pr view <url> --json state -q '.state'
   ```
3. **Also scan `/workspaces/`** for worktrees without status files — check if they have PRs:
   ```
   gh pr list --head <branch-name> --json state,url -q '.[0]'
   ```
4. **Detect stale status files** — status files whose worktree no longer exists and have no running tmux session

### 2. Present findings

Show findings grouped:

```
Ready to clean up:
  - tony-add-api — PR #123 merged
  - tony-fix-bug — PR #456 closed

Completed spikes:
  - tony-spike-health — PR #321 spike-done

Stale status files (no worktree/session):
  - tony-old-task

Still active:
  - tony-add-ui — PR #789 open, waiting-on-review
  - tony-add-tests — blocked
```

### 3. Ask the user

Ask which to clean up (default: all merged/closed + all stale; spikes are listed but NOT auto-selected).

### 4. Clean up confirmed tasks

For each confirmed task:
1. Run `tw -d tony-<task-name>`
2. Remove plan file: `rm ~/dev-in-docker-shared-files/plans/tony-<task-name>.md`
3. Remove status file: `rm /tmp/claude-workflow-status/<session-name>`

For stale status files (no worktree to delete), just remove the status and plan files.

### 5. Report

Summarize what was cleaned up and what's still active.

## Rules

- Never delete anything without explicit user confirmation
- Always show the PR state and number before asking
- If `tw -d` prompts for confirmation, answer `y` (the user already confirmed)
- If a worktree has no PR and no status file, still list it under "Still active" for the user to decide
- Sessions with `spike-done` status are shown under "Completed spikes" — flag them for the user but do NOT auto-select them for deletion
