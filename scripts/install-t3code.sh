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

asset_dir=${XDG_DATA_HOME:-$HOME/.local/share}/$PROJECT_ID/t3code
appimage=$asset_dir/T3-Code-$T3_CODE_VERSION-x86_64.AppImage
url=https://github.com/pingdotgg/t3code/releases/download/v$T3_CODE_VERSION/T3-Code-$T3_CODE_VERSION-x86_64.AppImage

valid_asset() {
  [[ -x $appimage ]] || return 1
  printf '%s  %s\n' "$T3_CODE_SHA256" "$appimage" | sha256sum --check --status
}

if [[ $mode == check ]]; then
  valid_asset || { echo "T3 Code $T3_CODE_VERSION is missing or invalid." >&2; exit 1; }
  echo "T3 Code $T3_CODE_VERSION asset verified."
  exit 0
fi

if [[ $mode == dry-run ]]; then
  echo "Would install $url as $appimage after SHA-256 verification."
  exit 0
fi

valid_asset && { echo "T3 Code $T3_CODE_VERSION already verified."; exit 0; }
tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT
download=$tmpdir/t3code.AppImage
curl --fail --location --proto '=https' --tlsv1.2 --output "$download" "$url"
printf '%s  %s\n' "$T3_CODE_SHA256" "$download" | sha256sum --check
install -d -m 0700 -- "$asset_dir"
install -m 0755 -- "$download" "$appimage"
echo "Installed T3 Code $T3_CODE_VERSION to $appimage"
