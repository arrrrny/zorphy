# Zorphy

**Zorphy** is a powerful code generation package for Dart/Flutter that provides clean, immutable class definitions with advanced features including copyWith methods, JSON serialization, equality, toString, inheritance support, and sophisticated patch mechanisms.

## ✨ Features

- 📋 **Immutable Data Classes** - Clean, immutable class definitions with minimal boilerplate
- 🔄 **CopyWith Methods** - Generate `copyWith` methods for creating modified copies
- 🎯 **Function-based CopyWith** - Optional function-based copyWith for computed updates
- 🔧 **Patch System** - Advanced patching mechanism for partial updates with nested support
- 📦 **JSON Serialization** - Full `toJson`/`fromJson` support with polymorphic type handling
- ⚖️ **Equality** - Auto-generated `==` operator and `hashCode`
- 📝 **toString** - Meaningful string representations for debugging
- 🔐 **Sealed Classes** - Support for sealed classes with exhaustiveness checking
- 🌳 **Self-Referencing Types** - Handle tree structures and hierarchical data
- 🏭 **Factory Methods** - Support for custom factory constructors
- 🧬 **Inheritance & Polymorphism** - Multiple inheritance, generics, and interfaces
- 🔢 **Enum Support** - Full enum integration with JSON serialization
- 📊 **CompareTo** - Generate comparison methods showing differences between instances
- 🔄 **ChangeTo** - Convert between related types in inheritance hierarchies
- 🤖 **AI-Friendly CLI** - Command-line tool optimized for AI agents and developers
- 🔌 **MCP Server** - Model Context Protocol server for agentic integration

## 📦 Installation

Add the dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  zorphy_annotation: ^1.1.1

dev_dependencies:
  zorphy: ^1.1.1
  build_runner: ^2.4.0
```

Install the CLI globally:

```bash
dart pub global activate zorphy
```

## 🚀 Quick Start

### Using the CLI (Recommended for AI Agents)

The Zorphy CLI is designed for optimal AI agent usage:

```bash
# Interactive entity creation
zorphy create -n User

# Create with fields
zorphy create -n Product \
  --field name:String \
  --field price:double \
  --field inStock:bool

# Quick create (simple entity with defaults)
zorphy new -n Category

# Build all entities
zorphy build

# List entities
zorphy list
```

### Manual Class Definition

Or create classes manually:

```dart
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'user.zorphy.dart';

@Zorphy()
abstract class $User {
  String get name;
  int get age;
  String? get email;
}
```

Run the generator:

```bash
dart run build_runner build
```

Use the generated class:

```dart
void main() {
  final user = User(name: 'Alice', age: 30);
  
  // Copy with changes
  final olderUser = user.copyWith(age: 31);
  
  // Convert to JSON (if generateJson: true)
  final json = user.toJson();
  
  // Create from JSON
  final fromJson = User.fromJson(json);
}
```

## 🤖 Zorphy CLI

The Zorphy CLI provides an intuitive interface for creating and managing entities, optimized for both human developers and AI agents.

### Installation

```bash
# Install globally
dart pub global activate zorphy

# Or run directly
dart run zorphy:zorphy_cli
```

### CLI Commands

#### `create` - Create New Entity

Create a new Zorphy entity with full control over options:

```bash
zorphy create [options]
```

**Options:**
- `-n, --name` - Entity name (required)
- `-o, --output` - Output directory (default: `lib/entities`)
- `-p, --package` - Package name for imports
- `--json` - Enable JSON serialization (default: true)
- `--copywith-fn` - Enable function-based copyWith (default: false)
- `--compare` - Enable compareTo (default: true)
- `--sealed` - Create sealed class (default: false)
- `--non-sealed` - Create non-sealed class (default: false)
- `-f, --fields` - Interactive field prompts (default: true)
- `--field` - Add fields directly (`name:type` or `name:type?`)
- `--extends` - Interface to extend (e.g., `$BaseEntity`)
- `--subtype` - Explicit subtypes for polymorphism

**Examples:**

```bash
# Interactive creation
zorphy create -n User

# With fields
zorphy create -n User \
  --field name:String \
  --field age:int \
  --field email:String?

# With all options
zorphy create -n Product \
  --output lib/models \
  --json \
  --compare \
  --field name:String \
  --field price:double \
  --field category:String?

# Sealed class
zorphy create -n Result --sealed

