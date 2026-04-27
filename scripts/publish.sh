#!/bin/bash

# Monorepo publish script for zorphy
# Updates versions, CHANGELOGs, and pushes tags to trigger GitHub Actions publishing.
# Usage: ./scripts/publish.sh <version> [description]

set -e

# Get script directory and navigate to monorepo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

VERSION="$1"
DESCRIPTION="${2:-Release $VERSION}"

if [ -z "$VERSION" ]; then
    echo "❌ Error: Version is required."
    echo "Usage: $0 <version> [description]"
    exit 1
fi

# Validate version format
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format. Expected format: X.Y.Z (e.g., 1.2.0)"
    exit 1
fi

DATE=$(date +%Y-%m-%d)

echo "🚀 Streamlining release for zorphy version $VERSION..."
echo "📍 Working directory: $REPO_ROOT"

# Helper for cross-platform sed
safe_sed() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$1" "$2"
    else
        sed -i "$1" "$2"
    fi
}

# 1. Update zorphy_annotation
echo "📝 Updating zorphy_annotation..."
safe_sed "s/^version: .*/version: $VERSION/" zorphy_annotation/pubspec.yaml
if grep -q "## \[Unreleased\]" zorphy_annotation/CHANGELOG.md; then
    safe_sed "s/## \[Unreleased\]/## [$VERSION] - $DATE/" zorphy_annotation/CHANGELOG.md
fi

# 2. Update zorphy
echo "📝 Updating zorphy..."
safe_sed "s/^version: .*/version: $VERSION/" zorphy/pubspec.yaml
safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" zorphy/pubspec.yaml
if grep -q "## \[Unreleased\]" zorphy/CHANGELOG.md; then
    safe_sed "s/## \[Unreleased\]/## [$VERSION] - $DATE/" zorphy/CHANGELOG.md
fi

# Clean up pubspec_overrides.yaml (important for publishing)
if [ -f "zorphy/pubspec_overrides.yaml" ]; then
    echo "🧹 Cleaning zorphy/pubspec_overrides.yaml..."
    # We remove path overrides so it uses the pub.dev version
    rm -f zorphy/pubspec_overrides.yaml
fi

# 3. Update README
echo "📝 Updating README.md..."
safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" README.md
safe_sed "s/zorphy: .*/zorphy: ^$VERSION/" README.md

# 4. Commit changes
echo "🔨 Committing changes..."
git add .
git commit -m "chore: release v$VERSION" || echo "  ⚠️ No changes to commit"

# 5. Create PR (if gh CLI available)
if command -v gh &> /dev/null; then
    echo "🔄 Creating/Updating pull request..."
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    PR_TITLE="chore: release v$VERSION"
    PR_BODY="Release version $VERSION\n\n$DESCRIPTION"

    if gh pr list --head "$CURRENT_BRANCH" --json number | grep -q "\"number\""; then
        echo "  ✓ PR already exists for branch $CURRENT_BRANCH"
    else
        gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base master || echo "  ⚠️ Could not create PR automatically"
    fi
fi

# 6. Create and push tags
# Pushing these tags will trigger the 'Publish to Pub.dev' GitHub Action
echo "🏷️ Creating git tags..."
git tag -a "annotation-v$VERSION" -m "Release zorphy_annotation $VERSION" || echo "  ⚠️ Tag annotation-v$VERSION already exists"
git tag -a "v$VERSION" -m "Release zorphy $VERSION" || echo "  ⚠️ Tag v$VERSION already exists"

echo "📤 Pushing changes and tags to origin..."
git push origin "$(git rev-parse --abbrev-ref HEAD)"
git push origin --tags

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Release v$VERSION prepared and tags pushed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The GitHub Action 'Publish to Pub.dev' has been triggered."
echo "It will automatically publish:"
echo "  1. zorphy_annotation: $VERSION"
echo "  2. zorphy:            $VERSION"
echo ""
echo "Monitor progress here: https://github.com/arrrrny/zorphy/actions"
echo ""
