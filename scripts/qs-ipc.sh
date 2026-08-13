#!/usr/bin/env bash
set -euo pipefail

# Systemd services can launch before a calling terminal has inherited the same
# display identity. IPC is already restricted to this Unix user; selecting its
# instance across displays also makes diagnostics over SSH deterministic.
exec qs ipc --any-display "$@"
