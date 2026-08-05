# Zorphy Quick Start Guide for AI Agents

This guide is specifically designed for AI agents (Claude, GPT, etc.) to quickly understand and use Zorphy effectively.

## 🎯 What is Zorphy?

Zorphy is a Dart/Flutter code generator that creates immutable data classes with:
- CopyWith methods
- JSON serialization
- Equality operators
- toString methods
- Patch system for updates
- Sealed class support
- Inheritance and polymorphism

> **Version:** ^2.0.0

## 🚀 Three Ways to Use Zorphy

### Method 1: Via MCP Server (Recommended for Agents)

The MCP server provides programmatic access to all Zorphy features.

**Available Tools (4 total):**

1. **`create_entity`** - Create a new entity class
```python
mcp.call_tool("create_entity", {
    "name": "User",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "name", "type": "String"},
        {"name": "email", "type": "String?"}
    ],
    "generateJson": True,
    "generateCompareTo": True
})
```

2. **`create_enum`** - Create an enum
```python
mcp.call_tool("create_enum", {
    "name": "Status",
    "values": ["active", "inactive", "pending"]
})
```

3. **`add_field`** - Add field(s) to an existing entity
```python
mcp.call_tool("add_field", {
    "name": "User",
    "fields": [
        {"name": "age", "type": "int"},
        {"name": "role", "type": "String?"}
    ]
})
```

4. **`list_entities`** - List all entities and enums
```python
mcp.call_tool("list_entities", {})
```

### Method 2: Via CLI Commands

Execute shell commands to create entities:

```bash
# Simple entity
zorphy create -n User

# With fields
zorphy create -n User \
  --field name:String \
  --field age:int \
  --field email:String?

# Sealed class
zorphy create -n Result --sealed

# Quick create (simple)
zorphy new -n Product

# Build all
zorphy build
```

### Method 3: Direct Code Generation

Write the code yourself:

```dart
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'user.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $User {
  String get id;
  String get name;
  String? get email;
}
```

Then run: `dart run build_runner build`

## 📝 Entity Creation Patterns

### Basic Entity
```python
{
    "name": "User",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "name", "type": "String"}
    ]
}
```

### With Nullable Fields
```python
{
    "name": "User",
    "fields": [
        {"name": "name", "type": "String"},
        {"name": "email", "type": "String?"}
    ]
}
```

### With Complex Types
```python
{
    "name": "Article",
    "fields": [
        {"name": "title", "type": "String"},
        {"name": "tags", "type": "List<String>"},
        {"name": "metadata", "type": "Map<String, dynamic>"},
        {"name": "createdAt", "type": "DateTime"}
    ]
}
```

### With Inheritance
```python
{
    "name": "Admin",
    "extends": "$User",
    "fields": [
        {"name": "permissions", "type": "List<String>"}
    ]
}
```

### With All Options
```python
{
    "name": "User",
    "outputDir": "lib/src/domain/entities",
    "package": "my_app",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "name", "type": "String"},
        {"name": "email", "type": "String?"}
    ],
    "generateJson": True,
    "generateCompareTo": True,
    "sealed": False,
    "nonSealed": False,
    "extends": null,
    "explicitSubTypes": []
}
```

### Sealed Class with Subtypes
```python
{
    "name": "Result",
    "sealed": True,
    "explicitSubTypes": ["Success", "Error", "Loading"],
    "fields": []
}
# Then create each subtype as a separate entity with extends
```

## 🔧 Common Workflows

### Workflow 1: Create and Use Entity

```python
# 1. Create entity
mcp.call_tool("create_entity", {
    "name": "User",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "name", "type": "String"}
    ],
    "generateJson": True
})

# 2. Build code
# dart run build_runner build

# 3. Use in code
# final user = User(id: "1", name: "Alice");
# final json = user.toJson();
```

### Workflow 2: Create Sealed Hierarchy

```python
# 1. Create sealed base
mcp.call_tool("create_entity", {
    "name": "Result",
    "sealed": True,
    "explicitSubTypes": ["Success", "Error", "Loading"],
    "fields": []
})

# 2. Create each subtype
mcp.call_tool("create_entity", {
    "name": "Success",
    "extends": "$Result",
    "fields": [{"name": "data", "type": "dynamic"}]
})

mcp.call_tool("create_entity", {
    "name": "Error",
    "extends": "$Result",
    "fields": [{"name": "message", "type": "String"}]
})

# 3. Build and use with exhaustiveness checking
# dart run build_runner build
```

### Workflow 3: Add Fields to Existing Entity

```python
# 1. Check existing entities
mcp.call_tool("list_entities", {})

# 2. Add fields
mcp.call_tool("add_field", {
    "name": "User",
    "fields": [
        {"name": "age", "type": "int?"},
        {"name": "avatarUrl", "type": "String?"}
    ]
})

# 3. Rebuild
# dart run build_runner build
```

## 📊 Field Type Reference

### Basic Types
- `String` - Text
- `int` - Integer numbers
- `double` - Floating point numbers
- `bool` - Boolean values
- `num` - Any number
- `DateTime` - Date and time

### Nullable Types
Add `?` to the type
- `String?`
- `int?`
- `DateTime?`

### Collection Types
- `List<Type>` - Ordered list
- `Set<Type>` - Unique items
- `Map<Key, Value>` - Key-value pairs

