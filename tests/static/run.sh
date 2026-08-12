#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
for test in "$ROOT"/tests/static/test-*.sh; do
  printf '\n==> %s\n' "${test#$ROOT/}"
  bash "$test"
done
find "$ROOT" -type f -name '*.sh' -not -path '*/.git/*' -print0 | xargs -0 -n1 bash -n
! grep -RniE '\b(setenforce[[:space:]]+0|SELINUX=disabled|chmod[[:space:]]+-R[[:space:]]+777|curl[^|]*\|[[:space:]]*(ba)?sh)\b' "$ROOT" --exclude-dir=.git --exclude=run.sh
! grep -RniE '\b(hyprland|hypridle|hyprlock|xdg-desktop-portal-hyprland)\b' "$ROOT/config" "$ROOT/packages" "$ROOT/scripts" "$ROOT/tests" --exclude=run.sh
git -C "$ROOT" diff --check
printf '\nstatic suite: PASS\n'
