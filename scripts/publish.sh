#!/bin/bash

# Monorepo publish script for zorphy
# Updates versions, CHANGELOGs, publishes directly to pub.dev, then tags and pushes.
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

# Function to update package
update_package() {
    local pkg_dir="$1"
    local pkg_name="$2"

    echo "📝 Updating $pkg_name..."

    # Update pubspec version
    safe_sed "s/^version: .*/version: $VERSION/" "$pkg_dir/pubspec.yaml"

    # Update CHANGELOG
    if grep -q "## \[Unreleased\]" "$pkg_dir/CHANGELOG.md"; then
        safe_sed "s/## \[Unreleased\]/## [$VERSION] - $DATE/" "$pkg_dir/CHANGELOG.md"
    elif ! grep -q "## \[$VERSION\]" "$pkg_dir/CHANGELOG.md"; then
        # If no Unreleased and no current version, insert at top (after potential title)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "1i\\
## [$VERSION] - $DATE\\
\\
### Change\\
- $DESCRIPTION\\
" "$pkg_dir/CHANGELOG.md"
        else
            sed -i "1i ## [$VERSION] - $DATE\n\n### Change\n- $DESCRIPTION\n" "$pkg_dir/CHANGELOG.md"
        fi
    fi
}

# 1. Update zorphy_annotation
update_package "zorphy_annotation" "zorphy_annotation"

# 2. Update zorphy
update_package "zorphy" "zorphy"
# Also update the dependency on annotation
safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" "zorphy/pubspec.yaml"

# Clean up pubspec_overrides.yaml if it exists
if [ -f "zorphy/pubspec_overrides.yaml" ]; then
    echo "🧹 Cleaning zorphy/pubspec_overrides.yaml..."
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

# 6. Publish to pub.dev directly
echo "📦 Publishing zorphy_annotation v$VERSION..."
cd "$REPO_ROOT/zorphy_annotation"
dart pub publish --force || echo "  ⚠️ zorphy_annotation publish failed or already published"

echo "📦 Publishing zorphy v$VERSION..."
cd "$REPO_ROOT/zorphy"
# Retry pub get since zorphy_annotation may not be indexed yet
for i in {1..10}; do
  if dart pub get 2>/dev/null; then
    dart pub publish --force && break
  fi
  if [ $i -lt 10 ]; then
    echo "  ⏳ Waiting for pub.dev indexing (attempt $i/10)..."
    sleep 15
  else
    echo "  ⚠️ zorphy publish failed after 10 attempts"
  fi
done

echo "🏷️ Creating and pushing git tags..."
cd "$REPO_ROOT"
git tag -a "annotation-v$VERSION" -m "Release zorphy_annotation $VERSION" || echo "  ⚠️ Tag annotation-v$VERSION already exists"
git tag -a "v$VERSION" -m "Release zorphy $VERSION" || echo "  ⚠️ Tag v$VERSION already exists"

echo "📤 Pushing changes and tags to origin..."
git push origin "$(git rev-parse --abbrev-ref HEAD)"
git push origin --tags

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Release v$VERSION published and tags pushed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
