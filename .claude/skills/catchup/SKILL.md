---
name: catchup
description: Load context for the current worktree — reads the plan, shows git diff, PR status, CI state, and open comments. Use when picking up a session for manual iteration.
---

# Catchup

Quickly load all relevant context for the current worktree so you can start iterating immediately.

## Workflow

1. **Determine the task** — derive from `basename "$PWD"` (expects `/workspaces/tony-<task>`)
2. **Read the plan** — `~/dev-in-docker-shared-files/plans/tony-<task>.md`
3. **Show git state:**
   - Current branch: `git branch --show-current`
   - Commits ahead of base: `git log --oneline origin/dev..HEAD` (or the plan's base branch)
   - Uncommitted changes: `git status --short`
4. **Check for a PR:**
   - `gh pr list --head <branch> --json number,url,state,isDraft,title -q '.[0]'`
   - If PR exists:
     - Show title, state, draft status
     - Show CI status: `gh pr checks <number>`
     - Show open comments: `gh api repos/{owner}/{repo}/pulls/<number>/comments --jq '[.[] | {user: .user.login, body: .body[:100], path: .path, line: .line}]'`
     - Show issue-level comments: `gh api repos/{owner}/{repo}/issues/<number>/comments --jq '[.[] | {user: .user.login, body: .body[:100]}]'`
     - Show review status: `gh pr view <number> --json reviewDecision -q '.reviewDecision'`
5. **Present a summary** — concise, scannable:
   ```
   ## Task: tony-<task>
   **Plan:** <one-line summary from plan>
   **Branch:** <branch> (<N> commits ahead of <base>)
   **PR:** #<number> — <state> <draft?> <CI status>
   **Reviews:** <decision or pending>
   **Comments:** <count> open
   
   ### Key files changed
   <list from git diff --stat>
   
   ### Open comments
   <formatted list>
   
   ### CI failures (if any)
   <failed check names>
   ```
6. **Ask:** "What would you like to do?" — then follow the user's direction

## Rules

- If no plan file exists, still proceed with git/PR info — the user may have manually started work
- If no PR exists, skip PR-related sections
- Keep the summary scannable — no walls of text
- Don't take any action beyond reading and presenting — wait for the user's instruction
- This skill is for orientation, not automation
