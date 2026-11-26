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

# Validate version format (supporting optional SemVer prerelease like -dev.N, -rc.1, etc.)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    echo "❌ Invalid version format. Expected format: X.Y.Z or X.Y.Z-prerelease (e.g., 3.0.0-dev.2)"
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
    if [ -f "$pkg_dir/CHANGELOG.md" ]; then
        if grep -q "## \\[Unreleased\\]" "$pkg_dir/CHANGELOG.md"; then
            safe_sed "s/## \\[Unreleased\\]/## [$VERSION] - $DATE/" "$pkg_dir/CHANGELOG.md"
        elif ! grep -q "## \\[$VERSION\\]" "$pkg_dir/CHANGELOG.md"; then
            # If no Unreleased and no current version, insert at top (after potential title)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "1i\\
## [$VERSION] - $DATE\\
\\
### Change\\
- $DESCRIPTION\\
" "$pkg_dir/CHANGELOG.md"
            else
                sed -i "1i ## [$VERSION] - $DATE\\n\\n### Change\\n- $DESCRIPTION\\n" "$pkg_dir/CHANGELOG.md"
            fi
        fi
    fi
}

# 1. Update zorphy_annotation
update_package "zorphy_annotation" "zorphy_annotation"

# 2. Update zorphy
update_package "zorphy" "zorphy"

# 3. Update zorphy_migrator
update_package "zorphy_migrator" "zorphy_migrator"

# Convert zorphy_annotation dependency in zorphy and zorphy_migrator to hosted version for publishing.
for pkg in zorphy zorphy_migrator; do
    PERL_PUBSPEC="$pkg/pubspec.yaml"
    # 1. Two-line path form → single-line hosted
    perl -0777 -i -pe 's/zorphy_annotation:\s*\n\s*path:\s*\.\.\/zorphy_annotation/zorphy_annotation: ^/g' "$PERL_PUBSPEC"
    # 2. Any remaining single-line form → hosted
    safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" "$PERL_PUBSPEC"
    # 3. Strip dependency_overrides block entirely
    perl -0777 -i -pe 's/\n\ndependency_overrides:\n(?:[ \t#].*\n)*//s' "$PERL_PUBSPEC"

    if [ -f "$pkg/pubspec_overrides.yaml" ]; then
        echo "🧹 Cleaning $pkg/pubspec_overrides.yaml..."
        rm -f "$pkg/pubspec_overrides.yaml"
    fi
done

# 4. Update README
echo "📝 Updating README.md..."
safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" README.md
safe_sed "s/zorphy: .*/zorphy: ^$VERSION/" README.md

# 5. Commit changes
echo "🔨 Committing changes..."
git add .
git commit -m "chore: release v$VERSION" || echo "  ⚠️ No changes to commit"

# 6. Create PR (if gh CLI available)
if command -v gh &> /dev/null; then
    echo "🔄 Creating/Updating pull request..."
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    PR_TITLE="chore: release v$VERSION"
    PR_BODY="Release version v$VERSION\\n\\n$DESCRIPTION"

    if gh pr list --head "$CURRENT_BRANCH" --json number | grep -q "\"number\""; then
        echo "  ✓ PR already exists for branch $CURRENT_BRANCH"
    else
        gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base master || echo "  ⚠️ Could not create PR automatically"
    fi
fi

# 7. Publish to pub.dev directly (Topological order: zorphy_annotation -> zorphy -> zorphy_migrator)
echo "📦 Publishing zorphy_annotation v$VERSION..."
cd "$REPO_ROOT/zorphy_annotation"
dart pub publish --force || echo "  ⚠️ zorphy_annotation publish failed or already published"

echo "📦 Publishing zorphy v$VERSION..."
cd "$REPO_ROOT/zorphy"
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

echo "📦 Publishing zorphy_migrator v$VERSION..."
cd "$REPO_ROOT/zorphy_migrator"
for i in {1..10}; do
  if dart pub get 2>/dev/null; then
    dart pub publish --force && break
  fi
  if [ $i -lt 10 ]; then
    echo "  ⏳ Waiting for pub.dev indexing (attempt $i/10)..."
    sleep 15
  else
    echo "  ⚠️ zorphy_migrator publish failed after 10 attempts"
  fi
done

echo "🏷️ Creating and pushing git tags..."
cd "$REPO_ROOT"
git tag -a "annotation-v$VERSION" -m "Release zorphy_annotation $VERSION" || echo "  ⚠️ Tag annotation-v$VERSION already exists"
git tag -a "v$VERSION" -m "Release zorphy $VERSION" || echo "  ⚠️ Tag v$VERSION already exists"
git tag -a "migrator-v$VERSION" -m "Release zorphy_migrator $VERSION" || echo "  ⚠️ Tag migrator-v$VERSION already exists"

echo "📤 Pushing changes and tags to origin..."
git push origin "$(git rev-parse --abbrev-ref HEAD)"
git push origin --tags || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Release v$VERSION published and tags pushed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
