#!/usr/bin/env bash
# check_version_sync.sh — Fails if zorphy and zorphy_annotation versions diverge.
# Usage: ./scripts/check_version_sync.sh
# Exit code: 0 = in sync, 1 = diverged.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

ZORPHY_VER="$(grep '^version:' "$ROOT_DIR/zorphy/pubspec.yaml" | head -1 | awk '{print $2}')"
ZA_VER="$(grep '^version:' "$ROOT_DIR/zorphy_annotation/pubspec.yaml" | head -1 | awk '{print $2}')"

if [ "$ZORPHY_VER" != "$ZA_VER" ]; then
  echo "ERROR: version mismatch — zorphy=$ZORPHY_VER, zorphy_annotation=$ZA_VER"
  exit 1
fi

echo "OK: both packages at version $ZORPHY_VER"
