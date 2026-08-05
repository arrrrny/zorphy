# Nested Zorphy Objects in Collections

## Overview

Zorphy provides **full support** for nested Zorphy objects (like `$CreditCard`, `$User`, etc.) in:
- ✅ Single fields (nullable or non-nullable)
- ✅ Lists (`List<$ZorphyObject>`)
- ✅ Maps (`Map<String, $ZorphyObject>`)
- ✅ Polymorphic objects with proper type discrimination
- ✅ Deep nesting at any level

All nested objects are automatically serialized with `__typename` discriminator for proper deserialization!

## Examples

### 1. Single Nested Zorphy Object

```dart
@Zorphy(generateJson: true)
abstract class $User {
  String get id;
  $Address? get address;  // Nested Zorphy object
}

@Zorphy(generateJson: true)
abstract class $Address {
  String get street;
  String get city;
  String get country;
}

// Usage
final user = User(
  id: '1',
  address: Address(
    street: '123 Main St',
    city: 'New York',
    country: 'USA',
  ),
);

// JSON includes __typename for nested object
final json = user.toJson();
// {
//   "id": "1",
//   "address": {
//     "street": "123 Main St",
//     "city": "New York",
//     "country": "USA",
//     "__typename": "Address"  // ← Type discriminator
//   },
//   "__typename": "User"
// }

// Deserialization works automatically
final fromJson = User.fromJson(json);
```

### 2. List of Zorphy Objects

```dart
@Zorphy(generateJson: true)
abstract class $Order {
  String get orderId;
  List<$OrderItem> get items;  // List of Zorphy objects
}

@Zorphy(generateJson: true)
abstract class $OrderItem {
  String get productId;
  String get name;
  double get price;
}

// Usage
final order = Order(
  orderId: 'order1',
  items: [
    OrderItem(productId: '1', name: 'Laptop', price: 999.99),
    OrderItem(productId: '2', name: 'Mouse', price: 29.99),
  ],
);

// Each item in list gets __typename
final json = order.toJson();
// {
//   "orderId": "order1",
//   "items": [
//     {
//       "productId": "1",
//       "name": "Laptop",
//       "price": 999.99,
//       "__typename": "OrderItem"  // ← Each item has type
//     },
//     {
//       "productId": "2",
//       "name": "Mouse",
//       "price": 29.99,
//       "__typename": "OrderItem"
//     }
//   ],
//   "__typename": "Order"
// }

// Deserializes correctly
final fromJson = Order.fromJson(json);
expect(fromJson.items.length, 2);
expect(fromJson.items[0].name, 'Laptop');
```

### 3. Map with Zorphy Object Values

```dart
@Zorphy(generateJson: true)
abstract class $ProductCatalog {
  String get catalogId;
  Map<String, $Product> get products;  // Map with Zorphy values
}

@Zorphy(generateJson: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;
}

// Usage
final catalog = ProductCatalog(
  catalogId: 'cat1',
  products: {
    'prod1': Product(id: '1', name: 'Laptop', price: 999.99),
    'prod2': Product(id: '2', name: 'Mouse', price: 29.99),
  },
);

// Each map value gets __typename
final json = catalog.toJson();
// {
//   "catalogId": "cat1",
//   "products": {
//     "prod1": {
//       "id": "1",
//       "name": "Laptop",
//       "price": 999.99,
//       "__typename": "Product"  // ← Each value has type
//     },
//     "prod2": {
//       "id": "2",
//       "name": "Mouse",
//       "price": 29.99,
//       "__typename": "Product"
//     }
//   },
//   "__typename": "ProductCatalog"
// }

// Deserializes correctly
final fromJson = ProductCatalog.fromJson(json);
expect(fromJson.products['prod1']?.name, 'Laptop');
```

### 4. Polymorphic Nested Objects

```dart
@Zorphy()
abstract class $$PaymentMethod {}

@Zorphy(generateJson: true)
abstract class $CreditCard implements $$PaymentMethod {
  String get cardNumber;
  String get expiryDate;
}

@Zorphy(generateJson: true)
abstract class $PayPal implements $$PaymentMethod {
  String get email;
}

@Zorphy(generateJson: true)
abstract class $Transaction {
  String get transactionId;
  $$PaymentMethod get paymentMethod;  // Polymorphic nested object
  List<$$PaymentMethod> get history;  // List of polymorphic objects
  Map<String, $$PaymentMethod> get availableMethods;  // Map of polymorphic
}

// Usage
final transaction = Transaction(
  transactionId: 'txn1',
  paymentMethod: CreditCard(
    cardNumber: '4111111111111111',
    expiryDate: '12/25',
  ),
  history: [
    CreditCard(cardNumber: '4111111111111111', expiryDate: '12/25'),
    PayPal(email: 'user@example.com'),
  ],
  availableMethods: {
    'credit_card': CreditCard(cardNumber: '4111111111111111', expiryDate: '12/25'),
    'paypal': PayPal(email: 'user@example.com'),
  },
);

// JSON preserves polymorphic types
final json = transaction.toJson();
// {
//   "transactionId": "txn1",
//   "paymentMethod": {
//     "cardNumber": "4111111111111111",
//     "expiryDate": "12/25",
//     "__typename": "CreditCard"  // ← Type is preserved
//   },
//   "history": [
//     {"cardNumber": "4111111111111111", "expiryDate": "12/25", "__typename": "CreditCard"},
//     {"email": "user@example.com", "__typename": "PayPal"}
//   ],
//   "availableMethods": {
//     "credit_card": {"cardNumber": "...", "expiryDate": "12/25", "__typename": "CreditCard"},
//     "paypal": {"email": "user@example.com", "__typename": "PayPal"}
//   },
//   "__typename": "Transaction"
// }

// Deserializes with correct types
final fromJson = Transaction.fromJson(json);
expect(fromJson.paymentMethod, isA<CreditCard>());
expect(fromJson.history[0], isA<CreditCard>());
expect(fromJson.history[1], isA<PayPal>());
```

