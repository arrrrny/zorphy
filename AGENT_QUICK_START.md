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

## 🚀 Three Ways to Use Zorphy

### Method 1: Via MCP Server (Recommended for Agents)

The MCP server provides programmatic access to all Zorphy features.

**Available Tools:**

1. **`create_entity`** - Create a new entity class
```python
mcp.call_tool("create_entity", {
    "name": "User",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "name", "type": "String"},
        {"name": "email", "type": "String?", "nullable": true}
    ],
    "options": {
        "generateJson": True,
        "generateCompareTo": True
    }
})
```

2. **`create_sealed_hierarchy`** - Create sealed class with variants
```python
mcp.call_tool("create_sealed_hierarchy", {
    "base_name": "Result",
    "variants": [
        {
            "name": "Success",
            "fields": [{"name": "data", "type": "dynamic"}]
        },
        {
            "name": "Error",
            "fields": [{"name": "message", "type": "String"}]
        }
    ]
})
```

3. **`list_entities`** - List all entities
4. **`analyze_entity`** - Get entity structure
5. **`generate_entity_code`** - Preview code without writing
6. **`build_entities`** - Run code generation

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
        {"name": "email", "type": "String?", "nullable": True}
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
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "name", "type": "String"},
        {"name": "email", "type": "String?", "nullable": True}
    ],
    "options": {
        "generateJson": True,
        "generateCopyWithFn": False,
        "generateCompareTo": True,
        "sealed": False,
        "nonSealed": False
    }
}
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
    "options": {"generateJson": True}
})

# 2. Build code
mcp.call_tool("build_entities", {})

# 3. Use in code
# final user = User(id: "1", name: "Alice");
# final json = user.toJson();
```

### Workflow 2: Analyze Existing Entity

```python
# Analyze
analysis = mcp.call_tool("analyze_entity", {
    "file_path": "lib/entities/user.dart"
})

# Returns structure, fields, options
```

### Workflow 3: Create Sealed Hierarchy

```python
# Create Result type
mcp.call_tool("create_sealed_hierarchy", {
    "base_name": "Result",
    "variants": [
        {"name": "Success", "fields": [{"name": "data", "type": "dynamic"}]},
        {"name": "Error", "fields": [{"name": "message", "type": "String"}]},
        {"name": "Loading", "fields": []}
    ]
})

# Build and use with exhaustiveness checking
```

### Workflow 4: Preview Before Creating

```python
# Preview code
code = mcp.call_tool("generate_entity_code", {
    "name": "User",
    "fields": [{"name": "id", "type": "String"}]
})

# Review the generated code
# Then create if satisfied
mcp.call_tool("create_entity", {...})
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
Add `?` and set `"nullable": true`
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

## 🎨 Annotation Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `generateJson` | boolean | false | Enable toJson/fromJson |
| `generateCopyWithFn` | boolean | false | Function-based copyWith |
| `generateCompareTo` | boolean | true | Compare methods |
| `sealed` | boolean | false | Create sealed class |
| `nonSealed` | boolean | false | Non-sealed abstract |
| `extends` | string | null | Interface to implement |
| `explicit_subtypes` | string[] | null | Polymorphic subtypes |

## 💡 Best Practices for Agents

### 1. Always Check First
```python
# Check if entity exists
entities = mcp.call_tool("list_entities", {})
```

### 2. Preview Before Creating
```python
# Preview code
code = mcp.call_tool("generate_entity_code", {...})
# Review before actual creation
```

### 3. Use Proper Types
```python
# Good
{"type": "String"}

# Bad (missing ? for nullable)
{"type": "String?", "nullable": False}
```

### 4. Build After Creation
```python
# Always build after creating entities
mcp.call_tool("create_entity", {...})
mcp.call_tool("build_entities", {})
```

### 5. Use Sealed Hierarchies for State
```python
# State machines
mcp.call_tool("create_sealed_hierarchy", {
    "base_name": "UiState",
    "variants": [
        {"name": "Loading", "fields": []},
        {"name": "Success", "fields": [{"name": "data", "type": "dynamic"}]},
        {"name": "Error", "fields": [{"name": "message", "type": "String"}]}
    ]
})
```

## 🐛 Common Mistakes to Avoid

### 1. Forgetting to Build
```python
# Wrong
mcp.call_tool("create_entity", {...})
# Trying to use the class immediately fails

# Right
mcp.call_tool("create_entity", {...})
mcp.call_tool("build_entities", {})
# Now the class is ready
```

### 2. Incorrect Nullable Syntax
```python
# Wrong
{"name": "email", "type": "String", "nullable": true}

# Right
{"name": "email", "type": "String?", "nullable": true}
```

### 3. Missing $ Prefix in Manual Code
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

### 4. Forgetting Part Directive
```dart
// Always include this
part 'user.zorphy.dart';
```

## 📚 Quick Reference

### Create Simple Entity
```bash
zorphy create -n EntityName
```

### Create with Fields
```python
mcp.call_tool("create_entity", {
    "name": "Entity",
    "fields": [
        {"name": "field1", "type": "String"},
        {"name": "field2", "type": "int?"}
    ]
})
```

### Build All
```bash
zorphy build
```

### List Entities
```bash
zorphy list
```

### Analyze Entity
```python
mcp.call_tool("analyze_entity", {
    "file_path": "lib/entities/entity.dart"
})
```

## 🎯 Decision Tree

**Need a simple data class?**
→ Use `create_entity` with basic types

**Need a state machine?**
→ Use `create_sealed_hierarchy`

**Need inheritance?**
→ Use `create_entity` with `extends` parameter

**Need JSON support?**
→ Set `generateJson: true` in options

**Need immutable updates?**
→ Zorphy generates copyWith automatically

**Need partial updates?**
→ Use the generated Patch classes

## ✅ Agent Checklist

Before creating an entity:
- [ ] Name is in PascalCase
- [ ] Fields have correct types
- [ ] Nullable fields have `?` suffix
- [ ] Required options are set
- [ ] Output directory exists

After creating:
- [ ] Run `build_entities`
- [ ] Verify generated code
- [ ] Test instantiation

## 🚀 Ready to Go!

You now have everything you need to:
1. Create entities programmatically
2. Build and use them
3. Handle complex scenarios
4. Avoid common pitfalls

**Start creating entities now!**

---

For more details, see the main README.md or comprehensive_example.dart