# With inheritance
zorphy create -n Admin \
  --extends '$User' \
  --field permissions:List<String>
```

#### `new` - Quick Create

Create a simple entity with default settings:

```bash
zorphy new -n EntityName
```

**Options:**
- `-n, --name` - Entity name (required)
- `-o, --output` - Output directory (default: `lib/entities`)
- `--json` - Enable JSON (default: true)

**Example:**
```bash
zorphy new -n Product
```

#### `build` - Run Code Generation

Generate code for all Zorphy entities:

```bash
zorphy build [options]
```

**Options:**
- `-w, --watch` - Watch for changes (default: false)
- `-c, --clean` - Clean before build (default: false)
- `-o, --output` - Build output directory

**Examples:**
```bash
# Build once
zorphy build

# Clean and build
zorphy build --clean

# Watch mode
zorphy build --watch
```

#### `list` - List Entities

List all Zorphy entities in a directory:

```bash
zorphy list [options]
```

**Options:**
- `-o, --output` - Directory to search (default: `lib/entities`)

**Example:**
```bash
zorphy list
# Output:
# 📂 Zorphy Entities in lib/entities:
# 
# 📄 User
#    File: lib/entities/user.dart
#    ✓ JSON support
#    ✓ Function-based copyWith
# 
# Total: 1 entity/entities
```

### Field Types

The CLI supports various field types:

- **Basic types:** `String`, `int`, `double`, `bool`, `num`, `DateTime`
- **Nullable types:** Add `?` after type (e.g., `String?`, `int?`)
- **Generic types:** `List<Type>`, `Set<Type>`, `Map<KeyType, ValueType>`
- **Custom types:** Any other class name

**Examples:**
```bash
--field name:String
--field age:int
--field email:String?
--field tags:List<String>
--field metadata:Map<String, dynamic>
--field createdAt:DateTime
```

### Interactive Mode

When using `create` with `--fields` (default), the CLI prompts for fields:

```bash
$ zorphy create -n User

📝 Creating Zorphy Entity: User
Enter fields one by one. Press Enter without input to finish.

Field name (or press Enter to finish): name
Field type (e.g., String, int, List<String>): String
✓ Added field: name (String)

Field name (or press Enter to finish): age
Field type (e.g., String, int, List<String>): int
✓ Added field: age (int)

Field name (or press Enter to finish): 

✓ Created entity file: lib/entities/user.dart

📋 Next steps:
  1. Run: zorphy build
  2. Or run: dart run build_runner build
  3. Import and use your User class

✨ Generated 2 fields:
  - name: String
  - age: int
