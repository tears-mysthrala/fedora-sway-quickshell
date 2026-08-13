#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH=$(readlink -f -- "${BASH_SOURCE[0]}")
ROOT=$(cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)
# shellcheck source=config/project.conf
source "$ROOT/config/project.conf"

appimage=${XDG_DATA_HOME:-$HOME/.local/share}/$PROJECT_ID/t3code/T3-Code-$T3_CODE_VERSION-x86_64.AppImage
[[ -x $appimage ]] || { echo 'T3 Code is not installed; run ./install.sh.' >&2; exit 1; }
codex_path=${CODEX_CLI_PATH:-$HOME/.local/bin/codex}
[[ -x $codex_path ]] || { echo 'Codex CLI is unavailable; run ./install.sh.' >&2; exit 1; }

export CODEX_CLI_PATH=$codex_path
export ELECTRON_OZONE_PLATFORM_HINT=wayland
# The project installs an integrity-pinned AppImage and updates it only through
# install.sh/update-check.sh. T3 otherwise checks GitHub every four minutes,
# which defeats both that trust boundary and the idle-power policy.
export T3CODE_DISABLE_AUTO_UPDATE=true
# Electron's protocol registration rewrites its desktop file. Keep that
# mutable registration in the application-owned tree so the repository's
# launcher symlink remains the auditable source of truth.
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/$PROJECT_ID/t3code/xdg-data"
install -d -m 0700 "$XDG_DATA_HOME"
exec "$appimage" --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
