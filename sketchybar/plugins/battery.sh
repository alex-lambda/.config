#!/bin/sh

# Keep the current label when pmset briefly fails or returns an incomplete sample.
sketchybar_command=${SKETCHYBAR:-sketchybar}
battery_state=$(/usr/bin/pmset -g batt 2>/dev/null) || exit 0
percentage=$(
  /usr/bin/printf '%s\n' "$battery_state" |
    /usr/bin/awk 'match($0, /[0-9]+%/) { value = substr($0, RSTART, RLENGTH - 1); print value; exit }'
) || exit 0

case $percentage in
  ''|*[!0-9]*) exit 0 ;;
esac
[ "$percentage" -le 100 ] || exit 0

charging=false
case $battery_state in
  *'; charging;'*) charging=true ;;
esac

if [ "$charging" = true ]; then
  icon=""
  color=${GREEN:-0xffa6e3a1}
elif [ "$percentage" -le 20 ]; then
  icon=""
  color=${RED:-0xfff38ba8}
elif [ "$percentage" -le 40 ]; then
  icon=""
  color=${TEXT:-0xffcdd6f4}
elif [ "$percentage" -le 60 ]; then
  icon=""
  color=${TEXT:-0xffcdd6f4}
elif [ "$percentage" -le 80 ]; then
  icon=""
  color=${TEXT:-0xffcdd6f4}
else
  icon=""
  color=${TEXT:-0xffcdd6f4}
fi

"$sketchybar_command" --set "${NAME:-battery}" \
  icon="$icon" \
  icon.color="$color" \
  label="${percentage}%" \
  label.color="$color"
