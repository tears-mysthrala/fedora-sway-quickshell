#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT
export HOME="$TEST_ROOT/home"
export XDG_STATE_HOME="$TEST_ROOT/state"
mkdir -p "$HOME/.config" "$TEST_ROOT/repo"
printf 'managed\n' >"$TEST_ROOT/repo/config"

source "$ROOT/scripts/lib/common.sh"
source "$ROOT/scripts/lib/install-state.sh"

printf 'personal\n' >"$HOME/.config/demo"
ensure_managed_link "$TEST_ROOT/repo/config" "$HOME/.config/demo"
[[ -L $HOME/.config/demo ]]
[[ $(readlink "$HOME/.config/demo") == "$TEST_ROOT/repo/config" ]]
mapfile -t backups < <(find "$PROJECT_STATE_DIR/backups" -type f)
(( ${#backups[@]} == 1 ))
grep -qx personal "${backups[0]}"

ensure_managed_link "$TEST_ROOT/repo/config" "$HOME/.config/demo"
mapfile -t backups_after < <(find "$PROJECT_STATE_DIR/backups" -type f)
(( ${#backups_after[@]} == 1 ))

record_installed_package sway
record_installed_package sway
[[ $(grep -cx sway "$PROJECT_STATE_DIR/installed-packages.txt") == 1 ]]

echo 'install state: PASS'
