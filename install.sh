#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$ROOT
source "$ROOT/scripts/lib/common.sh"
source "$ROOT/scripts/lib/install-state.sh"

MODE=install
case ${1:-} in
  '') ;;
  --check) MODE=check ;;
  --dry-run) MODE=dry-run ;;
  *) die "Usage: ./install.sh [--check|--dry-run]" ;;
esac

(( EUID != 0 )) || die 'Run as the target desktop user, not root; sudo is requested only for DNF.'
[[ -r /etc/os-release ]] || die '/etc/os-release is unavailable.'
source /etc/os-release
[[ ${ID:-} == fedora ]] || die "Fedora is required (detected: ${ID:-unknown})."
[[ ${VERSION_ID%%.*} == "$SUPPORTED_FEDORA_RELEASE" ]] || die "Fedora $SUPPORTED_FEDORA_RELEASE is required (detected: ${VERSION_ID:-unknown})."
command -v dnf >/dev/null || die 'dnf is unavailable.'

log INFO "Checking Fedora $SUPPORTED_FEDORA_RELEASE repository metadata"
dnf -q makecache >/dev/null || die 'DNF metadata/connectivity check failed.'

mapfile -t packages < <(load_packages)
declare -a missing=()
for package in "${packages[@]}"; do
  if rpm -q "$package" >/dev/null 2>&1; then
    log OK "$package already installed"
    continue
  fi
  missing+=("$package")
  if ! query_output=$(dnf -q repoquery --available --latest-limit 1 \
    --arch="$(uname -m),noarch" --qf '%{repoid}' "$package" 2>&1); then
    die "DNF could not resolve $package: $query_output"
  fi
  mapfile -t origins < <(printf '%s\n' "$query_output" | sed '/^[[:space:]]*$/d' | sort -u)
  (( ${#origins[@]} > 0 )) || die "Package unavailable: $package"
  for origin in "${origins[@]}"; do
    is_allowed_repo "$origin" || die "$package resolves from unauthorized repository: $origin"
  done
  log OK "$package resolves from Fedora repository: ${origins[*]}"
done

if [[ $MODE == check ]]; then
  (( ${#missing[@]} == 0 )) || die "Missing packages: ${missing[*]}"
  log OK 'Package and platform checks passed.'
  exit 0
fi

if [[ $MODE == dry-run ]]; then
  log INFO "Would install: ${missing[*]:-(none)}"
  for name in sway quickshell swayidle swaylock; do
    log INFO "Would manage ~/.config/$name"
  done
  log INFO 'Would manage project files within ~/.config/environment.d and ~/.config/systemd/user'
  exit 0
fi

if (( ${#missing[@]} > 0 )); then
  log INFO "Installing ${#missing[@]} packages with DNF"
  # Keep the declared surface exact. Fedora recommends large optional payloads
  # for some developer tools (npm, docs, cross-architecture emulators); none is
  # required by this project and all remain available for explicit installation.
  sudo dnf install --assumeyes --setopt=install_weak_deps=False "${missing[@]}"
  for package in "${missing[@]}"; do record_installed_package "$package"; done
fi

ensure_managed_link "$ROOT/config/sway" "$HOME/.config/sway"
ensure_managed_link "$ROOT/config/quickshell" "$HOME/.config/quickshell"
ensure_managed_link "$ROOT/config/swayidle" "$HOME/.config/swayidle"
ensure_managed_link "$ROOT/config/swaylock" "$HOME/.config/swaylock"
ensure_managed_link "$ROOT/config/environment.d/10-fedora-sway-demo.conf" "$HOME/.config/environment.d/10-fedora-sway-demo.conf"
for unit in "$ROOT"/config/systemd/user/*; do
  ensure_managed_link "$unit" "$HOME/.config/systemd/user/$(basename "$unit")"
done
ensure_managed_link "$ROOT/scripts" "$HOME/.local/bin/fedora-sway-demo"

systemctl --user daemon-reload
log OK 'Installation converged successfully.'
log INFO 'Log out and start the packaged Sway session. A reboot is not required.'
