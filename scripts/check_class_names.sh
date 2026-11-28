#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT"

# Enumerate every tracked Dart file across the WHOLE monorepo, not only the
# lib/bin/test/benchmark subdirectories of each package: a future `Impl` class
# or file under tool/, .gym/ or any other root must be caught too (the issue
# asks for a monorepo-wide ban). Generated outputs (*.zorphy.dart, *.g.dart)
# are excluded.
#
# A sentinel file count guards the "nothing to scan" case without relying on
# mapfile (absent in macOS's bash 3.2).
scanned=0
violations=0
while IFS= read -r -d '' file; do
  case "$file" in
    *.zorphy.dart|*.g.dart) continue ;;
  esac
  [ -f "$file" ] || continue
  scanned=$((scanned + 1))

  # Basenames only: parent paths such as simple_class are not file names.
  # The FILE_NAME ban targets the `impl` letters ending a naming segment
  # (immediately followed by a non-lowercase char or end of the basename), so a
  # name that merely CONTAINS the letters inside a longer lowercase word
  # (simple.dart, implementation.dart) is NOT rejected, while
  # cost_guards_impl.dart / COST_IMPL.dart are.
  basename="${file##*/}"
  if printf '%s' "$basename" | grep -qE '[Ii][Mm][Pp][Ll]([^a-z]|$)'; then
    printf 'FILE_NAME %s\n' "$file"
    violations=1
  fi

  # Any type identifier (class/enum/mixin/extension) whose name carries an
  # `Impl` naming segment is banned, with the SAME token rule as the FILE_NAME
  # check (case-insensitive `impl` letters, segment ends at a non-lowercase
  # boundary) so neither rejects a legitimate name such as `Simple`.
  #
  # The awk pass blanks out comments (// line, /* block, nested) and string
  # literals (single/double, and triple-quoted forms) BEFORE matching, so a
  # declaration mentioned only in a comment or string is not flagged, and it
  # matches a declaration keyword and its name across arbitrary whitespace
  # (including a newline between `class` and `BadImpl`). It prints the 1-based
  # line of each offending declaration's keyword.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    printf 'CLASS_NAME %s:%s\n' "$file" "$line"
    violations=1
  done < <(awk '
    # Blank comments and string-literal contents, preserving length and
    # newlines so reported line numbers stay correct. State carried across
    # lines: "block" (block-comment depth in `depth`), "str" (delimiter in
    # `q`), "triple" (delimiter in `q3`). `//` comments end at the newline.
    function blank(buf,   out, n, i, c, two, three) {
      out = ""; n = length(buf); i = 1
      while (i <= n) {
        c = substr(buf, i, 1); two = substr(buf, i, 2); three = substr(buf, i, 3)
        if (state == "block") {
          if (two == "/*") { depth++; out = out "  "; i += 2; continue }
          if (two == "*/") { depth--; out = out "  "; i += 2; if (depth <= 0) state = "normal"; continue }
          out = out " "; i++; continue
        }
        if (state == "triple") {
          if (three == q3) { state = "normal"; out = out "   "; i += 3; continue }
          if (c == "\\") { out = out "  "; i += 2; continue }
          out = out " "; i++; continue
        }
        if (state == "str") {
          if (c == "\\") { out = out "  "; i += 2; continue }
          if (c == q) { state = "normal"; out = out " "; i++; continue }
          out = out " "; i++; continue
        }
        # normal state
        if (two == "//") { out = out sprintf("%*s", n - i + 1, ""); break }
        if (two == "/*") { state = "block"; depth = 1; out = out "  "; i += 2; continue }
        if (c == "\047" || c == "\042") {
          q = c
          if (three == c c c) { state = "triple"; q3 = c c c; out = out "   "; i += 3; continue }
          state = "str"; out = out " "; i++; continue
        }
        out = out c; i++
      }
      return out
    }
    { cleaned = cleaned blank($0) "\n" }
    END {
      # (^|non-identifier) keyword, whitespace (incl. newlines), name prefix,
      # the `impl` segment, ending at a non-lowercase boundary.
      re = "(^|[^[:alnum:]_$])(class|enum|mixin|extension)[^[:alnum:]_$]+[A-Za-z0-9_$]*[Ii][Mm][Pp][Ll]([^a-z]|$)"
      rest = cleaned
      while (match(rest, re)) {
        start = RSTART; len = RLENGTH
        prefix = substr(rest, 1, start - 1)
        line = 1 + gsub(/\n/, "\n", prefix)
        printf "%d\n", line
        rest = substr(rest, start + len - 1)
      }
    }
  ' "$file")
done < <(git ls-files -z --cached --others --exclude-standard -- '*.dart')

if [ "$scanned" -eq 0 ]; then
  echo "No tracked Dart files found under $ROOT" >&2
  exit 2
fi

if [ "$violations" -ne 0 ]; then
  echo "Impl class/file naming policy violated." >&2
  exit 1
fi

echo "Class and file naming gate passed."