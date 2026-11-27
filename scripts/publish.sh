#!/bin/bash

# Monorepo publish script for zorphy
# Updates versions, CHANGELOGs, publishes directly to pub.dev, then tags and pushes.
# Usage: ./scripts/publish.sh <version> [description] [--dry-run]
#
# --dry-run prints every step the release would take and executes none of it:
# no file is rewritten or removed, and nothing is committed, pushed, tagged or
# published. Every side effect in this script goes through `run` below.

set -e

# Get script directory and navigate to monorepo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

usage() {
    echo "Usage: $0 <version> [description] [--dry-run]"
}

# The first non-flag argument is the version and the second is the description.
# --dry-run is accepted in any position so it can never be read as the description.
DRY_RUN=false
VERSION=""
DESCRIPTION=""
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -*) echo "❌ Unknown option: $arg"; usage; exit 1 ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$arg"
            elif [ -z "$DESCRIPTION" ]; then
                DESCRIPTION="$arg"
            else
                echo "❌ Unexpected argument: $arg"; usage; exit 1
            fi
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo "❌ Error: Version is required."
    usage
    exit 1
fi

# Validate version format (supporting optional SemVer prerelease like -dev.N, -rc.1, etc.)
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    echo "❌ Invalid version format. Expected format: X.Y.Z or X.Y.Z-prerelease (e.g., 3.0.0-dev.2)"
    exit 1
fi

DESCRIPTION="${DESCRIPTION:-Release $VERSION}"
DATE=$(date +%Y-%m-%d)

# Runs a command, or under --dry-run only reports it.
run() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

# Release gate (issue #314): run the SAME clean-checkout CI simulation CI runs,
# against a pristine clone of the release commit, BEFORE anything is published
# or pushed. A maintainer machine never proves the release — local locks, a
# gitignored pubspec_overrides.yaml and local package resolution all differ from
# CI's pristine checkout, and 3.0.0-dev.4 shipped base-red exactly that way.
# Any failing step aborts the whole release (set -e), naming the step.
release_gate() {
    echo "🧪 Running release gate (clean-checkout CI simulation)…"

    local check_dir
    if $DRY_RUN; then
        check_dir="<pristine-clone>"
    else
        check_dir="$(mktemp -d "${TMPDIR:-/tmp}/zorphy-release-check.XXXXXX")"
    fi

    # A pristine clone of the release commit — exactly what CI checks out.
    run git clone --depth 1 "file://$REPO_ROOT" "$check_dir"

    # 1. Version sync across the 3 packages.
    echo "  == check_version_sync.sh"
    run bash -c "cd '$check_dir' && bash scripts/check_version_sync.sh"

    # 2. Each committed pubspec.lock must match its pubspec.yaml (the same
    #    4-package --enforce-lockfile loop the CI version_sync job runs).
    local pkg
    for pkg in zorphy_annotation zorphy zorphy_migrator zorphy/example; do
        echo "  == $pkg (enforce-lockfile)"
        run bash -c "cd '$check_dir/$pkg' && dart pub get --enforce-lockfile"
    done

    # 3. Format from zorphy/ with NO pub get — an unresolved include is CI's
    #    own format-job environment; the formatter must still succeed.
    echo "  == dart format (zorphy/)"
    run bash -c "cd '$check_dir/zorphy' && dart format --output=none --set-exit-if-changed ."

    # 4. The release guard test suite.
    echo "  == dart test test/release/"
    run bash -c "cd '$check_dir/zorphy' && dart test test/release/"

    # 5. Stacked-PR orphan sweep (issue #315): no merged PR's content may have
    #    evaporated before a release ships. A failing sweep aborts the release,
    #    exactly like any other gate step (set -e).
    echo "  == sweep_merged_content.sh"
    run bash -c "cd '$check_dir' && bash scripts/sweep_merged_content.sh"

    if ! $DRY_RUN; then
        rm -rf "$check_dir"
    fi
    echo "✅ Release gate passed."
}

