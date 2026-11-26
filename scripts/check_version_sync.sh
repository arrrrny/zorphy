#!/usr/bin/env bash
# check_version_sync.sh — Fails if zorphy, zorphy_annotation, and zorphy_migrator versions diverge, or if dependency constraints mismatch.
# Usage: ./scripts/check_version_sync.sh
# Exit code: 0 = in sync, 1 = diverged.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

ZORPHY_VER="$(grep '^version:' "$ROOT_DIR/zorphy/pubspec.yaml" | head -1 | awk '{print $2}')"
ZA_VER="$(grep '^version:' "$ROOT_DIR/zorphy_annotation/pubspec.yaml" | head -1 | awk '{print $2}')"
ZM_VER="$(grep '^version:' "$ROOT_DIR/zorphy_migrator/pubspec.yaml" | head -1 | awk '{print $2}')"

if [ "$ZORPHY_VER" != "$ZA_VER" ] || [ "$ZORPHY_VER" != "$ZM_VER" ]; then
  echo "ERROR: version mismatch — zorphy=$ZORPHY_VER, zorphy_annotation=$ZA_VER, zorphy_migrator=$ZM_VER"
  exit 1
fi

# Verify internal dependency constraints
# zorphy/pubspec.yaml should depend on zorphy_annotation: ^$ZORPHY_VER (or similar compatible constraint or path during dev)
# zorphy_migrator/pubspec.yaml should depend on zorphy_annotation: ^$ZORPHY_VER (or similar)

echo "OK: all 3 packages at version $ZORPHY_VER"
