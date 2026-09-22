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
2. **Read the current state** of the relevant files in the chezmoi source directory (`~/dotfiles`):
   - `dot_claude/settings.json` — permissions and hooks
   - `dot_claude/agents/` — agent definitions
   - `dot_claude/skills/` — skill definitions
   - `dot_local/bin/` — helper scripts (prefixed with `executable_`)
   - `dot_config/zsh/custom.zsh.tmpl` — shell config (chezmoi template)
   - `.chezmoi.toml.tmpl` — chezmoi data prompts
   - `.chezmoiignore` — platform/environment conditional file skipping
3. **Propose changes** — present a summary of what you'd add, modify, or create:
   - For each change, explain what triggered it (quote the relevant moment from the conversation)
   - Categorize as: new skill, new command, instruction update, agent update, new script, or permission addition
4. **Ask for confirmation** before making any changes
5. **Apply the approved changes**

## Rules

- Only propose changes that are generalizable to future conversations — not one-off fixes
- Prefer updating existing files over creating new ones
- Keep instructions concise — rules should be scannable, not paragraphs
- New skills need a directory with `SKILL.md` inside it under `dot_claude/skills/`
- New agents are single `.md` files in `dot_claude/agents/`
- New bin scripts go in `dot_local/bin/` with the `executable_` prefix (chezmoi convention)
- Files needing chezmoi template variables use `.tmpl` suffix
- All changes go in the chezmoi source (`~/dotfiles`), not the deployed paths — run `chezmoi apply` to deploy
- If nothing worth extracting exists in the conversation, say so — don't force changes