echo "🚀 Streamlining release for zorphy version $VERSION..."
echo "📍 Working directory: $REPO_ROOT"
if $DRY_RUN; then
    echo "dry run: nothing below is executed"
fi

# Helper for cross-platform sed
safe_sed() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        run sed -i '' "$1" "$2"
    else
        run sed -i "$1" "$2"
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
                run sed -i '' "1i\\
## [$VERSION] - $DATE\\
\\
### Change\\
- $DESCRIPTION\\
" "$pkg_dir/CHANGELOG.md"
            else
                run sed -i "1i ## [$VERSION] - $DATE\\n\\n### Change\\n- $DESCRIPTION\\n" "$pkg_dir/CHANGELOG.md"
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
    run perl -0777 -i -pe 's/zorphy_annotation:\s*\n\s*path:\s*\.\.\/zorphy_annotation/zorphy_annotation: ^/g' "$PERL_PUBSPEC"
    # 2. Any remaining single-line form → hosted
    safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" "$PERL_PUBSPEC"
    # 3. Strip dependency_overrides block entirely
    run perl -0777 -i -pe 's/\n\ndependency_overrides:\n(?:[ \t#].*\n)*//s' "$PERL_PUBSPEC"

    if [ -f "$pkg/pubspec_overrides.yaml" ]; then
        echo "🧹 Cleaning $pkg/pubspec_overrides.yaml..."
        run rm -f "$pkg/pubspec_overrides.yaml"
    fi
done

# 4. Update README
echo "📝 Updating README.md..."
safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" README.md
safe_sed "s/zorphy: .*/zorphy: ^$VERSION/" README.md

# 5. Commit changes
echo "🔨 Committing changes..."
run git add .
run git commit -m "chore: release v$VERSION" || echo "  ⚠️ No changes to commit"

# 5b. Release gate — abort BEFORE any push or publish unless the release commit
# passes the clean-checkout CI simulation (issue #314).
release_gate

# 6. Create PR (if gh CLI available)
if $DRY_RUN; then
    echo "🔄 Would create a pull request: chore: release v$VERSION"
elif command -v gh &> /dev/null; then
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
run dart pub publish --force || echo "  ⚠️ zorphy_annotation publish failed or already published"

# Publishes one package, retrying until pub.dev has indexed the packages before it.
publish_after_indexing() {
    local pkg_dir="$1"
    local pkg_name="$2"

    echo "📦 Publishing $pkg_name v$VERSION..."
    cd "$REPO_ROOT/$pkg_dir"
    if $DRY_RUN; then
        run dart pub publish --force
        return
    fi
    for i in {1..10}; do
        if dart pub get 2>/dev/null; then
            dart pub publish --force && break
        fi
        if [ $i -lt 10 ]; then
            echo "  ⏳ Waiting for pub.dev indexing (attempt $i/10)..."
            sleep 15
        else
            echo "  ⚠️ $pkg_name publish failed after 10 attempts"
        fi
    done
}

publish_after_indexing "zorphy" "zorphy"
publish_after_indexing "zorphy_migrator" "zorphy_migrator"

echo "🏷️ Creating and pushing git tags..."
cd "$REPO_ROOT"
run git tag -a "annotation-v$VERSION" -m "Release zorphy_annotation $VERSION" || echo "  ⚠️ Tag annotation-v$VERSION already exists"
run git tag -a "v$VERSION" -m "Release zorphy $VERSION" || echo "  ⚠️ Tag v$VERSION already exists"
run git tag -a "migrator-v$VERSION" -m "Release zorphy_migrator $VERSION" || echo "  ⚠️ Tag migrator-v$VERSION already exists"

echo "📤 Pushing changes and tags to origin..."
if $DRY_RUN; then
    echo "  [dry-run] git push origin <current branch>"
    echo "  [dry-run] git push origin --tags"
else
    git push origin "$(git rev-parse --abbrev-ref HEAD)"
    git push origin --tags || true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if $DRY_RUN; then
    echo "dry run complete: v$VERSION was NOT modified, committed, tagged, pushed or published."
else
    echo "✅ Release v$VERSION published and tags pushed!"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
