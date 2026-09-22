#!/bin/bash

COLOR=$BLUE

sketchybar --add item volume right \
	   --set volume script="$PLUGIN_DIR/volume.sh" \
			background.border_color=$COLOR \
			icon.color=$COLOR \
	   --subscribe volume volume_change \
