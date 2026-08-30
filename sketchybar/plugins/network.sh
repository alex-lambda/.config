#!/bin/sh

# Keep only byte counters locally; never query or display network identifiers.
state_root=${XDG_CACHE_HOME:-${TMPDIR:-/tmp}}
state_dir="$state_root/sketchybar"
state_file="$state_dir/network.state"
sketchybar_command=${SKETCHYBAR:-sketchybar}

set_label() {
  "$sketchybar_command" --set "${NAME:-network}" label="$1"
}

is_uint() {
  case $1 in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

interface=$(
  /usr/sbin/networksetup -listallhardwareports 2>/dev/null |
    /usr/bin/awk '
      /^Hardware Port: (Wi-Fi|AirPort)$/ { wifi = 1; next }
      wifi && /^Device: / { print $2; exit }
    '
)

if [ -z "$interface" ] || ! /sbin/ifconfig "$interface" 2>/dev/null | /usr/bin/grep -q 'status: active'; then
  /bin/rm -f "$state_file"
  set_label "↓   --/s ↑   --/s"
  exit 0
fi

counters=$(
  /usr/sbin/netstat -ibn -I "$interface" 2>/dev/null |
    /usr/bin/awk -v interface="$interface" '
      NR == 1 {
        for (column = 1; column <= NF; column++) {
          if ($column == "Ibytes") in_column = column
          if ($column == "Obytes") out_column = column
        }
        next
      }
      $1 == interface && in_column && out_column &&
        $in_column ~ /^[0-9]+$/ && $out_column ~ /^[0-9]+$/ {
          print $in_column, $out_column
          exit
        }
    '
)

set -- $counters
if [ "$#" -ne 2 ] || ! is_uint "$1" || ! is_uint "$2"; then
  set_label "↓   --/s ↑   --/s"
  exit 0
fi

in_bytes=$1
out_bytes=$2
now=$(/bin/date +%s)
down_rate=0
up_rate=0

if [ -r "$state_file" ]; then
  old_interface=
  old_in=
  old_out=
  old_time=
  read -r old_interface old_in old_out old_time < "$state_file"

  if [ "$old_interface" = "$interface" ] &&
     is_uint "$old_in" && is_uint "$old_out" && is_uint "$old_time"; then
    rates=$(
      /usr/bin/awk \
        -v current_in="$in_bytes" -v current_out="$out_bytes" \
        -v previous_in="$old_in" -v previous_out="$old_out" \
        -v current_time="$now" -v previous_time="$old_time" '
          BEGIN {
            elapsed = current_time - previous_time
            if (elapsed > 0 && current_in >= previous_in)
              down = (current_in - previous_in) / elapsed
            if (elapsed > 0 && current_out >= previous_out)
              up = (current_out - previous_out) / elapsed
            printf "%.0f %.0f\n", down, up
          }
        '
    )
    set -- $rates
    if [ "$#" -eq 2 ] && is_uint "$1" && is_uint "$2"; then
      down_rate=$1
      up_rate=$2
    fi
  fi
fi

/bin/mkdir -p "$state_dir" 2>/dev/null
state_tmp="$state_file.$$"
if /usr/bin/printf '%s %s %s %s\n' "$interface" "$in_bytes" "$out_bytes" "$now" > "$state_tmp" 2>/dev/null; then
  /bin/mv -f "$state_tmp" "$state_file"
else
  /bin/rm -f "$state_tmp"
fi

formatted=$(
  /usr/bin/awk -v down="$down_rate" -v up="$up_rate" '
    function rate(value, unit) {
      unit = "B"
      if (value >= 1000) { value /= 1024; unit = "K" }
      if (value >= 1000) { value /= 1024; unit = "M" }
      if (value >= 1000) { value /= 1024; unit = "G" }
      if (value > 999) value = 999
      if (value < 100 && unit != "B") return sprintf("%4.1f%s/s", value, unit)
      return sprintf("%4.0f%s/s", value, unit)
    }
    BEGIN { printf "%s|%s\n", rate(down), rate(up) }
  '
)
download=${formatted%%|*}
upload=${formatted#*|}

set_label "↓$download ↑$upload"
