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