```

## 🔌 Zorphy MCP Server

The Model Context Protocol (MCP) server enables AI agents like Claude to programmatically create and manage Zorphy entities.

### Setting up the MCP Server

Add to your Claude/MCP client configuration:

```json
{
  "mcpServers": {
    "zorphy": {
      "command": "dart",
      "args": ["run", "zorphy:zorphy_mcp_server"]
    }
  }
}
```

### Available MCP Tools

#### `create_entity`

Create a new Zorphy entity programmatically.

**Parameters:**
```json
{
  "name": "string (required)",
  "output_dir": "string (default: lib/entities)",
  "fields": [
    {
      "name": "string",
      "type": "string",
      "nullable": "boolean (default: false)"
    }
  ],
  "options": {
    "generateJson": "boolean (default: true)",
    "generateCopyWithFn": "boolean (default: false)",
    "generateCompareTo": "boolean (default: true)",
    "sealed": "boolean (default: false)",
    "nonSealed": "boolean (default: false)"
  },
  "extends": "string (optional)",
  "explicit_subtypes": ["string"]
}
```

**Example:**
```json
{
  "name": "User",
  "fields": [
    {"name": "id", "type": "String"},
    {"name": "name", "type": "String"},
    {"name": "email", "type": "String?", "nullable": true},
    {"name": "age", "type": "int"}
  ],
  "options": {
    "generateJson": true,
    "generateCompareTo": true
  }
}
```

#### `list_entities`

List all Zorphy entities in a directory.

**Parameters:**
```json
{
  "directory": "string (default: lib/entities)"
}
```

#### `generate_entity_code`

Generate entity code without writing to file (preview mode).

**Parameters:** Same as `create_entity`

**Use case:** Preview generated code before creating the file.

#### `build_entities`

Run build_runner to generate Zorphy code.

**Parameters:**
```json
{
  "clean": "boolean (default: false)",
  "watch": "boolean (default: false)"
}
```

#### `analyze_entity`

Analyze an existing entity file and return its structure.

**Parameters:**
```json
{
  "file_path": "string (required)"
}
```

**Returns:**
```json
{
  "name": "User",
  "path": "lib/entities/user.dart",
  "hasJson": true,
  "hasCopyWithFn": false,
  "isSealed": false,
  "fields": ["id: String", "name: String", "email: String?", "age: int"],
  "extends": null
}
```

#### `create_sealed_hierarchy`

Create a sealed class hierarchy with multiple variants.

**Parameters:**
```json
{
  "base_name": "string (required)",
  "variants": [
    {
      "name": "string",
      "fields": [
        {"name": "string", "type": "string", "nullable": "boolean"}
      ]
    }
  ],
  "output_dir": "string (default: lib/entities)",
  "generate_json": "boolean (default: true)"
}
```

**Example - Creating a Result type:**
```json
{
  "base_name": "Result",
  "variants": [
    {
      "name": "Success",
      "fields": [
        {"name": "data", "type": "dynamic"}
      ]
    },
    {
      "name": "Error",
      "fields": [
        {"name": "message", "type": "String"},
        {"name": "code", "type": "int"}
      ]
    }
  ]
}
```

This creates:
- `$$Result` - Sealed base class
- `$Success` - Success variant
- `$Error` - Error variant

### Agentic Usage Examples

**Example 1: Agent Creating a User Entity**

```python
# Agent using MCP server
mcp.call_tool("create_entity", {
    "name": "User",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "username", "type": "String"},
        {"name": "email", "type": "String?", "nullable": true},
        {"name": "createdAt", "type": "DateTime"}
    ],
    "options": {
        "generateJson": True,
        "generateCompareTo": True
    }
})
```

**Example 2: Agent Creating a Payment Hierarchy**

```python
mcp.call_tool("create_sealed_hierarchy", {
    "base_name": "PaymentMethod",
    "variants": [
        {
            "name": "CreditCard",
            "fields": [
                {"name": "cardNumber", "type": "String"},
                {"name": "expiryDate", "type": "String"}
            ]
        },
        {
            "name": "PayPal",
            "fields": [
                {"name": "email", "type": "String"}
            ]
        }
    ]
})
```

**Example 3: Agent Analyzing and Extending**

```python
# Analyze existing entity
analysis = mcp.call_tool("analyze_entity", {
    "file_path": "lib/entities/user.dart"
})

# Extend with new field
mcp.call_tool("create_entity", {
    "name": "Admin",
    "extends": "$User",
    "fields": [
        {"name": "permissions", "type": "List<String>"}
    ]
})
```

## 📖 Complete Feature Guide

### 1. Class Definition Patterns

#### Concrete Classes (Single $)

Use a single `$` prefix for concrete classes:

```dart
@Zorphy()
abstract class $Person {
  String get firstName;
  String get lastName;
  int? get age;
}

// Usage: Omit the $ when using
final person = Person(firstName: 'John', lastName: 'Doe');
```

#### Sealed Abstract Classes (Double $$)

Use `$$` prefix for sealed abstract classes. Sealed classes enable exhaustiveness checking:

```dart
@Zorphy()
abstract class $$Shape {
  double get area;
}

@Zorphy()
abstract class $Circle implements $$Shape {
  double get radius;
  
  @override
  double get area => 3.14159 * radius * radius;
}

@Zorphy()
abstract class $Rectangle implements $$Shape {
  double get width;
  double get height;
  
  @override
  double get area => width * height;
}

// Exhaustiveness checking
String describeShape(Shape shape) => switch (shape) {
  Circle() => 'A circle',
  Rectangle() => 'A rectangle',
};
```

#### Non-Sealed Abstract Classes

Use `nonSealed: true` to create non-sealed abstract classes:

```dart
@Zorphy(nonSealed: true)
abstract class $$BaseEntity {
  String get id;
  DateTime get createdAt;
}
```

### 2. JSON Serialization

Enable JSON generation with `generateJson: true`:

```dart
@Zorphy(generateJson: true)
abstract class $User {
  String get id;
  String get name;
  String? get email;
}
```

**Features:**
- Automatic `toJson()` and `fromJson()`
- `toJsonLean()` removes metadata for cleaner output
- Handles nested objects and collections
- Supports polymorphic serialization with type discriminators

#### Polymorphic JSON

```dart
@Zorphy()
abstract class $$Animal {}

