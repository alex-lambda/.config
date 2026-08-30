#!/bin/sh

# Keep the bar itself transparent; each visible module draws its own surface.
"$SKETCHYBAR" --bar \
  position=top \
  height=36 \
  color="$TRANSPARENT" \
  border_width=0 \
  shadow=off \
  blur_radius=0 \
  margin=0 \
  padding_left=8 \
  padding_right=8 \
  y_offset=0 \
  sticky=on \
  show_in_fullscreen=off

"$SKETCHYBAR" --default \
  drawing=on \
  updates=on \
  padding_left=3 \
  padding_right=3 \
  icon.font="$ICON_FONT" \
  icon.color="$TEXT" \
  icon.padding_left=7 \
  icon.padding_right=4 \
  label.font="$TEXT_FONT" \
  label.color="$TEXT" \
  label.padding_left=7 \
  label.padding_right=7 \
  background.drawing=off \
  background.height=24 \
  background.corner_radius=8 \
  background.border_width=1 \
  background.border_color="$SURFACE0" \
  background.shadow.drawing=off
