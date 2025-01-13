#!/usr/bin/env bash

source colors.sh

if [ -z "$FOCUSED_WORKSPACE" ]; then
    FOCUSED_WORKSPACE="$(echo $(aerospace list-workspaces --focused))"
fi

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=on
else
    sketchybar --set $NAME background.drawing=off
fi
