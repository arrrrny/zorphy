#!/bin/bash

# Monorepo publish script for zorphy - publishes zorphy_annotation first, then zorphy
# Usage: ./scripts/publish.sh <version> [description]
# Example: ./scripts/publish.sh 1.2.0 "Add new features and bug fixes"
#
# Order of operations:
#   1. Publish zorphy_annotation (tag: annotation-vX.Y.Z)
#   2. Publish zorphy (tag: vX.Y.Z)

set -e

# Get script directory and navigate to monorepo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

VERSION="$1"
PROMOTE_MODE=false

# Check if we should promote [Unreleased]
if [ $# -eq 1 ]; then
    if grep -q "^## \[Unreleased\]" zorphy_annotation/CHANGELOG.md || \
       grep -q "^## \[Unreleased\]" zorphy/CHANGELOG.md; then
        echo "✨ Detected [Unreleased] section. Promoting to version $VERSION..."
        PROMOTE_MODE=true
    else
        echo "❌ No description provided and no [Unreleased] section found in CHANGELOG.md."
        echo "Usage: $0 <version> [description]"
        exit 1
    fi
else
    DESCRIPTION="${2:-Release $VERSION}"
    TYPE="change"

    shift 2 2>/dev/null || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --feat|--fix|--docs|--style|--refactor|--perf|--test|--build|--ci|--chore|--revert|--change)
                TYPE="${1#--}"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Capitalize the type for CHANGELOG
    TYPE_CAPITALIZED=$(echo "$TYPE" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
fi

# Validate version format
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format. Expected format: X.Y.Z (e.g., 1.2.0)"
    exit 1
fi

    # Get current date
DATE=$(date +%Y-%m-%d)

echo "🚀 Publishing zorphy monorepo version $VERSION..."
echo "📍 Working directory: $REPO_ROOT"
echo ""
echo "📦 Publishing order:"
echo "   1. zorphy_annotation (tag: annotation-vX.Y.Z)"
echo "   2. zorphy (tag: vX.Y.Z)"
echo ""

# Function to update comparison links at bottom of CHANGELOG
update_changelog_links() {
    local package_dir="$1"
    local version="$2"
    local prev_version=""

    echo "  📝 Updating comparison links..."
    cd "$package_dir"

    # Extract previous version from [Unreleased] link
    if grep -q "^\[Unreleased\]:" CHANGELOG.md; then
        prev_version=$(grep "^\[Unreleased\]:" CHANGELOG.md | sed -E 's/.*\/compare\/v?([0-9]+\.[0-9]+\.[0-9]+)\.\.\..*/\1/')
    fi

    # If no previous version found, default to 1.0.0
    if [ -z "$prev_version" ]; then
        prev_version="1.0.0"
    fi

    # Get the package name prefix (annotation-v or v)
    if [[ "$package_dir" == *"annotation"* ]]; then
        prefix="annotation-v"
    else
        prefix="v"
    fi

    # Update or add [Unreleased] link
    if grep -q "^\[Unreleased\]:" CHANGELOG.md; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^\[Unreleased\]:.*|[Unreleased]: https://github.com/arrrrny/zorphy/compare/${prefix}${version}...HEAD|" CHANGELOG.md
        else
            sed -i "s|^\[Unreleased\]:.*|[Unreleased]: https://github.com/arrrrny/zorphy/compare/${prefix}${version}...HEAD|" CHANGELOG.md
        fi
    else
        # Add [Unreleased] link at end
        echo "" >> CHANGELOG.md
        echo "[Unreleased]: https://github.com/arrrrny/zorphy/compare/${prefix}${version}...HEAD" >> CHANGELOG.md
    fi

    # Add new version link
    if ! grep -q "^\[${version}\]:" CHANGELOG.md; then
        if grep -q "^\[${prev_version}\]:" CHANGELOG.md; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "/^\[${prev_version}\]:/a\\
[${version}]: https://github.com/arrrrny/zorphy/compare/${prefix}${prev_version}...${prefix}${version}
" CHANGELOG.md
            else
                sed -i "/^\[${prev_version}\]:/a\\
[${version}]: https://github.com/arrrrny/zorphy/compare/${prefix}${prev_version}...${prefix}${version}
" CHANGELOG.md
            fi
        fi
    fi

    echo "  ✓ Comparison links updated"
    cd "$REPO_ROOT" > /dev/null
}

# Function to update CHANGELOG
update_changelog() {
    local package_dir="$1"
    local package_name="$2"

    echo "📝 Updating $package_name CHANGELOG..."
    cd "$package_dir"

    # Check if [Unreleased] section exists
    if ! grep -q "^## \[Unreleased\]" CHANGELOG.md; then
        echo "  ⚠️  No [Unreleased] section found, adding it..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "1s/^/## [Unreleased]\\n\\n/" CHANGELOG.md
        else
            sed -i "1s/^/## [Unreleased]\n\n/" CHANGELOG.md
        fi
    fi

    if [ "$PROMOTE_MODE" = true ]; then
        # Replace [Unreleased] with version and date
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^## \[Unreleased\]/## [$VERSION] - $DATE/" CHANGELOG.md
        else
            sed -i "s/^## \[Unreleased\]/## [$VERSION] - $DATE/" CHANGELOG.md
        fi
    else
        # Insert new version after [Unreleased]
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/^## \[Unreleased\]/a\\
\\
## [$VERSION] - $DATE\\
\\
### $TYPE_CAPITALIZED\\
- $DESCRIPTION
" CHANGELOG.md
        else
            sed -i "/^## \[Unreleased\]/a\\
\\
## [$VERSION] - $DATE\\
\\
### $TYPE_CAPITALIZED\\
- $DESCRIPTION
" CHANGELOG.md
        fi

        # Remove [Unreleased] section before publishing
        echo "  🔽 Removing [Unreleased] section before publishing..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Match from [Unreleased] to the next ## header, delete [Unreleased] and blank lines
            perl -i -0pe 's/^## \[Unreleased\]\n\n//' CHANGELOG.md
        else
            perl -i -0pe 's/^## \[Unreleased\]\n\n//' CHANGELOG.md
        fi
    fi

    # Update comparison links
    update_changelog_links "$package_dir" "$VERSION"

    echo "  ✓ CHANGELOG.md updated"
    cd "$REPO_ROOT" > /dev/null
}
update_pubspec() {
    local package_dir="$1"
    local package_name="$2"

    echo "📝 Updating $package_name pubspec.yaml..."
    cd "$package_dir"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version: .*/version: $VERSION/" pubspec.yaml
    else
        sed -i "s/^version: .*/version: $VERSION/" pubspec.yaml
    fi

    echo "  ✓ Version updated to $VERSION"
    cd "$REPO_ROOT" > /dev/null
}

# ========================================================================
# STEP 1: Publish zorphy_annotation
# ========================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 1/2: Publishing zorphy_annotation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

update_pubspec "zorphy_annotation" "zorphy_annotation"
update_changelog "zorphy_annotation" "zorphy_annotation"

cd zorphy_annotation

# Commit changes
echo "🔨 Committing zorphy_annotation changes..."
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: release zorphy_annotation $VERSION"
echo "  ✓ Changes committed"

# Create PR (if gh CLI available)
if command -v gh &> /dev/null; then
    echo "🔄 Creating pull request to master..."
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    if gh pr list --head "$CURRENT_BRANCH" --json number | grep -q "\"number\""; then
        echo "  ⚠️  PR already exists for branch $CURRENT_BRANCH"
    else
        gh pr create --base master --head "$CURRENT_BRANCH" \
            --title "chore: release zorphy_annotation $VERSION" \
            --body "Release zorphy_annotation $VERSION

**Description:** $DESCRIPTION

**Date:** $DATE

**Changes:**
- Bump version to $VERSION
- Update CHANGELOG.md

Please review and merge this PR to master before proceeding with the release."
        echo "  ✓ PR created"
    fi
fi

# Publish to pub.dev
echo "📦 Publishing zorphy_annotation to pub.dev..."
dart pub publish --force

echo ""
echo "✅ Successfully published zorphy_annotation version $VERSION!"
echo ""

cd "$REPO_ROOT"

echo "⏳ Waiting 90 seconds for pub.dev to process zorphy_annotation..."
sleep 90

# ========================================================================
# STEP 2: Publish zorphy
# ========================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 2/2: Publishing zorphy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

update_pubspec "zorphy" "zorphy"
update_changelog "zorphy" "zorphy"

cd zorphy

# Update zorphy_annotation dependency in pubspec.yaml to match version
echo "📝 Updating zorphy_annotation dependency in zorphy/pubspec.yaml..."
perl -i -0777 -pe "s/^  zorphy_annotation:\n    path: \.\.\/zorphy_annotation$/  zorphy_annotation: ^$VERSION/m; s/^  zorphy_annotation: .*/  zorphy_annotation: ^$VERSION/m" pubspec.yaml
echo "  ✓ Dependency updated to ^$VERSION"

# Commit changes
echo "🔨 Committing zorphy changes..."
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: release zorphy $VERSION"
echo "  ✓ Changes committed"

# Create PR (if gh CLI available)
if command -v gh &> /dev/null; then
    echo "🔄 Creating pull request to master..."
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    if gh pr list --head "$CURRENT_BRANCH" --json number | grep -q "\"number\""; then
        echo "  ⚠️  PR already exists for branch $CURRENT_BRANCH"
    else
        gh pr create --base master --head "$CURRENT_BRANCH" \
            --title "chore: release zorphy $VERSION" \
            --body "Release zorphy $VERSION

**Description:** $DESCRIPTION

**Date:** $DATE

**Changes:**
- Bump version to $VERSION
- Update zorphy_annotation dependency to ^$VERSION
- Update CHANGELOG.md

Please review and merge this PR to master before proceeding with the release."
        echo "  ✓ PR created"
    fi
fi

# Create and push tag
echo "🏷️  Creating git tag for zorphy..."
git tag -a "v$VERSION" -m "Release zorphy $VERSION"
git push origin "$(git rev-parse --abbrev-ref HEAD)"
git push origin "v$VERSION"
echo "  ✓ Tag v$VERSION pushed"

# Run tests
echo "🧪 Running tests..."
dart test
echo "  ✓ Tests passed"

# Publish to pub.dev
echo "📦 Publishing zorphy to pub.dev..."
dart pub publish --force

echo ""
echo "✅ Successfully published zorphy version $VERSION!"
echo ""

cd "$REPO_ROOT"

# ========================================================================
# SUMMARY
# ========================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Publish Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Version: $VERSION"
echo "Date: $DATE"
echo "Description: $DESCRIPTION"
echo ""
echo "📦 Published Packages:"
echo "   • zorphy_annotation: https://pub.dev/packages/zorphy_annotation/$VERSION"
echo "   • zorphy:            https://pub.dev/packages/zorphy/$VERSION"
echo ""
echo "🏷️  Git Tags:"
echo "   • annotation-v$VERSION"
echo "   • v$VERSION"
echo ""
echo "✨ All done! Your packages are live on pub.dev!"
