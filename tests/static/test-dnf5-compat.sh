#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)

grep -Fq 'dnf -q makecache >/dev/null' "$ROOT/install.sh"
! grep -Eq 'dnf .*makecache .*--timer' "$ROOT/install.sh"
grep -Fq -- '--arch="$(uname -m),noarch"' "$ROOT/install.sh"
! grep -Fq -- '--archlist=' "$ROOT/install.sh"
grep -Fq 'DNF could not resolve' "$ROOT/install.sh"

printf 'dnf5 compatibility contract: PASS\n'
