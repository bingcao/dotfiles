#!/bin/bash

COLOR=$PURPLE

sketchybar --add item calendar right \
           --set calendar icon=􀐫  \
                          icon.color=$COLOR \
                          background.border_color=$COLOR \
                          update_freq=1 \
                          script="$PLUGIN_DIR/calendar.sh"
