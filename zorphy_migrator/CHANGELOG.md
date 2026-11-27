## [3.0.0-dev.5] - 2026-11-27

### Change
- ZorphyNested, fromJson/toJson aliases, enum boundary wire, colocated .zorphy.dart (retires _br_), wire-capability matrix, stacked-PR integrity, clean-checkout release gate

## [3.0.0-dev.4] - 2026-11-27

### Change
- ZorphyField.asObject erasure + static registry (#301), ZorphyNested (#303), union factory fixes, autoId removal (#300)

## [3.0.0-dev.3] - 2026-11-26

### Documentation (#275, ZRP-006)

- No migrator code change in this release. The `migrate` subcommand already
  emits the zero-preset v3 archetypes and strips every `preset:` / `generate*`
  argument (3.0.0-dev.2); the README and website documentation pass (#275)
  describes the same v3 target surface the codemod produces.

## [3.0.0-dev.2] - 2026-11-26

### Changed (BREAKING — v3.0.0)

- **`lean` subcommand removed (#233).** The v3 zero-preset archetypes have no
  presets to minimize, so the `lean` subcommand and its detector are gone. The
  `migrate` subcommand now emits the zero-preset v3 archetypes
  (`@ZorphyEntity(principalKey: #id)` / `@ZorphyValue()` / `@ZorphyUnion()`)
  instead of `@Zorphy(preset: …)`, and the smoke corpus validates migration
  into the v3 surface rather than back into the legacy one.

### Change

- Version aligned with the `zorphy` 3.0.0 major. The `migrate` subcommand's
  output changed with this major (see Changed above): it now emits the
  zero-preset v3 archetypes instead of `@Zorphy(preset: …)`.
- A package-root target also scans `test/` and `integration_test/`, since a
  feature used only by tests still has to be generated, and skips generated
  shared parts under `lib/_br_/` so generated code cannot skew the scan.

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
