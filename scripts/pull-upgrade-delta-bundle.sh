#!/usr/bin/env bash
# Refresh .upgrade-delta/ from a local upgrade-delta checkout (sibling by default).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${UPGRADE_DELTA_DIR:-$ROOT/../upgrade-delta}"
[[ -d "$SRC" ]] || { echo "FATAL: upgrade-delta not found at $SRC (set UPGRADE_DELTA_DIR)" >&2; exit 1; }
cd "$SRC"
bash scripts/sync-vendor-bundle.sh
rm -rf "$ROOT/.upgrade-delta"
cp -a "$SRC/.upgrade-delta" "$ROOT/.upgrade-delta"
echo "Updated $ROOT/.upgrade-delta from $SRC"
