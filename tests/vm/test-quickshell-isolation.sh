#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
evidence=${EVIDENCE_DIR:-$ROOT/.evidence/quickshell-isolation}
mkdir -p "$evidence"

swaymsg -t get_version >"$evidence/sway-before.json"
swaymsg exec 'foot --title isolation-terminal-a' >/dev/null
swaymsg exec 'foot --title isolation-terminal-b' >/dev/null
sleep 2
swaymsg -t get_tree >"$evidence/tree-before.json"

idle_pid=$(pgrep -xo swayidle)
polkit_pid=$(pgrep -fo '/usr/libexec/lxqt-policykit-agent')
systemctl --user stop fedora-sway-quickshell.service
! pgrep -x quickshell >/dev/null

swaymsg -t get_version >"$evidence/sway-without-shell.json"
swaymsg workspace number 2 >/dev/null
swaymsg workspace number 1 >/dev/null
swaymsg exec 'foot --title isolation-terminal-after-kill' >/dev/null
[[ $(pgrep -xo swayidle) == "$idle_pid" ]]
[[ $(pgrep -fo '/usr/libexec/lxqt-policykit-agent') == "$polkit_pid" ]]
command -v swaylock >"$evidence/swaylock-path.txt"
swaymsg -t get_tree >"$evidence/tree-without-shell.json"

systemctl --user start fedora-sway-quickshell.service
for _ in {1..20}; do qs ipc show >/dev/null 2>&1 && break; sleep 0.25; done
qs ipc show >"$evidence/quickshell-after.txt"
swaymsg -t get_tree >"$evidence/tree-after.json"
printf 'Quickshell isolation: observed PASS\n' | tee "$evidence/result.txt"
