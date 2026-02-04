# Using Nested Zorphy Objects with CLI & MCP

This guide shows how to create entities with **nested Zorphy objects** (like `$CreditCard`, `$User`, `$Address`) using the CLI and MCP server.

## ✅ What's Supported

Zorphy **fully supports** nested Zorphy objects in:
- ✅ Single fields: `$Address`, `$CreditCard?`
- ✅ Lists: `List<$OrderItem>`, `List<$PaymentMethod>`
- ✅ Maps: `Map<String, $Product>`, `Map<String, $User>`
- ✅ Polymorphic: `$$PaymentMethod` with concrete `$CreditCard`, `$PayPal`
- ✅ Deep nesting at any level

All nested objects automatically get `_className_` in JSON for proper deserialization!

## 🖥️ CLI Usage

### Basic Nested Object

```bash
# Create User with nested Address
zorphy create -n User \
  --field id:String \
  --field name:String \
  --field address:\$Address

# Create the Address entity
zorphy create -n Address \
  --field street:String \
  --field city:String \
  --field country:String
```

This generates:
```dart
@Zorphy(generateJson: true)
abstract class $User {
  String get id;
  String get name;
  $Address get address;  // Nested Zorphy object
}

@Zorphy(generateJson: true)
abstract class $Address {
  String get street;
  String get city;
  String get country;
}
```

### Nullable Nested Object

```bash
zorphy create -n User \
  --field id:String \
  --field name:String \
  --field address:\$Address?  # Nullable with ?
```

### List of Zorphy Objects

```bash
# Create Order with list of OrderItems
zorphy create -n Order \
  --field orderId:String \
  --field user:\$User \
  --field items:List<\$OrderItem>

# Create OrderItem
zorphy create -n OrderItem \
  --field productId:String \
  --field name:String \
  --field price:double
```

This generates:
```dart
@Zorphy(generateJson: true)
abstract class $Order {
  String get orderId;
  $User get user;
  List<$OrderItem> get items;  // List of Zorphy objects
}
```

### Map with Zorphy Object Values

```bash
zorphy create -n ProductCatalog \
  --field catalogId:String \
  --field products:Map<String,\$Product>

zorphy create -n Product \
  --field id:String \
  --field name:String \
  --field price:double
```

This generates:
```dart
@Zorphy(generateJson: true)
abstract class $ProductCatalog {
  String get catalogId;
  Map<String, $Product> get products;  // Map with Zorphy values
}
```

### Polymorphic Nested Objects

```bash
# Create sealed payment method base
zorphy create -n PaymentMethod --sealed

# Create concrete payment types
zorphy create -n CreditCard \
  --field cardNumber:String \
  --field expiryDate:String \
  --field cvv:String

zorphy create -n PayPal \
  --field email:String

# Create Transaction using polymorphic field
zorphy create -n Transaction \
  --field transactionId:String \
  --field paymentMethod:\$\$PaymentMethod \
  --field history:List<\$\$PaymentMethod> \
  --field availableMethods:Map<String,\$\$PaymentMethod>
```

**Important:** Use `$$` prefix for polymorphic base types in field definitions!

### Real-World E-commerce Example

```bash
# 1. Create base entities
zorphy create -n User \
  --field id:String \
  --field name:String \
  --field email:String? \
  --field address:\$Address?

zorphy create -n Address \
  --field street:String \
  --field city:String \
  --field state:String \
  --field zipCode:String \
  --field country:String

# 2. Create product entities
zorphy create -n Product \
  --field id:String \
  --field name:String \
  --field description:String? \
  --field price:double \
  --field inStock:bool

zorphy create -n ProductVariant \
  --field id:String \
  --field name:String \
  --field price:double \
  --field attributes:Map<String,String>

# 3. Create order entities
zorphy create -n Order \
  --field orderId:String \
  --field user:\$User \
  --field items:List<\$OrderItem> \
  --field status:\$\$OrderStatus \
  --field total:double \
  --field createdAt:DateTime \
  --field shippedAt:DateTime?

zorphy create -n OrderItem \
  --field productId:String \
  --field product:\$Product \
  --field quantity:int \
  --field unitPrice:double

# 4. Create payment entities
zorphy create -n OrderStatus --sealed

zorphy create -n StatusPending

zorphy create -n StatusProcessing

zorphy create -n StatusShipped

zorphy create -n StatusDelivered

zorphy create -n Payment \
  --field paymentId:String \
  --field amount:double \
  --field method:\$\$PaymentMethod \
  --field status:\$\$PaymentStatus \
  --field createdAt:DateTime

zorphy create -n PaymentStatus --sealed

zorphy create -n PaymentStatusPending

zorphy create -n PaymentStatusCompleted

zorphy create -n PaymentStatusFailed

# 5. Build everything
zorphy build
```

