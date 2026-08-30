#!/bin/sh

# SB-005 owns Wi-Fi discovery and rate calculation.
"$SKETCHYBAR" --add item network right \
  --set network \
    icon="" \
    icon.font="MesloLGS Nerd Font:Regular:14.0" \
    icon.padding_left=7 \
    icon.padding_right=2 \
    label="↓ --/s ↑ --/s" \
    label.font="$MONO_FONT" \
    label.align=right \
    label.padding_left=2 \
    label.padding_right=7 \
    background.drawing=on \
    background.color="$MODULE_BASE" \
    background.corner_radius=8 \
    background.height=24 \
    background.border_width=1 \
    background.border_color="$SURFACE0" \
    background.shadow.drawing=off \
    update_freq=1 \
    script="$PLUGIN_DIR/network.sh"
