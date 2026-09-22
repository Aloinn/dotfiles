#!/usr/bin/env bash
# tmux-select-output.sh
# Select the last command + output: from after the prompt character on the
# previous prompt line through the last line before the current prompt.
# Works on local (p10k with ) and remote hosts (hostname% style).

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

# Use the entire last line (trimmed) as the literal search string
prompt_match=$(echo "$last_line" | sed 's/[[:space:]]*$//')

if [ -z "$prompt_match" ]; then
  tmux display-message "Empty prompt line"
  exit 1
fi

# Find all lines containing the prompt literally
mapfile -t prompt_lines < <(echo "$content" | grep -nF "$prompt_match" | cut -d: -f1)

count=${#prompt_lines[@]}
if [ "$count" -lt 2 ]; then
  # Fallback: try last 20 chars
  short_match="${prompt_match: -20}"
  if [ ${#short_match} -ge 3 ]; then
    mapfile -t prompt_lines < <(echo "$content" | grep -nF "$short_match" | cut -d: -f1)
    count=${#prompt_lines[@]}
  fi
fi

if [ "$count" -lt 2 ]; then
  tmux display-message "Only found ${count} prompt(s)"
  exit 1
fi

last_prompt=${prompt_lines[$((count - 1))]}
prev_prompt=${prompt_lines[$((count - 2))]}

# The previous prompt line has the command typed after it.
# We want to select starting from the command text (after the prompt chars),
# not the prompt decoration itself.
# Output ends at last_prompt - 1.
select_start=$prev_prompt
select_end=$((last_prompt - 1))

if [ "$select_start" -gt "$select_end" ]; then
  tmux display-message "No output between prompts"
  exit 1
fi

total_lines=$(echo "$content" | wc -l)
up_to_end=$((total_lines - select_end))
select_lines=$((select_end - select_start))

# Get the prev_prompt line content to find where the command starts
prev_line=$(echo "$content" | sed -n "${prev_prompt}p")

# Find the column position after the prompt match text.
# The prev_prompt line = prompt_match + command_text
# So the command starts at position len(prompt_match) + 1
prompt_len=${#prompt_match}

# Enter copy mode
tmux copy-mode -t "$pane_id"
tmux send-keys -t "$pane_id" -X cancel
tmux copy-mode -t "$pane_id"

# Move up to the last line of output
if [ "$up_to_end" -gt 0 ]; then
  tmux send-keys -t "$pane_id" -X -N "$up_to_end" cursor-up
fi
tmux send-keys -t "$pane_id" -X end-of-line
tmux send-keys -t "$pane_id" -X begin-selection

# Select up to the command line
if [ "$select_lines" -gt 0 ]; then
  tmux send-keys -t "$pane_id" -X -N "$select_lines" cursor-up
fi

# Position cursor after the prompt text (at start of command)
tmux send-keys -t "$pane_id" -X start-of-line
if [ "$prompt_len" -gt 0 ]; then
  tmux send-keys -t "$pane_id" -X -N "$prompt_len" cursor-right
fi
