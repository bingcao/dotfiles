---
name: improve-workflow
description: Review the current conversation for opportunities to improve existing skills, instructions, or agents — or add new ones. Proposes changes to the bench-dotfiles repo, installs them, and runs the container setup command.
---

# Improve Workflow

Review the current conversation and extract opportunities to improve or extend the AI workflow configuration. Look for patterns that suggest updates to skills, instructions, agents, or commands.

## What to look for

- Repeated corrections or guidance that should become a rule in `aurelia-instructions.md`
- Multi-step processes that could be automated as a new skill or command
- Existing skills/agents that behaved incorrectly or could be improved based on what happened
- New aliases, dev commands, or conventions that should be documented
- Feedback about agent behavior that should be codified
- **Commands that Claude requested permission for** — these should be added to allowed permissions in settings, or documented as safe commands in instructions

## Workflow

1. **Analyze the conversation** for any of the patterns above
2. **Read the current state** of the relevant files in `/home/aurelia/bench-dotfiles/ai/users/tony/`:
   - `aurelia-instructions.md` — always-on instructions
   - `claude-agents/` — agent definitions
   - `claude-skills/` — skill definitions
   - `scripts/` — helper scripts
3. **Propose changes** — present a summary of what you'd add, modify, or create:
   - For each change, explain what triggered it (quote the relevant moment from the conversation)
   - Categorize as: new skill, new command, instruction update, agent update, new script, or permission addition
4. **Ask for confirmation** before making any changes
5. **Apply the approved changes** to files in `/home/aurelia/bench-dotfiles/ai/users/tony/`
6. **Run the install script and its output command:**
   ```
   cd /home/aurelia/bench-dotfiles/ai && ./install.sh
   ```
   Then run whatever container setup command the install script outputs (typically `bash ~/dev-in-docker-shared-files/dotfiles-install/setup-finish.sh`). Do not ask — just run it.

## Rules

- Only propose changes that are generalizable to future conversations — not one-off fixes
- Prefer updating existing files over creating new ones
- Keep instructions concise — rules should be scannable, not paragraphs
- New skills need a directory with `SKILL.md` inside it
- New agents are single `.md` files in `claude-agents/`
- If nothing worth extracting exists in the conversation, say so — don't force changes
- If any changes affect skills, agents, or infrastructure, update `README.md` in this directory to keep it in sync
