## [2.5.0] - 2026-11-18

### Change

- First published release. The package existed in the repo but had never been
  on pub.dev: `dart pub publish` refused it twice over -- a package with
  `dependency_overrides` in its `pubspec.yaml` is rejected outright, and so is
  one with no LICENSE file. The local `zorphy_annotation` path override now
  lives in `pubspec_overrides.yaml` (a development-only file pub ignores), and
  the MIT LICENSE ships with the archive.
- `tool/probe.dart` is gone -- a scratch script that hard-coded
  `/tmp/mig_scratch` and was being published inside the archive.
- Version aligned with the zorphy 2.5.0 release, and the `zorphy_annotation`
  constraint moves to `^2.5.0`.
- The `migrate` subcommand itself is unchanged from 2.0.0.

## [0.2.4] - 2026-09-18

### Change

- Version bump for zorphy 2.4.3 ecosystem release (no migrator changes).

## [0.2.3] - 2026-09-18

### Change

- Version bump for zorphy 2.4.2 ecosystem release (no migrator changes).

## [0.2.2] - 2026-09-18

### Change

- Version bump for zorphy 2.4.1 ecosystem release (no migrator changes).

## [0.2.1] - 2026-09-13

### Change

- Version bump for zorphy 2.4.0 ecosystem release (no migrator changes).

## [0.2.0] - 2026-08-16

### Feat

- `@ExchangeableObject` / `@ExchangeableEnum` dialect: migrate custom codegen
  models (flutter_inappwebview forks, e.g. zikzak_inappwebview) that do not
  use Freezed — value objects become
  `@Zorphy(kind: ZorphyKind.valueObject, generateJson: true,
  generateCompareTo: true)` entities, class-based enums become plain Dart
  enums, the codegen `_` suffix is stripped, constructor defaults become
  `@JsonKey(defaultValue:)`, and sibling references drop the `_` suffix
  (closes zorphy #86)
- `@ExchangeableObjectMethod`/`@ExchangeableObjectProperty`/
  `@ExchangeableObjectConstructor` members, non-constructor fields, and enum
  wire values that do not map onto a plain enum are reported as manual —
  never silently dropped
- A directory with no detected models now warns and exits 1 instead of
  reporting a clean (no-op) migration

## [0.1.0] - 2026-07-30

### Feat

- Initial release: freezed → zorphy codemod using resolved AST analysis (`AnalysisContextCollection`, analyzer 14)
- Converts simple classes, sealed unions (`$$Base` + `$Variant` subtypes), `fromJson`/`toJson` (`generateJson: true`), `@Default` (→ `@JsonKey(defaultValue:)`), `@JsonKey` (preserved), and rewrites `$`-prefixed sibling type references
- Lean-preset inference for classes that only use lean features
- CLI: `migrate <path>` with `--dry-run` (default), `--apply`, `--report <file>`, `--fail-on-manual`; exit codes 0/1/2
- Markdown migration report: converted classes, manual-attention items with `file:line`, post-migration instructions
- Golden-fixture test suite + 11-class end-to-end smoke test (migrate → `build_runner build` → `dart analyze` clean against zorphy 2.0)
