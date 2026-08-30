#!/bin/sh

# Leave the existing label untouched when top does not produce a complete
# sample. SketchyBar will invoke us again at the item's next update interval.
cpu_percent=$(
  LC_ALL=C /usr/bin/top -l 1 -n 0 2>/dev/null |
    /usr/bin/awk '
      /CPU usage:/ {
        for (i = 2; i <= NF; i++) {
          if ($i == "idle" && $(i - 1) ~ /^[0-9]+([.][0-9]+)?%$/) {
            idle = $(i - 1)
            sub(/%$/, "", idle)
            percent = 100 - idle
            if (percent < 0) percent = 0
            if (percent > 100) percent = 100
            printf "%.0f\n", percent
            sampled = 1
            exit
          }
        }
      }
      END { if (!sampled) exit 1 }
    '
) || exit 0

sketchybar_command=${SKETCHYBAR:-sketchybar}
"$sketchybar_command" --set "${NAME:-cpu}" label="CPU ${cpu_percent}%"
