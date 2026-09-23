#!/usr/bin/env bash
set -u

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$ROOT
source "$ROOT/scripts/lib/common.sh"
# shellcheck source=config/mkdl-toolchain.conf
source "$ROOT/config/mkdl-toolchain.conf"
failures=0

# A doctor invocation over SSH is outside the graphical process tree, but the
# user manager owns the authoritative environment imported by Sway.
while IFS='=' read -r name value; do
  case $name in
    DISPLAY|WAYLAND_DISPLAY|SWAYSOCK|NIRI_SOCKET|XDG_CURRENT_DESKTOP|XDG_RUNTIME_DIR|XDG_SESSION_DESKTOP|XDG_SESSION_TYPE)
      declare -gx "$name=$value"
      ;;
  esac
done < <(systemctl --user show-environment 2>/dev/null || true)

ok() { printf '[OK] %s\n' "$1"; }
info() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; failures=$((failures + 1)); }
active_user_unit() { systemctl --user is-active --quiet "$1" 2>/dev/null; }
active_system_unit() { systemctl is-active --quiet "$1" 2>/dev/null; }
has_user_bus_name() { busctl --user --list --no-pager 2>/dev/null | awk '{print $1}' | grep -Fqx "$1"; }

printf 'Fedora Sway Workstation %s Doctor\n\n' "$PROJECT_VERSION"
if [[ -r /etc/os-release ]]; then
  source /etc/os-release
  if [[ ${ID:-} == fedora && ${VERSION_ID%%.*} == "$SUPPORTED_FEDORA_RELEASE" ]]; then ok "Fedora $VERSION_ID"; else fail "Fedora $SUPPORTED_FEDORA_RELEASE required; detected ${PRETTY_NAME:-unknown}"; fi
else fail 'Fedora identity unavailable'; fi

if [[ ${XDG_SESSION_TYPE:-} == wayland && -n ${WAYLAND_DISPLAY:-} && -S ${XDG_RUNTIME_DIR:-/nonexistent}/${WAYLAND_DISPLAY:-none} ]]; then ok 'Wayland socket available'; else warn 'Wayland session/socket not active in this invocation'; fi
if [[ -n ${NIRI_SOCKET:-} || ${XDG_CURRENT_DESKTOP:-} == niri ]]; then
  is_niri=true
  info 'Niri session detected; compositor checks follow Niri'
else
  is_niri=false
fi
if [[ -f /usr/share/wayland-sessions/niri.desktop ]]; then info 'Niri login session available'; else info 'Niri login session entry not found'; fi
if $is_niri; then
  if niri msg --json outputs >/dev/null 2>&1; then ok 'Niri IPC responsive'; else fail 'Niri IPC unavailable'; fi
elif swaymsg -t get_version >/dev/null 2>&1; then ok 'Sway IPC responsive'; else fail 'Sway IPC unavailable'; fi
if "$ROOT/scripts/qs-ipc.sh" show >/dev/null 2>&1 && active_user_unit fedora-sway-quickshell.service; then ok 'Quickshell IPC and user service active'; else fail 'Quickshell IPC or user service unavailable'; fi
if [[ -n ${DISPLAY:-} ]] && { pgrep -x Xwayland >/dev/null || pgrep -x xwayland-satellite >/dev/null; }; then ok 'XWayland display and process active'; else warn 'XWayland not observed (it may start on demand)'; fi

if active_user_unit xdg-desktop-portal.service && has_user_bus_name org.freedesktop.portal.Desktop; then ok 'xdg-desktop-portal active on D-Bus'; else fail 'xdg-desktop-portal frontend unavailable'; fi
if active_user_unit xdg-desktop-portal-wlr.service; then ok 'xdg-desktop-portal-wlr active'; else fail 'wlroots screen-capture portal inactive'; fi
if active_user_unit xdg-desktop-portal-gtk.service; then ok 'GTK portal fallback active'; else warn 'GTK portal fallback inactive'; fi

