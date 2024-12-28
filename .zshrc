# Make homebrew installed apps available in path
if [ -d "/opt/homebrew/bin" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set where to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it doesn't exist
if [ ! -d "$ZINIT_HOME" ]; then
        mkdir -p "$(dirname $ZINIT_HOME)"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# Load completions
autoload -U compinit && compinit
# Recommended by docs
zinit cdreplay -q

# Use emacs key binds, most notably:
#   - Ctrl+a/Ctrl+e to go to beginning/end of file
#   - Ctrl+f/Ctrl+b to go forwards/backwards
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Make completions ignore casing
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# Make completions use colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Make completions use fzf to preview
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always $realpath'
zstyle ':fzf-tab:complete:eza:*' fzf-preview 'eza --tree --level=2 --color=always $realpath'

# Aliases
alias vim="nvim"
alias cat="bat"
alias ls="eza --color=always --long --git --icons=always --no-user --no-filesize --no-permissions --no-time --all"

# Setup fzf
eval "$(fzf --zsh)"

# Preview files on Ctrl+t
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"

# Better previews when using **TAB
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in 
    cd)           fzf --preview 'eza --tree --color=always --level=2 {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo' '$'{}" "$@" ;;
    *)            fzf --preview 'bat -n --color=always --line-range :500 {}' "$@" ;;
  esac
}

# Setup zoxide
eval "$(zoxide init --cmd cd zsh)"

# Setup and use oh-my-posh
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/config.toml)"
