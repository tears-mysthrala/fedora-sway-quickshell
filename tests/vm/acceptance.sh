#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
evidence=${EVIDENCE_DIR:-$ROOT/.evidence/acceptance-$(date +%Y%m%d-%H%M%S)}
mkdir -p "$evidence"

source "$ROOT/config/project.conf"
source /etc/os-release
[[ $ID == fedora && ${VERSION_ID%%.*} == "$SUPPORTED_FEDORA_RELEASE" ]]
getenforce | tee "$evidence/selinux.txt" | grep -qx Enforcing
systemctl is-active firewalld | tee "$evidence/firewalld.txt" | grep -qx active

"$ROOT/install.sh" 2>&1 | tee "$evidence/install-first.txt"
"$ROOT/install.sh" 2>&1 | tee "$evidence/install-second.txt"
"$ROOT/install.sh" --check 2>&1 | tee "$evidence/install-check.txt"

if ! swaymsg -t get_version >/dev/null 2>&1; then
  printf 'Installation verified. Log in to Sway, then rerun this script for session acceptance.\n'
  exit 3
fi

"$ROOT/doctor.sh" 2>&1 | tee "$evidence/doctor.txt"
"$ROOT/tests/vm/test-portals.sh" 2>&1 | tee "$evidence/portals.txt"
"$ROOT/tests/vm/test-quickshell-isolation.sh" 2>&1 | tee "$evidence/isolation.txt"
"$ROOT/benchmark.sh" snapshot >"$evidence/performance-snapshot.tsv"
printf 'Automated acceptance complete. Run benchmark.sh ab for the deliberate 20-minute baseline.\n'
