#!/usr/bin/env bash
# tmux-select-output.sh
# Select the last command input + output: from the previous prompt line
# through the last line before the current prompt.
# Works on local (p10k) and remote hosts by detecting the actual prompt.

pane_id="${1:-}"
[ -z "$pane_id" ] && pane_id=$(tmux display-message -p '#{pane_id}')

# Capture last 500 lines of scrollback + visible
content=$(tmux capture-pane -t "$pane_id" -p -S -500)

# Find the last non-empty line — this is the current prompt
last_line=$(echo "$content" | tac | grep -m1 '.')

if [ -z "$last_line" ]; then
  tmux display-message "No content in pane"
  exit 1
fi

# Strategy: use the entire last line (trimmed) as the literal search string.
# This works because the current prompt is empty (no command typed yet),
# so every occurrence of this exact string is a prompt line.
# Trim trailing whitespace for cleaner matching.
prompt_match=$(echo "$last_line" | sed 's/[[:space:]]*$//')

if [ -z "$prompt_match" ]; then
  tmux display-message "Empty prompt line"
  exit 1
fi

# Find all lines matching the prompt literally
mapfile -t prompt_lines < <(echo "$content" | grep -nF "$prompt_match" | cut -d: -f1)

count=${#prompt_lines[@]}
if [ "$count" -lt 2 ]; then
  # Fallback: try matching just the last 20 chars (handles cases where
  # prompt has variable-width left segments like git branch, time, etc.)
  short_match="${prompt_match: -20}"
  if [ ${#short_match} -ge 3 ]; then
    mapfile -t prompt_lines < <(echo "$content" | grep -nF "$short_match" | cut -d: -f1)
    count=${#prompt_lines[@]}
  fi
fi

if [ "$count" -lt 2 ]; then
  tmux display-message "Only found ${count} prompt(s) for: ${prompt_match:0:30}..."
  exit 1
fi

# prev_prompt = the prompt line where the command was typed (select FROM here)
# last_prompt = current empty prompt (select TO the line before this)
last_prompt=${prompt_lines[$((count - 1))]}
prev_prompt=${prompt_lines[$((count - 2))]}

select_start=$prev_prompt
select_end=$((last_prompt - 1))

if [ "$select_start" -gt "$select_end" ]; then
  tmux display-message "No output between prompts"
  exit 1
fi

total_lines=$(echo "$content" | wc -l)

# Lines from bottom of capture to target positions
up_to_end=$((total_lines - select_end))
select_lines=$((select_end - select_start))

# Enter copy mode from a known position (bottom)
tmux copy-mode -t "$pane_id"
tmux send-keys -t "$pane_id" -X cancel
tmux copy-mode -t "$pane_id"

# Move up to the last line of output
if [ "$up_to_end" -gt 0 ]; then
  tmux send-keys -t "$pane_id" -X -N "$up_to_end" cursor-up
fi
tmux send-keys -t "$pane_id" -X end-of-line
tmux send-keys -t "$pane_id" -X begin-selection

# Select up to the prompt line (inclusive — includes the command itself)
if [ "$select_lines" -gt 0 ]; then
  tmux send-keys -t "$pane_id" -X -N "$select_lines" cursor-up
fi
tmux send-keys -t "$pane_id" -X start-of-line
