# Zorphy Annotation Examples

This directory contains comprehensive examples demonstrating how to use the `zorphy_annotation` package with the `zorphy` code generator.

## Prerequisites

Before running these examples, ensure you have the following dependencies installed:

```bash
dart pub get
```

## Running Code Generation

After making changes to any entity file, run the code generator:

```bash
dart run build_runner build
```

To automatically rebuild when files change:

```bash
dart run build_runner watch
```

To clean generated files before rebuilding:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Example Files

### [basic_example.dart](lib/basic_example.dart)
Demonstrates basic entity creation with:
- Simple entity definition
- Required and optional fields
- copyWith functionality
- Equality and toString
- Patch operations

### [json_example.dart](lib/json_example.dart)
Shows JSON serialization capabilities:
- toJson() and fromJson() methods
- Lean JSON (excluding metadata fields)
- Complex object serialization

### [sealed_class_example.dart](lib/sealed_class_example.dart)
Illustrates sealed class hierarchies:
- Polymorphic types
- Type-safe discriminators
- Exhaustiveness checking

### [nested_example.dart](lib/nested_example.dart)
Demonstrates nested object support:
- Nested entity composition
- Nested patching
- Tree structures

### [generic_example.dart](lib/generic_example.dart)
Shows generic type parameter support:
- Generic entities
- Type safety with generics
- Reusable data structures

### [enum_example.dart](lib/enum_example.dart)
Shows enum field integration:
- Enum fields in entities
- JSON serialization with enums
- Pattern matching

## Running the Examples

After generating code, you can run the main example file:

```bash
dart run lib/basic_example.dart
dart run lib/json_example.dart
dart run lib/sealed_class_example.dart
dart run lib/nested_example.dart
dart run lib/generic_example.dart
dart run lib/enum_example.dart
```

## Generated Code

When you run the code generator, Zorphy creates `.zorphy.dart` files alongside your entity files. These generated files contain:

- Concrete class implementations
- Constructors
- copyWith methods
- Patch classes for partial updates
- JSON serialization (when enabled)
- Equality operators
- toString methods
- Comparison methods (when enabled)

**Note:** Never edit the generated `.zorphy.dart` files directly, as they will be overwritten on the next build.

## Learning More

For complete documentation, visit:
- [zorphy_annotation on pub.dev](https://pub.dev/packages/zorphy_annotation)
- [zorphy on pub.dev](https://pub.dev/packages/zorphy)
- [GitHub Repository](https://github.com/arrrrny/zorphy)
