#!/bin/sh

AEROSPACE_BIN="$(command -v aerospace 2>/dev/null || true)"
workspace_frequency=0
workspace_click=

if [ -n "$AEROSPACE_BIN" ]; then
  workspace_frequency=5
fi

add_workspace() {
  workspace=$1
  if [ -n "$AEROSPACE_BIN" ]; then
    workspace_click="'$AEROSPACE_BIN' workspace '$workspace'"
  else
    workspace_click=
  fi

  "$SKETCHYBAR" --add item "workspace.$workspace" left \
    --set "workspace.$workspace" \
      drawing=off \
      icon="$workspace" \
      icon.font="MesloLGS Nerd Font:Bold:12.0" \
      icon.padding_left=7 \
      icon.padding_right=7 \
      label.drawing=off \
      label.font="MesloLGS Nerd Font:Regular:12.0" \
      label.y_offset=0 \
      label.padding_left=0 \
      label.padding_right=7 \
      background.drawing=on \
      background.color="$SURFACE0" \
      background.corner_radius=6 \
      background.height=20 \
      background.border_width=0 \
      update_freq="$workspace_frequency" \
      script="$PLUGIN_DIR/aerospace_workspace.sh" \
      click_script="$workspace_click" \
    --subscribe "workspace.$workspace" aerospace_workspace_change
}

for workspace_name in 1 2 3 4 5 6 7 8 9; do
  add_workspace "$workspace_name"
done

"$SKETCHYBAR" --add bracket workspaces \
    workspace.1 workspace.2 workspace.3 workspace.4 workspace.5 workspace.6 \
    workspace.7 workspace.8 workspace.9 \
  --set workspaces \
    drawing=off \
    background.drawing=on \
    background.color="$MODULE_BASE" \
    background.corner_radius=8 \
    background.height=24 \
    background.border_width=1 \
    background.border_color="$SURFACE0" \
    background.shadow.drawing=off

if [ -n "$AEROSPACE_BIN" ]; then
  "$SKETCHYBAR" --set workspaces drawing=on
fi
