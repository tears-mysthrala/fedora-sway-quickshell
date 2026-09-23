#!/usr/bin/env bash
# swayidle launcher: picks the idle config matching the running compositor.
# The Sway config drives DPMS through swaymsg; Niri through its own actions.
set -euo pipefail

config=$HOME/.config/swayidle/config
if [[ -n ${NIRI_SOCKET:-} ]]; then
  config=$HOME/.config/swayidle/config-niri
fi
[[ -r $config ]] || {
  printf 'Missing swayidle config: %s\n' "$config" >&2
  exit 1
}
exec /usr/bin/swayidle -w -C "$config"
