#!/bin/bash

COLOR=$RED

sketchybar --add item cpu right \
           --set cpu update_freq=2 \
                     icon=􀧓 \
                     background.border_color=$COLOR \
                     icon.color=$COLOR \
                     script="$PLUGIN_DIR/cpu.sh"
