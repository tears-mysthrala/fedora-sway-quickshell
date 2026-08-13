#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=config/mkdl-toolchain.conf
source "$ROOT/config/mkdl-toolchain.conf"

command -v podman >/dev/null || {
  echo "podman is required; run ./install.sh first" >&2
  exit 1
}

workdir=${MKDL_WORKDIR:-$PWD}
[[ -d $workdir ]] || { echo "not a directory: $workdir" >&2; exit 1; }
(( $# > 0 )) || set -- elixir
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/fedora-sway-quickshell-demo/mkdl-home
mkdir -p -- "$cache_dir"
chmod 0700 -- "$cache_dir"

exec podman run --rm --userns=keep-id \
  --workdir /workspace \
  --volume "$workdir:/workspace:Z" \
  --volume "$cache_dir:/tmp/mkdl-home:Z" \
  --env HOME=/tmp/mkdl-home \
  "$MKDL_ELIXIR_IMAGE" "$@"
