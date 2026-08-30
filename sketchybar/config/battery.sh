#!/bin/sh

# SB-006 owns status parsing and menu lifecycle signaling. The shell owns the
# stable click contract and subscribes its hidden observer to menu-state events.
"$SKETCHYBAR" --add item battery right \
  --set battery \
    icon="􀛨" \
    icon.font="$ICON_FONT" \
    label="--%" \
    background.drawing=on \
    background.color="$MODULE_BASE" \
    background.corner_radius=8 \
    background.height=24 \
    background.border_width=1 \
    background.border_color="$SURFACE0" \
    background.shadow.drawing=off \
    update_freq=120 \
    script="$PLUGIN_DIR/battery.sh" \
    click_script="$HELPER_CLI show-battery-menu --item battery" \
  --subscribe battery system_woke power_source_change
