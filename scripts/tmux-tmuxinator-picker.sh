#!/usr/bin/env bash
# tmux-tmuxinator-picker.sh — fzf picker that reuses existing sessions
set -euo pipefail

TMUXINATOR=/home/linuxbrew/.linuxbrew/bin/tmuxinator
FZF=/home/linuxbrew/.linuxbrew/bin/fzf
CONFIG_DIR="${HOME}/.config/tmuxinator"

# Pick a project
project=$($TMUXINATOR list -n | tail -n +2 | $FZF --prompt="tmuxinator> ") || exit 0

# Extract session name from the yml
yml="${CONFIG_DIR}/${project}.yml"
if [[ -f "$yml" ]]; then
  session_name=$(grep '^name:' "$yml" | head -1 | sed 's/^name: *//; s/^"//; s/"$//')
else
  session_name="$project"
fi

# If session already exists, switch to it; otherwise start fresh
if tmux has-session -t "=$session_name" 2>/dev/null; then
  tmux switch-client -t "=$session_name"
else
  $TMUXINATOR start "$project"
fi