### 5. Deep Nesting

```dart
@Zorphy(generateJson: true)
abstract class $Company {
  String get companyId;
  String get name;
  $CompanyAddress get address;
  List<$Department> get departments;
  Map<String, $Employee> get employeeDirectory;
}

@Zorphy(generateJson: true)
abstract class $CompanyAddress {
  String get street;
  String get city;
  String get country;
  $GeoLocation? get location;  // Nested nullable Zorphy object
}

@Zorphy(generateJson: true)
abstract class $GeoLocation {
  double get latitude;
  double get longitude;
}

@Zorphy(generateJson: true)
abstract class $Department {
  String get departmentId;
  String get name;
  $Employee get manager;
  List<$Employee> get members;
}

@Zorphy(generateJson: true)
abstract class $Employee {
  String get employeeId;
  String get name;
  $ContactInfo get contactInfo;
}

@Zorphy(generateJson: true)
abstract class $ContactInfo {
  String? get email;
}

// Deep nesting works at any level
final company = Company(
  companyId: '1',
  name: 'Acme Corp',
  address: CompanyAddress(
    street: '123 Ave',
    city: 'SF',
    country: 'USA',
    location: GeoLocation(latitude: 37.7749, longitude: -122.4194),
  ),
  departments: [
    Department(
      departmentId: 'dept1',
      name: 'Engineering',
      manager: Employee(
        employeeId: '1',
        name: 'Alice',
        contactInfo: ContactInfo(email: 'alice@example.com'),
      ),
      members: [],
    ),
  ],
  employeeDirectory: {},
);

// Every nested object has __typename
final json = company.toJson();
// json['address']['__typename'] == 'CompanyAddress'
// json['address']['location']['__typename'] == 'GeoLocation'
// json['departments'][0]['__typename'] == 'Department'
// json['departments'][0]['manager']['__typename'] == 'Employee'
// json['departments'][0]['manager']['contactInfo']['__typename'] == 'ContactInfo'
```

## Type Discriminator (`__typename`)

Every Zorphy object in JSON includes an `__typename` field that:

1. **Identifies the concrete type** during deserialization
2. **Enables polymorphism** - base types can deserialize to correct subtypes
3. **Is added automatically** - you don't need to do anything
4. **Works at any nesting level** - single objects, lists, maps, deep nesting

### Removing Type Discriminator

Use `toJsonLean()` to get JSON without `__typename`:

```dart
final json = user.toJson();        // Includes __typename
final lean = user.toJsonLean();    // Removes __typename
```

## CLI Usage

Create entities with nested Zorphy objects:

```bash
# User with nested Address
zorphy create -n User \
  --field id:String \
  --field address:\$Address?

# Create the nested Address entity
zorphy create -n Address \
  --field street:String \
  --field city:String \
  --field country:String
```

## MCP Server Usage

```python
mcp.call_tool("create_entity", {
    "name": "Order",
    "fields": [
        {"name": "orderId", "type": "String"},
        {"name": "user", "type": "$User"},           # Single nested Zorphy object
        {"name": "items", "type": "List<$OrderItem>"},  # List of Zorphy objects
        {"name": "metadata", "type": "Map<String, $PaymentMethod>"}  # Map of Zorphy objects
    ],
    "options": {"generateJson": True}
})
```

## Key Features

✅ **Automatic serialization** - No manual code needed  
✅ **Type preservation** - `__typename` ensures correct deserialization  
✅ **Polymorphism support** - Base types deserialize to concrete subtypes  
✅ **Deep nesting** - Works at any level  
✅ **Null safety** - Nullable nested objects supported  
✅ **Collections** - Lists and Maps fully supported  
✅ **CopyWith & Patch** - Update nested structures easily  

## Performance Notes

- Nested objects are serialized recursively
- Each object adds one field (`__typename`) to JSON
- No reflection used - all compile-time generated
- Minimal runtime overhead

## Summary

Zorphy provides **complete, automatic support** for nested Zorphy objects in any context:
- Single fields
- Lists
- Maps  
- Any depth of nesting
- With full type preservation through `__typename` discriminator

Just define your entities with nested Zorphy types, and everything works automatically! 🎉
