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

# Point zorphy_annotation at the local checkout from zorphy/pubspec_overrides.yaml,
# leaving the published constraint in zorphy/pubspec.yaml alone — the override is
# what redirects resolution. Existing overrides (an analyzer pin, for the CI
# compat matrix) are preserved, and an existing file is never overwritten.
echo "📝 Updating zorphy/pubspec_overrides.yaml..."
OVERRIDES_FILE="zorphy/pubspec_overrides.yaml"
ANNOTATION_KEY="zorphy_annotation"
ANNOTATION_PATH="../zorphy_annotation"

# Writes a `dependency_overrides:` block carrying the local path entry, merging
# into whatever the file already pins:
#   - an existing entry is replaced whether it is a scalar
#     (`zorphy_annotation: ^2.4.3`) or a mapping;
#   - the entry lands INSIDE the block, before the next top-level key
#     (`resolution: workspace`, say), so the file stays valid YAML;
#   - every other line is preserved — no heredoc overwrite of a file that
#     already exists.
write_annotation_override() {
  local file="$1"
  local tmp
  if [ ! -s "$file" ]; then
    mkdir -p "$(dirname "$file")"
    printf 'dependency_overrides:\n  %s:\n    path: %s\n' \
      "$ANNOTATION_KEY" "$ANNOTATION_PATH" > "$file"
    return
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/to_path.XXXXXX")" || return 1
  awk -v key="$ANNOTATION_KEY" -v path="$ANNOTATION_PATH" '
    function indent_of(s) {
      match(s, /^ */)
      return RLENGTH
    }
    function emit_range(a, b, i) {
      for (i = a; i <= b; i++) print buf[i]
    }
    { buf[NR] = $0 }
    END {
      n = NR
      header = 0
      for (i = 1; i <= n; i++) {
        if (buf[i] ~ /^dependency_overrides:[[:space:]]*$/) {
          header = i
          break
        }
      }
      if (header == 0) {
        print "dependency_overrides:"
        print "  " key ":"
        print "    path: " path
        emit_range(1, n)
        exit
      }
      # The block ends at the next top-level key, so the entry is inserted
      # before it instead of being appended after it.
      block_end = n + 1
      for (i = header + 1; i <= n; i++) {
        if (buf[i] ~ /^[^[:space:]]/) {
          block_end = i
          break
        }
      }
      entry = 0
      for (i = header + 1; i < block_end; i++) {
        trimmed = buf[i]
        sub(/^[[:space:]]+/, "", trimmed)
        if (index(trimmed, key ":") == 1) {
          entry = i
          break
        }
      }
      skip_until = 0
      if (entry > 0) {
        entry_indent = indent_of(buf[entry])
        skip_until = entry
        for (i = entry + 1; i < block_end; i++) {
          if (buf[i] ~ /^[[:space:]]*$/) continue
          if (indent_of(buf[i]) > entry_indent) {
            skip_until = i
            continue
          }
          break
        }
      }
      emit_range(1, header)
      if (entry > 0) emit_range(header + 1, entry - 1)
      else emit_range(header + 1, block_end - 1)
      print "  " key ":"
      print "    path: " path
      if (entry > 0) emit_range(skip_until + 1, block_end - 1)
      emit_range(block_end, n)
    }
  ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
  mv "$tmp" "$file"
}

write_annotation_override "$OVERRIDES_FILE"

echo "  ✓ Updated zorphy_annotation to use local path in pubspec_overrides.yaml"
echo ""
cd "$REPO_ROOT"

echo "✅ Successfully updated to path references for development!"
echo ""
echo "📦 Active Dependencies:"
echo "   • zorphy → zorphy_annotation: ../zorphy_annotation (via pubspec_overrides.yaml)"
echo ""
echo "✨ All packages now use local path references!"