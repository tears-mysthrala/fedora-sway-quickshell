#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$ROOT
# shellcheck source=scripts/lib/common.sh
source "$ROOT/scripts/lib/common.sh"

printf 'Fedora Sway Workstation %s Update Check\n\n' "$PROJECT_VERSION"

update_log=$(mktemp)
trap 'rm -f -- "$update_log"' EXIT
dnf_status=0
dnf -q check-upgrade >"$update_log" 2>&1 || dnf_status=$?
case $dnf_status in
  0) printf '[OK] Fedora packages current\n' ;;
  100) printf '[INFO] Fedora package updates available; run sudo dnf upgrade --refresh\n' ;;
  *) printf '[WARN] Fedora update check failed (dnf exit %s)\n' "$dnf_status" ;;
esac

latest_codex=$(npm view @openai/codex version)
if [[ $latest_codex == "$CODEX_CLI_VERSION" ]]; then
  printf '[OK] Codex CLI pin %s is current\n' "$CODEX_CLI_VERSION"
else
  printf '[INFO] Codex CLI %s available; pinned %s\n' "$latest_codex" "$CODEX_CLI_VERSION"
fi

latest_t3=$(curl --fail --silent --show-error --location \
  https://api.github.com/repos/pingdotgg/t3code/releases/latest | jq -r '.tag_name | ltrimstr("v")')
if [[ $latest_t3 == "$T3_CODE_VERSION" ]]; then
  printf '[OK] T3 Code pin %s is current\n' "$T3_CODE_VERSION"
else
  printf '[INFO] T3 Code %s available; pinned %s\n' "$latest_t3" "$T3_CODE_VERSION"
fi

printf '\nPins are updated only through a reviewed repository change with fresh hashes and VM acceptance.\n'
