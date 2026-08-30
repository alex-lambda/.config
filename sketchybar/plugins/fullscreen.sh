#!/bin/sh

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
CONFIG_DIR=${CONFIG_DIR:-$(CDPATH= cd "$SCRIPT_DIR/.." && pwd -P)}
# shellcheck source=../config/palette.sh
. "$CONFIG_DIR/config/palette.sh"

# SketchyBar's show_in_fullscreen=off setting handles native full-screen spaces
# without conflating them with AeroSpace's maximized/fullscreen layout mode.
# The battery helper emits this custom event with ACTIVE=on while its native
# menu is presented and ACTIVE=off on every dismissal path.
[ "${SENDER:-}" = battery_menu_state ] || exit 0

menu_state=${ACTIVE:-${STATE:-${INFO:-off}}}
case $menu_state in
  1|on|true|open) border_color=$LAVENDER ;;
  *) border_color=$SURFACE0 ;;
esac
sketchybar_command=${SKETCHYBAR:-sketchybar}
"$sketchybar_command" --set battery background.border_color="$border_color"
