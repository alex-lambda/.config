#!/bin/sh

# front_app_switched supplies the display name in INFO. Keep the item strictly
# informational: this script only changes its dynamically sized label.
if [ "${SENDER:-}" = "front_app_switched" ] && [ -n "${INFO:-}" ]; then
  sketchybar --set "${NAME:-front_app}" label="$INFO"
fi
