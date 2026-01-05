#!/bin/bash
# Get the focused workspace on HDMI-A-1
current_ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.output=="HDMI-A-1" and .visible==true) | .name')
# Focus that workspace
swaymsg workspace "$current_ws"
# Launch rofi
rofi -show drun
