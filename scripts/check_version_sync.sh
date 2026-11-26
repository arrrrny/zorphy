#!/usr/bin/env bash
# check_version_sync.sh — Fails if zorphy, zorphy_annotation, and zorphy_migrator versions diverge,
# or if zorphy / zorphy_migrator depend on zorphy_annotation through anything other than a local path
# or the constraint ^<that version>.
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

# Verify the internal dependency on zorphy_annotation. The packages are
# version-locked, so a hosted dependency must be exactly ^$ZORPHY_VER (the
# form publish.sh writes). A path dependency is local development and is
# accepted as-is.
for pkg in zorphy zorphy_migrator; do
  PUBSPEC="$ROOT_DIR/$pkg/pubspec.yaml"
  CONSTRAINT="$(awk '
    /^  zorphy_annotation:[ \t]*[^ \t]/ { print $2; exit }
    /^  zorphy_annotation:[ \t]*$/ { in_dep = 1; next }
    in_dep && /^    path:/ { print "path"; exit }
    in_dep && /^  [^ ]/ { exit }
  ' "$PUBSPEC")"
  case "$CONSTRAINT" in
    "path") ;;
    "^$ZORPHY_VER") ;;
    *)
      echo "ERROR: $pkg/pubspec.yaml must depend on zorphy_annotation: ^$ZORPHY_VER (found: ${CONSTRAINT:-none})"
      exit 1
      ;;
  esac
done

echo "OK: all 3 packages at version $ZORPHY_VER, with matching zorphy_annotation dependency constraints"
