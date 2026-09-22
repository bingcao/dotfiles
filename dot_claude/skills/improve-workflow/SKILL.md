---
name: improve-workflow
description: Review the current conversation for opportunities to improve existing skills, agents, commands, or settings. Edits the dotfiles repo directly and deploys via chezmoi.
---

# Improve Workflow

Review the current conversation and extract opportunities to improve or extend the AI workflow configuration. All configuration lives in the chezmoi source directory — edit there, then deploy.

Resolve the source directory once at the start:
```
DOTFILES="$(chezmoi source-path)"
```

## What to look for

- Repeated corrections or guidance that should become a rule in instructions
- Multi-step processes that could be automated as a new skill or command
- Existing skills/agents that behaved incorrectly or could be improved based on what happened
- Feedback about agent behavior that should be codified
- New aliases, shell functions, or conventions worth persisting
- **Commands that Claude requested permission for** — add to allowed permissions in settings

## Workflow

1. **Analyze the conversation** for any of the patterns above
2. **Read the relevant source files** in `$DOTFILES`:
   - `dot_claude/settings.json` — permissions, hooks, model
   - `dot_claude/agents/*.md` — agent definitions
   - `dot_claude/skills/*/SKILL.md` — skill definitions
   - `dot_local/bin/executable_*` — bin scripts
   - `dot_config/zsh/custom.zsh.tmpl` — shell config
   - `.chezmoiignore` — platform/environment conditional skipping
3. **Propose changes** — for each, explain:
   - What triggered it (quote the relevant moment)
   - Category: new skill, new command, agent update, settings change, shell config, or permission addition
4. **Ask for confirmation** before making any changes
5. **Apply approved changes:**
   - Edit files in `$DOTFILES`
   - Commit: `git -C $DOTFILES add -A && git -C $DOTFILES commit -m "<description>"`
   - Deploy: `chezmoi apply --source $DOTFILES`
6. **Verify** — spot-check that the deployed files match expectations (e.g. `cat ~/.claude/settings.json`)

## Chezmoi conventions

| What | Where in `$DOTFILES` | Deploys to |
|---|---|---|
| Agent | `dot_claude/agents/<name>.md` | `~/.claude/agents/<name>.md` |
| Skill | `dot_claude/skills/<name>/SKILL.md` | `~/.claude/skills/<name>/SKILL.md` |
| Bin script | `dot_local/bin/executable_<name>` | `~/.local/bin/<name>` (executable) |
| Shell config | `dot_config/zsh/custom.zsh.tmpl` | `~/.config/zsh/custom.zsh` |
| Settings | `dot_claude/settings.json` | `~/.claude/settings.json` |

- `dot_` prefix → `.` in target path
- `executable_` prefix → stripped, file gets +x
- `.tmpl` suffix → processed as a Go template with chezmoi data (name, email, is_work, branch_prefix)
- macOS-only files → add to `.chezmoiignore` under the `{{ if ne .chezmoi.os "darwin" }}` block
- work-only logic → use `{{ if .is_work }}` in `.tmpl` files

## Rules

- Only propose changes that are generalizable — not one-off fixes
- Prefer updating existing files over creating new ones
- Keep instructions concise — scannable, not paragraphs
- Always edit `$DOTFILES`, never the deployed paths directly
- Always commit after changes so they aren't lost
- Always run `chezmoi apply` so changes take effect in the current session
- If nothing worth extracting exists in the conversation, say so — don't force changes
