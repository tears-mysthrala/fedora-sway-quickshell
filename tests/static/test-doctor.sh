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
grep -Fq 'org.freedesktop.secrets' "$doctor"
grep -Fq 'T3 Code $T3_CODE_VERSION verified' "$doctor"
grep -Fq 'ChatGPT desktop app present' "$doctor"
grep -Fq 'TuneD power profiles active on D-Bus' "$doctor"
grep -Fq 'systemctl --user show-environment' "$doctor"
grep -Fq 'NetworkManager API and Quickshell event listener responsive' "$doctor"
grep -Fq 'readlink -f -- "$(command -v elixir)"' "$doctor"
grep -Fq 'Animations:' "$doctor"
grep -Fq 'clipboard history service active' "$doctor"
grep -Fq 'wallpaper rotation timer active' "$doctor"
grep -Fq "xdg-mime query default image/png" "$doctor"
grep -Fq 'findmnt -no FSTYPE /develop' "$doctor"
if grep -Eq 'command -v sway.*ok|command -v quickshell.*ok' "$doctor"; then exit 1; fi
echo 'doctor contract: PASS'
