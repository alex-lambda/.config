#!/bin/bash
# Claude Code status line: cwd + git branch, model name, context usage %

input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir_name=$(basename "$dir")

branch=""
if git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
fi

model=$(echo "$input" | jq -r '.model.display_name')

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Catppuccin Mocha (truecolor); no dim attribute — the pastels are already muted
DIM_BLUE='\033[38;2;137;180;250m'    # blue    #89b4fa
DIM_GREEN='\033[38;2;166;227;161m'   # green   #a6e3a1
DIM_YELLOW='\033[38;2;249;226;175m'  # yellow  #f9e2af
DIM_GRAY='\033[38;2;108;112;134m'    # overlay0 #6c7086
RESET='\033[0m'

out="${DIM_BLUE}${dir_name}${RESET}"
if [ -n "$branch" ]; then
  out="${out} ${DIM_GREEN}(${branch})${RESET}"
fi
out="${out} ${DIM_GRAY}|${RESET} ${DIM_YELLOW}${model}${RESET}"
if [ -n "$used" ]; then
  out="${out} ${DIM_GRAY}|${RESET} $(printf '%.0f' "$used")% ctx"
fi

printf "%b\n" "$out"