@Zorphy(generateJson: true)
abstract class $Dog implements $$Animal {
  String get breed;
}

@Zorphy(generateJson: true)
abstract class $Cat implements $$Animal {
  double get whiskerLength;
}

// Serialization includes type discriminator
final dog = Dog(breed: 'Labrador');
final json = dog.toJson();
// {"_className_": "Dog", "breed": "Labrador"}

// Deserialization automatically handles type
final animal = Animal.fromJson(json);
print(animal); // Instance of Dog
```

### 3. CopyWith Methods

#### Basic CopyWith

```dart
@Zorphy()
abstract class $User {
  String get name;
  int get age;
}

final user = User(name: 'Alice', age: 30);
final updated = user.copyWith(name: 'Bob');
// User(name: 'Bob', age: 30)
```

#### Function-based CopyWith

Enable with `generateCopyWithFn: true`:

```dart
@Zorphy(generateCopyWithFn: true)
abstract class $Counter {
  int get value;
}

final counter = Counter(value: 0);
final incremented = counter.copyWithCounterFn(
  value: () => counter.value + 1,
);
// Counter(value: 1)
```

#### Type-specific CopyWith

```dart
@Zorphy()
abstract class $Pet {
  String get name;
  int get age;
}

@Zorphy()
abstract class $Dog implements $Pet {
  String get breed;
}

final dog = Dog(name: 'Buddy', age: 5, breed: 'Labrador');
final updated = dog.copyWithDog(breed: 'Golden Retriever');
// Updates only Dog-specific fields
```

### 4. Patch System

The patch system provides powerful partial updates with nested support:

```dart
@Zorphy()
abstract class $User {
  String get name;
  int get age;
}

// Create a patch
final patch = UserPatch.create()
  ..withName('New Name')
  ..withAge(25);

// Apply patch
final updated = user.patchWithUser(patchInput: patch);
```

#### Nested Patches

```dart
@Zorphy()
abstract class $Address {
  String get street;
  String get city;
}

@Zorphy()
abstract class $User {
  String get name;
  Address get address;
}

// Nested patching
final patch = UserPatch.create()
  ..withName('Updated Name')
  ..withAddressPatch((addrPatch) => addrPatch
    ..withStreet('123 New St')
    ..withCity('New York'));

final updated = user.patchWithUser(patchInput: patch);
```

#### Collection Patching

```dart
@Zorphy()
abstract class $TodoList {
  String get title;
  List<Todo> get todos;
}

// Update specific item in list
final patch = TodoListPatch.create()
  ..updateTodosAt(0, (todoPatch) => todoPatch
    ..withCompleted(true)
    ..withTitle('Updated Title'));
```

#### Functional Patches

```dart
// Using functions for computed updates
final patch = CounterPatch.create()
  ..withValue((current) => current + 1);

final updated = counter.patchWithCounter(patchInput: patch);
```

### 5. Inheritance & Polymorphism

#### Multiple Inheritance

```dart
@Zorphy()
abstract class $Pet {
  String get name;
  int get age;
}

@Zorphy()
abstract class $Dog {
  String get barkSound;
}

@Zorphy()
abstract class $Cat {
  double get whiskerLength;
}

// Implement multiple interfaces
@Zorphy()
abstract class $FrankensteinsDogCat implements $Dog, $Pet, $Cat {
  // Inherits all fields from all interfaces
}
```

#### Generic Inheritance

```dart
@Zorphy()
abstract class $$Repository<T> {
  T? find(String id);
  List<T> getAll();
}

@Zorphy()
abstract class $UserRepository implements $$Repository<User> {
  @override
  User? find(String id);
  
  @override
  List<User> getAll();
}
```

#### Generic Classes with Type Constraints

```dart
@Zorphy()
abstract class $$Base<T> {
  T get value;
}

@Zorphy()
abstract class $Derived<T extends num> implements $$Base<T> {
  @override
  T get value;
  
  T get doubled => value * 2;
}
```

### 6. Explicit Subtypes & ChangeTo

Use `explicitSubTypes` to enable cross-type operations:

```dart
@Zorphy(explicitSubTypes: [$Dog, $Cat])
abstract class $Pet {
  String get name;
  int get age;
}

@Zorphy()
abstract class $Dog implements $Pet {
  String get breed;
}

