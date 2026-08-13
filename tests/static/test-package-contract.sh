#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source "$ROOT/config/project.conf"

[[ $SUPPORTED_FEDORA_RELEASE == 44 ]]
[[ $PROJECT_ID == fedora-sway-quickshell-demo ]]

mapfile -t manifests < <(find "$ROOT/packages" -maxdepth 1 -name '*.txt' -type f | sort)
(( ${#manifests[@]} == 5 ))

packages=$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "${manifests[@]}")
[[ -n $packages ]]
[[ $(printf '%s\n' "$packages" | wc -l) -eq $(printf '%s\n' "$packages" | sort -u | wc -l) ]]
! printf '%s\n' "$packages" | grep -Eqi 'hypr|copr'

for required in sway quickshell swayidle swaylock xdg-desktop-portal-wlr; do
  grep -qx "$required" <<<"$packages"
done
for required in alacritty firefox Thunar mousepad pavucontrol imv; do
  grep -qx "$required" <<<"$packages"
done
for required in podman git git-lfs gcc postgresql nodejs22 python3 rust cargo neovim; do
  grep -qx "$required" <<<"$packages"
done
! grep -qx foot <<<"$packages"
! grep -qx elixir <<<"$packages"
grep -Fq -- '--setopt=install_weak_deps=False' "$ROOT/install.sh"
grep -Fq 'docker.io/hexpm/elixir:1.20.1-erlang-29.0.2' \
  "$ROOT/config/mkdl-toolchain.conf"
grep -Fq '@sha256:' "$ROOT/config/mkdl-toolchain.conf"
grep -Fq -- '--userns=keep-id' "$ROOT/scripts/mkdl-elixir.sh"
grep -Fq -- ':/workspace:Z' "$ROOT/scripts/mkdl-elixir.sh"

source "$ROOT/scripts/lib/common.sh"
required_packages=$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' \
  "$ROOT/packages/base.txt" "$ROOT/packages/desktop.txt" \
  "$ROOT/packages/apps.txt" "$ROOT/packages/development.txt")
[[ $(load_packages | wc -l) -eq $(printf '%s\n' "$required_packages" | wc -l) ]]
is_allowed_repo fedora
is_allowed_repo updates
! is_allowed_repo rpmfusion-free

echo 'package contract: PASS'
