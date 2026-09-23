#!/usr/bin/env bash
# Niri spawn-at-startup helper: align the systemd user manager with the Niri
# session (environment.d defaults to the Sway desktop names) and bring up the
# shared session target that also serves the Sway session.
set -euo pipefail

systemctl --user set-environment XDG_CURRENT_DESKTOP=niri XDG_SESSION_DESKTOP=niri
dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP=niri XDG_SESSION_DESKTOP=niri
systemctl --user start fedora-sway-session.target
systemctl --user start fedora-sway-wallpaper.service
