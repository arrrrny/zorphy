## [Unreleased]

### Added

- Collection delta patches (#183): `ListPatchDelta<E>` and
  `MapPatchDelta<K, V>` carry an ordered sequence of `ListPatchOp` /
  `MapPatchOp` steps and implement the full v3 algebra — minimal `diff`
  (no op for an unchanged collection, one op per appended/removed/edited
  element or put/removed key), fold-ordered `apply` that never mutates,
  concatenating `compose`, round-tripping `invert`, and `toWire` rendering
  each step as a descriptor. Both also implement the legacy `Patch<T>` arm,
  which is how a generated `patchWith` applies them.
- `PatchNested` implements `Patch<Sub>` as well as `ZorphyPatch<Sub>`, so a
  parent patch's carried nested patch resolves through the same legacy arm,
  and gained `invertNested(before)` for inverting a carried sub-patch (#183).

- `PatchBase` is const-constructible through `PatchBase.empty()`, which backs
  the generated `<Name>Patch.empty()` constructor: the empty patch is the
  allocation-free neutral element of `compose` and `apply` returns its target
  unchanged (#182).

- The v3 patch algebra: `ZorphyPatch<T>` (`isEmpty` / `isNotEmpty`, `apply`,
  `compose`, `invert`, `toWire`) with its laws documented on the interface,
  plus the field-level shapes it composes with — `PatchValue<V>`
  (`unchanged` / `set`), `PatchNested<Sub, SubPatch>`, `ListPatchOp<E>`
  (`replaceAll` / `append` / `removeAt` / `updateAt`) and
  `MapPatchOp<K, V>` (`replaceAll` / `put` / `remove`) (#181). Every op
  returns a fresh collection and never mutates its input.
- The five v3 archetypes, all zero-toggle: `ZorphyEntity` (`principalKey`),
  `ZorphyState`, `ZorphyUnion`, `ZorphyIntent` (`replaySafe`, required) and
  `ZorphyValue`, plus the marker interfaces `ZorphyEntityBase<Id>`,
  `ZorphyStateBase`, `ZorphyUnionBase`, `ZorphyIntentBase`, `ZorphyValueBase`
  and the shared `ZorphyPolymorphicBase` (#175, #176). A class is annotated
  with exactly one archetype; polymorphism is declared through `discriminator`
  (default `'kind'`) and `explicitSubTypes`.
- `ZorphyMock` — a field-level seed hint, not a toggle — and
  `ZorphyMockPresets`, the reserved `preset` names (`email`, `uuid`, `price`,
  `url`) as constants so a consumer and the generator share one closed set.

### Changed

- `ZorphyNamedConstructor` moved to `src/annotations.dart` — the library URI
  the generator resolves it from — so the move is source-compatible.
- SDK floor raised to `>=3.11.0` to match what the tracked lockfile resolves
  and what `zorphy` / `zorphy_migrator` already declare. `dartx` dropped: it
  had no reference in this package. The package also gains its first dev
  dependency, `test`, for the archetype suite in `test/annotations_test.dart`
  (previously its tests ran from the `zorphy` package only).

### Deprecated

- The pre-v3 surface (`@Zorphy`, `@Zorphy2`, `@ZValueObject`, `ZorphyPreset`,
  `ZorphyKind`, the `generate*` flags, `ZorphyX`, and the
  `getGenericToJsonFn` / `getFromJsonToGenericFn` runtime helpers) is kept and
  exported for source compatibility: `zorphy` resolves this package by path
  and reads its annotations from this library URI, and `zorphy_migrator` emits
  `@Zorphy(...)` text. It is removed once the generator is ported onto the
  archetypes (#177, #178, #181, #187).

## [3.0.0] - 2026-11-17

### Change

- Version synced with `zorphy` 3.0.0. **No API change** — the 3.0.0 breaking
  change is in the generator's output layout (shared parts under `lib/_br_/`),
  not in these annotations.
- `ZorphyPreset` semantics are unchanged; `lean` still means class,
  constructor, `copyWith`, `==`/`hashCode`, `toString`, with every other
  feature opt-in.

## [2.5.0] - 2026-11-16

### Change

- Version synced with `zorphy` 2.5.0 (no annotation API changes).
- No constraint changes: `zorphy_annotation` keeps its own `>=3.8.0` SDK floor
  because its dependency set (collection, dartx, json_annotation, meta,
  quiver) resolves there. Consumers of `zorphy` inherit `zorphy`'s
  `>=3.11.0` floor, which is the binding minimum for the generator's
  dependency set.

## [2.4.6] - 2026-11-15

### Change

- Version synced with `zorphy` 2.4.6 (no annotation API changes — formatting only)

### Style

- Mechanical `dart format` of drifted sources, e.g. `query/filter.dart` (#150)
- `meta` constraint normalized to caret form `^1.17.0` — same `>=1.17.0 <2.0.0` range

## [2.4.5] - 2026-11-10

### Change

- Version synced with `zorphy` 2.4.5 (no annotation API changes in this release; generator-side fixes #142 and #148 ship in `zorphy`).

## [2.4.4] - 2026-10-20

### Change

- Version synced with `zorphy` 2.4.4 (no annotation API changes in this release).

## [2.4.3] - 2026-09-18

### Change

- Version synced with `zorphy` 2.4.3 (no annotation API changes in this release).

## [2.4.2] - 2026-09-18

### Change

- Version synced with `zorphy` 2.4.2 (no annotation API changes in this release).

## [2.4.1] - 2026-09-18

### Change

- Version synced with `zorphy` 2.4.1 (no annotation API changes in this release).

## [2.4.0] - 2026-09-13

### Change

- Version synced with `zorphy` 2.4.0 (no annotation API changes in this release).

## [2.3.1] - 2026-08-27

### Change

- Version synced with `zorphy` 2.3.1 (no annotation API changes in this
  release).

## [2.3.0] - 2026-08-23

### Feat

- Added `equalityExcludes` to `@Zorphy`, `@Zorphy2`, and `ZorphyX` for excluding selected fields from generated equality, lean JSON, and comparison surfaces.
- Added agent annotations: `@AgentTool`, `@AgentRisk`, `@AgentInternal`, `@AgentExclude`, and `@AgentToolParam`.
- Added `@ZorphyNamedConstructor` support for custom constructor bodies.

## [2.2.0] - 2026-08-21

### Change

- Version synced with `zorphy` 2.2.0 (no annotation API changes in this
  release).

## [2.1.1] - 2026-08-21

### Change

- Version synced with `zorphy` 2.1.1 (no annotation API changes in this
  release).

## [2.1.0] - 2026-08-03

### Feat

- Added `MergeMode` enum (`smart` / `force`) for future per-class merge
  control — re-exported from `zorphy_annotation.dart` for consumer access

### Change

- SDK constraint aligned to `>=3.8.0 <4.0.0` (matches `zorphy` package)
- Version synced with `zorphy` 2.1.0

## [2.0.0] - 2026-08-16

### Feat

- `@Zorphy(autoId: true)` — auto-generated identity: the generated
  concrete constructor's `id` parameter is optional and defaults to a
  fresh `Uuid().v4()` at construction time (zuraffa#307 — entities like
  `ChatMessage` / `TelemetryEvent` no longer need callers to supply ids).
  The annotated class declares `String get id;` and the library imports
  `package:uuid/uuid.dart`.
- `ZorphyKind` (`entity` / `valueObject`) on `@Zorphy`/`@Zorphy2` plus the
  `@ZValueObject` const alias — marks a class as an immutable composition
  type with no identity. Codegen (equality, copyWith, JSON) is unchanged;
  the kind is consumed by the zfa `make` pipeline to skip root plugins.
- `ZorphyX` interface extended with `kind` and `autoId` getters.

## [2.1.0] - 2026-08-03

### Feat

- Added `MergeMode` enum (`smart` / `force`) for future per-class merge
  control — re-exported from `zorphy_annotation.dart` for consumer access

### Change

- SDK constraint aligned to `>=3.8.0 <4.0.0` (matches `zorphy` package)
- Version synced with `zorphy` 2.1.0

## [2.0.0] - 2026-07-30

### Break

- All feature flags on `@Zorphy`/`@Zorphy2` are now `bool?` (default `null` = inherit from preset). Source-compatible for named-argument use; the resolved semantics are unchanged for defaults
- `ZorphyX.generateFilter` getter type changed `bool` → `bool?`

### Feat

- New `ZorphyPreset` enum (`lean` / `standard` / `full`) and `preset` parameter on both annotations (default `standard`, reproducing 1.9.0 output)
- New flags: `generateCopyWith`, `generatePropertyHelpers`, `generateEqualsToString`, `generateChangeTo`
- `@zorphy2`/`Zorphy2` deprecated — the generator is single-pass since 2.0; the alias behaves identically and will be removed in a later major

## [1.9.0] - 2026-07-21

### Break

- Removed `ZorphyJsonHelper` and `ZorphyJsonCastError` classes — no longer used; JSON deserialization is now fully handled by `json_serializable`'s native `checked: true` generation
- Removed `export 'src/json_helper.dart'` and `export 'src/json_cast_error.dart'` from `zorphy.dart`

## [1.8.10] - 2026-07-21

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.9] - 2026-07-21

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.8] - 2026-07-21

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.7] - 2026-07-21

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.6] - 2026-07-20

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.5] - 2026-07-20

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.4] - 2026-07-20

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.3] - 2026-07-20

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.2] - 2026-07-20

### Change
- Sync version with zorphy package for consistent release numbering

## [1.8.1] - 2026-07-20

### Feature

- Added `ZorphyJsonCastError` and `ZorphyJsonHelper` classes for shared safe JSON casting with field-level error messages

## [1.8.0] - 2026-07-20

### Change
- Sync version with zorphy package for consistent release numbering

## [1.7.1] - 2026-05-02

### Change
- Release 1.7.1
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

### 
- 

## [1.6.6] - 2026-04-05

### Feature
- Added `PatchBase` class to centralize JSON serialization for leaner patch generation.

## [1.6.5] - 2026-04-01

### Change
- Analyzer 12 compabilities

## [1.6.4] - 2026-02-15

### Fix
- Have to upgrade Analyzer package due to bug in 10.0.0

## [1.6.3] - 2026-02-15

### Fix
- downgraded annotation dependency to meta 1.17

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

[Unreleased]: https://github.com/arrrrny/zorphy/compare/annotation-v1.6.7...HEAD
[1.5.6]: https://github.com/arrrrny/zorphy/compare/v1.5.5...v1.5.6
[1.6.1]: https://github.com/arrrrny/zorphy/compare/annotation-v1.5.6...annotation-v1.6.1
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
