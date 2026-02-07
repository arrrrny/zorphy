## [1.3.4] - 2026-02-07

### Fix
- Referencing

## [1.3.3] - 2026-02-07

### Fix
- Upgraded

## [1.3.3] - 2026-02-07

### Fix
- Upgraded

## [1.3.2] - 2026-02-06

### Fix
- Analyzer

## [1.3.1] - 2026-02-06

### Fix
- Improved

## [1.3.0] - 2026-02-06

### Changed
- Updated to new Zorhpy Api
- 

## [1.2.1] - 2026-02-05

### Chore
- Updated test dependency

## [1.2.0] - 2026-02-05

### Chore
- Downgraded analyzer version to match latest flutter sdk

## [1.1.1] - 2026-02-05

### Fix
- Fixed copyWith method name generation

## [1.1.0] - 2026-02-05

### Change
- Fixed an edge case where a class extends a sealed class and implements another class was causing parameters not passed in super constructor

## [1.0.0] - 2026-02-04

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[Unreleased]: https://github.com/arrrrny/zorphy/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/arrrrny/zorphy/releases/tag/v1.0.0
