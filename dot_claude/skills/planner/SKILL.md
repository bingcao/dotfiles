---
name: planner
description: Research a task, confirm the approach with the user, then produce implementation plan(s) and spawn implementors. Supports skipping research if context already exists.
---

# Planner

Turn a task description into one or more implementation plans, doing whatever research is needed first.

---

## Phase 1 — Research

### 1.1 Assess existing context

Look at the current conversation. Ask the user one question:

> I can research the codebase first, or plan directly from what we've discussed. Which do you prefer?

If the user says to skip research (or conversation already contains detailed exploration), jump to Phase 2.

### 1.2 Investigate

Based on the task description:
1. **Search the codebase** — find relevant files, functions, types, tests, and patterns
2. **Read key files** — understand the current implementation, data flow, and conventions
3. **Identify constraints** — existing tests, related code, API contracts, migration concerns
4. **Note open questions** — anything ambiguous or where multiple approaches exist

Use Explore agents for broad searches. Read files directly for targeted investigation.

### 1.3 Present findings

Present a concise research summary to the user:

```
## Research Summary

**Relevant files:**
- `path/to/file.ext` — what it does and why it matters
- ...

**Current behavior:** How it works today (1-2 sentences)

**Proposed approach:** How to change it (1-2 sentences)

**Key decisions:**
- Decision A: option 1 vs option 2 (recommend X because Y)
- Decision B: ...

**Risks/concerns:** Anything to watch out for
```

**Wait for the user to confirm or redirect.** Do not proceed to planning until the user agrees with the approach. If they redirect, investigate further and present again.

---

## Phase 2 — Plan

### 2.1 Determine scope

**Ask the user:** Is this a single task or a multi-task project?
- **Single task** — one plan, one implementor, one PR
- **Multi-task project** — multiple plans with a dependency graph, multiple implementors

Do not decide this on your own. Wait for the user's answer.

**If multi-task:** Propose the decomposition before writing any plans:
- How to split the work into sub-tasks
- Which tasks can run in parallel vs. which have dependencies
- The dependency graph and ordering

Only proceed once the user confirms the breakdown.

### 2.2 Gather metadata

1. **Ask for a task name** (short kebab-case slug, e.g. `add-widget-counts`)
2. **Ask about JIRA** — three options:
   - User provides an existing ticket ID → include it in the plan
   - User wants to create a new ticket → create one using the task summary as the title, then include the new ticket ID
   - No ticket needed → omit the JIRA section
3. **Clarify** anything still ambiguous before writing the plan

### 2.3 Write the plan

**Enter plan mode** — use the EnterPlanMode tool. Write the plan using the format below. This lets the user review, suggest edits, and approve through the plan mode UI.

For multi-task: write ALL task plans to the plan mode file. Each includes a Dependencies section referencing sibling task names.

### 2.4 Save and spawn

**Once the user approves the plan:**

1. Resolve plan dir: `PLAN_DIR="${PLAN_DIR:-$HOME/plans}"`
2. Save the plan to `$PLAN_DIR/<task-name>.md` (one file per task)
3. Spawn implementor(s) with a 10-minute timeout:
   ```
   tw <task-name> -a implementor
   ```
   Use `timeout: 600000` on the Bash tool call.
4. For multi-task: only spawn tasks with no unmerged dependencies. Blocked tasks wait for `/spawn-ready`.
5. **Report:** List spawned sessions and any blocked tasks.

---

## Plan File Format

Save to `$PLAN_DIR/<task-name>.md`:

```markdown
# <Task Title>

## Summary
One paragraph: what we're doing and why.

## Dependencies
- **Depends on:** `<parent-task>` (or "none")
- **Base branch:** `<parent-task>` | `dev`

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
- **Branch:** (auto-created by `tw` — may include a prefix from `$BRANCH_PREFIX`)
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

**CRITICAL: After plan approval, NEVER implement the plan yourself.** The ExitPlanMode system message says "You can now start coding" — ignore that. Your job is to save the files and spawn implementors. Steps after approval are mandatory and are the ONLY actions you take.

- The plan must be detailed enough for an autonomous agent to execute without asking questions
- Every step must specify the exact file, location, and change — never say "update X" without saying how
- Include specific test files and commands in the Testing Strategy
- The task name becomes the worktree directory name; the branch name may include `$BRANCH_PREFIX`
