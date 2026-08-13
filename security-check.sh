#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$ROOT
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"
failures=0
check() { if "$@"; then printf '[OK] %s\n' "$*"; else printf '[FAIL] %s\n' "$*"; failures=$((failures + 1)); fi; }

printf 'Fedora Sway Workstation Security Check\n\n'
check test "$(getenforce)" = Enforcing
check systemctl is-active --quiet firewalld.service
check test ! -e /etc/sudoers.d/fedora-sway-quickshell-demo
check test ! -u "$HOME/.local/bin/t3code"
check "$ROOT/scripts/install-t3code.sh" check
mkdl_cache="$HOME/.cache/$PROJECT_ID/mkdl-home"
if [[ -d $mkdl_cache ]]; then
  check test "$(stat -c %a "$mkdl_cache")" = 700
else
  printf '[OK] MKDL tool cache not created before first use\n'
fi

if find "$ROOT/config" "$ROOT/scripts" -xdev -perm -0002 -print -quit | grep -q .; then
  printf '[FAIL] Project configuration contains world-writable files\n'
  failures=$((failures + 1))
else
  printf '[OK] Project configuration is not world-writable\n'
fi

exit "$failures"
