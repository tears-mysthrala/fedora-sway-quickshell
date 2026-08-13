#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
evidence=${EVIDENCE_DIR:-$ROOT/.evidence/quickshell-isolation}
mkdir -p "$evidence"

original_workspace=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused).name')
lock_pid=
cleanup() {
  [[ -z $lock_pid ]] || kill "$lock_pid" 2>/dev/null || true
  systemctl --user start fedora-sway-quickshell.service 2>/dev/null || true
  swaymsg '[title="^isolation-terminal-"] kill' >/dev/null 2>&1 || true
  swaymsg workspace "$original_workspace" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# A previous interrupted acceptance run must not affect the terminal count.
swaymsg '[title="^isolation-terminal-"] kill' >/dev/null 2>&1 || true

swaymsg -t get_version >"$evidence/sway-before.json"
swaymsg exec 'alacritty --title isolation-terminal-a' >/dev/null
swaymsg exec 'alacritty --title isolation-terminal-b' >/dev/null
sleep 2
swaymsg -t get_tree >"$evidence/tree-before.json"
before_terminals=$(jq '[.. | objects | select(.app_id? == "Alacritty")] | length' "$evidence/tree-before.json")
(( before_terminals >= 2 ))

idle_pid=$(pgrep -xo swayidle)
polkit_pid=$(pgrep -fo '/usr/libexec/lxqt-policykit-agent')
systemctl --user stop fedora-sway-quickshell.service
[[ $(systemctl --user show -p MainPID --value fedora-sway-quickshell.service) == 0 ]]

swaymsg -t get_version >"$evidence/sway-without-shell.json"
swaymsg workspace number 2 >/dev/null
swaymsg workspace number 1 >/dev/null
swaymsg exec 'alacritty --title isolation-terminal-after-kill' >/dev/null
sleep 1
without_shell_terminals=$(swaymsg -t get_tree | jq '[.. | objects | select(.app_id? == "Alacritty")] | length')
(( without_shell_terminals >= before_terminals + 1 ))
[[ $(pgrep -xo swayidle) == "$idle_pid" ]]
[[ $(pgrep -fo '/usr/libexec/lxqt-policykit-agent') == "$polkit_pid" ]]
command -v swaylock >"$evidence/swaylock-path.txt"
# Foreground mode gives the harness a process it can observe and terminate.
# `-f` means daemonize in swaylock and would make $! exit before validation.
swaylock >"$evidence/swaylock.log" 2>&1 &
lock_pid=$!
for _ in {1..20}; do kill -0 "$lock_pid" 2>/dev/null && pgrep -x swaylock >/dev/null && break; sleep 0.1; done
kill -0 "$lock_pid"
pgrep -x swaylock >"$evidence/swaylock-pid.txt"
kill "$lock_pid"
wait "$lock_pid" 2>/dev/null || true
lock_pid=
swaymsg -t get_tree >"$evidence/tree-without-shell.json"

systemctl --user start fedora-sway-quickshell.service
for _ in {1..20}; do "$ROOT/scripts/qs-ipc.sh" show >/dev/null 2>&1 && break; sleep 0.25; done
"$ROOT/scripts/qs-ipc.sh" show >"$evidence/quickshell-after.txt"
swaymsg -t get_tree >"$evidence/tree-after.json"
cleanup
trap - EXIT
sleep 0.5
systemctl --user is-active --quiet fedora-sway-quickshell.service
! swaymsg -t get_tree | jq -e '.. | objects | select((.name? // "") | startswith("isolation-terminal-"))' >/dev/null
printf 'Quickshell isolation: observed PASS\n' | tee "$evidence/result.txt"
