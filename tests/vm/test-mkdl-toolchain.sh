#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
evidence=${EVIDENCE_DIR:-$ROOT/.evidence/mkdl-toolchain}
mkdir -p "$evidence"

work=$(mktemp -d)
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT

(
  cd "$work"
  elixir --version | tee "$evidence/elixir-version.txt"
  mix new smoke --sup | tee "$evidence/mix-new.txt"
  cd smoke
  mix test | tee "$evidence/mix-test.txt"
)

# shellcheck source=config/mkdl-toolchain.conf
source "$ROOT/config/mkdl-toolchain.conf"
podman image inspect --format '{{.Digest}}' "$MKDL_ELIXIR_IMAGE" \
  | tee "$evidence/image-digest.txt" \
  | grep -Fxq "sha256:${MKDL_ELIXIR_IMAGE##*@sha256:}"
printf 'MKDL Elixir toolchain: pinned image, project generation and tests: PASS\n' | tee "$evidence/result.txt"