if wpctl status >/dev/null 2>&1; then ok 'PipeWire graph responsive'; else fail 'PipeWire graph unavailable'; fi
if active_user_unit wireplumber.service && pgrep -x wireplumber >/dev/null; then ok 'WirePlumber service and process active'; else fail 'WirePlumber inactive'; fi
if active_system_unit polkit.service && pgrep -f '/usr/libexec/lxqt-policykit-agent' >/dev/null; then ok 'polkit service and independent agent active'; else fail 'polkit service or authentication agent inactive'; fi
if active_user_unit fedora-sway-idle.service && pgrep -x swayidle >/dev/null; then ok 'swayidle service and process active'; else fail 'swayidle inactive'; fi
if active_user_unit fedora-sway-clipboard.service; then ok 'clipboard history service active'; else fail 'clipboard history service inactive'; fi
if systemctl --user is-active --quiet fedora-sway-wallpaper.timer; then ok 'wallpaper rotation timer active'; else fail 'wallpaper rotation timer inactive'; fi
if rpm -q swaylock >/dev/null 2>&1 && [[ -r $HOME/.config/swaylock/config ]]; then info 'swaylock installed/configured; functional lock requires interactive test'; else fail 'swaylock package/config unavailable'; fi
if active_system_unit NetworkManager.service && nmcli -t -f STATE general status >/dev/null 2>&1; then
  network_snapshot=$("$ROOT/scripts/qs-ipc.sh" call network snapshot 2>/dev/null || true)
  if [[ $network_snapshot =~ source=NetworkManager-events.*monitorPid=[1-9][0-9]* ]]; then
    ok 'NetworkManager API and Quickshell event listener responsive'
  else
    fail 'NetworkManager works but the Quickshell event listener is unavailable'
  fi
else fail 'NetworkManager unavailable'; fi
if busctl --system status org.freedesktop.UPower >/dev/null 2>&1; then
  if upower -e 2>/dev/null | grep -q battery; then ok 'UPower active; battery present'; else info 'UPower active; battery unavailable'; fi
else info 'UPower unavailable'; fi
if systemctl is-enabled --quiet greetd.service 2>/dev/null; then ok 'greetd login manager enabled'; else fail 'greetd login manager not enabled'; fi
if active_system_unit tuned.service && tuned-adm active >/dev/null 2>&1 && \
   busctl --system get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
     net.hadess.PowerProfiles ActiveProfile >/dev/null 2>&1; then
  ok 'TuneD power profiles active on D-Bus'
else
  fail 'TuneD power profiles unavailable'
fi
if active_system_unit bluetooth.service; then
  if busctl --system status org.bluez >/dev/null 2>&1; then ok 'BlueZ service and D-Bus API active'; else warn 'BlueZ active without observable D-Bus API'; fi
else info 'Bluetooth service inactive'; fi
if systemctl is-enabled --quiet cups.socket 2>/dev/null; then ok 'CUPS socket activation enabled'; else warn 'CUPS socket activation disabled'; fi
if has_user_bus_name org.freedesktop.secrets; then ok 'Secret Service/keyring active'; else fail 'Secret Service/keyring unavailable'; fi
if [[ $(xdg-mime query default image/png 2>/dev/null) == imv.desktop ]]; then ok 'imv is the default image viewer'; else warn 'imv is not the default PNG viewer'; fi
if [[ -d /develop ]]; then
  develop_fs=$(findmnt -no FSTYPE /develop 2>/dev/null || true)
  develop_options=$(findmnt -no OPTIONS /develop 2>/dev/null || true)
  if [[ $develop_fs == ext4 && $develop_options == *rw* ]]; then ok '/develop is mounted read-write on ext4'; else warn "/develop exists but mount state is unexpected (${develop_fs:-not mounted})"; fi
else info '/develop is optional and not configured on this machine'; fi

printf '\nDEVELOPMENT\n\n'
missing_dev=()
for dev_command in git gh podman docker node python3 rustc cargo psql nvim rg shellcheck mix codex t3code; do
  command -v "$dev_command" >/dev/null 2>&1 || missing_dev+=("$dev_command")
