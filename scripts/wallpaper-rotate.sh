#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir=${XDG_DATA_HOME:-$HOME/.local/share}/backgrounds/raiju
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/fedora-sway
state_file=$state_dir/wallpaper-index

mapfile -t wallpapers < <(find -L "$wallpaper_dir" -maxdepth 1 -type f -iname '*.png' -print | sort)
((${#wallpapers[@]} > 0)) || exit 0

mkdir -p "$state_dir"
index=0
if [[ -r $state_file ]]; then
    read -r index < "$state_file" || index=0
fi
[[ $index =~ ^[0-9]+$ ]] || index=0

wallpaper=${wallpapers[index % ${#wallpapers[@]}]}
if [[ -n ${NIRI_SOCKET:-} ]]; then
  # Niri has no built-in wallpaper support; point the persistent swaybg
  # service at the new image through a stable symlink.
  current_link=${XDG_DATA_HOME:-$HOME/.local/share}/backgrounds/raiju-current.png
  ln -sf -- "$wallpaper" "$current_link"
  systemctl --user restart fedora-sway-wallpaper-bg.service
else
  swaymsg output '*' bg "$wallpaper" fill >/dev/null
fi
printf '%s\n' "$((index + 1))" > "$state_file"
