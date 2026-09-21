#!/usr/bin/env bash
# Dotfiles installer — one command to set up a new environment.
#
# Usage:
#   ./install.sh          # Full install (detect environment, install packages, stow)
#   ./install.sh --link   # Only stow/symlink (skip package installation)
#
# Environment support:
#   - macOS: installs via Homebrew (full desktop + CLI tools)
#   - Linux: installs core CLI tools only (no desktop apps)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
LINK_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --link) LINK_ONLY=true ;;
    --help|-h)
      echo "Usage: ./install.sh [--link]"
      echo "  --link    Only create symlinks (skip package installation)"
      exit 0
      ;;
  esac
done

info()  { printf '\033[34m[install]\033[0m %s\n' "$1"; }
ok()    { printf '\033[32m[install]\033[0m %s\n' "$1"; }
warn()  { printf '\033[33m[install]\033[0m %s\n' "$1"; }
error() { printf '\033[31m[install]\033[0m %s\n' "$1"; }

# --- Phase 1: Detect environment ---

OS="$(uname -s)"
info "Detected OS: $OS"

# --- Phase 2: Install packages ---

if [ "$LINK_ONLY" = false ]; then
  if [ "$OS" = "Darwin" ]; then
    # macOS: use Homebrew
    if ! command -v brew &>/dev/null; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    info "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock
    ok "Packages installed."

  elif [ "$OS" = "Linux" ]; then
    warn "Linux detected — skipping package installation."
    warn "Install these manually if needed: nvim, tmux, fzf, eza, bat, zoxide, yazi, lazygit, delta, jq, stow"
  fi

  # Install stow if not present
  if ! command -v stow &>/dev/null; then
    error "GNU Stow is required but not installed."
    error "  macOS: brew install stow"
    error "  Ubuntu/Debian: apt install stow"
    exit 1
  fi
fi

# --- Phase 3: Stow dotfiles ---

info "Linking dotfiles with stow..."
cd "$DOTFILES_DIR"
stow . --target="$HOME" --restow --verbose=1 2>&1 | grep -v "^$" || true
ok "Dotfiles linked."

# --- Phase 4: Post-install setup ---

# Create plan directory
mkdir -p "${PLAN_DIR:-$HOME/plans}"

# Create worktree root
mkdir -p "${WORKTREE_ROOT:-$HOME/worktrees}"

# Ensure zinit is installed
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  info "Installing zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  ok "Zinit installed."
fi

# Ensure tpm (tmux plugin manager) is installed
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  info "Installing tmux plugin manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ok "TPM installed. Run 'prefix + I' in tmux to install plugins."
fi

# --- Phase 5: Reminders ---

echo ""
ok "Done! Next steps:"
echo "  1. Restart your shell or run: source ~/.zshrc"
echo "  2. Open tmux and press Prefix+I to install tmux plugins"
echo "  3. Open nvim and run :Lazy sync, then :Mason"

if [ "$OS" = "Darwin" ] && [ ! -f "$HOME/.config/sketchybar/plugins/weather.env.sh" ]; then
  echo ""
  warn "Sketchybar weather needs a config file:"
  echo "  Create ~/.config/sketchybar/plugins/weather.env.sh with:"
  echo '    KEY="your-weatherapi-key"'
  echo '    CITY="your-city"'
fi

if [ -n "${MAIN_TREE_ROOT:-}" ] || [ -n "${WORKTREE_ROOT:-}" ]; then
  echo ""
  info "Worktree env vars detected:"
  [ -n "${MAIN_TREE_ROOT:-}" ] && echo "  MAIN_TREE_ROOT=$MAIN_TREE_ROOT"
  [ -n "${WORKTREE_ROOT:-}" ] && echo "  WORKTREE_ROOT=$WORKTREE_ROOT"
fi
