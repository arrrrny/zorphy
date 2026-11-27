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

# Pre-publish gate (issue #325, split from the old monolithic release gate):
# run the satisfiability checks against a pristine clone of the release commit
# BEFORE anything is published or pushed. A maintainer machine never proves the
# release — local locks, a gitignored pubspec_overrides.yaml and local package
# resolution all differ from CI's pristine checkout, and 3.0.0-dev.4 shipped
# base-red exactly that way.
#
# It MUST NOT run `dart pub get --enforce-lockfile` here (issue #325): at this
# point, the release commit's internal constraints still carry the previously
# published line (`^3.0.0-dev.4`) while the new version (`3.0.0-dev.5`) does not
# exist on pub.dev yet, so an enforce-lockfile step against the new version is
# unresolvable pre-publish, forever. The lockfile gate moves to
# `post_publish_verify`, which runs after the new version is published. Here we
# only prove the constraints
# are *satisfiable*: a resolve-allowed `dart pub get` per package (internal
# deps resolved from the pristine clone via a throwaway override) plus a check
# that the internal constraints still ADMIT the previously published version
# and stay on its base line. The internal constraint bump to ^<version> is NOT
# committed here — it lands with the lock refresh in the post-publish phase
# (issue #325). Any failing step aborts the whole release (set -e), naming it.
pre_publish_gate() {
    echo "🧪 Running pre-publish gate (constraint satisfiability)…"

    local check_dir
    if $DRY_RUN; then
        check_dir="<pristine-clone>"
    else
        check_dir="$(mktemp -d "${TMPDIR:-/tmp}/zorphy-release-check.XXXXXX")"
    fi

    # A pristine clone of the release commit — exactly what CI checks out.
    # Full history (no --depth 1): the stacked-PR orphan sweep below runs
    # `git merge-base --is-ancestor` against master, which a depth-1 clone
    # cannot satisfy — it would report every healthy PR as orphaned and block
    # the release (issue #322).
    run git clone "file://$REPO_ROOT" "$check_dir"

    # 1. Internal constraints must ADMIT the previously published version and
    #    stay on its numeric base line: a prerelease bump advances -dev.N but
    #    must not jump to a base no published version anchors (issue #325).
    #    The helper strips the `^` prefix before extracting the base — a caret
    #    constraint like ^3.0.0-dev.5 must not fail against a bare 3.0.0. This
    #    reads the COMMITTED constraint, before the throwaway rewrite below.
    echo "  == internal-constraint admission check"
    run bash -c "cd '$check_dir' && bash scripts/check_internal_constraints.sh '$VERSION'"

    # 2. Version sync across the 3 packages. The internal constraint is bumped
    #    to ^<version> in this THROWAWAY clone only, so the strict
    #    check_version_sync.sh contract (#314) sees the post-publish shape; the
    #    committed line was validated by step 1 and this clone is discarded.
    run bash -c "cd '$check_dir' && for p in zorphy zorphy_migrator; do perl -0777 -i -pe 's/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/' \"\$p/pubspec.yaml\"; done"
    echo "  == check_version_sync.sh"
    run bash -c "cd '$check_dir' && bash scripts/check_version_sync.sh"

    # 3. Resolve-allowed `dart pub get` per package — proves the EXTERNAL
    #    constraints are satisfiable against *published* versions. The one
    #    dependency that cannot resolve against pub.dev yet is the internal
    #    zorphy_annotation at the new version, so a throwaway
    #    pubspec_overrides.yaml points it (and zorphy, for the example) at the
    #    pristine clone's local packages. The clone is discarded below, so the
    #    override never reaches the release commit.
    echo "  == dart pub get (resolve-allowed, internal deps overridden locally)"
    run bash -c "printf 'dependency_overrides:\n  zorphy_annotation:\n    path: ../zorphy_annotation\n' > '$check_dir/zorphy/pubspec_overrides.yaml'"
    run bash -c "printf 'dependency_overrides:\n  zorphy_annotation:\n    path: ../zorphy_annotation\n' > '$check_dir/zorphy_migrator/pubspec_overrides.yaml'"
    run bash -c "printf 'dependency_overrides:\n  zorphy:\n    path: ..\n  zorphy_annotation:\n    path: ../../zorphy_annotation\n' > '$check_dir/zorphy/example/pubspec_overrides.yaml'"
    local pkg
    for pkg in zorphy_annotation zorphy zorphy_migrator zorphy/example; do
        echo "  == $pkg (resolve)"
        run bash -c "cd '$check_dir/$pkg' && dart pub get"
    done

    # 4. Format from zorphy/ with NO pub get — an unresolved include is CI's
    #    own format-job environment; the formatter must still succeed.
    echo "  == dart format (zorphy/)"
    run bash -c "cd '$check_dir/zorphy' && dart format --output=none --set-exit-if-changed ."

    # 5. The release guard test suite.
    echo "  == dart test test/release/"
    run bash -c "cd '$check_dir/zorphy' && dart test test/release/"

    # 6. Stacked-PR orphan sweep (issue #315): no merged PR's content may have
    #    evaporated before a release ships. A failing sweep aborts the release,
    #    exactly like any other gate step (set -e).
    echo "  == sweep_merged_content.sh"
    run bash -c "cd '$check_dir' && bash scripts/sweep_merged_content.sh"

    if ! $DRY_RUN; then
        rm -rf "$check_dir"
    fi
    echo "✅ Pre-publish gate passed."
}

