#!/bin/sh

# SB-003 owns the samplers. These stable paths and cadences are ready for it.
"$SKETCHYBAR" --add item ram right \
  --set ram \
    icon.drawing=off \
    label="RAM --%" \
    label.font="$MONO_FONT" \
    label.padding_left=4 \
    label.padding_right=8 \
    update_freq=2 \
    script="$PLUGIN_DIR/ram.sh"

"$SKETCHYBAR" --add item cpu right \
  --set cpu \
    icon.drawing=off \
    label="CPU --%" \
    label.font="$MONO_FONT" \
    label.padding_left=8 \
    label.padding_right=4 \
    update_freq=2 \
    script="$PLUGIN_DIR/cpu.sh"

"$SKETCHYBAR" --add bracket metrics cpu ram \
  --set metrics \
    background.drawing=on \
    background.color="$MODULE_BASE" \
    background.corner_radius=8 \
    background.height=24 \
    background.border_width=1 \
    background.border_color="$SURFACE0" \
    background.shadow.drawing=off
