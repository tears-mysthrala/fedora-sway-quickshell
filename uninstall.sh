#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$ROOT
source "$ROOT/scripts/lib/common.sh"

systemctl --user disable --now fedora-sway-session.target 2>/dev/null || true

manifest="$PROJECT_STATE_DIR/managed-links.tsv"
if [[ -f $manifest ]]; then
  while IFS=$'\t' read -r source destination backup; do
    [[ -n $destination ]] || continue
    if [[ -L $destination && $(readlink -- "$destination") == "$source" ]]; then
      unlink -- "$destination"
      log INFO "Removed managed link $destination"
      if [[ -n $backup && ( -e $backup || -L $backup ) && ! -e $destination && ! -L $destination ]]; then
        mv -- "$backup" "$destination"
        log INFO "Restored backup to $destination"
      fi
    else
      log INFO "Preserved changed path $destination"
    fi
  done <"$manifest"
fi

systemctl --user daemon-reload
codex_prefix=${XDG_DATA_HOME:-$HOME/.local/share}/$PROJECT_ID/codex
if [[ -x $codex_prefix/bin/codex ]] && command -v npm >/dev/null 2>&1; then
  npm uninstall --global --prefix "$codex_prefix" @openai/codex
  log INFO "Removed project-owned Codex CLI payload from $codex_prefix"
fi
if [[ -s $PROJECT_STATE_DIR/installed-packages.txt ]]; then
  log INFO 'Packages installed by the demo (not removed):'
  sed 's/^/  /' "$PROJECT_STATE_DIR/installed-packages.txt"
fi
