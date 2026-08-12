#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source "$ROOT/config/project.conf"
name="fedora-sway-demo-f${SUPPORTED_FEDORA_RELEASE}"
virsh --connect qemu:///session start "$name" 2>/dev/null || true
exec virsh --connect qemu:///session console "$name"
