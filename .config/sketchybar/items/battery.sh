#!/bin/bash

COLOR=$GREEN

sketchybar --add item battery right \
           --set battery update_freq=60 \
                         script="$PLUGIN_DIR/battery.sh" \
                         background.border_color=$COLOR \
                         icon.color=$COLOR \
           --subscribe battery system_woke power_source_change
