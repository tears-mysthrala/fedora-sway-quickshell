#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
SCRIPT=$ROOT/scripts/system-setup.sh

grep -Fq '[[ -L $display_manager_link ]]' "$SCRIPT" || {
  echo 'FAIL: display-manager detection must ignore an absent link' >&2
  exit 1
}
grep -Fq 'readlink -e -- "$display_manager_link"' "$SCRIPT" || {
  echo 'FAIL: display-manager detection must require a resolvable target' >&2
  exit 1
}
grep -Fq 'systemctl set-default graphical.target' "$SCRIPT" || {
  echo 'FAIL: the installed display manager must be reached at boot' >&2
  exit 1
}
grep -Fq 'default-target.before' "$SCRIPT" || {
  echo 'FAIL: the previous boot target must be recoverable' >&2
  exit 1
}
grep -Fq 'unit-states.before.tsv' "$SCRIPT" || {
  echo 'FAIL: service enable/active state must be recoverable' >&2
  exit 1
}
grep -Fq 'tracked_units=("$session_unit" "${managed_units[@]}")' "$SCRIPT" || {
  echo 'FAIL: greetd prior state must be recorded with other managed services' >&2
  exit 1
}
if grep -Fq 'systemctl disable greetd.service' "$SCRIPT"; then
  echo 'FAIL: uninstall must restore the recorded greetd state' >&2
  exit 1
fi
grep -Fq 'cp --archive -- "$managed" "$backup"' "$SCRIPT" || {
  echo 'FAIL: greetd backup must retain metadata and SELinux context' >&2
  exit 1
}

echo 'PASS: system setup guards display-manager detection'
