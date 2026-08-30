#!/bin/sh

# Activity Monitor's used-memory presentation is approximated from disjoint
# resident vm_stat buckets: active + inactive + wired + physical compressor
# pages. "Pages stored in compressor" is intentionally excluded because it is
# the uncompressed logical page count, not additional physical memory.
total_bytes=$(/usr/sbin/sysctl -n hw.memsize 2>/dev/null) || exit 0

ram_percent=$(
  /usr/bin/vm_stat 2>/dev/null |
    /usr/bin/awk -v total_bytes="$total_bytes" '
      function page_count(raw) {
        if (raw !~ /^[0-9]+[.]$/) return -1
        sub(/[.]$/, "", raw)
        return raw + 0
      }

      NR == 1 && /^Mach Virtual Memory Statistics:/ {
        if ($8 ~ /^[0-9]+$/) {
          page_size = $8 + 0
          have_page_size = 1
        } else {
          invalid = 1
        }
      }
      /^Pages active:/ {
        active = page_count($3)
        if (active < 0) invalid = 1
        have_active = 1
      }
      /^Pages inactive:/ {
        inactive = page_count($3)
        if (inactive < 0) invalid = 1
        have_inactive = 1
      }
      /^Pages wired down:/ {
        wired = page_count($4)
        if (wired < 0) invalid = 1
        have_wired = 1
      }
      /^Pages occupied by compressor:/ {
        compressed = page_count($5)
        if (compressed < 0) invalid = 1
        have_compressed = 1
      }

      END {
        if (total_bytes !~ /^[0-9]+$/ || total_bytes <= 0 || invalid ||
            !have_page_size || !have_active || !have_inactive ||
            !have_wired || !have_compressed) exit 1

        used_bytes = (active + inactive + wired + compressed) * page_size
        percent = used_bytes * 100 / total_bytes
        if (percent < 0) percent = 0
        if (percent > 100) percent = 100
        printf "%.0f\n", percent
      }
    '
) || exit 0

sketchybar_command=${SKETCHYBAR:-sketchybar}
"$sketchybar_command" --set "${NAME:-ram}" label="RAM ${ram_percent}%"
