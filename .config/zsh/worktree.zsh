# ============================================================
# worktree.zsh - Git Worktree Setup & Shortcuts for Dev-in-Docker
# Place this file in ~/.config/zsh/worktree.zsh
# ============================================================

# --- Aurelia Root Auto-Switching ---
AURELIA_WORKTREE_ROOTS=(
  '^(.*/\.cursor/worktrees/aurelia[^/]+/[^/]+)'
  '^(/workspaces/[^/]+).*'
)
AURELIA_DEFAULT_ROOT="/src"

function chpwd() {
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
chpwd

# --- Worktree Shortcuts ---
wt-require-main-tree() {
  if ! git rev-parse --git-dir &>/dev/null; then
    echo -e "\033[31m[wt] Error:\033[0m Not inside a git repository. Please navigate to /src first."
    return 1
  fi
  if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]] && \
     [[ -n "$(git rev-parse --git-common-dir 2>/dev/null)" ]] && \
     [[ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ]]; then
    echo -e "\033[31m[wt] Error:\033[0m You are inside a worktree. Please navigate to the main tree (/src) before running this command."
    return 1
  fi
  return 0
}

wt-setup() {
  local name=$1
  cp /src/.buildkite_access_token /workspaces/$name/.buildkite_access_token
  cp /src/.env.local /workspaces/$name/.env.local
  cd /workspaces/$name
  echo n | dev setup requirements
}

wt-add() {
  wt-require-main-tree || return 1
  local name=$1
  local branch=${2:-$1}
  local start=${3:-HEAD}
  if git rev-parse --verify $branch &>/dev/null; then
    git worktree add /workspaces/$name $branch
  else
    git worktree add /workspaces/$name -b $branch $start
  fi
  wt-setup $name
}

wt-switch() {
  cd /workspaces/$1
}

wt-remove() {
  wt-require-main-tree || return 1
  git worktree remove /workspaces/$1
}

wt-list() {
  git worktree list
}

