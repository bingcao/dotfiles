---
name: improve-workflow
description: Review the current conversation for opportunities to improve existing skills, instructions, or agents — or add new ones. Proposes changes to the dotfiles repo.
---

# Improve Workflow

Review the current conversation and extract opportunities to improve or extend the AI workflow configuration. Look for patterns that suggest updates to skills, instructions, agents, or commands.

## What to look for

- Repeated corrections or guidance that should become a rule in instructions
- Multi-step processes that could be automated as a new skill or command
- Existing skills/agents that behaved incorrectly or could be improved based on what happened
- New aliases, dev commands, or conventions that should be documented
- Feedback about agent behavior that should be codified
- **Commands that Claude requested permission for** — these should be added to allowed permissions in settings

## Workflow

1. **Analyze the conversation** for any of the patterns above
2. **Read the current state** of the relevant files in the dotfiles repo (`~/.claude/` or the dotfiles source):
   - `.claude/settings.json` — permissions and hooks
   - `.claude/agents/` — agent definitions
   - `.claude/skills/` — skill definitions
   - `.local/bin/` — helper scripts
3. **Propose changes** — present a summary of what you'd add, modify, or create:
   - For each change, explain what triggered it (quote the relevant moment from the conversation)
   - Categorize as: new skill, new command, instruction update, agent update, new script, or permission addition
4. **Ask for confirmation** before making any changes
5. **Apply the approved changes**

## Rules

- Only propose changes that are generalizable to future conversations — not one-off fixes
- Prefer updating existing files over creating new ones
- Keep instructions concise — rules should be scannable, not paragraphs
- New skills need a directory with `SKILL.md` inside it
- New agents are single `.md` files in `.claude/agents/`
- If nothing worth extracting exists in the conversation, say so — don't force changes
