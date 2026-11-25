# Zorphy Annotation

> **⚠️ v3.0.0 — archetypes only, zero codegen toggles.** The legacy `@Zorphy` /
> `@Zorphy2` / `ZorphyPreset` / `ZValueObject` / `generate*` surface was removed
> after the v3 migration gate (#233). The only class annotations are the
> zero-preset archetypes — `@ZorphyEntity(principalKey: #id)`, `@ZorphyValue()`,
> `@ZorphyUnion()`, `@ZorphyState`, `@ZorphyIntent` — and none carries a
> `generate*` toggle. The package keeps a single external dependency, `crypto`
> (the SHA-256 intent digest, #189); the #176 zero-dependency gate is reconciled
> against that requirement in #175.

[![pub package](https://img.shields.io/badge/pub-v1.0.0-blue)](https://pub.dev/packages/zorphy_annotation)
[![Dart SDK](https://img.shields.io/badge/sdk-Dart%20%3E%3D%203.0.0-blue)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**Annotations for the Zorphy code generation package** - A powerful, type-safe code generation solution for Dart/Flutter that provides clean class definitions with automatic generation of constructors, copyWith methods, JSON serialization, toString, equality operators, and advanced inheritance support.

## 🎯 Features

Zorphy annotation package provides the core annotations used by the [Zorphy](https://pub.dev/packages/zorphy) code generator. This package contains no runtime logic - it only defines the annotations that you use in your code.

### Core Capabilities

When used with the Zorphy builder, these annotations enable:

- ✅ **Immutable Data Classes** - Define clean, immutable entities with minimal boilerplate
- ✅ **Automatic Constructors** - Generate typed constructors with required and optional parameters
- ✅ **Smart CopyWith** - Create modified copies with `copyWith()` and function-based variants
- ✅ **Advanced Patching** - Partial updates with nested object patching support
- ✅ **JSON Serialization** - Built-in `toJson()` and `fromJson()` with lean JSON option
- ✅ **Sealed Classes** - Polymorphic hierarchies with type-safe discriminators
- ✅ **Multiple Inheritance** - Combine multiple abstract class definitions
- ✅ **Generic Support** - Full support for generic type parameters
- ✅ **Enum Integration** - First-class enum field support
- ✅ **Self-Referencing Types** - Tree structures and recursive models
- ✅ **Comparison Methods** - Diff generation and comparison utilities
- ✅ **Equality & HashCode** - Automatic `operator ==` and `hashCode` generation
- ✅ **ToString** - Human-readable string representations
- ✅ **Constant Constructors** - Support for compile-time constants

## 📦 Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  zorphy_annotation: ^1.4.1
```

Then add the builder package as a development dependency:

```yaml
dev_dependencies:
  zorphy: ^1.4.1
  build_runner: ^2.0.0
```

## 🚀 Quick Start

### 1. Define Your Entity

Pick the archetype that matches the semantics of the type — `@ZorphyEntity`,
`@ZorphyState`, `@ZorphyUnion`, `@ZorphyIntent` or `@ZorphyValue`:

```dart
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'user.zorphy.dart';

@ZorphyEntity(principalKey: #id)
abstract class $User {
  String get id;
  String get name;
  int get age;
  String? get email;
}
```

Every archetype generates the same unconditional surface (`copyWith`,
`==`/`hashCode`, `toString`, patching, filters, and JSON), so what you pick
changes the SEMANTICS, never the feature set. An `@ZorphyEntity` root must
name its `principalKey`; a subtype inherits it and leaves it unset.

> The pre-v3 `@Zorphy()` / `@Zorphy2()` / `@ZValueObject` annotations and the
> `generate*` flags are still exported for source compatibility while the
> generator is ported onto the archetypes (#177, #178, #181, #187). New code
> should use the archetypes above.

### 2. Run Code Generation

```bash
dart run build_runner build
```

### 3. Use the Generated Class

```dart
// Create instances
final user = User(name: 'Alice', age: 30);

// Copy with changes
final olderUser = user.copyWith(age: 31);

// Patch with partial updates
final patched = user.patchWithUser(
  patchInput: UserPatch.create()..withName('Bob'),
);

// String representation
print(user); // User(name: Alice, age: 30, email: null)

// Equality
final sameUser = User(name: 'Alice', age: 30);
print(user == sameUser); // true
```

## 📚 Annotation Options

The v3 archetypes are zero-toggle: the generated surface is unconditional, so
there is no `generateJson` / `generatePatch` / `generateCompareTo` flag to
set. What each archetype accepts is only what its semantics needs.

### `principalKey` (`ZorphyEntity` only, `Symbol?`)

The identity field of the entity root, e.g. `#id`. Required at generation time
for a root; inherited by subtypes, which leave it unset.

```dart
@ZorphyEntity(principalKey: #id)
abstract class $Product {
  String get id;
  String get name;
  double get price;
}
```

### `discriminator` (all archetypes, `String`, default `'kind'`)

The JSON key the base's `fromJson` dispatches on.

### `explicitSubTypes` (all but `ZorphyUnion`, `List<Type>`, default `[]`)

The subtype set declared on a polymorphic base, as `$`-prefixed abstract
classes. `ZorphyUnion` takes its variant set from the `implements` clause, so
it has no such parameter.

### `replaySafe` (`ZorphyIntent` only, `bool`, required)

Whether replaying the intent is safe. No default by design.

### `@ZorphyMock` (field annotation, not a toggle)

A seed hint for generated mock data — never changes what is generated.

```dart
@ZorphyMock(preset: 'email')
String get email;
```

### Legacy options (deprecated)

The pre-v3 `@Zorphy()` options below — `generateJson`, `generateCompareTo`,
`generateCopyWithFn`, `explicitSubTypes` on `@Zorphy`, `defaultFieldValue` —
still work through the compatibility surface, because the current generator
reads `@Zorphy`. They are removed with it (#177, #178, #181, #187).

final product = Product(id: '1', name: 'Laptop', price: 999.99);
final json = product.toJson();
final restored = Product.fromJson(json);
```

### `generateCompareTo` (bool, default: false)

Generate comparison methods that return a map of differences between two instances.

```dart
@Zorphy(generateCompareTo: true)
abstract class $Document {
  String get title;
  String get content;
  int get version;
}

final doc1 = Document(title: 'A', content: 'X', version: 1);
final doc2 = Document(title: 'A', content: 'Y', version: 2);
final diff = doc1.compareToDocument(doc2);
print(diff); // {content: Y, version: 2}
```

### `generateCopyWithFn` (bool, default: false)

Generate function-based copyWith that accepts closures for computed values.

```dart
@Zorphy(generateCopyWithFn: true)
abstract class $Counter {
  int get value;
  String get label;
}

final counter = Counter(value: 0, label: 'Count');
final incremented = counter.copyWithFn(
  value: (current) => current + 1,
);
print(incremented.value); // 1
```

### `explicitSubTypes` (List<Type>, default: null)

Specify explicit subtypes for sealed class hierarchies. Used for polymorphic serialization.

```dart
@Zorphy(explicitSubTypes: [$CreditCard, $PayPal])
abstract class $$PaymentMethod {
  String get displayName;
}

@Zorphy(generateJson: true)
abstract class $CreditCard implements $$PaymentMethod {
  String get cardNumber;
  String get expiryDate;
}

@Zorphy(generateJson: true)
abstract class $PayPal implements $$PaymentMethod {
  String get email;
}
```

### `defaultFieldValue` (String?, default: null)

Specify default values for fields.

```dart
@Zorphy()
abstract class $Config {
  String get apiKey;
  
  @ZorphyField(default: 'anonymous')
  String get username;
}
```

## 🎨 Advanced Features

### Sealed Classes & Polymorphism

Create type-safe hierarchies with exhaustiveness checking:

```dart
// Sealed base class (use double $$ for sealed)
@Zorphy(explicitSubTypes: [$Circle, $Rectangle])
abstract class $$Shape {
  double get area;
}

// Implementations
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

### Multiple Inheritance

Combine multiple abstract class definitions:

```dart
@Zorphy()
abstract class $Timestamped {
  DateTime get createdAt;
  DateTime? get updatedAt;
}

@Zorphy()
abstract class $Identified {
  String get id;
}

// Combine both interfaces
@Zorphy()
abstract class $Post implements $Timestamped, $Identified {
  String get title;
  String get content;
}
```

### Self-Referencing Types

Build tree structures and recursive models:

```dart
@Zorphy(generateJson: true)
abstract class $CategoryNode {
  String get id;
  String get name;
  List<$CategoryNode>? get children;
  $CategoryNode? get parent;
}

final root = CategoryNode(
  id: '1',
  name: 'Technology',
  children: [
    CategoryNode(id: '2', name: 'Dart', children: []),
    CategoryNode(id: '3', name: 'Flutter', children: []),
  ],
);
```

### Generic Classes

Full support for generic type parameters:

```dart
@Zorphy()
abstract class $Result<T> {
  bool get success;
  T? get data;
  String? get errorMessage;
}

final success = Result<int>(success: true, data: 42, errorMessage: null);
final error = Result<String>(success: false, data: null, errorMessage: 'Failed');
```

### Nested Patching

Update deeply nested structures easily:

```dart
@Zorphy()
abstract class $Address {
  String get street;
  String get city;
}

@Zorphy()
abstract class $Person {
  String get name;
  $Address get address;
}

final person = Person(
  name: 'John',
  address: Address(street: '123 Main St', city: 'NYC'),
);

// Patch nested objects
final updated = person.patchWithPerson(
  patchInput: PersonPatch.create()
    ..withAddressPatch(
      AddressPatch.create()..withCity('LA'),
    ),
);
print(updated.address.city); // LA
```

### Enum Support

First-class support for enum fields with JSON serialization:

```dart
enum Status { active, inactive, pending }

@Zorphy(generateJson: true)
abstract class $Account {
  String get username;
  Status get status;
}

final account = Account(username: 'alice', status: Status.active);
final json = account.toJson();
// {'username': 'alice', 'status': 'active'}
```

### Lean JSON

Exclude metadata fields from JSON serialization:

```dart
@Zorphy(generateJson: true)
abstract class $Entity {
  String get id;
  DateTime get createdAt;
  String get data;
}

final entity = Entity(
  id: '1',
  createdAt: DateTime.now(),
  data: 'important',
);

// Full JSON with metadata
entity.toJson();

// Lean JSON without metadata (excludes createdAt)
entity.toJsonLean();
```

## 🏗️ Generated Code

For each `@Zorphy()` annotated class, Zorphy generates:

- **Concrete Class** - Immutable implementation with final fields
- **Constructor** - Typed constructor with required/optional parameters
- **CopyWith Method** - `copyWith()` for creating modified copies
- **CopyWithFn Method** - Function-based variant if `generateCopyWithFn: true`
- **Patch Class** - Partial update support with fluent API
- **PatchWith Method** - `patchWith[Class]()` for applying patches
- **Equality** - `operator ==` for value comparison
- **HashCode** - `hashCode` for map/set usage
- **ToString** - Readable string representation
- **CompareTo** - Comparison methods if `generateCompareTo: true`
- **JSON Methods** - `toJson()` and `fromJson()` if `generateJson: true`
- **Lean JSON** - `toJsonLean()` if `generateJson: true`

## 📖 Naming Conventions

- **Abstract Class Prefix** - Use `$` prefix (e.g., `$User`)
- **Sealed Class Prefix** - Use `$$` prefix (e.g., `$$Shape`)
- **Part File** - `.zorphy.dart` extension
- **Generated Class** - Same name without `$` prefix (e.g., `User`)
- **Patch Class** - `ClassNamePatch` (e.g., `UserPatch`)

## 🔗 Related Packages

- [zorphy](https://pub.dev/packages/zorphy) - The code generator that uses these annotations

## 📄 License

MIT License - see [LICENSE](LICENSE) for details


## 📮 Support

For issues, questions, or suggestions, please visit:
- [GitHub Issues](https://github.com/arrrrny/zorphy/issues)
- [Pub.dev](https://pub.dev/packages/zorphy_annotation)

---

**Made with 🔥 by the ZikZak AI team for the community and AI agents**
