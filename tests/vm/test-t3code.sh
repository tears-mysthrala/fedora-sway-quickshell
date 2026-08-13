#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
evidence=${EVIDENCE_DIR:-$ROOT/.evidence/t3code}
mkdir -p "$evidence"

command -v t3code >"$evidence/command.txt"
command -v codex >"$evidence/codex-command.txt"
swaymsg -t get_version >"$evidence/sway-version.json"

unit=fedora-sway-t3code-acceptance.service
systemctl --user stop "$unit" 2>/dev/null || true
systemd-run --user --unit="${unit%.service}" --collect \
  --property=KillMode=control-group --property=TimeoutStopSec=2s \
  t3code >"$evidence/t3code.log"
cleanup() {
  systemctl --user kill --kill-whom=all --signal=KILL "$unit" 2>/dev/null || true
  systemctl --user stop --no-block "$unit" 2>/dev/null || true
}
trap cleanup EXIT

found=false
for _ in {1..40}; do
  if swaymsg -t get_tree | jq -e '.. | objects | select(.app_id? == "t3code")' >/dev/null; then
    found=true
    break
  fi
  sleep 0.5
done
[[ $found == true ]] || { echo 'T3 Code did not create a Sway window.' >&2; exit 1; }
t3_pid=$(systemctl --user show -p MainPID --value "$unit")
(( t3_pid > 0 ))
tr '\0' '\n' <"/proc/$t3_pid/environ" >"$evidence/environment.txt"

ps -u "$USER" -o pid=,ppid=,args= >"$evidence/processes.txt"
if grep -E -- '(^|[[:space:]])--no-sandbox([[:space:]]|$)' "$evidence/processes.txt"; then
  echo 'T3 Code disabled the Electron sandbox.' >&2
  exit 1
fi
swaymsg -t get_tree >"$evidence/tree.json"
cleanup
trap - EXIT
[[ $(systemctl --user show -p MainPID --value "$unit" 2>/dev/null || echo 0) == 0 ]]
printf 'T3 Code: observed Wayland window, pinned updates, Codex and sandbox: PASS\n' | tee "$evidence/result.txt"
