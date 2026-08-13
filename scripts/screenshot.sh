#!/usr/bin/env bash
set -euo pipefail
pictures=${XDG_PICTURES_DIR:-}
if [[ -z $pictures ]] && command -v xdg-user-dir >/dev/null 2>&1; then
  pictures=$(xdg-user-dir PICTURES)
fi
directory=${pictures:-$HOME/Pictures}/Screenshots
mkdir -p "$directory"
file="$directory/$(date +%Y-%m-%d_%H-%M-%S).png"
case ${1:-} in
  region) geometry=$(slurp) || exit 0; grim -g "$geometry" "$file" ;;
  output) grim "$file" ;;
  *) printf 'Usage: %s {region|output}\n' "$0" >&2; exit 2 ;;
esac
swappy -f "$file" -o "$file" || true
wl-copy --type image/png <"$file"
notify-send 'Captura guardada' "$file" 2>/dev/null || true
