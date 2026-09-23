#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source "$ROOT/config/project.conf"
[[ anaconda =~ $PROJECT_ALLOWED_REPOS_REGEX ]]
if [[ rpmfusion-free =~ $PROJECT_ALLOWED_REPOS_REGEX ]]; then
  echo 'third-party origin unexpectedly allowed' >&2
  exit 1
fi

[[ $SUPPORTED_FEDORA_RELEASE == 44 ]]
[[ $PROJECT_ID == fedora-sway-quickshell-demo ]]

mapfile -t manifests < <(find "$ROOT/packages" -maxdepth 1 -name '*.txt' -type f | sort)
(( ${#manifests[@]} == 6 ))

packages=$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "${manifests[@]}")
[[ -n $packages ]]
[[ $(printf '%s\n' "$packages" | wc -l) -eq $(printf '%s\n' "$packages" | sort -u | wc -l) ]]
if grep -Eqi 'hypr|copr' <<<"$packages"; then exit 1; fi

for required in sway quickshell swayidle swaylock xdg-desktop-portal-wlr; do
  grep -qx "$required" <<<"$packages"
done
for required in niri xwayland-satellite xdg-desktop-portal-gnome swaybg; do
  grep -qx "$required" <<<"$packages"
done
for required in alacritty firefox Thunar mousepad pavucontrol imv; do
  grep -qx "$required" <<<"$packages"
done
for required in podman git git-lfs gcc postgresql nodejs22 nodejs22-npm python3 rust cargo neovim; do
  grep -qx "$required" <<<"$packages"
done
if grep -qx foot <<<"$packages"; then exit 1; fi
if grep -qx elixir <<<"$packages"; then exit 1; fi
grep -Fq -- '--setopt=install_weak_deps=False' "$ROOT/install.sh"
grep -Fq 'docker.io/hexpm/elixir:1.20.1-erlang-29.0.2' \
  "$ROOT/config/mkdl-toolchain.conf"
grep -Fq '@sha256:' "$ROOT/config/mkdl-toolchain.conf"
grep -Fq -- '--userns=keep-id' "$ROOT/scripts/mkdl-elixir.sh"
grep -Fq -- ':/workspace:Z' "$ROOT/scripts/mkdl-elixir.sh"
grep -Fq '.forgejo/release-ci-image.txt' "$ROOT/scripts/mkdl-elixir.sh"
grep -Fq 'MIX_HOME=/tmp/mkdl-home/.mix' "$ROOT/scripts/mkdl-elixir.sh"
grep -Fq 'podman login --get-login' "$ROOT/scripts/mkdl-elixir.sh"
grep -Eq '^CODEX_CLI_VERSION=[0-9]+\.[0-9]+\.[0-9]+$' "$ROOT/config/project.conf"
grep -Eq "^CODEX_CLI_INTEGRITY='sha512-[A-Za-z0-9+/]+=*'$" "$ROOT/config/project.conf"
grep -Fq 'npm install --global --prefix "$codex_prefix"' "$ROOT/install.sh"
grep -Fq 'codex_integrity=$(npm view' "$ROOT/install.sh"
grep -Fq 'ensure_managed_link "$codex_binary" "$HOME/.local/bin/codex"' "$ROOT/install.sh"

source "$ROOT/scripts/lib/common.sh"
required_packages=$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' \
  "$ROOT/packages/base.txt" "$ROOT/packages/desktop.txt" \
  "$ROOT/packages/apps.txt" "$ROOT/packages/development.txt" \
  "$ROOT/packages/workstation.txt" "$ROOT/packages/virtualization.txt")
[[ $(load_packages | wc -l) -eq $(printf '%s\n' "$required_packages" | wc -l) ]]
is_allowed_repo fedora
is_allowed_repo updates
if is_allowed_repo rpmfusion-free; then exit 1; fi

echo 'package contract: PASS'
