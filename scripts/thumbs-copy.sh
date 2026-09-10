#!/bin/bash
# tmux-thumbs clipboard helper: sets tmux buffer + emits OSC 52 for kitty
TEXT="$1"
tmux set-buffer -- "$TEXT"
B64=$(echo -n "$TEXT" | base64 | tr -d '\n')
TTY=$(tmux display-message -p '#{client_tty}')
printf "\033]52;c;%s\a" "$B64" > "$TTY"
