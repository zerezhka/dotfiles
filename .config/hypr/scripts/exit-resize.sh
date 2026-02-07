#!/bin/bash
rm -f $HOME/.cache/hypr_resize_mode
hyprctl keyword "general:col.active_border" "rgb(268bd2)"
hyprctl keyword "general:col.inactive_border" "rgb(073642)"
hyprctl dispatch submap reset
