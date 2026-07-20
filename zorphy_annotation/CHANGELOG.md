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
