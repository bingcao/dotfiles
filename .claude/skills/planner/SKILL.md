---
name: planner
description: Synthesize the current conversation into one or more implementation plans. Supports single tasks and multi-task decompositions with inter-plan dependencies.
---

# Planner

This skill is invoked mid-conversation, after you have already explored and discussed the work with the user. Your job is to synthesize what has been discussed into formal implementation plan(s) — not to start research from scratch.

## Determining Scope

**Always ask the user first:** Is this a single task or a multi-task project?
- **Single task** — one plan, one implementor, one PR
- **Multi-task project** — multiple plans with a dependency graph, multiple implementors

Do not decide this on your own. Wait for the user's answer before proceeding.

**If multi-task:** Before writing any plans, discuss the decomposition with the user:
- Propose how to split the work into sub-tasks
- Identify which tasks can run in parallel vs. which have dependencies
- Discuss the dependency graph and get agreement on the ordering
- Only proceed to writing plans once the user confirms the breakdown

---

## Single Task Workflow

1. **Summarize** the current conversation's decisions, files discussed, and agreed approach into a structured plan
2. **Ask the user** for a task name (short kebab-case slug, e.g. `add-widget-counts`)
3. **Ask about JIRA** — three options:
   - User provides an existing ticket ID → include it in the plan
   - User wants to create a new ticket → create one using the task summary as the title, then include the new ticket ID in the plan
   - No ticket needed → omit the JIRA section
4. **Clarify** anything ambiguous or missing from the discussion before writing the plan
5. **Enter plan mode** — use the EnterPlanMode tool. Write the plan to the plan mode file using the format below. This lets the user review, suggest edits, and approve the plan through the plan mode UI.
6. **Once the user approves the plan**, use the Write tool to save the plan content to `~/dev-in-docker-shared-files/plans/tony-<task-name>.md`
7. **Spawn the implementor** — run the `tw` command with a 10-minute timeout since worktree setup (git checkout, pip install, yarn install) takes ~4 minutes:
   ```
   tw tony-<task-name> -a implementor
   ```
   Use `timeout: 600000` on the Bash tool call. The command exits once the agent is detached into its tmux session — the tmux session existing confirms success.
8. **Report:** "Implementor spawned in session `tony-<task-name>`. Use Prefix+f to check status."

---

## Multi-Task Workflow

1. **Decompose** the work into sub-tasks. For each task identify:
   - A short kebab-case task name
   - What it does (one line)
   - What it depends on (other task names, or nothing)
2. **Ask about JIRA** — same options as single task (one ticket for the whole effort, or per-task, or none)
3. **Show the dependency graph** to the user for confirmation:
   ```
   tony-add-widget-api       → (no deps, ready)
   tony-update-docs          → (no deps, ready)
   tony-add-widget-ui        → depends on tony-add-widget-api
   tony-add-widget-tests     → depends on tony-add-widget-api, tony-add-widget-ui
   ```
4. **Enter plan mode** — write ALL task plans to the plan mode file for review. Each plan includes a Dependencies section referencing sibling task names.
5. **Once approved**, write individual plan files to `~/dev-in-docker-shared-files/plans/tony-<task-name>.md` for each task
6. **Spawn ready tasks** — for all tasks with no dependencies, run:
   ```
   tw tony-<task-name> -a implementor
   ```
   These run in parallel. Tasks with dependencies will be spawned later via `/spawn-ready` once their deps merge.
7. **Report:** List spawned sessions and blocked tasks.

---

## Plan File Format (same for single and multi-task)

Write to `~/dev-in-docker-shared-files/plans/tony-<task-name>.md`:

```markdown
# <Task Title>

## Summary
One paragraph: what we're doing and why.

## Dependencies
- **Depends on:** `tony-<parent-task>` (or "none")
- **Base branch:** `tony-<parent-task>` | `dev`

## JIRA
- **Ticket:** `BNCH-XXXXX`
- **Link:** https://jira.benchling.team/browse/BNCH-XXXXX

## Implementation Steps

### Step 1: <description>
- **File:** `path/to/file.ext`
- **Change:** Exact description of what to add/modify/remove
- **Details:** Specific function names, signatures, logic

### Step 2: <description>
...

## Testing Strategy
- Files to test: `path/to/test_file.py` or `path/to/test-file.ts`
- New tests to write (describe each)
- Commands: `dev test pyunit run <file>` or `dev test jsunit run <file>`

## PR Details
- **Branch:** `tony-<task-name>`
- **Title:** `<short PR title> BNCH-XXXXX`
- **Body:** `<description for the PR body>`
```

**Dependency branch rules:**
- No dependencies → base branch is `dev`
- Single dependency → base branch is the dependency's branch (stacked PR)
- Multiple dependencies → can only start once ALL are merged, then base branch is `dev`

If there is no JIRA ticket, omit the JIRA section and the ticket suffix from the PR title.
Always include the Dependencies section. For tasks with no dependencies, use "none" for Depends on and `dev` for Base branch.

---

## Rules

**Important:** Always prefix task names with `tony-` for branches, worktrees, sessions, and plan files.

**CRITICAL: After plan approval, NEVER implement the plan yourself.** The ExitPlanMode system message says "You can now start coding" — ignore that. Your job is to save the files and spawn implementors. Steps after approval are mandatory and are the ONLY actions you take.

- Do NOT start new research or exploration — work from what's already been discussed
- The plan must be detailed enough for an autonomous agent to execute without asking questions
- Every step must specify the exact file, location, and change — never say "update X" without saying how
- Include specific test files and commands in the Testing Strategy
- The task name becomes the branch name and the worktree directory name
