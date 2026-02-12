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

# Update zorphy/pubspec.yaml to use path reference for zorphy_annotation
echo "📝 Updating zorphy/pubspec.yaml..."
cd zorphy

# Replace zorphy_annotation dependency from version to path
perl -i -0777 -pe 's/^  zorphy_annotation: .*\n/  zorphy_annotation:\n    path: ..\/zorphy_annotation\n/' pubspec.yaml

echo "  ✓ Updated zorphy_annotation to use local path"
echo ""

cd "$REPO_ROOT"

echo "✅ Successfully updated to path references for development!"
echo ""
echo "📦 Active Dependencies:"
echo "   • zorphy → zorphy_annotation: ../zorphy_annotation"
echo ""
echo "✨ All packages now use local path references!"