tw() {
  local name="" branch="" subdir="" agent="" base=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        echo "Usage: tw [name] [branch] [-b <base>] [-p <subdir>] [-a <agent>]"
        echo ""
        echo "Git worktree + tmux session manager."
        echo ""
        echo "Commands:"
        echo "  tw                          List worktrees and tmux sessions"
        echo "  tw <name>                   Switch to session, or create worktree + session"
        echo "  tw <name> <branch>          Create worktree from existing branch with a custom name"
        echo "  tw <name> -b <base>         Create new branch starting from base (for stacking)"
        echo "  tw <name> -a <agent>        Create worktree and launch Claude with specified agent"
        echo "  tw -d <name>                Delete worktree and kill its tmux session"
        echo ""
        echo "Options:"
        echo "  -a <agent>          Launch Claude with this agent type (auto-starts with allowed tools)"
        echo "  -b <base>           Create new branch from this base branch (for stacked PRs)"
        echo "  -p <subdir>         Start tmux windows in this subdirectory of the worktree"
        echo "  -h, --help          Show this help message"
        echo ""
        echo "When creating a new session, tw sets up four tmux windows:"
        echo "  claude  - Opens claude (or claude --agent <agent> if -a specified)"
        echo "  git     - Opens lazygit"
        echo "  nvim    - Opens neovim"
        echo "  cmd     - Empty shell"
        return 0
        ;;
      -d)
        local target="$2"
        local target_session="${target//[.\/::]/-}"
        echo "This will:"
        tmux has-session -t "$target_session" 2>/dev/null && echo "  - Kill tmux session '$target_session'"
        [[ -d "/workspaces/$target" ]] && echo "  - Remove worktree /workspaces/$target"
        git -C /src rev-parse --verify "$target" &>/dev/null && echo "  - Delete local branch '$target'"
        printf "Proceed? [y/N] "
        read -r confirm
        if [[ "$confirm" != [yY] ]]; then
          return 0
        fi
        tmux kill-session -t "$target_session" 2>/dev/null
        (cd /src && wt-remove "$target")
        git -C /src branch -D "$target"
        return $?
        ;;
      -a)
        agent="$2"
        shift 2
        ;;
      -b)
        base="$2"
        shift 2
        ;;
      -p)
        subdir="$2"
        shift 2
        ;;
      *)
        if [[ -z "$name" ]]; then
          name="$1"
        else
          branch="$1"
        fi
        shift
        ;;
    esac
  done

  local session_name="${name//[.\/::]/-}"

  # No args: list worktrees and sessions
  if [[ -z "$name" ]]; then
    echo "Worktrees:"
    wt-list
    echo "\nSessions:"
    tmux list-sessions 2>/dev/null || echo "(none)"
    return 0
  fi

  # Session already exists: just switch
  if tmux has-session -t "$session_name" 2>/dev/null; then
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$session_name"
    else
      tmux attach -t "$session_name"
    fi
    return 0
  fi

  # Worktree doesn't exist: create via wt-add
  if [[ ! -d "/workspaces/$name" ]]; then
    branch="${branch:-$name}"
    # Determine start point: use -b base branch if specified, otherwise HEAD
    local start_point
    if [[ -n "$base" ]]; then
      # Stacking: create new branch from the base branch
      start_point="$(git -C /src rev-parse "$base" 2>/dev/null || git -C /src rev-parse "origin/$base" 2>/dev/null)"
      echo -e "Creating branch \033[1;33m$branch\033[0m from \033[33m$base\033[0m"
    else
      # Check if branch exists locally or on remote
      if ! git -C /src rev-parse --verify "$branch" &>/dev/null && \
         ! git -C /src rev-parse --verify "origin/$branch" &>/dev/null; then
        local start_ref
        start_ref="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")"
        echo -e "Creating branch \033[1;33m$branch\033[0m from \033[33m$start_ref\033[0m"
      fi
      start_point="$(git rev-parse HEAD 2>/dev/null)"
    fi
    (cd /src && wt-add "$name" "$branch" "$start_point")
  fi

  # Create tmux session with window layout
  local wt_path="/workspaces/$name${subdir:+/$subdir}"
  tmux new-session -d -s "$session_name" -c "$wt_path" -n "claude"
  if [[ -n "$agent" ]]; then
    # Agent mode: 'auto' is first window, 'claude' free for manual use
    tmux rename-window -t "${session_name}" "auto"
    if [[ "$agent" == "implementor" ]]; then
      # Implementor uses the watcher for CI/comment lifecycle
      tmux send-keys -t "${session_name}:auto" "~/.config/scripts/pr-watcher.sh --implement ${session_name} ${name} ${name}" Enter
    else
      # Other agents (spike, etc.) run directly
      tmux send-keys -t "${session_name}:auto" "claude --agent $agent --allowedTools 'Bash Read Write Edit Grep Glob Skill'" Enter
      for i in {1..30}; do
        if tmux capture-pane -t "${session_name}:auto" -p 2>/dev/null | grep -qE '❯|>'; then
          break
        fi
        sleep 1
      done
      tmux send-keys -t "${session_name}:auto" "begin" Enter
    fi
    tmux new-window -t "$session_name" -n "claude" -c "$wt_path"
    tmux send-keys -t "${session_name}:claude" "claude" Enter
  else
    tmux send-keys -t "${session_name}:claude" "claude" Enter
  fi
  tmux new-window -t "$session_name" -n "git" -c "$wt_path"
  tmux send-keys -t "${session_name}:git" "lazygit" Enter
  tmux new-window -t "$session_name" -n "nvim" -c "$wt_path"
  tmux send-keys -t "${session_name}:nvim" "nvim" Enter
  tmux new-window -t "$session_name" -n "cmd" -c "$wt_path"
  tmux select-window -t "${session_name}:claude"

  if [[ -z "$agent" ]]; then
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$session_name"
    else
      tmux attach -t "$session_name"
    fi
  fi
}
