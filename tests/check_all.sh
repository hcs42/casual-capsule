#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# Copyright (C) 2026- Cursor Insight
#
# SPDX-License-Identifier: Apache-2.0
#-------------------------------------------------------------------------------
# Run all lint checks.
#-------------------------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)"
cd "$ROOT_DIR"

shopt -s nullglob

dclint_files=(
  compose.y*ml
  tests/fixtures/*/compose.y*ml
)
hadolint_files=(
  Dockerfile
  tests/fixtures/*/Dockerfile
)
shellcheck_files=(
  *.sh
  docker/*.sh
  tests/*.sh
  tests/fixtures/*/*.sh
)

run_linter() {
  local tool="$1"
  local category="$2"
  shift 2
  local files=("$@")

  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'WARNING: %s not found; skipping %s lint.\n' \
      "$tool" "$category" >&2
    return 0
  fi

  if [[ "${#files[@]}" -eq 0 ]]; then
    printf 'INFO: no %s files; skipping %s.\n' "$category" "$tool"
    return 0
  fi

  printf '%s: checking %d files\n' "$tool" "${#files[@]}"
  if "$tool" "${files[@]}"; then
    printf 'PASS: %s checks passed.\n' "$tool"
    return 0
  fi

  printf 'FAIL: %s checks failed.\n' "$tool" >&2
  return 1
}

status=0
printf '%s\n' 'Running lint checks...'
run_linter dclint Compose "${dclint_files[@]}" || status=1
run_linter hadolint Dockerfile "${hadolint_files[@]}" || status=1
run_linter shellcheck shell "${shellcheck_files[@]}" || status=1

if [[ "$status" -eq 0 ]]; then
  printf '%s\n' 'All available lint checks passed.'
fi

exit "$status"
