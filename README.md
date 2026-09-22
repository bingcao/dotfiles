## Installation

### First time setup

**Prerequisites:** `git` and `curl` must be available:
```
apt-get update && apt-get install -y git curl
```

**1. Install chezmoi and apply dotfiles:**

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply bingcao/dotfiles
```

You'll be prompted for:
- **Your full name** — used in git config
- **Your git email** — used in git config
- **Is this a work machine** — enables work-specific shell config
- **Git branch prefix** — prepended to branches in lazygit (leave empty for none)

**2. Start zsh:**

```
zsh
```

To make zsh your default shell:

```
chsh -s $(which zsh)
```

**3. Install tmux plugins** (first time opening tmux):

Press `prefix + I` (Ctrl-b then Shift-i) to install tmux plugins via tpm.

### From a local clone

```
chezmoi init --apply --source ~/dotfiles
```

### Updating

After pulling changes to the dotfiles repo:

```
chezmoi apply
```

### What gets installed

**CLI tools:** zsh, neovim, tmux, fzf, eza, bat, zoxide, yazi, lazygit, delta, oh-my-posh, jq, Claude Code

**macOS desktop:** Ghostty, AeroSpace, SketchyBar, borders

**Configs:** zsh, neovim, tmux, ghostty, aerospace, sketchybar, lazygit, git, yazi, oh-my-posh

**Commands** (installed to `~/.local/bin/`):
- `tw` — git worktree + tmux session manager
- `pr-watcher` — watches PRs for CI results and comments, runs Claude agents
- `workflow-status` — writes workflow status files for session picker
- `tmux-session-switcher` — fzf session picker with Claude/workflow status
- `claude-status-hook` — Claude Code hook for tmux status integration

**Claude Code** (installed to `~/.claude/`):
- Agents: implementor, spike, ci-fixer, comment-addresser
- Skills: planner, spike, spawn-ready, reap, catchup, sync-status, improve-workflow
- Hooks: tmux status integration for working/done/permission states

### Environment variables

The worktree workflow is parameterized for different environments:

| Variable | Default | Purpose |
|---|---|---|
| `WORKTREE_ROOT` | `~/worktrees` | Where git worktrees are created |
| `MAIN_TREE_ROOT` | auto-detect from git | Main repo root for worktree creation |
| `PLAN_DIR` | `~/plans` | Where plan/brief files are stored |

Set these in your `.zshrc` or container setup script to override defaults.

### Post-create hook

After `tw` creates a worktree, it runs `~/.config/tw/post-create <worktree-path>` if that file exists and is executable. Use this for environment-specific setup (copying `.env` files, running dependency install, etc.).

### Platform support

- **macOS**: Full install via Homebrew (Brewfile). Includes desktop apps (Ghostty, AeroSpace, SketchyBar).
- **Linux**: Core CLI tools installed via apt + direct downloads. Desktop apps are skipped automatically.

### Work vs personal

On `chezmoi init`, you're prompted whether this is a work machine. When `is_work = true`, zsh sources `~/.config/zsh/work.zsh` if it exists — put work-specific aliases, env vars, and tool setup there.
