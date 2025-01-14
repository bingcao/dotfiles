#!/usr/bin/env bash

source colors.sh
COLOR="$2"

if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE="$(echo $(aerospace list-workspaces --focused))"
fi

args=()

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    args+=(--set $NAME background.drawing=on icon.color="$COLOR" label.color="$COLOR")
else
    args+=(--set $NAME background.drawing=off icon.color="$WHITE" label.color="$WHITE")
fi

WINDOWS=$(aerospace list-windows --workspace "$1" | awk -F '|' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
icon_strip=""
if [ ! -z "$WINDOWS" ]; then
    while read -r window; do
        icon_strip+="$($CONFIG_DIR/plugins/icon_map_fn.sh "$window")"
    done < <(echo "$WINDOWS")

    args+=(--set $NAME label="$icon_strip"
                   label.font="sketchybar-app-font:Regular:16.0"
                   label.drawing=on
     )
else
    args+=(--set $NAME label.drawing=off)
fi

sketchybar "${args[@]}"
