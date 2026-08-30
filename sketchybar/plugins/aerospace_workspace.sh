#!/bin/sh

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
CONFIG_DIR=${CONFIG_DIR:-$(CDPATH= cd "$SCRIPT_DIR/.." && pwd -P)}
# shellcheck source=../config/palette.sh
. "$CONFIG_DIR/config/palette.sh"

item=${NAME:-}
workspace=${item#workspace.}

if [ -z "$item" ] || [ "$workspace" = "$item" ]; then
  exit 0
fi

if ! command -v aerospace >/dev/null 2>&1; then
  sketchybar --set '/workspace\..*/' drawing=off \
             --set workspaces drawing=off
  exit 0
fi

focused_workspace=${FOCUSED_WORKSPACE:-}
if [ -z "$focused_workspace" ]; then
  focused_workspace=$(aerospace list-workspaces --focused --format '%{workspace}' 2>/dev/null | sed -n '1p')
fi

label_drawing=off
app_names=
case $workspace in
  1|2|3|4|5|6|7|8|9)
    app_names=$(
      aerospace list-windows --workspace "$workspace" --format '%{app-name}' 2>/dev/null |
        awk '
          NF && !seen[$0]++ {
            if (names != "") names = names " · "
            names = names $0
          }
          END { print names }
        '
    )
    if [ -n "$app_names" ]; then
      occupied=on
      label_drawing=on
    else
      occupied=off
    fi
    ;;
  *)
    window_count=$(aerospace list-windows --workspace "$workspace" --count 2>/dev/null) || window_count=
    case $window_count in
      ''|*[!0-9]*|0) occupied=off ;;
      *) occupied=on ;;
    esac
    ;;
esac

# AeroSpace keeps one visible workspace per monitor. Distinguish the focused
# workspace from a workspace visible on another monitor so both are legible in
# the shared workspace strip.
visible_workspace=off
if aerospace list-workspaces --monitor all --visible --format '%{workspace}' 2>/dev/null |
   grep -Fqx -- "$workspace"; then
  visible_workspace=on
fi

icon=$workspace
if [ "$workspace" = "$focused_workspace" ]; then
  drawing=on
  color=$LAVENDER
  icon_color=$BASE
  label_color=$BASE
elif [ "$visible_workspace" = on ]; then
  drawing=on
  color=$BLUE
  icon_color=$BASE
  label_color=$BASE
  icon="󰍹 $workspace"
elif [ "$occupied" = on ]; then
  drawing=on
  color=$SURFACE0
  icon_color=$TEXT
  label_color=$TEXT
else
  drawing=off
  color=$SURFACE0
  icon_color=$TEXT
  label_color=$TEXT
fi

sketchybar --set workspaces drawing=on \
           --set "$item" drawing="$drawing" \
                         icon="$icon" \
                         icon.color="$icon_color" \
                         label="$app_names" \
                         label.drawing="$label_drawing" \
                         label.color="$label_color" \
                         background.drawing=on \
                         background.color="$color"