### Examples
```json
{
    "fields": [
        {"name": "name", "type": "String"},
        {"name": "age", "type": "int?"},
        {"name": "tags", "type": "List<String>"},
        {"name": "metadata", "type": "Map<String, dynamic>"},
        {"name": "scores", "type": "List<double>?"},
        {"name": "createdAt", "type": "DateTime"}
    ]
}
```

## 🎨 create_entity Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | **yes** | - | Entity name (PascalCase) |
| `fields` | array of {name, type} | no | `[]` | Field definitions |
| `outputDir` | string | no | `lib/src/domain/entities` | Output directory |
| `package` | string | no | - | Package name |
| `generateJson` | boolean | no | `true` | Enable toJson/fromJson |
| `generateCompareTo` | boolean | no | `true` | Compare methods |
| `sealed` | boolean | no | `false` | Create sealed class |
| `nonSealed` | boolean | no | `false` | Non-sealed abstract |
| `extends` | string | no | null | Interface to implement |
| `explicitSubTypes` | string[] | no | `[]` | Polymorphic subtypes |

## 🎨 create_enum Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | **yes** | - | Enum name (PascalCase) |
| `values` | string[] | **yes** | - | Enum values |

## 🎨 add_field Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | **yes** | - | Entity name to add fields to |
| `fields` | array of {name, type} | **yes** | - | Fields to add |

## 💡 Best Practices for Agents

### 1. Always Check First
```python
# Check if entity exists
entities = mcp.call_tool("list_entities", {})
```

### 2. Use Proper Types
```python
# Good - nullable indicated by ? in type
{"type": "String?"}

# Bad - don't use separate nullable flag
{"type": "String", "nullable": True}
```

### 3. Use Enums for Fixed Value Sets
```python
# Create an enum first
mcp.call_tool("create_enum", {
    "name": "UserRole",
    "values": ["admin", "editor", "viewer"]
})

# Then reference it in an entity
mcp.call_tool("create_entity", {
    "name": "User",
    "fields": [
        {"name": "role", "type": "UserRole"}
    ]
})
```

### 4. Use Sealed Hierarchies for State
```python
# State machines - create base then subtypes
mcp.call_tool("create_entity", {
    "name": "UiState",
    "sealed": True,
    "explicitSubTypes": ["Loading", "Success", "Error"],
    "fields": []
})
# Then create each subtype with extends: "$UiState"
```

## 🐛 Common Mistakes to Avoid

### 1. Incorrect Nullable Syntax
```python
# Wrong - separate nullable flag (v1 style)
{"name": "email", "type": "String", "nullable": true}

# Right - use ? suffix in type (v2 style)
{"name": "email", "type": "String?"}
```

### 2. Missing $ Prefix in Manual Code
```python
# Wrong
@Zorphy()
abstract class User {  # Missing $
    String get name;
}

# Right
@Zorphy()
abstract class $User {  # Has $
    String get name;
}
```

### 3. Forgetting Part Directive
```dart
// Always include this
part 'user.zorphy.dart';
```

### 4. Using Nested Options (v1 style)
```python
# Wrong (v1 - nested options)
{
    "name": "User",
    "fields": [...],
    "options": {"generateJson": True}
}

# Right (v2 - flat params)
{
    "name": "User",
    "fields": [...],
    "generateJson": True
}
```

## 📚 Quick Reference

### Create Simple Entity
```bash
zorphy create -n EntityName
```

### Create with Fields (MCP)
```python
mcp.call_tool("create_entity", {
    "name": "Entity",
    "fields": [
        {"name": "field1", "type": "String"},
        {"name": "field2", "type": "int?"}
    ]
})
```

### Create Enum (MCP)
```python
mcp.call_tool("create_enum", {
    "name": "Status",
    "values": ["active", "inactive"]
})
```

### Add Field (MCP)
```python
mcp.call_tool("add_field", {
    "name": "User",
    "fields": [{"name": "age", "type": "int?"}]
})
```

### Build All
```bash
zorphy build
# or: dart run build_runner build
```

### List Entities
```bash
zorphy list
# or (MCP):
mcp.call_tool("list_entities", {})
```

## 🎯 Decision Tree

**Need a simple data class?**
→ Use `create_entity` with basic types

**Need a state machine / union type?**
→ Use `create_entity` with `sealed: true` and `explicitSubTypes`, then create each subtype with `extends`

**Need a fixed set of values?**
→ Use `create_enum`

**Need inheritance?**
→ Use `create_entity` with `extends` parameter

**Need JSON support?**
→ Set `generateJson: true`

**Need to add a field later?**
→ Use `add_field` on the existing entity

**Need immutable updates?**
→ Zorphy generates copyWith automatically

**Need partial updates?**
→ Use the generated Patch classes

## ✅ Agent Checklist

Before creating an entity:
- [ ] Name is in PascalCase
- [ ] Fields have correct types
- [ ] Nullable fields have `?` suffix
- [ ] Parameters are flat (no nested `options`)

After creating:
- [ ] Run `dart run build_runner build`
- [ ] Verify generated code
- [ ] Test instantiation

## 🚀 Ready to Go!

You now have everything you need to:
1. Create entities and enums programmatically
2. Add fields to existing entities
3. Build and use them
4. Handle sealed hierarchies and inheritance
5. Avoid common pitfalls

**Start creating entities now!**

---

For more details, see the main README.md or comprehensive_example.dart
