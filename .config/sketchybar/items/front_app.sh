#!/bin/bash

COLOR=$PINK

sketchybar --add item front_app q \
           --set front_app icon.font="sketchybar-app-font:Regular:16.0" \
                           icon.color=$COLOR \
                           background.border_color=$COLOR \
                           script="$PLUGIN_DIR/front_app.sh" \
           --subscribe front_app front_app_switched