## 🤖 MCP Server Usage

### Single Nested Object

```python
mcp.call_tool("create_entity", {
    "name": "User",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "name", "type": "String"},
        {"name": "address", "type": "$Address"}  # Nested Zorphy object
    ],
    "options": {"generateJson": True}
})
```

### List of Zorphy Objects

```python
mcp.call_tool("create_entity", {
    "name": "Order",
    "fields": [
        {"name": "orderId", "type": "String"},
        {"name": "user", "type": "$User"},
        {"name": "items", "type": "List<$OrderItem>"}  # List of nested objects
    ],
    "options": {"generateJson": True}
})

mcp.call_tool("create_entity", {
    "name": "OrderItem",
    "fields": [
        {"name": "productId", "type": "String"},
        {"name": "name", "type": "String"},
        {"name": "price", "type": "double"}
    ],
    "options": {"generateJson": True}
})
```

### Map with Zorphy Values

```python
mcp.call_tool("create_entity", {
    "name": "ProductCatalog",
    "fields": [
        {"name": "catalogId", "type": "String"},
        {
            "name": "products",
            "type": "Map<String, $Product>"  # Map with Zorphy values
        }
    ],
    "options": {"generateJson": True}
})
```

### Polymorphic with Sealed Hierarchy

```python
# Create sealed payment method hierarchy
mcp.call_tool("create_sealed_hierarchy", {
    "base_name": "PaymentMethod",
    "variants": [
        {
            "name": "CreditCard",
            "fields": [
                {"name": "cardNumber", "type": "String"},
                {"name": "expiryDate", "type": "String"},
                {"name": "cvv", "type": "String"}
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

# Create transaction using polymorphic field
mcp.call_tool("create_entity", {
    "name": "Transaction",
    "fields": [
        {"name": "transactionId", "type": "String"},
        {"name": "paymentMethod", "type": "$$PaymentMethod"},  # Use $$ for sealed
        {"name": "history", "type": "List<$$PaymentMethod>"},  # List of polymorphic
        {
            "name": "availableMethods",
            "type": "Map<String, $$PaymentMethod>"  # Map of polymorphic
        }
    ],
    "options": {"generateJson": True}
})
```

### Complex Real-World Example

