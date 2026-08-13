#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)

grep -Fq 'dnf -q makecache >/dev/null' "$ROOT/install.sh"
if grep -Eq 'dnf .*makecache .*--timer' "$ROOT/install.sh"; then exit 1; fi
grep -Fq -- '--arch="$(uname -m),noarch"' "$ROOT/install.sh"
if grep -Fq -- '--archlist=' "$ROOT/install.sh"; then exit 1; fi
grep -Fq 'DNF could not resolve' "$ROOT/install.sh"
grep -Fq -- '--installed --qf' "$ROOT/install.sh"
grep -Fq 'Installed package $package came from unauthorized repository' "$ROOT/install.sh"

printf 'dnf5 compatibility contract: PASS\n'
