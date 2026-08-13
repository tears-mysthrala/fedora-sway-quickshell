#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)

config="$ROOT/config/sway/config"
grep -Eq '^bar[[:space:]]*\{' "$config" && grep -Eq 'swaybar_command[[:space:]]+none' "$config"
grep -Fq 'set $term alacritty' "$config"
for binding in 'exec $term' 'kill' 'fullscreen toggle' 'floating toggle' 'workspace number 1' 'move container to workspace number 1' 'swaylock'; do
  grep -Fq "$binding" "$config"
done
! grep -Eq '^bindsym F[0-9]+ ' "$config"
grep -Fq 'fedora-sway-session.target' "$config"
grep -Fq 'title="Applications"' "$config"
grep -Fq 'Wants=pipewire.service wireplumber.service' "$ROOT/config/systemd/user/fedora-sway-session.target"

grep -Fq 'before-sleep' "$ROOT/config/swayidle/config"
grep -Fq 'swaylock' "$ROOT/config/swayidle/config"

for unit in quickshell idle polkit; do
  grep -Fq 'PartOf=fedora-sway-session.target' "$ROOT/config/systemd/user/fedora-sway-$unit.service"
done
! grep -RniE 'while[[:space:]]+true|sleep[[:space:]]+0\.[0-9]' "$ROOT/scripts" "$ROOT/config"

echo 'session config: PASS'
