---
name: reap
description: Check for merged/closed PRs across worktree sessions, optionally update Jira tickets (story points + done), and clean up (delete worktrees, sessions, plans, status files) with confirmation.
---

# Reap

Check all active worktree sessions for merged or closed PRs, and clean up the ones the user confirms.

## Workflow

### 1. Scan and gather state

Resolve: `PLAN_DIR="${PLAN_DIR:-$HOME/plans}"` and `WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/worktrees}"`.

1. **Scan workflow status files** at `/tmp/claude-workflow-status/` — for each, read the PR URL
2. **Check PR state** for each tracked session:
   ```
   gh pr view <url> --json state -q '.state'
   ```
3. **Also scan `$WORKTREE_ROOT/`** for worktrees without status files — check if they have PRs:
   ```
   gh pr list --head <branch-name> --json state,url -q '.[0]'
   ```
4. **Detect stale status files** — status files whose worktree no longer exists and have no running tmux session

### 2. Present findings

Show findings grouped:

```
Ready to clean up:
  - <task-a> — PR #123 merged
  - <task-b> — PR #456 closed

Completed spikes:
  - <task-c> — PR #321 spike-done

Stale status files (no worktree/session):
  - <task-d>

Still active:
  - <task-e> — PR #789 open, waiting-on-review
  - <task-f> — blocked
```

### 3. Ask the user

Ask which to clean up (default: all merged/closed + all stale; spikes are listed but NOT auto-selected).

### 4. Check Jira tickets (requires Jira MCP)

For each task confirmed for cleanup, check if it has a corresponding Jira ticket:

1. **Find the ticket key** — look at the PR title/body or plan file for a Jira key (e.g., `BENCH-1234`)
2. **Get the cloudId** if not already known:
   - Call `getAccessibleAtlassianResources` and use the first cloud site's `id`
3. **Check ticket status and story points** — call `getJiraIssue` with the ticket key:
   - Look at the `status` field for current state
   - Look at `customfield_10016` for story points (or discover the field via `getJiraIssueTypeMetaWithFields` if needed)
4. **If story points are not set**, ask the user what to set them to, then call `editJiraIssue` to update the field
5. **Ask the user** whether to mark the ticket as done (do NOT auto-mark — always prompt per ticket)
6. If confirmed, transition the ticket:
   - Call `listJiraIssueTransitions` to find the transition ID for "Done"
   - Call `transitionJiraIssue` with that transition ID

If the Jira MCP is not connected, skip this step and note it in the report.

### 5. Clean up confirmed tasks

For each confirmed task:
1. Run `tw -d <task-name>`
2. Remove plan file: `rm $PLAN_DIR/<task-name>.md`
3. Remove status file: `rm /tmp/claude-workflow-status/<session-name>`

For stale status files (no worktree to delete), just remove the status and plan files.

### 6. Report

Summarize what was cleaned up, any Jira tickets updated, and what's still active.

## Rules

- Never delete anything without explicit user confirmation
- Always show the PR state and number before asking
- If `tw -d` prompts for confirmation, answer `y` (the user already confirmed)
- If a worktree has no PR and no status file, still list it under "Still active" for the user to decide
- Sessions with `spike-done` status are shown under "Completed spikes" — flag them for the user but do NOT auto-select them for deletion
