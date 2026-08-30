#!/bin/sh

# SB-007 owns formatting. The clock intentionally has neither icon nor action.
"$SKETCHYBAR" --add item clock right \
  --set clock \
    icon.drawing=off \
    label="--- --/-- --:--" \
    label.font="$TEXT_FONT" \
    label.padding_left=10 \
    label.padding_right=10 \
    background.drawing=on \
    background.color="$MODULE_BASE" \
    background.corner_radius=8 \
    background.height=24 \
    background.border_width=1 \
    background.border_color="$SURFACE0" \
    background.shadow.drawing=off \
    update_freq=30 \
    script="$PLUGIN_DIR/clock.sh"
