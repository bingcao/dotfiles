#!/usr/bin/env bash
# tmux session switcher with fzf
# enter=switch, ctrl-r=rename, ctrl-a=new
# Shows HEAD commit message under each session name

generate_entries() {
  for session in $(tmux list-sessions -F '#{session_name}'); do
    path=$(tmux display-message -t "$session" -p '#{pane_current_path}' 2>/dev/null)
    branch=$(git -C "$path" branch --show-current 2>/dev/null || echo "")
    commit=$(git -C "$path" log --oneline -1 2>/dev/null || echo "(no git repo)")
    printf "%s\n  \033[33m%s\033[0m \033[90m%s\033[0m\0" "$session" "$branch" "$commit"
  done
}

while true; do
  output=$(generate_entries | fzf --read0 --ansi --reverse \
    --header 'enter=switch / ctrl-r=rename / ctrl-a=new' \
    --expect=ctrl-r,ctrl-a)

  # fzf exited with no output (Esc/Ctrl-C)
  [ -z "$output" ] && exit 0

  key=$(echo "$output" | head -1)
  session=$(echo "$output" | sed -n '2p')

  if [ "$key" = "ctrl-a" ]; then
    printf "Session name (empty to cancel): "
    read -r new_session
    if [ -n "$new_session" ]; then
      tmux new-session -d -s "$new_session"
      tmux switch-client -t "$new_session"
      exit 0
    fi
  elif [ "$key" = "ctrl-r" ]; then
    printf "Rename '%s' to: " "$session"
    read -r new_name
    [ -n "$new_name" ] && tmux rename-session -t "$session" "$new_name"
  elif [ -n "$session" ]; then
    tmux switch-client -t "$session"
    exit 0
  fi
done
