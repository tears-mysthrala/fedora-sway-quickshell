#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
evidence=${EVIDENCE_DIR:-$ROOT/.evidence/portals}
mkdir -p "$evidence"

"$ROOT/scripts/check-portals.sh" | tee "$evidence/interfaces.txt"
wpctl status >"$evidence/pipewire-before.txt"
grim "$evidence/direct-screenshot.png"
file "$evidence/direct-screenshot.png" | tee "$evidence/screenshot-type.txt"
clipboard_token="fedora-sway-clipboard-$RANDOM-$RANDOM"
printf '%s' "$clipboard_token" | wl-copy --paste-once
[[ $(wl-paste) == "$clipboard_token" ]]
printf 'Wayland clipboard round trip: PASS\n' | tee "$evidence/clipboard.txt"

cat <<'EOF'
[MANUAL] Open a GTK file chooser in a portal-aware application and confirm selection.
[MANUAL] Open an https URL through xdg-open and confirm the chosen browser.
[MANUAL] Serve tests/vm/screen-share.html on localhost, share an output in Firefox, and retain portal journal and wpctl status.
EOF
journalctl --user -b --no-pager -u xdg-desktop-portal.service -u xdg-desktop-portal-wlr.service -u xdg-desktop-portal-gtk.service >"$evidence/journal.txt"
