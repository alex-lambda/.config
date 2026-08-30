#!/bin/sh

set -- $(LC_TIME=C date '+%a %m/%d %I:%M %p')

case $4 in
  AM) period=a ;;
  PM) period=p ;;
esac

sketchybar_command=${SKETCHYBAR:-sketchybar}
"$sketchybar_command" --set "${NAME:-clock}" label="$1 $2 ${3#0}$period"
