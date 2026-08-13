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
codex_prefix=${XDG_DATA_HOME:-$HOME/.local/share}/$PROJECT_ID/codex
codex_binary=$codex_prefix/bin/codex
declare -a missing=()
for package in "${packages[@]}"; do
  if rpm -q "$package" >/dev/null 2>&1; then
    mapfile -t installed_records < <(dnf -q repoquery --installed \
      --qf $'%{from_repo}\t%{name}\t%{epoch}\t%{version}\t%{release}\t%{arch}\n' "$package" |
      sed '/^[[:space:]]*$/d' | sort -u)
    (( ${#installed_records[@]} > 0 )) || die "DNF could not inspect installed package $package."
    for record in "${installed_records[@]}"; do
      IFS=$'\t' read -r origin installed_name installed_epoch installed_version installed_release installed_arch <<<"$record"
      if is_allowed_repo "$origin"; then continue; fi
      if [[ $origin == '<unknown>' ]]; then
        signature=$(rpm -q --qf '%{RSAHEADER:pgpsig}\n%{DSAHEADER:pgpsig}\n' "$package" | sed '/^(none)$/d')
        [[ -n $signature ]] || die "Installed package $package has no RPM header signature."
        mapfile -t available_records < <(dnf -q repoquery --available \
          --qf $'%{repoid}\t%{name}\t%{epoch}\t%{version}\t%{release}\t%{arch}\n' "$package" |
          sed '/^[[:space:]]*$/d' | sort -u)
        matched_allowed_nevra=false
        for available_record in "${available_records[@]}"; do
          IFS=$'\t' read -r available_repo available_name available_epoch available_version available_release available_arch <<<"$available_record"
          if is_allowed_repo "$available_repo" &&
             [[ $available_name == "$installed_name" && $available_epoch == "$installed_epoch" &&
                $available_version == "$installed_version" && $available_release == "$installed_release" &&
                $available_arch == "$installed_arch" ]]; then
            matched_allowed_nevra=true
            break
          fi
        done
        $matched_allowed_nevra || die "Installed package $package has unknown origin and no exact match in an allowed repository."
        log OK "$package installed origin unavailable; exact signed package matches an allowed Fedora repository"
        continue
      fi
      die "Installed package $package came from unauthorized repository: $origin"
    done
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
  [[ -x $codex_binary ]] || die 'Codex CLI is not installed by this project.'
  [[ $($codex_binary --version) == "codex-cli $CODEX_CLI_VERSION" ]] ||
    die "Codex CLI version does not match $CODEX_CLI_VERSION."
  "$ROOT/scripts/install-t3code.sh" check
  "$ROOT/scripts/system-setup.sh" check
  log OK 'Package and platform checks passed.'
  exit 0
fi

if [[ $MODE == dry-run ]]; then
  log INFO "Would install: ${missing[*]:-(none)}"
  log INFO "Would install @openai/codex@$CODEX_CLI_VERSION under $codex_prefix"
  "$ROOT/scripts/install-t3code.sh" dry-run
  "$ROOT/scripts/system-setup.sh" dry-run
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

if [[ ! -x $codex_binary || $($codex_binary --version 2>/dev/null || true) != "codex-cli $CODEX_CLI_VERSION" ]]; then
  codex_integrity=$(npm view "@openai/codex@$CODEX_CLI_VERSION" dist.integrity)
  [[ $codex_integrity == "$CODEX_CLI_INTEGRITY" ]] ||
    die "Codex CLI registry integrity mismatch for $CODEX_CLI_VERSION."
  log INFO "Installing @openai/codex@$CODEX_CLI_VERSION into the project-owned user prefix"
  npm install --global --prefix "$codex_prefix" --ignore-scripts --no-audit --no-fund \
    "@openai/codex@$CODEX_CLI_VERSION"
fi

"$ROOT/scripts/install-t3code.sh" install

ensure_managed_link "$ROOT/config/sway" "$HOME/.config/sway"
ensure_managed_link "$ROOT/config/quickshell" "$HOME/.config/quickshell"
ensure_managed_link "$ROOT/config/swayidle" "$HOME/.config/swayidle"
ensure_managed_link "$ROOT/config/swaylock" "$HOME/.config/swaylock"
ensure_managed_link "$ROOT/config/environment.d/10-fedora-sway-demo.conf" "$HOME/.config/environment.d/10-fedora-sway-demo.conf"
ensure_managed_link "$ROOT/config/xdg-desktop-portal/sway-portals.conf" "$HOME/.config/xdg-desktop-portal/sway-portals.conf"
for unit in "$ROOT"/config/systemd/user/*; do
  ensure_managed_link "$unit" "$HOME/.config/systemd/user/$(basename "$unit")"
done
ensure_managed_link "$ROOT/scripts" "$HOME/.local/bin/fedora-sway-demo"
ensure_managed_link "$codex_binary" "$HOME/.local/bin/codex"
ensure_managed_link "$ROOT/scripts/t3code.sh" "$HOME/.local/bin/t3code"
ensure_managed_link "$ROOT/config/applications/t3code.desktop" "$HOME/.local/share/applications/t3code.desktop"
for beam_command in mix elixir iex; do
  ensure_managed_link "$ROOT/scripts/mkdl-elixir.sh" "$HOME/.local/bin/$beam_command"
done

xdg-user-dirs-update
sudo "$ROOT/scripts/system-setup.sh" install

systemctl --user daemon-reload
log OK 'Installation converged successfully.'
log INFO 'Reboot once to enter the greetd login on graphical.target; TTY recovery remains available.'