done
if (( ${#missing_dev[@]} == 0 )); then
  ok 'MKDL native development commands available'
else
  fail "MKDL development commands missing: ${missing_dev[*]}"
fi
if command -v npm >/dev/null 2>&1; then info 'npm available for the pinned Codex CLI installer'; else fail 'npm unavailable for Codex CLI maintenance'; fi
if command -v codex >/dev/null 2>&1 && [[ $(codex --version 2>/dev/null) == "codex-cli $CODEX_CLI_VERSION" ]]; then
  ok "Codex CLI $CODEX_CLI_VERSION available"
else
  fail "Codex CLI $CODEX_CLI_VERSION unavailable"
fi
if "$ROOT/scripts/install-t3code.sh" check >/dev/null 2>&1; then ok "T3 Code $T3_CODE_VERSION verified"; else fail 'T3 Code asset missing or invalid'; fi
if command -v chatgpt >/dev/null 2>&1; then info "ChatGPT desktop app present ($(rpm -q --qf '%{VERSION}-%{RELEASE}' chatgpt 2>/dev/null || echo unmanaged))"; else info 'ChatGPT desktop app is optional and not installed'; fi
if codex login status >/dev/null 2>&1; then ok 'Codex authenticated'; else info 'Codex installed but interactive login is pending'; fi
if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then ok 'KVM available to the current user'; else info 'KVM unavailable; virt-manager can still use software emulation'; fi
if command -v elixir >/dev/null 2>&1 && \
   [[ $(readlink -f -- "$(command -v elixir)") == "$ROOT/scripts/mkdl-elixir.sh" ]]; then
  if podman image exists "$MKDL_ELIXIR_IMAGE" 2>/dev/null; then
    ok 'Digest-pinned MKDL Elixir OCI toolchain cached'
  else
    info 'MKDL Elixir wrapper ready; pinned image downloads on first use'
  fi
elif command -v elixir >/dev/null 2>&1; then
  warn 'Host Elixir present; verify it independently against the repository runtime floor'
else
  fail 'MKDL Elixir wrapper unavailable'
fi

printf '\nPERFORMANCE\n\n'
for pair in 'Sway:sway' 'Quickshell:fedora-sway-quickshell.service'; do
  label=${pair%%:*}; process=${pair#*:}
  if [[ $label == Quickshell ]]; then
    pid=$(systemctl --user show -p MainPID --value "$process" 2>/dev/null || true)
    [[ $pid != 0 ]] || pid=
  else
    pid=$(pgrep -xo "$process" 2>/dev/null || true)
  fi
  if [[ -n $pid ]]; then printf '%-20s %s KiB (measured RSS)\n' "$label RSS:" "$(ps -o rss= -p "$pid" | tr -d ' ')"; else printf '%-20s unavailable\n' "$label RSS:"; fi
done
qs_pid=$(systemctl --user show -p MainPID --value fedora-sway-quickshell.service 2>/dev/null || true)
nm_pid=
[[ $qs_pid =~ ^[1-9][0-9]*$ ]] && nm_pid=$(pgrep -P "$qs_pid" -x nmcli 2>/dev/null || true)
if [[ $nm_pid =~ ^[1-9][0-9]*$ ]]; then
  printf '%-20s %s KiB (measured RSS)\n' 'NM event listener:' "$(ps -o rss= -p "$nm_pid" | tr -d ' ')"
else
  printf '%-20s unavailable\n' 'NM event listener:'
fi
printf '%-20s short, bounded UI transitions only\n' 'Animations:'
if grep -RqiE 'while[[:space:]]+true|sleep[[:space:]]+0\.' "$ROOT/config" "$ROOT/scripts"; then
  printf '%-20s detected; inspect required\n' 'Periodic polling:'
else
  printf '%-20s none; nmcli monitor is a blocking D-Bus event listener\n' 'Periodic polling:'
fi
printf '%-20s Sway IPC, PipeWire, NetworkManager, UPower, notifications\n' 'Event listeners:'

exit "$failures"