@Zorphy()
abstract class $Cat implements $Pet {
  double get whiskerLength;
}
```

This generates `changeTo` methods:

```dart
final dog = Dog(name: 'Buddy', age: 5, breed: 'Labrador');

// Convert Dog to Cat
final cat = dog.changeToCat(whiskerLength: 3.5);
// Cat(name: 'Buddy', age: 5, whiskerLength: 3.5)
```

### 7. CompareTo Feature

Generate comparison methods showing differences between instances:

```dart
@Zorphy(generateCompareTo: true)
abstract class $User {
  String get name;
  int get age;
}

final user1 = User(name: 'Alice', age: 30);
final user2 = User(name: 'Alice', age: 35);

final diff = user1.compareToUser(user2);
// {'age': () => 35}
```

### 8. Enum Support

Full enum integration with JSON serialization:

```dart
enum Status {
  active,
  inactive,
  pending,
}

@Zorphy(generateJson: true)
abstract class $User {
  String get name;
  Status get status;
}

final user = User(name: 'Alice', status: Status.active);
final json = user.toJson();
// {"name": "Alice", "status": "active"}

final fromJson = User.fromJson(json);
// User(name: 'Alice', status: Status.active)
```

### 9. Self-Referencing Classes

Handle tree structures and hierarchical data:

```dart
@Zorphy(generateJson: true)
abstract class $TreeNode {
  String get value;
  List<TreeNode>? get children;
  TreeNode? get parent;
}

final tree = TreeNode(
  value: 'root',
  children: [
    TreeNode(value: 'child1'),
    TreeNode(value: 'child2'),
  ],
);
```

### 10. Factory Methods

Support for custom factory constructors:

```dart
@Zorphy()
abstract class $Person {
  String get firstName;
  String get lastName;
  
  // Custom factory method
  factory $Person.fromNames(String first, String last) = _PersonFromNames;
  
  // Default factory
  factory $Person.empty() => Person(firstName: '', lastName: '');
}

class _PersonFromNames extends Person {
  _PersonFromNames({
    required String first,
    required String last,
  }) : super(
    firstName: first.toUpperCase(),
    lastName: last.toUpperCase(),
  );
}

// Usage
final person = Person.fromNames('john', 'doe');
// Person(firstName: 'JOHN', lastName: 'DOE')
```

### 11. Private Constructors

Use underscore suffix to hide public constructor:

```dart
@Zorphy(hidePublicConstructor: true)
abstract class $Config_ {
  String get apiKey;
  String get endpoint;
}

// Define custom factory in the same file
Config createProductionConfig() {
  return Config._(
    apiKey: 'prod-key',
    endpoint: 'https://api.prod.com',
  );
}

Config createDevConfig() {
  return Config._(
    apiKey: 'dev-key',
    endpoint: 'https://api.dev.com',
  );
}

// Usage - Config() constructor is not available
final config = createProductionConfig();
```

### 12. Constant Constructors

Enable constant constructors for immutable values:

```dart
@Zorphy()
abstract class $Color {
  int get red;
  int get green;
  int get blue;
  
  const $Color();
}

// Usage
const red = Color(red: 255, green: 0, blue: 0);
```

### 13. Nullable Fields

Full null safety support:

```dart
@Zorphy()
abstract class $User {
  String get name;
  String? get email;
  String? get phone;
}

final user = User(name: 'Alice');
// email and phone are null

final withEmail = user.copyWith(email: 'alice@example.com');
```

### 14. Complex Nested Structures

```dart
@Zorphy()
abstract class $Company {
  String get name;
  List<Department> get departments;
}

@Zorphy()
abstract class $Department {
  String get name;
  List<Employee> get employees;
}

@Zorphy()
abstract class $Employee {
  String get name;
  String? get title;
}

// Deep nesting with proper JSON support
final company = Company(
  name: 'Tech Corp',
  departments: [
    Department(
      name: 'Engineering',
      employees: [
        Employee(name: 'Alice', title: 'Engineer'),
      ],
    ),
  ],
);
```

### 15. Generic Fields and Methods

```dart
typedef JsonConverter<T> = T Function(dynamic);

@Zorphy()
abstract class $ApiResponse<T> {
  bool get success;
  T? get data;
  String? get error;
}

@Zorphy()
abstract class $UserListResponse implements $ApiResponse<List<User>> {
  @override
  bool get success;
  
  @override
  List<User>? get data;
  
