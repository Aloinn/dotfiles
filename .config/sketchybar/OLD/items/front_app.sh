#!/bin/zsh

sketchybar --add item front_app left \
           --set front_app       background.color=$C_CYAN \
                                 icon.padding_left=8 \
                                 label.padding_right=8 \
                                 background.corner_radius=5 \
                                 icon.color=$WHITE \
                                 label.color=$WHITE \
                                 label.font="Comic Mono:Bold:16.0" \
                                 script="$PLUGIN_DIR/front_app.sh"            \
           --subscribe front_app front_app_switched