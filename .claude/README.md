# AI Workflow

An automated development workflow built on Claude Code agents, tmux sessions, and git worktrees. Work is planned in conversation, then executed autonomously in isolated worktrees with full CI integration.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Conversation (interactive Claude session)                       │
│                                                                 │
│  /planner ──→ formal plan ──→ tw tony-<task> -a implementor     │
│  /spike   ──→ brief       ──→ tw tony-<task> -a spike           │
└─────────────────────────────────────────────────────────────────┘
        │                                │
        ▼                                ▼
┌───────────────────┐     ┌───────────────────────────────────────┐
│  Plan/Brief file  │     │  New worktree + tmux session          │
│  ~/dev-in-docker- │     │  /workspaces/tony-<task>              │
│  shared-files/    │     │                                       │
│  plans/tony-*.md  │     │  Agent reads plan → implements →      │
│                   │     │  pushes draft PR → polls CI →         │
│  (each plan can   │     │  (implementor only: watches for       │
│   depend on any   │     │   author comments on draft PRs)       │
│   other plan)     │     │                                       │
└───────────────────┘     └───────────────────────────────────────┘
                                         │
                                         ▼
                              ┌──────────────────────┐
                              │  Status file         │
                              │  /tmp/claude-        │
                              │  workflow-status/    │
                              │  <session-name>      │
                              └──────────────────────┘
                                         │
                                         ▼
                              ┌──────────────────────┐
                              │  Session picker      │
                              │  (Prefix+f)          │
                              │  Shows status +      │
                              │  PR link per session  │
                              └──────────────────────┘
