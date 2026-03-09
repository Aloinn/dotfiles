#!/bin/bash

KITTY_TITLE="floating"

# Get window ID of the kitty window with title "floating"
WIN_ID=$(yabai -m query --windows | jq -r '.[] | select(.app == "kitty" and .title == "FLOATING") | .id')

if [ -z "$WIN_ID" ]; then
  # No window exists, launch kitty with custom title
  kitty --title "$KITTY_TITLE" &
  sleep 0.5  # Give it time to launch
  WIN_ID=$(yabai -m query --windows | jq -r \
    --arg title "$KITTY_TITLE" \
    '.[] | select(.app == "kitty" and .title == $title) | .id')
fi

# Float it and focus
if [ -n "$WIN_ID" ]; then
  yabai -m window --focus "$WIN_ID"
  # yabai -m window --grid 4:4:1:1:2:2
  yabai -m window --layer top
  yabai -m window --toggle float
fi