```python
# User management
mcp.call_tool("create_entity", {
    "name": "User",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "username", "type": "String"},
        {"name": "email", "type": "String?", "nullable": True},
        {"name": "profile", "type": "$UserProfile?"}
    ],
    "options": {"generateJson": True}
})

mcp.call_tool("create_entity", {
    "name": "UserProfile",
    "fields": [
        {"name": "displayName", "type": "String"},
        {"name": "bio", "type": "String?"},
        {"name": "avatarUrl", "type": "String?"},
        {"name": "preferences", "type": "Map<String, dynamic>"}
    ],
    "options": {"generateJson": True}
})

# Content management
mcp.call_tool("create_entity", {
    "name": "Article",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "title", "type": "String"},
        {"name": "content", "type": "String"},
        {"name": "author", "type": "$User"},
        {"name": "tags", "type": "List<String>"},
        {"name": "comments", "type": "List<$Comment>"}
    ],
    "options": {"generateJson": True}
})

mcp.call_tool("create_entity", {
    "name": "Comment",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "content", "type": "String"},
        {"name": "author", "type": "$User"},
        {"name": "createdAt", "type": "DateTime"}
    ],
    "options": {"generateJson": True}
})

# E-commerce
mcp.call_tool("create_entity", {
    "name": "ShoppingCart",
    "fields": [
        {"name": "cartId", "type": "String"},
        {"name": "user", "type": "$User?"},
        {"name": "items", "type": "List<$CartItem>"},
        {"name": "createdAt", "type": "DateTime"},
        {"name": "updatedAt", "type": "DateTime"}
    ],
    "options": {"generateJson": True}
})

mcp.call_tool("create_entity", {
    "name": "CartItem",
    "fields": [
        {"name": "productId", "type": "String"},
        {"name": "product", "type": "$Product"},
        {"name": "quantity", "type": "int"}
    ],
    "options": {"generateJson": True}
})

mcp.call_tool("create_entity", {
    "name": "Product",
    "fields": [
        {"name": "id", "type": "String"},
        {"name": "name", "type": "String"},
        {"name": "description", "type": "String?"},
        {"name": "price", "type": "double"},
        {"name": "variants", "type": "List<$ProductVariant>"},
        {"name": "attributes", "type": "Map<String, String>"}
    ],
    "options": {"generateJson": True}
})

# Build all
mcp.call_tool("build_entities", {})
```

## 📋 Type Syntax Reference

### CLI Field Syntax

| Pattern | Example | Description |
|---------|---------|-------------|
| Basic type | `name:String` | Simple field |
| Nullable | `email:String?` | Add `?` after type |
| Nested Zorphy | `address:\$Address` | Single nested object |
| Nullable nested | `address:\$Address?` | Nullable nested |
| List of Zorphy | `items:List<\$Item>` | List of nested objects |
| Map with Zorphy | `users:Map<String,\$User>` | Map with Zorphy values |
| Polymorphic | `payment:\$\$PaymentMethod` | Use `$$` for sealed base |

### MCP Field Type Syntax

```json
{
  "name": "fieldName",
  "type": "$TypeName"           // Single nested
}
```

```json
{
  "name": "fieldName",
  "type": "$TypeName?",
  "nullable": true
}
```

```json
{
  "name": "fieldName",
  "type": "List<$Item>"
}
```

```json
{
  "name": "fieldName",
  "type": "Map<String, $Product>"
}
```

```json
{
  "name": "fieldName",
  "type": "$$SealedType"  // Use $$ for sealed base types
}
```

## 🔑 Key Points

1. **Use `$` prefix** for concrete Zorphy types: `$Address`, `$User`, `$CreditCard`
2. **Use `$$` prefix** for sealed/polymorphic base types: `$$PaymentMethod`, `$$OrderStatus`
3. **Add `?`** for nullable: `$Address?`, `List<$Item?>`
4. **Works everywhere** - single fields, lists, maps, any nesting level
5. **Automatic JSON** - all nested objects get `_className_` discriminator

## 📊 Generated JSON Example

```dart
final order = Order(
  orderId: 'order1',
  user: User(id: 'user1', name: 'Alice', address: null),
  items: [
    OrderItem(productId: 'prod1', name: 'Laptop', price: 999.99),
  ],
);

final json = order.toJson();
// {
//   "orderId": "order1",
//   "user": {
//     "id": "user1",
//     "name": "Alice",
//     "address": null,
//     "_className_": "User"  // ← Type preserved!
//   },
//   "items": [
//     {
//       "productId": "prod1",
//       "name": "Laptop",
//       "price": 999.99,
//       "_className_": "OrderItem"  // ← Each item has type!
//     }
//   ],
//   "_className_": "Order"
// }
```

## ✅ Summary

- **CLI:** Use `--field name:\$Type` syntax
- **MCP:** Use `"type": "$Type"` in field definition
- **Prefixes:** `$` for concrete, `$$` for sealed/polymorphic
- **Collections:** `List<$Type>`, `Map<Key, $Type>`
- **Nullable:** Add `?` after type
- **Automatic:** `_className_` added to JSON for all nested objects

🎉 **That's it! Nested Zorphy objects work seamlessly in CLI and MCP!**
