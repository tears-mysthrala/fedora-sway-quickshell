#!/usr/bin/env bash

if [[ -z ${PROJECT_ROOT:-} ]]; then
  PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
fi

# shellcheck source=../../config/project.conf
source "$PROJECT_ROOT/config/project.conf"

PROJECT_STATE_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/$PROJECT_ID

load_packages() {
  sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' \
    "$PROJECT_ROOT/packages/base.txt" "$PROJECT_ROOT/packages/desktop.txt" |
    LC_ALL=C sort -u
}

is_allowed_repo() {
  [[ ${1:-} =~ $PROJECT_ALLOWED_REPOS_REGEX ]]
}

log() {
  printf '[%s] %s\n' "$1" "$2"
}

die() {
  log FAIL "$1" >&2
  exit 1
}
