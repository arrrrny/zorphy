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

# Update zorphy/pubspec.yaml to use hosted version reference and local path override
echo "📝 Updating zorphy/pubspec.yaml..."
cd zorphy

# Ensure pubspec.yaml uses hosted constraint for zorphy_annotation and pubspec_overrides.yaml has local path
perl -i -pe 'if (/^  zorphy_annotation: .+$/) { $_ = "  zorphy_annotation: ^2.5.0\n"; }' pubspec.yaml
cat << 'EOF' > pubspec_overrides.yaml
dependency_overrides:
  zorphy_annotation:
    path: ../zorphy_annotation
EOF

echo "  ✓ Updated zorphy_annotation to use local path in pubspec_overrides.yaml"
echo ""

cd "$REPO_ROOT"

echo "✅ Successfully updated to path references for development!"
echo ""
echo "📦 Active Dependencies:"
echo "   • zorphy → zorphy_annotation: ../zorphy_annotation"
echo ""
echo "✨ All packages now use local path references!"