```

## Skills

### `/planner`

Synthesizes the current conversation into a formal implementation plan. Supports single tasks and multi-task decompositions with inter-plan dependencies.

**Flow:**
1. Asks: single task or multi-task?
2. For multi-task: discusses decomposition and dependency graph before writing plans
3. Asks for task name, JIRA ticket preference
4. Enters plan mode for review
5. On approval: saves plan, spawns implementor agent via `tw tony-<task> -a implementor`

**Produces:** `~/dev-in-docker-shared-files/plans/tony-<task>.md` (detailed step-by-step plan)

### `/spike`

Like `/planner` but lighter. Writes a medium-detail brief and spawns a fast spike agent that skips tests and CI.

**Flow:**
1. Summarizes conversation into a brief (key files + approach)
2. Asks for task name, JIRA ticket preference
3. Shows brief inline for quick confirmation
4. On confirmation: saves brief, spawns spike agent via `tw tony-<task> -a spike`

**Produces:** `~/dev-in-docker-shared-files/plans/tony-<task>.md` (brief with key decisions)

### `/spawn-ready`

Scans all plan files for dependency graphs and spawns implementors for tasks whose dependencies are satisfied.

- No args: scans all plans, shows dependency graph and statuses, lets you pick
- With task name: spawns a specific task if deps are met

Uses stacked PRs (`-b` flag) for tasks with single dependencies.

### `/reap`

Scans for completed/abandoned work and cleans up with confirmation.

Groups findings as:
- **Ready to clean up** — merged/closed PRs (auto-selected)
- **Completed spikes** — spike-done sessions (shown but NOT auto-selected)
- **Stale status files** — orphaned files with no worktree/session (auto-selected)
- **Still active** — open PRs, no-PR sessions

Cleanup: kills tmux session, removes worktree, deletes plan and status files.

### `/catchup`

Loads context for the current worktree into a fresh session. Reads the plan, shows git diff stats, PR status, CI state, and open comments in a scannable summary. Use when picking up a worktree for manual iteration (e.g., after an implementor exited, or when actively focused on a PR).

### `/sync-status`

Detects actual workflow state from git/PR/CI and corrects stale status files.

Checks in order: no commits → implementing, commits no PR → pushing, PR merged → merged, CI failing → fixing-ci, CI pending → waiting-ci, CI pass → waiting-on-review, changes requested → has-comments.

### `/improve-workflow`

Reviews the current conversation for improvement opportunities:
- Repeated corrections that should become instruction rules
- Processes that could be new skills
- Commands that needed permission (should be pre-allowed)
- Agent behavior that could be improved

Applies changes and runs the install pipeline automatically.

## Agents

### `implementor`

Autonomous implementation agent. Implements the plan, pushes a draft PR, then hands off to the watcher. Phases:

1. **Initialization** — reads plan, verifies branch
2. **Implementation** — follows plan step-by-step, runs linter and tests
3. **Commit & Push** — creates draft PR, requests copilot review
4. **Start Watcher & Exit** — launches `pr-watcher.sh` in the `cmd` pane, then stops

The implementor does NOT poll CI or watch for comments — that's the watcher's job.

### `ci-fixer`

Focused agent launched by the watcher when CI fails. Reads the plan for context, identifies failing checks, applies fixes, and pushes. Exits immediately after pushing — the watcher resumes CI polling.

### `comment-addresser`

Focused agent launched by the watcher when the author leaves comments on a draft PR. Reads comments, makes requested changes, pushes. Exits after pushing.

### `spike`

Lightweight agent for quick implementations. Phases:

1. **Initialization** — reads brief
2. **Implementation** — builds the feature (no tests, no lint)
3. **Commit & Push** — creates draft PR
4. **Done** — writes `spike-done` status, stops

## Infrastructure

### `tw` command

Git worktree + tmux session manager (`~/.config/zsh/worktree.zsh`).

```bash
tw tony-<task>                  # Create worktree + session, switch to it
tw tony-<task> -a implementor   # Create + launch agent (stays in current session)
tw tony-<task> -b tony-<base>   # Stack: branch from base (for dependent tasks)
tw -d tony-<task>               # Delete worktree + session + branch
```

Each session gets 4 tmux windows: `claude`, `git` (lazygit), `nvim`, `cmd`.

### PR watcher

`~/.config/scripts/pr-watcher.sh` is a bash script that runs in the `cmd` tmux pane after the implementor finishes. It:
- Polls CI status every 60s (after initial 5min wait)
- On CI failure: launches `ci-fixer` agent in the `claude` pane (up to 3 attempts)
- On CI pass: switches to watching for author comments
- On new comments (with 60s debounce): launches `comment-addresser` agent
- On PR marked ready for review: exits
- On PR merged/closed: exits

Zero token cost while polling — Claude is only invoked when there's actual work.

### Workflow status

`~/.config/scripts/workflow-status.sh` writes status to `/tmp/claude-workflow-status/<session>`.

Format:
```
status: <phase>
pr: <url>
branch: <branch>
updated: <timestamp>
```

### Session picker

`~/.config/tmux/session-switcher.sh` (bound to Prefix+f) shows all sessions with:
- Current branch and HEAD commit
- Claude tool status (working/permission/responded)
- Webpack status
- Workflow status with full PR link

Status indicators:
- `🔨 implementing` — agent is writing code
- `🧪 testing` — running tests
- `⬆ pushing` — committing and creating PR
- `⏳ CI running <url>` — waiting for CI
- `🔧 fixing CI <url>` — addressing CI failures
- `✗ CI stuck <url>` — 3 failed attempts
- `👀 awaiting comments <url>` — watching for author feedback
- `✓ review <url>` — PR ready, waiting on reviewer
- `💬 comments <url>` — changes requested
- `✓ spike done <url>` — spike complete
- `🎉 merged <url>` — PR merged

## Multi-Task Dependencies

For complex work, `/planner` creates multiple plan files in `~/dev-in-docker-shared-files/plans/`, each with a Dependencies section referencing sibling tasks by name. There is no separate project file — the dependency graph is implicit in the plans themselves.

Tasks are spawned in dependency order. `/spawn-ready` scans all plans, checks which tasks have their dependencies' PRs merged, and spawns them. Stacked PRs use the `-b` flag to branch from the parent task's branch. New dependent tasks can be added at any time by creating a plan that references an existing task.

## Persistence

All plans live in `~/dev-in-docker-shared-files/` which survives container restarts. Status files in `/tmp/` are ephemeral but can be reconstructed via `/sync-status`.

## Typical Workflows

### Quick spike
```
(discuss feature) → /spike → agent builds it → review draft PR → iterate or close
```

### Standard task
```
(discuss feature) → /planner → review plan → agent implements → CI passes → 
leave comments on draft → agent addresses them → mark ready for review
```

### Multi-task
```
(discuss large feature) → /planner (multi-task) → review plans + deps →
agents implement parallel tasks → /spawn-ready (as deps merge) →
all tasks done → review and merge
```

### Cleanup
```
/reap → shows merged PRs, completed spikes, stale sessions → confirm → 
deletes worktrees, kills sessions, removes plan and status files
```

Run `/reap` periodically to clean up finished work. Merged/closed PRs and stale status files are auto-selected for deletion; completed spikes are flagged but require explicit selection. Use `/sync-status` first if you suspect status files are out of date.
