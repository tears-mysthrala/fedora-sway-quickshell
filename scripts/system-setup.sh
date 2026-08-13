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
managed=/etc/greetd/config.toml
source_config=$ROOT/config/greetd/config.toml
backup=$state_dir/greetd-config.toml.backup
default_target_backup=$state_dir/default-target.before
unit_states_backup=$state_dir/unit-states.before.tsv
session_unit=greetd.service
managed_units=(bluetooth.service tuned.service cups.socket avahi-daemon.socket)
tracked_units=("$session_unit" "${managed_units[@]}")

if [[ $mode == check ]]; then
  cmp -s -- "$source_config" "$managed" || { echo 'greetd configuration differs.' >&2; exit 1; }
  for unit in greetd.service bluetooth.service tuned.service cups.socket avahi-daemon.socket; do
    systemctl is-enabled --quiet "$unit" || { echo "$unit is not enabled." >&2; exit 1; }
  done
  [[ $(systemctl get-default) == graphical.target ]] || { echo 'The default boot target is not graphical.target.' >&2; exit 1; }
  echo 'System services and greetd configuration verified.'
  exit 0
fi

if [[ $mode == dry-run ]]; then
  echo "Would install $source_config as $managed with a one-time backup."
  echo 'Would preserve the current default target and select graphical.target.'
  echo 'Would enable greetd, Bluetooth, TuneD, CUPS and Avahi socket activation.'
  exit 0
fi

if [[ $mode == uninstall ]]; then
  if cmp -s -- "$source_config" "$managed"; then
    if [[ -f $backup ]]; then
      cp --archive -- "$backup" "$managed"
      unlink -- "$backup"
    else
      unlink -- "$managed"
    fi
    echo 'Removed the project greetd configuration.'
  else
    echo 'Preserved changed greetd configuration.'
  fi
  if [[ -f $unit_states_backup ]]; then
    while IFS=$'\t' read -r unit was_enabled was_active; do
      [[ -n $unit ]] || continue
      [[ $was_enabled == enabled ]] || systemctl disable "$unit" >/dev/null 2>&1 || true
      [[ $was_active == active ]] || systemctl stop "$unit" >/dev/null 2>&1 || true
    done <"$unit_states_backup"
    rm -f -- "$unit_states_backup"
    echo 'Restored prior enable/active state for project-managed system services.'
  fi
  if [[ $(systemctl get-default) == graphical.target && -s $default_target_backup ]]; then
    previous_target=$(<"$default_target_backup")
    if [[ $previous_target =~ ^[a-zA-Z0-9@_.-]+\.target$ ]]; then
      systemctl set-default "$previous_target"
      rm -f -- "$default_target_backup"
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
if [[ -f $managed && ! -f $backup ]] && ! cmp -s -- "$source_config" "$managed"; then
  cp --archive -- "$managed" "$backup"
  echo "Backed up $managed to $backup"
fi
install -D -m 0644 -- "$source_config" "$managed"

systemctl set-default graphical.target
systemctl enable "$session_unit"
systemctl enable --now "${managed_units[@]}"
echo 'System setup converged. greetd will take effect at the next boot.'
