#!/bin/bash

COLOR=$TEAL

sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item space.$sid left \
               --subscribe space.$sid aerospace_workspace_change \
               --set space.$sid background.drawing=off \
                                background.color=$COLOR \
                                background.corner_radius=30 \
                                label="$sid" \
                                label.padding_left=8 \
                                label.padding_right=8 \
                                icon.drawing=off \
                                click_script="aerospace workspace $sid" \
                                script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done

# consolidate space numbers and add a background
sketchybar --add bracket spaces '/space\..*/'                  \
           --set         spaces background.border_color=$COLOR \
                                blur_radius=2                  \
                                background.height=30
