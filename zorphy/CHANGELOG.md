## [Unreleased]

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
