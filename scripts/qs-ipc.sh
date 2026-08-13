#!/usr/bin/env bash
set -euo pipefail

# Quickshell 0.2.1 on Fedora scopes the IPC client differently when this
# display variable is present. The shell process keeps its Wayland environment;
# only this short-lived control client drops it.
exec env -u WAYLAND_DISPLAY qs ipc "$@"
