#!/usr/bin/env bash
set -euo pipefail
case ${1:-} in
  up) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  micmute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
  *) printf 'Usage: %s {up|down|mute|micmute}\n' "$0" >&2; exit 2 ;;
esac
"$(dirname -- "$0")/qs-ipc.sh" call osd volume >/dev/null 2>&1 || true
