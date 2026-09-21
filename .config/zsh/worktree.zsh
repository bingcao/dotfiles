# worktree-hook.zsh - Sourced from .zshrc
# Sets AURELIA_ROOT based on current directory for worktree-aware tooling.
#
# Override WORKTREE_ROOT and MAIN_TREE_ROOT in your shell profile if
# your environment differs from the defaults.

AURELIA_WORKTREE_ROOTS=(
  '^(.*/\.cursor/worktrees/aurelia[^/]+/[^/]+)'
  "^(${WORKTREE_ROOT:-$HOME/worktrees}/[^/]+).*"
)
AURELIA_DEFAULT_ROOT="${MAIN_TREE_ROOT:-}"

function chpwd() {
  [ -z "$AURELIA_DEFAULT_ROOT" ] && return

  local new_aurelia_root="${AURELIA_DEFAULT_ROOT}"
  local pattern
  for pattern in "${AURELIA_WORKTREE_ROOTS[@]}"; do
    if [[ "$PWD" =~ "$pattern" ]]; then
      new_aurelia_root="${match[1]}"
      break
    fi
  done
  if [[ "$new_aurelia_root" != "$AURELIA_ROOT" ]]; then
    export AURELIA_ROOT="${new_aurelia_root}"
    if [[ "$new_aurelia_root" == "$AURELIA_DEFAULT_ROOT" ]]; then
      echo -e "\033[34m[ZSH Hook]\033[0m AURELIA_ROOT reset to default: \033[33m$AURELIA_ROOT\033[0m"
    else
      echo -e "\033[32m[ZSH Hook]\033[0m AURELIA_ROOT set to custom root: \033[33m$AURELIA_ROOT\033[0m"
    fi
  fi
}

# Run once at shell startup to set initial value
chpwd
