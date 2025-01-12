#!/bin/bash

STATE="$(echo "$INFO" | jq -r '.state')"
echo $STATE
if [ "$STATE" = "playing" ]; then
    MEDIA="$(echo "$INFO" | jq -r '.title + " - " + .artist')"
    sketchybar --set $NAME label="􀊄 $MEDIA" drawing=on
elif [ "$STATE" = "paused" ]; then
    MEDIA="$(echo "$INFO" | jq -r '.title + " - " + .artist')"
    sketchybar --set $NAME label="􀊆 $MEDIA" drawing=on
else
    sketchybar --set $NAME drawing=off
fi

