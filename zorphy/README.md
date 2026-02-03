# Zorphy

Zorphy is a powerful code generation package for Dart/Flutter that provides clean class definitions with copyWith, JSON serialization, toString, equality, and inheritance support.

## Features

- **CopyWith methods**: Generate `copyWith` methods for immutable data classes
- **JSON serialization**: Generate `toJson`/`fromJson` methods with full polymorphic support
- **Equality**: Generate `==` and `hashCode` methods
- **toString**: Generate meaningful `toString` representations
- **Polymorphism**: Support for sealed classes and interfaces
- **Self-referencing types**: Handle tree structures and hierarchical data
- **Factory methods**: Support for custom factory constructors

## Quick Start

Add the dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  zorphy_annotation: ^1.0.0

dev_dependencies:
  zorphy: ^1.0.0
  build_runner: ^2.4.0
```

Create a simple data class:

```dart
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'person.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $Person {
  String get name;
  int get age;
  String? get email;
}
```

Run the generator:

```bash
dart run build_runner build
```

## Migration from Morphy

Zorphy is designed for easy migration from Morphy. Simply replace:

- `@Morphy` with `@Zorphy`
- `morphy_annotation` with `zorphy_annotation`
- `zikzak_morphy` with `zorphy`

## Advanced Features

### Sealed Classes (Polymorphism)

```dart
@Zorphy()
abstract class $$Shape {
  double get area;
}

@Zorphy(generateJson: true)
abstract class $Circle implements $$Shape {
  double get radius;
  
  @override
  double get area => 3.14159 * radius * radius;
}

@Zorphy(generateJson: true)
abstract class $Rectangle implements $$Shape {
  double get width;
  double get height;
  
  @override
  double get area => width * height;
}
```

### Self-Referencing Classes

```dart
@Zorphy(generateJson: true)
abstract class $TreeNode {
  String get value;
  List<$TreeNode>? get children;
  $TreeNode? get parent;
}
```

## Configuration Options

- `generateJson`: Enable JSON serialization methods
- `explicitSubTypes`: Specify explicit subtypes for copyWith
- `explicitToJson`: Control JSON serialization behavior
- `generateCompareTo`: Generate comparison methods
- `generateCopyWithFn`: Generate function-based copyWith methods
- `hidePublicConstructor`: Hide the public constructor

## License

MIT