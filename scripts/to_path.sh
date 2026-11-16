#!/bin/bash

# Development setup script for zorphy - updates pubspec references to use local paths
# Usage: ./scripts/to_path.sh
#
# This script switches package dependencies to use local path references for development.

set -e

# Get script directory and navigate to monorepo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

echo "🔧 Switching to path references for development..."
echo "📍 Working directory: $REPO_ROOT"
echo ""

# Update zorphy/pubspec_overrides.yaml to use local path reference for zorphy_annotation
# while preserving any existing overrides (such as analyzer pins)
echo "📝 Updating zorphy/pubspec_overrides.yaml..."
OVERRIDES_FILE="zorphy/pubspec_overrides.yaml"
if [ -f "$OVERRIDES_FILE" ] && grep -q "^dependency_overrides:" "$OVERRIDES_FILE"; then
  if grep -q "^  zorphy_annotation:" "$OVERRIDES_FILE"; then
    perl -0777 -i -pe 's/  zorphy_annotation:\n(?:    .*\n)*/  zorphy_annotation:\n    path: ..\/zorphy_annotation\n/' "$OVERRIDES_FILE"
  else
    printf '  zorphy_annotation:\n    path: ../zorphy_annotation\n' >> "$OVERRIDES_FILE"
  fi
else
  cat << 'EOF' > "$OVERRIDES_FILE"
dependency_overrides:
  zorphy_annotation:
    path: ../zorphy_annotation
EOF
fi

echo "  ✓ Updated zorphy_annotation to use local path in pubspec_overrides.yaml"
echo ""
cd "$REPO_ROOT"

echo "✅ Successfully updated to path references for development!"
echo ""
echo "📦 Active Dependencies:"
echo "   • zorphy → zorphy_annotation: ../zorphy_annotation (via pubspec_overrides.yaml)"
echo ""
echo "✨ All packages now use local path references!"