# Post-publish verification (issue #325): run AFTER `dart pub publish` succeeds
# for all 3 packages — the new version now exists on pub.dev — and BEFORE the
# git tag is considered complete. This is the CI-equivalent lockfile gate that
# the pre-publish phase cannot run: a fresh clone regenerates each lock against
# the now-published version, proves it stable under --enforce-lockfile, runs the
# release guard tests. It then carries the EXACT verified locks into the
# worktree, bumps the internal `zorphy_annotation` constraints to ^<version>,
# and commits both together as the release's final base-green commit before the
# tag. This automates exactly what #308 did by hand after 3.0.0-dev.4.
post_publish_verify() {
    echo "🔒 Running post-publish verification (regenerate + enforce locks)…"

    # publish_after_indexing leaves the cwd in the last published package.
    cd "$REPO_ROOT"

    local check_dir
    if $DRY_RUN; then
        check_dir="<pristine-clone>"
    else
        check_dir="$(mktemp -d "${TMPDIR:-/tmp}/zorphy-post-publish.XXXXXX")"
    fi

    run git clone "file://$REPO_ROOT" "$check_dir"

    local pkg
    # 1. Regenerate each lock against the now-published version (resolve-allowed;
    #    the internal constraint still admits the previous line at this point).
    for pkg in zorphy_annotation zorphy zorphy_migrator zorphy/example; do
        echo "  == $pkg (regenerate lock)"
        run bash -c "cd '$check_dir/$pkg' && dart pub get"
    done

    # 2. Prove each regenerated lock is stable under --enforce-lockfile — the
    #    exact gate CI runs, now green because the version is published.
    for pkg in zorphy_annotation zorphy zorphy_migrator zorphy/example; do
        echo "  == $pkg (enforce-lockfile)"
        run bash -c "cd '$check_dir/$pkg' && dart pub get --enforce-lockfile"
    done

    # 3. Release guard tests against the regenerated tree.
    echo "  == dart test test/release/"
    run bash -c "cd '$check_dir/zorphy' && dart test test/release/"

    # 4. Preserve the locks that JUST PASSED the enforced gate. Copying them
    #    (instead of re-resolving in the maintainer worktree) guarantees the
    #    committed locks are the ones CI will enforce on the release tip.
    if ! $DRY_RUN; then
        for pkg in zorphy_annotation zorphy zorphy_migrator zorphy/example; do
            run cp "$check_dir/$pkg/pubspec.lock" "$REPO_ROOT/$pkg/pubspec.lock"
        done
        rm -rf "$check_dir"
    fi

    # 5. Bump the internal `zorphy_annotation` constraints to ^<version> and
    #    refresh the README examples. This used to happen BEFORE the release
    #    commit; per issue #325 it now lands here, committed with the locks.
    for pkg in zorphy zorphy_migrator; do
        PERL_PUBSPEC="$REPO_ROOT/$pkg/pubspec.yaml"
        run perl -0777 -i -pe 's/zorphy_annotation:\s*\n\s*path:\s*\.\.\/zorphy_annotation/zorphy_annotation: ^/g' "$PERL_PUBSPEC"
        safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" "$PERL_PUBSPEC"
        run perl -0777 -i -pe 's/\n\ndependency_overrides:\n(?:[ \t#].*\n)*//s' "$PERL_PUBSPEC"
    done
    echo "📝 Updating README.md..."
    safe_sed "s/zorphy_annotation: .*/zorphy_annotation: ^$VERSION/" "$REPO_ROOT/README.md"
    safe_sed "s/zorphy: .*/zorphy: ^$VERSION/" "$REPO_ROOT/README.md"

    # 6. Remove EVERY local override before staging — including the example's.
    #    A surviving gitignored `zorphy/example/pubspec_overrides.yaml` would
    #    record a local path source in the committed lock and make CI's
    #    --enforce-lockfile gate fail on the release tip.
    for pkg in zorphy zorphy_migrator zorphy/example; do
        if [ -f "$pkg/pubspec_overrides.yaml" ]; then
            echo "🧹 Cleaning $pkg/pubspec_overrides.yaml..."
            run rm -f "$pkg/pubspec_overrides.yaml"
        fi
    done

    # 7. Commit the verified locks + the bump together. Tolerate a no-op
    #    refresh (a re-run, or locks already current) so `set -e` cannot abort
    #    the release AFTER publishing but BEFORE the tag.
    echo "  == commit + push lock refresh + constraint bump"
    run git -C "$REPO_ROOT" add .
    run git -C "$REPO_ROOT" commit -m "chore: refresh lockfiles + internal constraints for v$VERSION" \
        || echo "  ⚠️ No lock/constraint changes to commit"
    if $DRY_RUN; then
        echo "  [dry-run] git -C $REPO_ROOT push origin <current branch>"
    else
        git -C "$REPO_ROOT" push origin "$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
    fi

    echo "✅ Post-publish verification passed — locks + constraints refreshed and pushed."
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

# 4. NOTE: the internal `zorphy_annotation` constraint bump (to ^$VERSION) and
#    the README examples are intentionally NOT rewritten here. Per issue #325
#    they are committed with the lock refresh in `post_publish_verify`, after
#    all 3 packages are published. The release commit therefore keeps the
#    previously published constraint line, which the pre-publish gate checks.

# 5. Commit changes
echo "🔨 Committing changes..."
run git add .
run git commit -m "chore: release v$VERSION" || echo "  ⚠️ No changes to commit"

# 5b. Pre-publish gate — abort BEFORE any push or publish unless the release
# commit's constraints are satisfiable against published versions (issue #325).
pre_publish_gate

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

# 7b. Post-publish verification (issue #325) — now that all 3 packages are
# published, regenerate + enforce the locks in a fresh clone, run the release
# guard tests, and push the lock refresh as the release's final base-green
# commit. This is the CI-equivalent lockfile gate the pre-publish phase cannot
# run, and it must land BEFORE the tag is created.
post_publish_verify

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
