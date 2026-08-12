#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
PROJECT_ROOT=$ROOT
source "$ROOT/scripts/lib/common.sh"
release_build=1.7
base="https://download.fedoraproject.org/pub/fedora/linux/releases/$SUPPORTED_FEDORA_RELEASE/Server/x86_64/iso"
dir="$ROOT/.vm"
iso="Fedora-Server-dvd-x86_64-$SUPPORTED_FEDORA_RELEASE-$release_build.iso"
checksum="Fedora-Server-$SUPPORTED_FEDORA_RELEASE-$release_build-x86_64-CHECKSUM"
mkdir -p "$dir"
curl --fail --location --continue-at - --output "$dir/$checksum" "$base/$checksum"
curl --fail --location --continue-at - --output "$dir/$iso" "$base/$iso"
(cd "$dir" && sha256sum --ignore-missing -c "$checksum")

