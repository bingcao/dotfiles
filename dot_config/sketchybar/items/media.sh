#!/bin/bash

COLOR=$ORANGE

sketchybar --add item media q \
           --set media label.max_chars=25 \
                       icon.font="sketchybar-app-font:Regular:16.0" \
                       scroll_texts=on \
                       script="$PLUGIN_DIR/media.sh" \
                       icon.color=$ORANGE \
                       background.border_color=$ORANGE \
           --subscribe media media_change
