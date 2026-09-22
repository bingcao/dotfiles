---
name: spawn-ready
description: Scan plan files for tasks whose dependencies are satisfied and spawn their implementors. With no args, presents options.
---

# Spawn Ready

Scan plan dependency graphs and spawn implementors for tasks that are ready to start.

## Usage

- `/spawn-ready` — scan all plans, show dependency graph and statuses, let the user pick what to spawn
- `/spawn-ready <task-name>` — spawn a specific task (if its deps are met)

## Workflow

### 1. Identify targets

Resolve plan dir: `PLAN_DIR="${PLAN_DIR:-$HOME/plans}"` and worktree root: `WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/worktrees}"`.

**No arguments given:**
1. List all plan files (`*.md`) in `$PLAN_DIR`
2. For each plan, parse the `## Dependencies` section to extract the `Depends on` value (task names or "none")
3. Determine each task's current state by checking in order:
   - **Done**: `gh pr list --head <task-name> --json state -q '.[0].state'` returns `MERGED`
   - **Active**: a worktree exists at `$WORKTREE_ROOT/<task-name>` OR a tmux session exists OR an open PR exists
   - **Candidate**: neither done nor active — eligible for spawning if deps are met
4. For each candidate, check if ALL dependencies' PRs are merged
5. Present the full graph:
   ```
   ✓ <task-a> (done — PR #123 merged)
   ⏳ <task-b> (ready — deps satisfied, not yet spawned)
   🔒 <task-c> (blocked — waiting on <task-b>)
   🔄 <task-d> (active — PR #456 open)
   ○ <task-e> (standalone — no deps, not yet spawned)
   ```
6. Ask the user what to spawn (specific tasks or all ready)

**Task name given:** Read that plan's Dependencies, check if all deps' PRs are merged, and spawn if so.

### 2. Check dependency satisfaction

For each dependency task name in the `Depends on` field:
- Check if the dependency's PR is merged: `gh pr list --head <dep-branch> --json state -q '.[0].state'`
- If merged → dependency satisfied
- If still open or no PR → dependency NOT satisfied

### 3. Spawn ready tasks

For each task being spawned:
1. Determine the base branch from the plan's Dependencies section:
   - No dependencies → branch from `dev` (default `tw` behavior)
   - Single dependency → pass the dependency branch: `tw <task> -b <parent-task> -a implementor`
   - Multiple dependencies (all merged) → branch from `dev`
2. Run:
   ```
   tw <task-name> -a implementor
   ```
   Or with base branch for stacking (single dependency):
   ```
   tw <task-name> -b <parent-task> -a implementor
   ```
   Use `timeout: 600000` on Bash tool calls.

### 4. Report

List what was spawned and what remains blocked.

## Rules

- Never spawn a task whose dependencies aren't satisfied
- When a task has multiple dependencies, ALL must be merged before it's ready
- Present information concisely — the user should be able to scan and decide quickly
