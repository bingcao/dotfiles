#!/bin/bash

STATE="$(echo "$INFO" | jq -r '.state')"
MEDIA="$(echo "$INFO" | jq -r '.title + " - " + .artist')"
APP="$(echo "$INFO" | jq -r '.app')"
if [ "$STATE" = "playing" ]; then
    sketchybar --set $NAME icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$APP")" label="$MEDIA" drawing=on
elif [ "$STATE" = "paused" ]; then
    sketchybar --set $NAME icon=􀊆 label="$MEDIA" drawing=on
else
    sketchybar --set $NAME drawing=off
fi
