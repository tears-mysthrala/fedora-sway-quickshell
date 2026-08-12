#!/usr/bin/env bash
set -euo pipefail
command -v brightnessctl >/dev/null || exit 0
case ${1:-} in
  up) brightnessctl set 5%+ ;;
  down) brightnessctl set 5%- ;;
  *) printf 'Usage: %s {up|down}\n' "$0" >&2; exit 2 ;;
esac
qs ipc call osd brightness >/dev/null 2>&1 || true

