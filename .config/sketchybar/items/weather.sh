#!/bin/bash

COLOR=$YELLOW

sketchybar --add item weather right \
           --set weather script="$PLUGIN_DIR/weather.sh" \
                         update_freq=60 \
                         icon.color=$COLOR \
                         background.border_color=$COLOR
