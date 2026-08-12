#!/usr/bin/env bash
set -euo pipefail
directory=${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots
mkdir -p "$directory"
file="$directory/$(date +%Y-%m-%d_%H-%M-%S).png"
case ${1:-} in
  region) geometry=$(slurp) || exit 0; grim -g "$geometry" "$file" ;;
  output) grim "$file" ;;
  *) printf 'Usage: %s {region|output}\n' "$0" >&2; exit 2 ;;
esac
wl-copy --type image/png <"$file"
notify-send 'Screenshot saved' "$file" 2>/dev/null || true
