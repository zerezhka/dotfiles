#!/bin/bash
touch $HOME/.cache/hypr_resize_mode
hyprctl keyword "general:col.active_border" "rgb(dc322f)"
hyprctl keyword "general:col.inactive_border" "rgb(dc322f)"
sleep 0.1
hyprctl dispatch submap resize
