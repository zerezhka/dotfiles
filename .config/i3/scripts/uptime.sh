#!/bin/sh

uptime=$(uptime -p)
days=$(echo "$uptime" | grep -oP '\d+(?= day)')
hours=$(echo "$uptime" | grep -oP '\d+(?= hour)')
minutes=$(echo "$uptime" | grep -oP '\d+(?= minute)')

formatted_uptime=""
if [ -n "$days" ]; then
  formatted_uptime="${days}d "
fi
formatted_uptime="${formatted_uptime}${hours}h ${minutes}m"

echo "$formatted_uptime" > ~/.config/i3/scripts/uptimedm