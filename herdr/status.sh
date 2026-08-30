#!/bin/sh
# Catppuccin-style status modules matching the tmux configuration.

case "${1:-}" in
  application)
    # Herdr exposes the active pane ID to status commands. Ask it for the
    # foreground process, which is the equivalent of tmux's pane_current_command.
    "${HERDR_BIN_PATH:-herdr}" pane process-info --pane "${HERDR_ACTIVE_PANE_ID:?}" 2>/dev/null |
      python3 -c '
import json
import sys

try:
    value = json.load(sys.stdin)
except (ValueError, OSError):
    raise SystemExit(0)

def find_processes(node):
    if isinstance(node, dict):
        processes = node.get("foreground_processes")
        if isinstance(processes, list):
            return processes
        for child in node.values():
            found = find_processes(child)
            if found is not None:
                return found
    elif isinstance(node, list):
        for child in node:
            found = find_processes(child)
            if found is not None:
                return found
    return None

processes = find_processes(value) or []
if processes:
    process = processes[-1]
    name = process.get("name") or process.get("argv0")
    if name:
        print(" " + name.rsplit("/", 1)[-1])
'
    ;;
  session)
    printf ' %s\n' "${HERDR_SESSION:-default}"
    ;;
  uptime)
    uptime | sed 's/^[^,]*up *//; s/, *[[:digit:]]* user.*//; s/ day.*, */d /; s/:/h /; s/ min//; s/$/m/' |
      sed 's/^/󰔟 /'
    ;;
  *)
    printf 'usage: %s {application|session|uptime}\n' "$0" >&2
    exit 2
    ;;
esac
