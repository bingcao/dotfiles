---
name: spike
description: Synthesize the current conversation into a brief and spawn a lightweight spike agent to quickly implement it in a new worktree with a draft PR.
---

# Spike

This skill is invoked mid-conversation, after you have discussed the work with the user. Your job is to synthesize what's been discussed into a concise implementation brief and spawn a spike agent to quickly build it. No formal plan, no test strategy — just the key decisions.

## Workflow

1. **Summarize** the current conversation into a brief (see format below)
2. **Ask the user** for a task name (short kebab-case slug, e.g. `spike-health-check`)
3. **Ask about JIRA** — three options:
   - User provides an existing ticket ID → include it in the brief
   - User wants to create a new ticket → create one, then include the new ticket ID
   - No ticket needed → omit the JIRA section
4. **Show the brief** to the user for quick confirmation (no need for plan mode — just show it inline)
5. **On confirmation**, save the brief to `~/dev-in-docker-shared-files/plans/tony-<task-name>.md`
6. **Spawn the spike agent**:
   ```
   tw tony-<task-name> -a spike
   ```
   Use `timeout: 600000` on the Bash tool call.
7. **Report:** "Spike spawned in session `tony-<task-name>`."

## Brief Format

Write to `~/dev-in-docker-shared-files/plans/tony-<task-name>.md`:

```markdown
# <Task Title>

## Summary
What we're building and why, in 2-3 sentences.

## JIRA
- **Ticket:** `BNCH-XXXXX`

## Key Files
- `path/to/file1.ext` — what to do here
- `path/to/file2.ext` — what to do here

## Approach
- Key decision 1 (e.g. "use existing FooService, add a new method")
- Key decision 2 (e.g. "follow the pattern in bar_handler.py")
- Any constraints or gotchas worth noting

## PR Details
- **Branch:** `tony-<task-name>`
- **Title:** `<short PR title> BNCH-XXXXX`
- **Body:** `<one-line description>`
```

If there is no JIRA ticket, omit the JIRA section and the ticket suffix from the PR title.

## Rules

**Important:** Always prefix task names with `tony-` for branches, worktrees, sessions, and plan files.

**CRITICAL: After the user confirms the brief, NEVER implement it yourself.** Save the file and spawn the spike agent. That's it.

- Do NOT start new research — work from what's already been discussed
- The brief should be enough for a competent agent to figure out the implementation without asking questions
- List the key files and what changes in each, but don't prescribe line-by-line edits
- Include approach notes and patterns to follow so the spike agent matches the codebase style
- Keep it concise — this is a spike, not a spec
