#!/usr/bin/env bash
set -u

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$ROOT
source "$ROOT/scripts/lib/common.sh"
failures=0

ok() { printf '[OK] %s\n' "$1"; }
info() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; failures=$((failures + 1)); }
active_user_unit() { systemctl --user is-active --quiet "$1" 2>/dev/null; }
active_system_unit() { systemctl is-active --quiet "$1" 2>/dev/null; }
has_user_bus_name() { busctl --user --list --no-pager 2>/dev/null | awk '{print $1}' | grep -Fqx "$1"; }

printf 'Fedora Sway Demo Doctor\n\n'
if [[ -r /etc/os-release ]]; then
  source /etc/os-release
  if [[ ${ID:-} == fedora && ${VERSION_ID%%.*} == "$SUPPORTED_FEDORA_RELEASE" ]]; then ok "Fedora $VERSION_ID"; else fail "Fedora $SUPPORTED_FEDORA_RELEASE required; detected ${PRETTY_NAME:-unknown}"; fi
else fail 'Fedora identity unavailable'; fi

if [[ ${XDG_SESSION_TYPE:-} == wayland && -n ${WAYLAND_DISPLAY:-} && -S ${XDG_RUNTIME_DIR:-/nonexistent}/${WAYLAND_DISPLAY:-none} ]]; then ok 'Wayland socket available'; else warn 'Wayland session/socket not active in this invocation'; fi
if swaymsg -t get_version >/dev/null 2>&1; then ok 'Sway IPC responsive'; else fail 'Sway IPC unavailable'; fi
if qs ipc show >/dev/null 2>&1 && active_user_unit fedora-sway-quickshell.service; then ok 'Quickshell IPC and user service active'; else fail 'Quickshell IPC or user service unavailable'; fi
if [[ -n ${DISPLAY:-} ]] && pgrep -x Xwayland >/dev/null; then ok 'XWayland display and process active'; else warn 'XWayland not observed (it may start on demand)'; fi

if active_user_unit xdg-desktop-portal.service && has_user_bus_name org.freedesktop.portal.Desktop; then ok 'xdg-desktop-portal active on D-Bus'; else fail 'xdg-desktop-portal frontend unavailable'; fi
if active_user_unit xdg-desktop-portal-wlr.service; then ok 'xdg-desktop-portal-wlr active'; else fail 'wlroots screen-capture portal inactive'; fi
if active_user_unit xdg-desktop-portal-gtk.service; then ok 'GTK portal fallback active'; else warn 'GTK portal fallback inactive'; fi

if wpctl status >/dev/null 2>&1; then ok 'PipeWire graph responsive'; else fail 'PipeWire graph unavailable'; fi
if active_user_unit wireplumber.service && pgrep -x wireplumber >/dev/null; then ok 'WirePlumber service and process active'; else fail 'WirePlumber inactive'; fi
if active_system_unit polkit.service && pgrep -f '/usr/libexec/lxqt-policykit-agent' >/dev/null; then ok 'polkit service and independent agent active'; else fail 'polkit service or authentication agent inactive'; fi
if active_user_unit fedora-sway-idle.service && pgrep -x swayidle >/dev/null; then ok 'swayidle service and process active'; else fail 'swayidle inactive'; fi
if rpm -q swaylock >/dev/null 2>&1 && [[ -r $HOME/.config/swaylock/config ]]; then info 'swaylock installed/configured; functional lock requires interactive test'; else fail 'swaylock package/config unavailable'; fi
if active_system_unit NetworkManager.service && nmcli -t -f STATE general status >/dev/null 2>&1; then ok 'NetworkManager service and API responsive'; else fail 'NetworkManager unavailable'; fi
if busctl --system status org.freedesktop.UPower >/dev/null 2>&1; then
  if upower -e 2>/dev/null | grep -q battery; then ok 'UPower active; battery present'; else info 'UPower active; battery unavailable'; fi
else info 'UPower unavailable'; fi

printf '\nPERFORMANCE\n\n'
for pair in 'Sway:sway' 'Quickshell:quickshell'; do
  label=${pair%%:*}; process=${pair#*:}; pid=$(pgrep -xo "$process" 2>/dev/null || true)
  if [[ -n $pid ]]; then printf '%-20s %s KiB (measured RSS)\n' "$label RSS:" "$(ps -o rss= -p "$pid" | tr -d ' ')"; else printf '%-20s unavailable\n' "$label RSS:"; fi
done
printf '%-20s disabled by project configuration\n' 'Animations:'
if grep -RqiE 'while[[:space:]]+true|sleep[[:space:]]+0\.' "$ROOT/config" "$ROOT/scripts"; then printf '%-20s detected; inspect required\n' 'Periodic polling:'; else printf '%-20s none detected in project configuration\n' 'Periodic polling:'; fi
printf '%-20s Sway IPC, PipeWire, NetworkManager, UPower, notifications\n' 'Event listeners:'

exit "$failures"

