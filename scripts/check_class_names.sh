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
  basename="${file##*/}"
  case "$basename" in
    *[Ii][Mm][Pp][Ll]*)
      printf 'FILE_NAME %s\n' "$file"
      violations=1
      ;;
  esac

  case "$file" in
    *.dart)
      while IFS= read -r match; do
        printf 'CLASS_NAME %s:%s\n' "$file" "$match"
        violations=1
      done < <(grep -nE '(^|[[:space:]])class[[:space:]]+[[:alnum:]_$]*Impl[[:alnum:]_$]*' "$file" || true)
      ;;
  esac
done < <(git ls-files -z --cached --others --exclude-standard -- "${scan_paths[@]}")

if [ "$violations" -ne 0 ]; then
  echo "Impl class/file naming policy violated." >&2
  exit 1
fi

echo "Class and file naming gate passed."
