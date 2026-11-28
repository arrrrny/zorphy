#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT"

scan_paths=()
while IFS= read -r -d '' pubspec; do
  package="${pubspec%/pubspec.yaml}"
  for subdir in lib bin test benchmark; do
    if [ -d "$package/$subdir" ]; then
      scan_paths+=("$package/$subdir")
    fi
  done
done < <(git ls-files -z --cached --others --exclude-standard -- '*pubspec.yaml')

if [ "${#scan_paths[@]}" -eq 0 ]; then
  echo "No Dart package source directories found under $ROOT" >&2
  exit 2
fi

violations=0
while IFS= read -r -d '' file; do
  [ -f "$file" ] || continue
  case "$file" in
    *.zorphy.dart|*.g.dart) continue ;;
  esac

  # Basenames only: parent paths such as simple_class are not file names.
  # The FILE_NAME ban targets Dart sources only (a fixture such as
  # test/impl_input.json is not a Dart package source file name).
  basename="${file##*/}"
  case "$file" in
    *.dart)
      # Token match, case-insensitive on the `impl` letters: `impl` is banned
      # when it ends a naming segment — i.e. it is immediately followed by a
      # non-lowercase character (an uppercase letter, digit, `_`, `.`, space,
      # end of the basename). A name that merely CONTAINS the letters inside a
      # longer lowercase word (simple.dart, simply.dart, implementation.dart)
      # is NOT rejected, while cost_guards_impl.dart / COST_IMPL.dart are.
      if printf '%s' "$basename" | grep -qE '[Ii][Mm][Pp][Ll]([^a-z]|$)'; then
        printf 'FILE_NAME %s\n' "$file"
        violations=1
      fi
      ;;
  esac

  case "$file" in
    *.dart)
      # Any type identifier (class/enum/mixin/extension) whose name carries an
      # `Impl` naming segment is banned, with the SAME token rule as the
      # FILE_NAME check above (case-insensitive `impl` letters, segment must end
      # at a non-lowercase boundary) so the two checks share one contract and
      # neither rejects a legitimate name such as `Simple`.
      while IFS= read -r match; do
        printf 'CLASS_NAME %s:%s\n' "$file" "$match"
        violations=1
      done < <(grep -nE '(^|[[:space:]])(class|enum|mixin|extension)[[:space:]]+[[:alnum:]_$]*[Ii][Mm][Pp][Ll]([^a-z]|$)' "$file" || true)
      ;;
  esac
done < <(git ls-files -z --cached --others --exclude-standard -- "${scan_paths[@]}")

if [ "$violations" -ne 0 ]; then
  echo "Impl class/file naming policy violated." >&2
  exit 1
fi

echo "Class and file naming gate passed."
