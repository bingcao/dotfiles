## Installation

### One-command setup (macOS)

```
git clone git@github.com:bingcao/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

This will:
1. Install all packages via Homebrew (Brewfile)
2. Symlink configs to `$HOME` via GNU Stow
3. Install zinit and tmux plugin manager

### Link-only (skip package installation)

```
cd ~/dotfiles
./install.sh --link
```

### What gets installed

**CLI tools:** neovim, tmux, fzf, eza, bat, zoxide, yazi, lazygit, delta, oh-my-posh, jq

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
