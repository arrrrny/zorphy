## [2.2.0] - 2026-08-21

### Refactor

- Generators: extract the cross-entity import guidance detector (issue #117)
  into a public, testable, analyzer-free helper — `CrossEntityImportDetector`
  at `package:zorphy/src/analysis/cross_entity_import_detector.dart`. The
  `ZorphyGenerator` still emits the same guidance comment; the detector is now
  unit-tested directly.

### Test

- Add regression tests for issue #117 (cross-entity `patchWith`/`fromJson` cast
  targets the concrete entity type) and issue #119 (subtype `patchWith` cast
  strips the leading `$`), with `example/lib/various` fixtures.
- Add unit tests for `CrossEntityImportDetector` (pre-filter, self-reference
  skip, missing-import detection, generic type arguments, snake_case
  conversion, and comment/string-literal-safe import scanning).

## [2.1.1] - 2026-08-21

### Feat

- CLI: `--static` flag emits static class members on generated entities
  (closes #107).
- Generators: `Patch` + `FieldEnum` generation for nonSealed abstract base
  classes (closes #111).
- Generators: bare `Function`/`Function?` callback fields on value-object
  entities no longer break json_serializable (closes #105).

## [2.1.0] - 2026-08-21

### Feat

- Polymorphic dispatch: `EntityConfig` gains `typeKey` (default `__typename`)
  and `subtypeWireValue` for custom polymorphic JSON keys/values, and the
  generated `ChangeTo` extension now serializes sealed subtypes via a
  `switch (this)` that calls the correct `toJson()` per subtype (fixes
  malformed polymorphic payloads for explicit-subtype hierarchies).

### Fix

- Generators: strip the leading `$` from `patchWith`/`fromJson` cast types for
  explicit-subtype fields — the generated `as $Credentials?` cast (undefined
  in the consuming file) now resolves to `as Credentials?`
  (fixes arrrrny/zorphy#119).

## [2.0.1] - 2026-08-19

### Fix

- Generators: typed `patchWith` — the generated `_patchMap` ternary chains
  collapse to `dynamic`; patched values are now cast with postfix `as T`
  (valid for nullable types too) instead of invalid prefix `(T)?` casts.
- Generators: `toJsonLean` sanitizes the map in place and returns the typed
  `Map<String, dynamic>` instead of returning the `dynamic` sanitizer result.
- CLI: `ImportResolver` emits relative sibling-entity imports for `!Type`
  (external) fields when the referenced entity exists on disk — cross-entity
  references now generate resolvable code (fixes json_serializable
  `InvalidType` failures).

Generated code from both fixes passes `dart analyze` with zero findings.

## [2.0.0] - 2026-08-16

### Feat

- `autoId` support: a `@Zorphy(autoId: true)` class whose source declares
  `String get id;` gets an optional `String? id` constructor parameter
  defaulting to `const Uuid().v4()` — the generated class is
  constructible without an explicit identity (zuraffa#307). The
  `@ZValueObject` / `ZorphyKind.valueObject` kind is parsed and threaded
  into `GenerationConfig` for framework consumers.
- `EntityConfig`/template: `autoId` and `kind` options — `zfa entity
  create --auto-id` emits the `id` getter, the uuid import and the
  `autoId: true` annotation option; `--kind=value_object` emits
  `kind: ZorphyKind.valueObject`.
- `zorphy_annotation` bumped to 2.2.0 (new `ZorphyKind`, `autoId`,
  `ZValueObject` annotation surface).

## [2.1.0] - 2026-08-03

### Feat

- AST-based smart regeneration engine — non-destructive merge of
  generated output with user edits (region markers, structural diff,
  conflict reporting)
- Plugin API & registry (`ZorphyPlugin`, `PluginContext`,
  `PluginRegistry`) — post-spec transform hooks with topological
  ordering, import injection, and diagnostic accumulation
- `MergeMode` enum (`smart` / `force`) and `isForce` builder/
  generator flag to bypass smart merge
- `ZorphyPlugin` abstract class exported from `zorphy.dart`

### Change

- Version synced with `zorphy_annotation` 2.1.0
- `zorphy_annotation` dependency bumped to `^2.1.0`

## [2.0.0] - 2026-07-30

### Break

- `analyzer` constraint widened to `>=13.0.0 <15.0.0` — consumers on modern Dart toolchains (analyzer 14.x) now resolve without overrides
- `build.yaml` consolidated to a single builder: one generation pass per library (roughly 2x faster consumer builds). The second pass (`zorphy2` builder) no longer exists; `@zorphy2`/`@Zorphy2` keep working as deprecated aliases of `@zorphy`
- Removed process-global static cross-asset state (`_allAnnotatedClasses`) — annotated-class graphs are now built per library, so build_runner caching/invalidation works correctly
- Fieldless explicit subtypes now emit a minimal patch class and identity `patchWith` — `changeTo` extensions reference them (previously produced undefined-method errors)

### Feat

- `ZorphyPreset` (`lean` / `standard` / `full`) plus per-feature `bool?` flags (`generateCopyWith`, `generatePropertyHelpers`, `generateEqualsToString`, `generateChangeTo`, and existing flags now nullable) — `null` inherits from the preset, explicit values override it
- `standard` preset reproduces 1.9.0 output semantics — upgrading with no annotation changes keeps full output (see note on `generateFilter` below)
- `lean` preset emits only class + constructor + copyWith + `==`/hashCode/toString; `full` adds `copyWithFn`
- All flag resolution is centralized in `GenerationConfig`; generators no longer read annotations directly
- CI matrix verifies `dart test` against analyzer 13.x and 14.x

### Note

- The deprecated `const zorphy`/`const zorphy2` top-level constants previously carried `generateFilter: false` (while the class default was `true`); in 2.0 both paths resolve consistently to the `standard` preset (`generateFilter: true`). Affected files gain `Fields` filter descriptors on regeneration. Pin `generateFilter: false` explicitly to opt out.

See MIGRATION-v2.md for the upgrade path.

## [1.9.0] - 2026-07-21

### Breaking

- Replaced inline `_zc`/`ZorphyJsonHelper` safe-cast approach with native `json_serializable` deserialization using `checked: true` — field-level error messages are now provided by `CheckedFromJsonException` from the `json_serializable` package rather than custom `ZorphyJsonCastError`
- Removed `zorphy_annotation` source files: `json_helper.dart` and `json_cast_error.dart` — these are no longer needed; all JSON deserialization is handled by `json_serializable` directly

### Fix

- `Map<K, V>` fields (e.g. `Map<String, String>?`, `Map<String, Entity>?`) now correctly deserialize because `checked: true` + native generation produces recursive `.map((k, e) => MapEntry(k, e as String))` conversions in the `.g.dart` file, resolving runtime `type '_Map<String, dynamic>' is not a subtype of type 'Map<String, String>'` errors

### Chore

- Upgraded `build_runner` to ^2.15.2, `source_gen` to ^4.2.3, `json_annotation` to ^4.12.0
- Removed `dependency_overrides` for `analyzer` and `meta` — packages now resolve coherently against the SDK

### Features preserved from earlier releases (cherry-picked)

- Refined nullable-string property helpers: `text?.isNotEmpty == true` instead of `text != null && text.isNotEmpty`
- Const constructor support for non-sealed abstract classes

## [1.8.10] - 2026-07-21

### Fix

- Replaced deprecated `@JsonKey(ignore: true)` with `@JsonKey(includeToJson: false, includeFromJson: false)` on `hashCode` getter
- `Map<K,V>` fields now use direct `(json['f'] as Map<K,V>?)` cast instead of `ZorphyJsonHelper.cast` to avoid runtime type erasure issues (e.g. `Map<String, dynamic>` vs `Map<String, String>`)

## [1.8.9] - 2026-07-21

### Fix

- Replaced deprecated `@JsonKey(ignore: true)` with `@JsonKey(includeToJson: false, includeFromJson: false)` on `hashCode` getter

## [1.8.8] - 2026-07-21

### Fix

- `hashCode` getter is now annotated with `@JsonKey(ignore: true)` to prevent json_serializable from including it in `toJson` output (regression from `createFactory: false` changes)

## [1.8.7] - 2026-07-21

### Fix

- `List<Object>` and other identity-cast list fields now cast directly to the target type (`as List<Object>?`) instead of going through `List<dynamic>` which isn't assignable in Dart 3
- Fields like `List<Object>? get match` now generate `(json['match'] as List<Object>?)`

## [1.8.6] - 2026-07-20

### Fix

- Reverted `List`/`Set` field casts from `ZorphyJsonHelper.cast<List<dynamic>>` back to `(json['f'] as List<dynamic>)` — generic function return types don't satisfy Dart 3's type system for downstream typed list parameters
- Enum detection now scans analyzer-level type arguments, catching enums that only appear inside generic types like `List<TransformationType>` without a bare `TransformationType` field

## [1.8.5] - 2026-07-20

### Fix

- `List<EnumType>` fields in fromJson now use `$enumDecode(_$EnumTypeEnumMap, e)` for element conversion instead of incorrectly calling `EnumType.fromJson(e as Map<String, dynamic>)`

## [1.8.4] - 2026-07-20

### Fix

- Fields with `@JsonKey(fromJson: someConverter)` but no `includeFromJson: false` now correctly call the converter instead of falling through to `.fromJson()` on the raw type

## [1.8.3] - 2026-07-20

### Fix

- Non-sealed abstract classes with `const` constructors now correctly generate `const ClassName();` instead of `ClassName();`

## [1.8.2] - 2026-07-20

### Refactor

- Simplified nullable string property helpers: `hasText` now uses `text?.isNotEmpty == true` instead of `text != null && text.isNotEmpty`

### Chore

- Removed CI-based pub.dev publishing; publish script now publishes directly via `dart pub publish --force`

## [1.8.1] - 2026-07-20

### Fix

- Replaced per-class `_zc<T>()` static helpers with shared `ZorphyJsonHelper.cast<T>()` from `zorphy_annotation` for Dart 3.12+ compatibility
- Added `ZorphyJsonCastError` with field-level context in error messages

## [1.8.0] - 2026-07-20

### Feature

- Safe fromJson casts with field-level error messages — replaces json_serializable delegates with inline `_zc<T>()` wrapper that throws `TypeError.withStackTrace` including field name, expected type, actual type, and the value itself
- Example error: `Zorphy: Field 'id' expected String, got int (42)`

## [1.7.1] - 2026-05-02

### Change

- updated dependencies

## [1.7.0] - 2026-04-30

### Change

- Upgrade to analyzer 13 and update dependencies

## [1.6.9] - 2026-04-27

### Change

- Revert property helper generation to ownFields and fix automated publishing flow

## [1.6.8] - 2026-04-27

### Change

- Streamline release process and fix PropertyHelpers extension generation for inherited fields

## [1.6.7] - 2026-04-06

### Fix

- Factory method parameter types now preserve import prefixes (`as` clauses) in generated code

## [1.6.6] - 2026-04-05

### Feature

- Extracted Patch class boilerplate into `PatchBase` to drastically reduce generated code size.
- Fixed `toJson()` bug on abstract base classes in explicit subtypes `changeTo` extension.

## [1.6.5] - 2026-04-01

### Change

- Analyzer 12 compabilities

## [1.6.4] - 2026-02-15

### Fix

- Have to upgrade Analyzer package due to bug in 10.0.0

## [1.6.3] - 2026-02-15

###

-

## [1.6.2] - 2026-02-15

### Fix

- works with analyzer 10.0.0 that dont require meta 1.18

## [1.6.1] - 2026-02-15

### Change

- Refactored CLI code to be more robust and consumable

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2026-02-14

### Change

- Update Zorphy CLI to be more extensible and consumable by other CLIs

## [1.5.8] - 2026-02-14

### Fix

- Nonsealed classes with explicit subtypes can have their own fromJson

## [1.5.7] - 2026-02-14

### Fix

- Modified skip logic in `getProperties()` to not skip fields that exist in both parentFields and ownFields (overridden fields)
- Prevents duplicate `@override` annotation when source already has it
- Constructor generation `isParentField` check now excludes fields in ownFields so overridden fields use `this.field` syntax
- Added `_getCovariantFields()` helper to detect fields where class type differs from interface type
- `getInterfaceCopyWithMethods()` now uses class field types (not interface types) for parameters and adds covariant where needed
- `getInterfaceCopyWithFnMethods()` now uses class field types for parameters

## [1.5.6] - 2026-02-14

### Chore

- Updated docs and created docusaurus website
- Create public constructors by default and only create private when hidden

## [1.5.5] - 2026-02-13

### Fix

- Fixed null type issue on custom toJson

## [1.5.4] - 2026-02-13

### Change

- Allow hybrid serialization with json_serializable for generic field types

## [1.5.3] - 2026-02-13

### Fix

- Fixed JsonKey and other annotations not being caught due to Analyzer 10 changes

## [1.5.2] - 2026-02-12

### Fix

- Updated copyWith generation to use a sentinel parameter pattern, preserving non-nullable fields while allowing explicit nulls for nullable fields

## [1.5.1] - 2026-02-11

### Fix

- Fixed issue with nested entity

## [1.5.0] - 2026-02-09

### Feat

- Added property helpers extension

## [1.4.1] - 2026-02-09

### Chore

- Bumped example versions

## [1.4.0] - 2026-02-07

### Feat

- Added [feature description needed]

## [1.3.4] - 2026-02-07

### Fix

- Referencing issues

## [1.3.3] - 2026-02-07

### Fix

- Upgraded dependencies

## [1.3.2] - 2026-02-06

### Fix

- Analyzer compatibility improvements

## [1.3.1] - 2026-02-06

### Fix

- Improved type handling

## [1.3.0] - 2026-02-06

### Changed

- Updated to new Zorphy API

## [1.2.1] - 2026-02-05

### Chore

- Updated test dependency

## [1.2.0] - 2026-02-05

### Chore

- Downgraded analyzer version to match latest Flutter SDK

## [1.1.1] - 2026-02-05

### Fix

- Fixed copyWith method name generation

## [1.1.0] - 2026-02-05

### Change

- Fixed edge case where a class extends a sealed class and implements another class causing parameters not passed in super constructor

## [1.0.0] - 2026-02-04

### Added

- Initial release of zorphy_annotation package
- Core `@Zorphy()` annotation with full configuration support
- `generateJson` option for JSON serialization
- `generateCompareTo` option for diff generation
- `generateCopyWithFn` option for function-based copyWith
- `explicitSubTypes` option for sealed class hierarchies
- Support for generic type parameters
- Support for nested object patching
- Support for self-referencing types
- Support for multiple inheritance via interfaces
- Support for enum fields
- Support for constant constructors
- Full TypeScript-style type safety

### Features

- Immutable data class generation
- Automatic constructor generation
- Smart copyWith methods
- Advanced patching system with fluent API
- JSON serialization with lean JSON option
- Sealed classes with polymorphic serialization
- Multiple inheritance support
- Generic class support
- Enum integration
- Self-referencing type support
- Comparison and diff generation
- Equality and hashCode generation
- ToString generation
- Type-safe field enums

### Documentation

- Comprehensive README with examples
- Quick start guide
- Feature reference
- Real-world usage examples

[Unreleased]: https://github.com/arrrrny/zorphy/compare/v1.6.5...HEAD
[1.5.6]: https://github.com/arrrrny/zorphy/compare/v1.5.5...v1.5.6
[1.6.1]: https://github.com/arrrrny/zorphy/compare/v1.5.6...v1.6.1
[1.6.2]: https://github.com/arrrrny/zorphy/compare/v1.6.1...v1.6.2
[1.6.3]: https://github.com/arrrrny/zorphy/compare/v1.6.2...v1.6.3
[1.6.4]: https://github.com/arrrrny/zorphy/compare/v1.6.3...v1.6.4
[1.6.5]: https://github.com/arrrrny/zorphy/compare/v1.6.4...v1.6.5
[1.5.5]: https://github.com/arrrrny/zorphy/compare/v1.5.4...v1.5.5
[1.5.4]: https://github.com/arrrrny/zorphy/compare/v1.5.3...v1.5.4
[1.5.3]: https://github.com/arrrrny/zorphy/compare/v1.5.2...v1.5.3
[1.5.2]: https://github.com/arrrrny/zorphy/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/arrrrny/zorphy/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/arrrrny/zorphy/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/arrrrny/zorphy/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/arrrrny/zorphy/compare/v1.3.4...v1.4.0
[1.3.4]: https://github.com/arrrrny/zorphy/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/arrrrny/zorphy/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/arrrrny/zorphy/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/arrrrny/zorphy/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/arrrrny/zorphy/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/arrrrny/zorphy/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/arrrrny/zorphy/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/arrrrny/zorphy/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/arrrrny/zorphy/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/arrrrny/zorphy/releases/tag/v1.0.0
