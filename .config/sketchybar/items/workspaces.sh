#!/bin/bash

COLOR=$PINK

sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item space.$sid left \
               --subscribe space.$sid aerospace_workspace_change \
                                      space_windows_change \
               --set space.$sid background.drawing=off \
                                icon="$sid" \
                                icon.padding_left=8 \
                                icon.padding_right=8 \
                                click_script="aerospace workspace $sid" \
                                script="$CONFIG_DIR/plugins/aerospace.sh $sid $COLOR"
done

# consolidate space numbers and add a background
sketchybar --add bracket spaces '/space\..*/'                  \
           --set         spaces background.border_color=$COLOR \
                                blur_radius=2                  \
                                background.height=30
