## [3.0.0] - 2026-11-17

### Change

- New `lean` subcommand: `zorphy_migrator lean <path> [--dry-run|--apply]
  [--report <file>]`. It scans a package and rewrites each `@Zorphy`
  annotation to the smallest flavor that still covers what the project
  consumes, so generated code shrinks without losing behaviour. See
  `zorphy_migrator/README.md`.
- Evidence is class-attributed and syntactic (no resolution), so a package the
  size of `zik_zak` scans in ~15s: `FooPatch` / `FooFields` / `copyWithFooFn`
  name their class and prove their feature unused when absent;
  `toJson`/`copyWithFn` are instance calls and only drop for a class nothing
  else references; a live class keeps the preset its author chose.
- Every non-feature named argument (`autoId`, `kind`, …) is carried over
  verbatim, and shared parts under `lib/_br_/` are excluded from the scan so
  generated code cannot make every class look used.
- A package-root target now also scans `test/` and `integration_test/`, since a
  feature used only by tests still has to be generated.
- A file that fails to parse is reported and skipped instead of aborting the
  whole scan.
- Version aligned with the `zorphy` 3.0.0 major; the migrator's own `migrate`
  subcommand is unchanged.

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
