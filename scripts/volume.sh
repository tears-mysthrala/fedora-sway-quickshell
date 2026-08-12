#!/usr/bin/env bash
set -euo pipefail
case ${1:-} in
  up) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  *) printf 'Usage: %s {up|down|mute}\n' "$0" >&2; exit 2 ;;
esac
qs ipc call osd volume >/dev/null 2>&1 || true

