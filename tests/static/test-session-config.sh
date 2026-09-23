#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)

config="$ROOT/config/sway/config"
grep -Eq '^bar[[:space:]]*\{' "$config" && grep -Eq 'swaybar_command[[:space:]]+none' "$config"
grep -Fq 'set $term alacritty' "$config"
for binding in 'exec $term' 'kill' 'fullscreen toggle' 'floating toggle' 'workspace number 1' 'move container to workspace number 1' 'swaylock'; do
  grep -Fq "$binding" "$config"
done
if grep -Eq '^bindsym F[0-9]+ ' "$config"; then exit 1; fi
grep -Fq 'fedora-sway-session.target' "$config"
grep -Fq 'title="Applications"' "$config"
grep -Fq 'bindsym $mod+b exec zen' "$config"
grep -Fq 'bindsym $mod+v' "$config"
grep -Fq 'gaps outer 8' "$config"
grep -Fq 'Wants=pipewire.service wireplumber.service' "$ROOT/config/systemd/user/fedora-sway-session.target"
grep -Fq 'fedora-sway-clipboard.service fedora-sway-wallpaper.timer' "$ROOT/config/systemd/user/fedora-sway-session.target"

columns="$ROOT/config/sway/config-columns"
grep -Fq 'include config' "$columns"
for binding in 'move left' 'move right' 'move up' 'move down' 'split toggle' \
  'workspace back_and_forth' 'move scratchpad' 'scratchpad show' \
  'workspace prev_on_output' 'workspace next_on_output' 'mode "resize"'; do
  grep -Fq "$binding" "$columns"
done
if grep -Eq '^bindsym F[0-9]+ ' "$columns"; then exit 1; fi
if grep -Fq 'swaybar_command' "$columns"; then exit 1; fi
if grep -Fq 'fedora-sway-session.target' "$columns"; then exit 1; fi

grep -Fq 'before-sleep' "$ROOT/config/swayidle/config"
grep -Fq 'swaylock' "$ROOT/config/swayidle/config"

niri_conf="$ROOT/config/niri/config.kdl"
grep -Fq 'layout "es"' "$niri_conf"
grep -Fq 'compose:caps' "$niri_conf"
grep -Fq 'natural-scroll' "$niri_conf"
grep -Fq 'focus-column-left' "$niri_conf"
grep -Fq 'consume-or-expel-window-left' "$niri_conf"
grep -Fq 'fedora-sway-session.target' "$niri_conf"
grep -Fq 'niri-session-env.sh' "$niri_conf"
if grep -Eq '^bindsym F[0-9]+ ' "$niri_conf"; then exit 1; fi
grep -Fq 'power-off-monitors' "$ROOT/config/swayidle/config-niri"
grep -Fq 'swaylock' "$ROOT/config/swayidle/config-niri"
grep -Fq 'swayidle-launch.sh' "$ROOT/config/systemd/user/fedora-sway-idle.service"
[[ -x $ROOT/scripts/swayidle-launch.sh ]]
[[ -x $ROOT/scripts/niri-session-env.sh ]]
grep -Fq 'set-environment XDG_CURRENT_DESKTOP=niri' "$ROOT/scripts/niri-session-env.sh"
grep -Fq 'swaybg' "$ROOT/scripts/wallpaper-rotate.sh"
[[ -f $ROOT/config/systemd/user/fedora-sway-wallpaper-bg.service ]]

for unit in quickshell idle polkit clipboard; do
  grep -Fq 'PartOf=fedora-sway-session.target' "$ROOT/config/systemd/user/fedora-sway-$unit.service"
done
grep -Fq 'OnUnitActiveSec=15min' "$ROOT/config/systemd/user/fedora-sway-wallpaper.timer"
grep -Fq 'find -L "$wallpaper_dir"' "$ROOT/scripts/wallpaper-rotate.sh"
if grep -RniE 'while[[:space:]]+true|sleep[[:space:]]+0\.[0-9]' "$ROOT/scripts" "$ROOT/config"; then exit 1; fi

echo 'session config: PASS'
