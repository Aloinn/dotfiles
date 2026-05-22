CONFIG_DIR=~/.config/sketchybar/
source "$CONFIG_DIR/colors.sh"
NAME=SPACE
CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces.[]')"
while read -r line
do
    for SPACE in $line
    do
    # echo $space
    APPS=$(yabai -m query --windows --space $SPACE | jq -r ".[].app")
    declare -i APPID=0
    APPSPACES="sketchybar --add item $NAME.$SPACE.NUMBER left --set $NAME.$SPACE.NUMBER label='$SPACE' background.color=$C_BG2
             --add item $NAME.$SPACE.GAP left"
    APPBRACKETS=""
    while AA= read -r APP;
    do
        ICON=$($CONFIG_DIR/plugins/icon_map_fn.sh "$APP")
        ITEM_NAME="$NAME.$SPACE.$APPID.ICON"
        APPSPACES+=" --add item $ITEM_NAME left --set $ITEM_NAME icon=$ICON"
        APPBRACKETS+=" $ITEM_NAME"
        APPID+=1
    done <<< "$APPS"
    
    # APPSPACES+=" --add bracket $NAME.$SPACE.BRACKET $NAME.$SPACE.NUMBER $NAME.$SPACE.GAP $APPBRACKETS"
    echo $APPSPACES
    t="sketchybar --add item $NAME.$SPACE.number left --set  $NAME.$SPACE.number label='$SPACE'"
    # eval $t
    eval $APPSPACES
    # eval $APPSPACES
    # args+=( "$NAME"."$SPACE".number )
        # sketchybar --add item $NAME.$SPACE.number left \
        #      --set $NAME.$SPACE.number label="$SPACE" background.color=$C_BG2 --add item $NAME.$SPACE.gap left \ 

    
        
             
    # sketchybar --add item $NAME.$space.number left \
    #          --set $NAME.$space.number label="$space" \
    #           --add item $NAME.$space.icons left \
    #           --set $NAME.$space.icons icon="$APPSPACES" \
    #          --add bracket $NAME.$space.bracket $NAME.$space.number $NAME.$space.icons \
    #          --set $NAME.$space.bracket background.color=$C_BG2 background.corner_radius=4 \
    #         --add item $NAME.$space.spacer left
    # echo $APPSPACES
    # echo $args
    done 
done <<< "$CURRENT_SPACES"