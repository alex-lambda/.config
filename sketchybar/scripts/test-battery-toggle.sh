#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd "$(dirname "$0")/.." && pwd -P)
binary=${TMPDIR:-/tmp}/sketchybar-battery-toggle-tests
trap 'rm -f "$binary"' EXIT HUP INT TERM

swiftc -parse-as-library \
  "$repo_dir/helper/Sources/MenuBarKit/Core/Protocol.swift" \
  "$repo_dir/helper/Sources/MenuBarKit/Battery/BatteryMenuClickHandler.swift" \
  "$repo_dir/helper/Tests/MenuBarKitTests/BatteryMenuClickHandlerTests.swift" \
  -o "$binary"

"$binary"
