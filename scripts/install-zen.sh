#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH=$(readlink -f -- "${BASH_SOURCE[0]}")
ROOT=$(cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)
# shellcheck source=config/project.conf
source "$ROOT/config/project.conf"

mode=${1:-install}
[[ $mode == install || $mode == check || $mode == dry-run ]] || {
  printf 'Usage: %s [install|check|dry-run]\n' "$0" >&2
  exit 2
}

asset_dir=${XDG_DATA_HOME:-$HOME/.local/share}/$PROJECT_ID/zen
browser=$asset_dir/zen/zen
archive_url=https://github.com/zen-browser/desktop/releases/download/$ZEN_VERSION/zen.linux-x86_64.tar.xz
version_ok() { [[ -x $browser ]] && [[ $($browser --version 2>/dev/null) == "Mozilla Zen $ZEN_VERSION" ]]; }

if [[ $mode == check ]]; then
  version_ok || { echo "Zen $ZEN_VERSION is missing or invalid." >&2; exit 1; }
  echo "Zen $ZEN_VERSION verified."
  exit 0
fi
if [[ $mode == dry-run ]]; then
  echo "Would install $archive_url below $asset_dir after SHA-256 verification."
  exit 0
fi
version_ok && { echo "Zen $ZEN_VERSION already verified."; exit 0; }

tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT
archive=$tmpdir/zen.tar.xz
curl --fail --location --proto '=https' --tlsv1.2 --output "$archive" "$archive_url"
printf '%s  %s\n' "$ZEN_SHA256" "$archive" | sha256sum --check
install -d -m 0700 -- "$asset_dir"
tar -xJf "$archive" -C "$asset_dir"
version_ok || { echo 'Extracted Zen binary failed its version check.' >&2; exit 1; }
echo "Installed Zen $ZEN_VERSION to $browser"
