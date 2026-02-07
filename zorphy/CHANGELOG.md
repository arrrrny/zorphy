## [1.3.4] - 2026-02-07

### Fix
- Referencing

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

### Features
- Added `--dry-run` flag to CLI commands (`create`, `new`, `enum`, `add-field`, `from-json`) to preview generated code without writing files.
- Added support for generating `explicitSubTypes` annotation without extending an interface.

### Changed
- Renamed `--subtype` flag to `--subtypes` in `create` command.
- Updated `zorphy_annotation` dependency to 1.3.0.

### Fix
- Fixed handling of special characters (like `<` and `>`) in CLI `List` and `Map` type arguments.

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

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-04

### Added

- Initial release of zorphy code generator
- Complete code generation for immutable data classes
- CLI tool for entity and enum generation
- JSON serialization support via json_serializable integration
- Comprehensive test suite with examples
- Support for all zorphy_annotation features

### Code Generation

- Immutable concrete class generation from abstract definitions
- Automatic constructor with required/optional parameters
- Smart copyWith methods
- Function-based copyWith (copyWithFn) option
- Patch class generation with fluent API
- Nested patch support
- Equality operator (==) generation
- HashCode generation
- ToString generation
- CompareTo method for diff generation

### Advanced Features

- Sealed class generation with explicit subtypes
- Polymorphic JSON serialization with type discriminators
- Multiple inheritance via interface implementation
- Generic type parameter support
- Self-referencing type support (tree structures)
- Enum field support with automatic serialization
- DateTime serialization (ISO 8601)
- Lean JSON option (excludes metadata)
- Constant constructor support

### CLI

- `zorphy create` command for entity generation
- `zorphy enum` command for enum generation
- Interactive field prompts
- Support for all annotation options via CLI
- Smart type detection and validation

### Integration

- Full build_runner integration
- json_serializable integration for JSON support
- Part file generation (.zorphy.dart)
- Efficient incremental builds

### Examples

- Comprehensive example suite
- Real-world usage patterns
- State management examples
- API response handling
- Nested configuration
- Comparison and patching

### Documentation

- Complete README with feature reference
- Quick start guide
- CLI documentation
- Real-world examples
- Troubleshooting guide

### Bug Fixes

- Fixed multiple inheritance super constructor calls
- Fixed self-referencing type resolution
- Fixed generic type parameter handling
- Added json_annotation to dev dependencies

### Performance

- Optimized build performance
- Efficient incremental compilation
- Minimal generated code overhead

[Unreleased]: https://github.com/arrrrny/zorphy/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/arrrrny/zorphy/releases/tag/v1.0.0
