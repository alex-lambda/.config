#!/bin/sh

"$SKETCHYBAR" --add item front_app left \
  --set front_app \
    icon.drawing=off \
    label="Active App" \
    label.font="$TEXT_FONT" \
    label.width=dynamic \
    label.padding_left=10 \
    label.padding_right=10 \
    background.drawing=on \
    background.color="$MODULE_BASE" \
    background.corner_radius=8 \
    background.height=24 \
    background.border_width=1 \
    background.border_color="$SURFACE0" \
    background.shadow.drawing=off \
    script="$PLUGIN_DIR/front_app.sh" \
  --subscribe front_app front_app_switched