  @override
  String? get error;
}
```

### 16. Combining Multiple Features

```dart
enum UserRole {
  admin,
  user,
  guest,
}

@Zorphy(
  generateJson: true,
  generateCopyWithFn: true,
  generateCompareTo: true,
)
abstract class $User {
  String get id;
  String get name;
  String? get email;
  int get age;
  UserRole get role;
  DateTime get createdAt;
  List<String>? get tags;
}

// All features available
final user = User(
  id: '1',
  name: 'Alice',
  age: 30,
  role: UserRole.admin,
  createdAt: DateTime.now(),
);

// CopyWith
final updated = user.copyWith(email: 'alice@example.com');

// Function-based CopyWith
final aged = user.copyWithUserFn(age: () => user.age + 1);

// Patch
final patched = user.patchWithUser(
  patchInput: UserPatch.create()..withTags(['developer', 'dart']),
);

// CompareTo
final diff = user.compareToUser(updated);

// JSON
final json = user.toJson();
final fromJson = User.fromJson(json);
```

## 🎨 Annotation Options

The `@Zorphy` annotation supports these options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `generateJson` | `bool` | `false` | Enable JSON serialization (`toJson`/`fromJson`) |
| `generateCopyWithFn` | `bool` | `false` | Generate function-based copyWith methods |
| `generateCompareTo` | `bool` | `true` | Generate comparison methods |
| `explicitSubTypes` | `List<Type>` | `null` | Specify explicit subtypes for polymorphic operations |
| `explicitToJson` | `bool` | `true` | Control JSON serialization generation |
| `hidePublicConstructor` | `bool` | `false` | Hide the public constructor for custom factories |
| `nonSealed` | `bool` | `false` | Create non-sealed abstract classes instead of sealed |

## 🏗️ Build Configuration

By default, Zorphy runs as part of the build process. The builder is configured in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      zorphy:zorphy:
        enabled: true
```

Run the generator:

```bash
# Build once
dart run build_runner build

# Build and watch for changes
dart run build_runner watch

# Clean generated files
dart run build_runner clean

# Or use the CLI
zorphy build
zorphy build --watch
zorphy build --clean
```

## 📝 Naming Conventions

### Class Prefixes

- **`$ClassName`** - Concrete class definition (use `ClassName` in code)
- **`$$ClassName`** - Sealed abstract class (exhaustiveness checking)
- **`$ClassName_`** - Class with hidden private constructor

### Generated Files

- **`*.zorphy.dart`** - Generated code from `@Zorphy` annotation
- **`*.zorphy2.dart`** - Generated code from `@Zorphy2` annotation (builds before zorphy)

### Generated Enums

- **`ClassName$`** - Enum of field names for patch system

### Generated Patch Classes

- **`ClassNamePatch`** - Patch class for partial updates

## 🔄 Migration from Morphy

Zorphy is designed for easy migration from Morphy:

1. Replace `@Morphy` with `@Zorphy`
2. Replace `morphy_annotation` dependency with `zorphy_annotation`
3. Replace `zikzak_morphy` dependency with `zorphy`
4. Run `dart run build_runner clean`
5. Run `dart run build_runner build`

**Key Differences:**
- Better patch system with nested support
- Enhanced generic handling
- Improved error messages
- More flexible inheritance patterns
- Built-in CLI and MCP server for AI agents

## 🐛 Troubleshooting

### Type Not Found Errors

If you get type not found errors, ensure:
1. You've added `part 'filename.zorphy.dart';` to your file
2. You've run `dart run build_runner build` or `zorphy build`
3. The import includes `package:zorphy_annotation/zorphy_annotation.dart`

### Generic Type Issues

When using generics, ensure type parameter names match between parent and child:

```dart
// ✅ Correct - Same generic name
abstract class $A<T> { }
abstract class $B<T> implements $A<T> { }

// ❌ Wrong - Different generic names
abstract class $A<T1> { }
abstract class $B<T2> implements $A<T1> { }
```

### Circular Dependencies

Use `@Zorphy2` for classes that need to be built before others:

```dart
@Zorphy2()
abstract class $Base {
  String get id;
}

@Zorphy()
abstract class $Derived implements $Base {
  String get extra;
}
```

##  License

MIT License - see LICENSE file for details

##  Acknowledgments

Inspired by and designed to improve upon the Morphy code generation package.

---

**Made with 🔥 by the ZikZak AI team for the community and AI agents**
