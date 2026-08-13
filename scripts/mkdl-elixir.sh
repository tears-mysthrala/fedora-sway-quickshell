#!/usr/bin/env bash
set -euo pipefail

invoked_as=$(basename -- "${BASH_SOURCE[0]}")
SCRIPT_PATH=$(readlink -f -- "${BASH_SOURCE[0]}")
ROOT=$(cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)
# shellcheck source=config/mkdl-toolchain.conf
source "$ROOT/config/mkdl-toolchain.conf"

command -v podman >/dev/null || {
  echo "podman is required; run ./install.sh first" >&2
  exit 1
}

workdir=${MKDL_WORKDIR:-$PWD}
[[ -d $workdir ]] || { echo "not a directory: $workdir" >&2; exit 1; }
case $invoked_as in
  mix|elixir|iex) set -- "$invoked_as" "$@" ;;
  *) (( $# > 0 )) || set -- elixir ;;
esac
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/fedora-sway-quickshell-demo/mkdl-home
mkdir -p -- "$cache_dir"
chmod 0700 -- "$cache_dir"

toolchain_image=$MKDL_ELIXIR_IMAGE
ci_image_file=$workdir/.forgejo/release-ci-image.txt
if [[ -r $ci_image_file ]]; then
  read -r toolchain_image <"$ci_image_file"
  [[ $toolchain_image =~ ^[a-zA-Z0-9._:/-]+@sha256:[a-f0-9]{64}$ ]] || {
    echo "invalid pinned CI image in $ci_image_file" >&2
    exit 1
  }
fi

registry=${toolchain_image%%/*}
if [[ $registry == herrementari.mkdl.jp ]] && \
   ! podman image exists "$toolchain_image" 2>/dev/null && \
   ! podman login --get-login "$registry" >/dev/null 2>&1; then
  printf 'The Kurogane CI image is private. Authenticate once, then retry:\n  podman login %s\n' "$registry" >&2
  exit 1
fi

podman_args=(run --rm --userns=keep-id --network=host)
for variable in MIX_ENV DATABASE_URL PGHOST PGPORT PGUSER PGPASSWORD; do
  [[ -v $variable ]] && podman_args+=(--env "$variable")
done

exec podman "${podman_args[@]}" \
  --workdir /workspace \
  --volume "$workdir:/workspace:Z" \
  --volume "$cache_dir:/tmp/mkdl-home:Z" \
  --env HOME=/tmp/mkdl-home \
  --env MIX_HOME=/tmp/mkdl-home/.mix \
  --env HEX_HOME=/tmp/mkdl-home/.hex \
  --env XDG_CACHE_HOME=/tmp/mkdl-home/.cache \
  "$toolchain_image" "$@"
