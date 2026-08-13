#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH=$(readlink -f -- "${BASH_SOURCE[0]}")
ROOT=$(cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)
# shellcheck source=config/project.conf
source "$ROOT/config/project.conf"

mode=${1:-install}
[[ $mode == install || $mode == check || $mode == dry-run || $mode == uninstall ]] || {
  printf 'Usage: %s [install|check|dry-run|uninstall]\n' "$0" >&2
  exit 2
}
if [[ $mode == install || $mode == uninstall ]]; then
  (( EUID == 0 )) || { echo 'system-setup.sh must run through sudo.' >&2; exit 1; }
fi

state_dir=/var/lib/$PROJECT_ID
files_manifest=$state_dir/system-files.tsv
default_target_backup=$state_dir/default-target.before
unit_states_backup=$state_dir/unit-states.before.tsv
session_unit=greetd.service
managed_units=(bluetooth.service tuned.service cups.socket avahi-daemon.socket cockpit.socket dnf5-automatic.timer fstrim.timer smartd.service)
tracked_units=("$session_unit" "${managed_units[@]}")
sources=(
  "$ROOT/config/greetd/config.toml"
  "$ROOT/config/greetd/raiju-sway.conf"
  "$ROOT/config/greetd/raiju.css"
  "$ROOT/assets/backgrounds/raiju/raiju_guardian_under_crimson_lightning.png"
  "$ROOT/config/system/dnf-automatic.conf"
)
destinations=(
  /etc/greetd/config.toml
  /etc/greetd/raiju-sway.conf
  /etc/greetd/raiju.css
  /usr/share/backgrounds/raiju/raiju_guardian_under_crimson_lightning.png
  /etc/dnf/automatic.conf
)

verify_files() {
  local index
  for index in "${!sources[@]}"; do
    cmp -s -- "${sources[index]}" "${destinations[index]}" || {
      echo "Managed system file differs: ${destinations[index]}" >&2
      return 1
    }
  done
}

if [[ $mode == check ]]; then
  verify_files
  for unit in "${tracked_units[@]}"; do
    systemctl is-enabled --quiet "$unit" || { echo "$unit is not enabled." >&2; exit 1; }
  done
  [[ $(systemctl get-default) == graphical.target ]] || { echo 'The default boot target is not graphical.target.' >&2; exit 1; }
  echo 'System services, login theme and update policy verified.'
  exit 0
fi

if [[ $mode == dry-run ]]; then
  for index in "${!sources[@]}"; do
    printf 'Would manage %s as %s with a recoverable backup.\n' "${sources[index]}" "${destinations[index]}"
  done
  echo 'Would preserve the current default target and service states, then select graphical.target.'
  echo 'Would enable greetd, Cockpit, hardware services, automatic updates, trimming and disk monitoring.'
  exit 0
fi

if [[ $mode == uninstall ]]; then
  if [[ -f $files_manifest ]]; then
    while IFS=$'\t' read -r source destination backup; do
      [[ -n $destination ]] || continue
      if cmp -s -- "$source" "$destination"; then
        if [[ -n $backup && -f $backup ]]; then
          cp --archive -- "$backup" "$destination"
          unlink -- "$backup"
        else
          unlink -- "$destination"
        fi
        echo "Restored managed system path: $destination"
      else
        echo "Preserved changed system path: $destination"
      fi
    done <"$files_manifest"
    unlink -- "$files_manifest"
  fi
  if [[ -f $unit_states_backup ]]; then
    while IFS=$'\t' read -r unit was_enabled was_active; do
      [[ -n $unit ]] || continue
      [[ $was_enabled == enabled ]] || systemctl disable "$unit" >/dev/null 2>&1 || true
      [[ $was_active == active ]] || systemctl stop "$unit" >/dev/null 2>&1 || true
    done <"$unit_states_backup"
    unlink -- "$unit_states_backup"
    echo 'Restored prior enable/active state for project-managed system services.'
  fi
  if [[ $(systemctl get-default) == graphical.target && -s $default_target_backup ]]; then
    previous_target=$(<"$default_target_backup")
    if [[ $previous_target =~ ^[a-zA-Z0-9@_.-]+\.target$ ]]; then
      systemctl set-default "$previous_target"
      unlink -- "$default_target_backup"
      echo "Restored the previous default target: $previous_target"
    fi
  fi
  exit 0
fi

display_manager_link=/etc/systemd/system/display-manager.service
if [[ -L $display_manager_link ]]; then
  display_manager=$(readlink -e -- "$display_manager_link" 2>/dev/null || true)
  if [[ -n $display_manager && $display_manager != /usr/lib/systemd/system/greetd.service ]]; then
    echo "Another display manager is configured: $display_manager" >&2
    exit 1
  fi
fi

install -d -m 0700 -- "$state_dir"
if [[ ! -f $default_target_backup ]]; then
  systemctl get-default >"$default_target_backup"
  chmod 0600 "$default_target_backup"
fi
if [[ ! -f $unit_states_backup ]]; then
  for unit in "${tracked_units[@]}"; do
    printf '%s\t%s\t%s\n' "$unit" \
      "$(systemctl is-enabled "$unit" 2>/dev/null || true)" \
      "$(systemctl is-active "$unit" 2>/dev/null || true)"
  done >"$unit_states_backup"
  chmod 0600 "$unit_states_backup"
fi

if [[ ! -f $files_manifest ]]; then
  : >"$files_manifest"
  chmod 0600 "$files_manifest"
  for index in "${!sources[@]}"; do
    source=${sources[index]}
    destination=${destinations[index]}
    backup=
    if [[ -e $destination ]] && ! cmp -s -- "$source" "$destination"; then
      backup=$state_dir/system-file-$index.backup
      cp --archive -- "$destination" "$backup"
    fi
    printf '%s\t%s\t%s\n' "$source" "$destination" "$backup" >>"$files_manifest"
  done
fi
for index in "${!sources[@]}"; do
  install -D -m 0644 -- "${sources[index]}" "${destinations[index]}"
done
command -v restorecon >/dev/null && restorecon -RF /etc/greetd /usr/share/backgrounds/raiju /etc/dnf/automatic.conf || true

systemctl set-default graphical.target
systemctl enable "$session_unit"
systemctl enable --now "${managed_units[@]}"
echo 'System setup converged. greetd will take effect at the next boot.'
