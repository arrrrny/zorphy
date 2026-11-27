#!/usr/bin/env bash
# check_internal_constraints.sh — pre-publish guard for the two-phase release
# gate (issue #325).
#
# For each internal `zorphy_annotation` constraint (zorphy/ and
# zorphy_migrator/), verify that:
#
#   1. the constraint ADMITS the previously published version — the highest
#      `annotation-v*` tag in the release commit (issue #325); and
#   2. its numeric major.minor.patch base matches that published base line.
#
# The constraint prefix is stripped BEFORE the base is extracted: a caret
# constraint such as `^3.0.0-dev.5` must read as base `3.0.0`, not fail the
# match against the bare `3.0.0` of the release version. Keep rejecting a
# genuinely different numeric base.
#
# This is a defensive guard. publish.sh's conversion loop normally leaves the
# constraint at the previously published value in the release commit and bumps
# it to `^<version>` only in the post-publish phase (issue #325). It fires only
# if that flow was skipped or altered — it is not a stronger invariant than
# the conversion itself.
#
# Usage: bash scripts/check_internal_constraints.sh <version-being-released>
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-}"

# The last published annotation version, from the tags carried by the clone.
PREVIOUS="$(git -C "$ROOT_DIR" tag --list 'annotation-v*' --sort=-v:refname 2>/dev/null \
    | head -n 1 | sed 's/^annotation-v//' || true)"

# Strip any constraint operator (`^`, `>=`, `~`, ...) before reading a version.
strip_prefix() { printf '%s' "$1" | sed -E 's/^[^0-9]+//'; }

# Numeric major.minor.patch base of a version or constraint.
base() { strip_prefix "$1" | sed -E 's/^([0-9]+[.][0-9]+[.][0-9]+).*/\1/'; }

# Fixed-width sortable key for X.Y.Z[-pre.N] so a string comparison is a
# correct numeric comparison without relying on GNU `sort -V` (macOS lacks it).
key() {
    printf '%s' "$1" | sed -E 's/^[^0-9]*//; s/[^0-9]+/ /g' \
        | awk '{ printf "%09d%09d%09d%09d\n", $1+0, $2+0, $3+0, $4+0 }'
}

if [ -z "$PREVIOUS" ]; then
    echo "  ⚠️  No annotation-v* tag found — skipping previous-version admission check"
    exit 0
fi

PREV_BASE="$(base "$PREVIOUS")"
PREV_KEY="$(key "$PREVIOUS")"

for pkg in zorphy zorphy_migrator; do
    constraint="$(awk '/^  zorphy_annotation:/ {print $2; exit}' \
        "$ROOT_DIR/$pkg/pubspec.yaml")"
    constraint_version="$(strip_prefix "$constraint")"

    if [ "$(base "$constraint_version")" != "$PREV_BASE" ]; then
        echo "ERROR: $pkg internal constraint $constraint is not on the previously published base line $PREV_BASE"
        exit 1
    fi
    # A constraint admits a version when its own floor is <= that version.
    if [[ "$(key "$constraint_version")" > "$PREV_KEY" ]]; then
        echo "ERROR: $pkg internal constraint $constraint excludes the previously published version $PREVIOUS"
        exit 1
    fi
done

echo "OK: internal constraints admit previously published version $PREVIOUS (base $PREV_BASE, release ${VERSION:-?})"
