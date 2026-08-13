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

generated="$HOME/.config/generated"
ensure_managed_link "$TEST_ROOT/repo/config" "$generated"
unlink "$generated"
printf 'application-generated\n' >"$generated"
ensure_managed_link "$TEST_ROOT/repo/config" "$generated"
[[ $(awk -F '\t' -v destination="$generated" '$2 == destination {count++} END {print count+0}' \
  "$PROJECT_STATE_DIR/managed-links.tsv") == 1 ]]
generated_backup=$(awk -F '\t' -v destination="$generated" '$2 == destination {print $3}' \
  "$PROJECT_STATE_DIR/managed-links.tsv")
grep -qx application-generated "$generated_backup"

record_installed_package sway
record_installed_package sway
[[ $(grep -cx sway "$PROJECT_STATE_DIR/installed-packages.txt") == 1 ]]

echo 'install state: PASS'
