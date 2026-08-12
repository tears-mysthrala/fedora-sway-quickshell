#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
output=$("$ROOT/scripts/vm/create.sh" --dry-run)
grep -Fq 'fedora-sway-demo-f44' <<<"$output"
grep -Fq 'Fedora-Server-dvd-x86_64-44' <<<"$output"
grep -Fq 'verify checksum' <<<"$output"
grep -Fq 'SUPPORTED_FEDORA_RELEASE=44' "$ROOT/config/project.conf"
echo 'vm harness: PASS'
