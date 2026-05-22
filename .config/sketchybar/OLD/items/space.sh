#!/bin/zsh

sketchybar --add item space left \
           --set space       background.color=$WHITE \
                                 icon.color=$BAR_COLOR \
                                 icon.font="sketchybar-app-font:Regular:16.0" \
                                 label.color=$BAR_COLOR \
                                 script="$PLUGIN_DIR/space.sh"            \
           --subscribe space front_app_switched