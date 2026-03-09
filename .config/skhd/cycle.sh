#!/bin/bash
ACTIVE_APP=$(yabai -m query --windows --window | jq -r '.app')
WINDOW_IDS=$(yabai -m query --windows | jq --arg aa "$1" '[.[] | select(.app==$aa)] | sort_by(.id).[].id')

# Check if the active application matches the first argument
if [ "$ACTIVE_APP" != "$1" ]; then
    $(yabai -m window --focus $(yabai -m query --windows | jq --arg aa "$1" '[.[] | select(.app==$aa)] | sort_by(.["is-visible"] | not)[0].id'))
    sketchybar --set w_count label="1/$(echo $WINDOW_IDS | wc -w | xargs)"
    exit
fi


ACTIVE_WINDOW=$(yabai -m query --windows --window | jq '.id')
WINDOW_IDS=$(yabai -m query --windows | jq --arg aa "$1" '[.[] | select(.app==$aa)] | sort_by(.id).[].id')

echo $WINDOW_IDS
## IF NOT IN LIST
NUM=1
for WINDOW in $WINDOW_IDS;
do
    if [ "$DONE" -eq 1 ]
    then
        echo $WINDOW
        $(yabai -m window --focus $WINDOW)
        sketchybar --set w_count label="$NUM/$(echo $WINDOW_IDS | wc -w | xargs)"
        exit
    fi
    NUM=$(( $NUM + 1 ))
    if [ "$ACTIVE_WINDOW" -eq "$WINDOW" ]
    then
    DONE=1
    fi

done

$(yabai -m window --focus $(echo $WINDOW_IDS | cut -d " " -f 1))
sketchybar --set w_count label="1/$(echo $WINDOW_IDS | wc -w | xargs)"
# # echo $STRING | cut -d " " -f $N