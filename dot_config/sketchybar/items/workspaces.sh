#!/bin/bash

COLOR=$PINK

sketchybar --add event aerospace_workspace_change

MONITORS=$(aerospace list-monitors --format "%{monitor-id} %{monitor-appkit-nsscreen-screens-id}")

IFS=$'\n'

for line in $(echo "$MONITORS"); do
    spaces=()
    aerospace_id=$(echo "$line" | awk '{print $1}')
    sketchybar_id=$(echo "$line" | awk '{print $2}')
    for sid in $(aerospace list-workspaces --monitor "$aerospace_id"); do
        spaces+=(space."$sid")
        sketchybar --add item space.$sid left \
                   --subscribe space.$sid aerospace_workspace_change \
                                          space_windows_change \
                   --set space.$sid background.drawing=off \
                                    display="$sketchybar_id" \
                                    icon="$sid" \
                                    icon.padding_left=8 \
                                    icon.padding_right=8 \
                                    click_script="aerospace workspace $sid" \
                                    script="$CONFIG_DIR/plugins/aerospace.sh $sid $COLOR"
    done
    # consolidate space numbers and add a background
    sketchybar --add bracket spaces."$sketchybar_id" "${spaces[@]}"                 \
               --set         spaces."$sketchybar_id" background.border_color=$COLOR \
                                    blur_radius=2                       \
                                    background.height=30

done
