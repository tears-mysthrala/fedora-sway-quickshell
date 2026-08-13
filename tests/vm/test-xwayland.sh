#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
evidence=${EVIDENCE_DIR:-$ROOT/.evidence/xwayland}
mkdir -p "$evidence"

swaymsg exec 'env -u WAYLAND_DISPLAY alacritty --title xwayland-proof' >/dev/null
found=false
for _ in {1..30}; do
  swaymsg -t get_tree >"$evidence/tree.json"
  if jq -e '.. | objects | select(.name? == "xwayland-proof" and .shell? == "xwayland")' \
      "$evidence/tree.json" >/dev/null; then
    found=true
    break
  fi
  sleep 0.2
done
[[ $found == true ]] || { echo 'The forced X11 client was not managed by XWayland.' >&2; exit 1; }
pgrep -a Xwayland | tee "$evidence/process.txt"
swaymsg '[title="xwayland-proof"] kill' >/dev/null
printf 'XWayland: observed process and managed X11 client: PASS\n' | tee "$evidence/result.txt"
