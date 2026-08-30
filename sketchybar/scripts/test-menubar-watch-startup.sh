#!/bin/sh
set -eu

CONFIG_DIR=$(CDPATH= cd "$(dirname "$0")/.." && pwd -P)
sandbox=$(mktemp -d)
watcher_pid=

cleanup() {
  if [ -n "$watcher_pid" ]; then
    kill "$watcher_pid" 2>/dev/null || true
    wait "$watcher_pid" 2>/dev/null || true
  fi
  rm -rf "$sandbox"
}
trap cleanup EXIT HUP INT TERM

mkdir "$sandbox/bin"
cat >"$sandbox/bin/sketchybar" <<'SH'
#!/bin/sh
exit 0
SH
chmod +x "$sandbox/bin/sketchybar"

CONFIG_DIR="$CONFIG_DIR" \
SKETCHYBAR=/usr/bin/true \
TMPDIR="$sandbox" \
PATH="$sandbox/bin:$PATH" \
sh "$CONFIG_DIR/sketchybarrc" >/dev/null 2>&1

pidfile="$sandbox/sketchybar-menubar-watch.pid"
test -s "$pidfile"
watcher_pid=$(cat "$pidfile")
kill -0 "$watcher_pid"

# A config reload must retain the existing watcher rather than creating one
# watcher per reload.
CONFIG_DIR="$CONFIG_DIR" \
SKETCHYBAR=/usr/bin/true \
TMPDIR="$sandbox" \
PATH="$sandbox/bin:$PATH" \
sh "$CONFIG_DIR/sketchybarrc" >/dev/null 2>&1

test "$(cat "$pidfile")" = "$watcher_pid"
kill -0 "$watcher_pid"

printf '%s\n' 'menu bar watcher starts once and survives a SketchyBar reload'
