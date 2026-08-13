#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
doctor="$ROOT/doctor.sh"
[[ -x $doctor ]]
grep -Fq 'swaymsg -t get_version' "$doctor"
grep -Fq 'wpctl status' "$doctor"
grep -Fq 'busctl --user' "$doctor"
grep -Fq 'systemctl --user is-active' "$doctor"
grep -Fq 'PERFORMANCE' "$doctor"
grep -Fq 'DEVELOPMENT' "$doctor"
grep -Fq 'Codex CLI $CODEX_CLI_VERSION available' "$doctor"
grep -Fq 'Animations:' "$doctor"
! grep -Eq 'command -v sway.*ok|command -v quickshell.*ok' "$doctor"
echo 'doctor contract: PASS'
