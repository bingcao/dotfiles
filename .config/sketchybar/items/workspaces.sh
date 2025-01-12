#!/bin/bash

sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item space.$sid left \
               --subscribe space.$sid aerospace_workspace_change \
               --set space.$sid background.drawing=off \
                                label="$sid" \
                                icon.drawing=off\
                                click_script="aerospace workspace $sid" \
                                script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done
