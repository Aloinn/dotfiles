#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

if [ "$SENDER" = "front_app_switched" ]; then
  CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces | @sh')"
  while read -r line
    echo "HI"
  do
  # sketchybar --set $NAME.$SPACE label="$INFO" icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$INFO")"
fi

# CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces | @sh')"
# args=()
# while read -r line
# do
#   for space in $line
#   do
#     # icon_strip=" "
#     #  
#     # if [ "$apps" != "" ]; then
#     #   while IFS= read -r app; do
#     #     icon_strip+=" $(__icon_map('Code'))"
#     #   done <<< "$apps"
#     # fi
#     args+=(--set space.$space label="$(__icon_map('Code')" label.drawing=on)
#   done
# done <<< "$CURRENT_SPACES"