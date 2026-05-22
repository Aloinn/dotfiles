CONFIG_DIR=~/.config/sketchybar/

source "$CONFIG_DIR/colors.sh"

CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces | @sh')"
args=()
while read -r line
do
    for space in $line
    do
    echo $space
    APPS=$(yabai -m query --windows --space $space | jq -r ".[].app")
    declare -i appI=0
    APPSPACES=" "
    while AA= read -r APP;
    do
        # echo $APP
        # for APP= APPNAME in $line2
        # do
        # echo "${CONFIG_DIR}/plugins/icon_map_fn.sh ${APP}"

        A=$($CONFIG_DIR/plugins/icon_map_fn.sh "$APP")
        APPSPACES+=$(${CONFIG_DIR}/plugins/icon_map_fn.sh ${APP})
        # appI+=1
        # done 
    done <<< "$APPS"
    sketchybar --add item $NAME.$space.number left \
             --set $NAME.$space.number label="$space" \
              --add item $NAME.$space.icons left \
              --set $NAME.$space.icons icon="$APPSPACES" \
             --add bracket $NAME.$space.bracket $NAME.$space.number $NAME.$space.icons \
             --set $NAME.$space.bracket background.color=$C_BG2 background.corner_radius=4 \
             -add item $NAME.$space.gap left \
            --add bracket $NAME.$space.outline $NAME.$space.bracket $NAME.$space.gap \
            --set $NAME.$space.outline label="HI" background.padding_left=12 background.padding_right=12

    echo $APPSPACES
    done 
done <<< "$CURRENT_SPACES"