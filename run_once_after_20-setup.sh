#!/bin/bash
set -euo pipefail

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    echo "Installing zinit..."
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

TPM_HOME="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_HOME" ]; then
    echo "Installing tmux plugin manager..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_HOME"
fi

mkdir -p "${WORKTREE_ROOT:-$HOME/worktrees}"
mkdir -p "${PLAN_DIR:-$HOME/plans}"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/tw"
