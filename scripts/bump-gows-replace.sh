#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WHATSMMEOW_ROOT="${WHATSMMEOW_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
DEFAULT_PARENT_ROOT="$(cd "$WHATSMMEOW_ROOT/.." && pwd)"
WAHA_FORGE_ROOT="${WAHA_FORGE_ROOT:-$DEFAULT_PARENT_ROOT/WahaForge}"
GOWS_SRC="${GOWS_SRC:-$WAHA_FORGE_ROOT/gows/src}"

if [[ ! -d "$WHATSMMEOW_ROOT" ]]; then
  echo "[bump-gows-replace] WHATSMMEOW_ROOT not found: $WHATSMMEOW_ROOT"
  exit 1
fi

if [[ ! -d "$GOWS_SRC" ]]; then
  echo "[bump-gows-replace] GOWS_SRC not found: $GOWS_SRC"
  exit 1
fi

echo "[bump-gows-replace] updating replace in $GOWS_SRC/go.mod"
cd "$GOWS_SRC"
go mod edit -replace=go.mau.fi/whatsmeow="$WHATSMMEOW_ROOT"

echo "[bump-gows-replace] running go mod tidy"
go mod tidy

echo "[bump-gows-replace] done"
