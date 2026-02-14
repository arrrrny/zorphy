---
name: zorphy
description: Generate Clean Architecture entities with Zorphy using consistent patterns for polymorphism, factories, nested objects, generics, patching, and JSON serialization.
version: 1.0.0
author: zorphy
---

## Overview

- Creating or updating Zorphy-annotated entities
- Adding polymorphic hierarchies with sealed or non-sealed behavior
- Generating copyWith, patch, compareTo, or JSON support
- Defining nested, generic, or enum-backed models

## Inputs

- Entity name and fields
- Annotation options (generateJson, generateCopyWithFn, generateCompareTo, nonSealed, explicitSubTypes)
- Target output directory

## Outputs

- Abstract class with getters
- Concrete class with immutable fields
- copyWith, patchWith, compareTo, equals/hashCode, toString
- JSON serialization and discriminator fields when enabled

## Quick Start

CLI:

```bash
dart run zorphy create --name User --output lib/src/domain/entities
```

MCP:

```bash
mcp__zuraffa__generate --name User --output lib/src/domain/entities --generate_json true
```

## Workflow

1. Define an abstract class using $ or $$ prefix
2. Configure options on @Zorphy
3. Run build or CLI generator
4. Use the generated concrete class

## Patterns

### Basic Entity

```dart
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'user.zorphy.dart';

@Zorphy()
abstract class $User {
  String get id;
  String get name;
  int get age;
  String? get email;
}
```

```dart
final user = User(id: '1', name: 'Alice', age: 30);
final updated = user.copyWith(name: 'Bob');
```

### Polymorphism: Sealed with explicitSubTypes

```dart
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'payment_method.zorphy.dart';

@Zorphy(
  generateJson: true,
  explicitSubTypes: [$CreditCard, $PayPal, $BankTransfer],
)
abstract class $$PaymentMethod {
  String get displayName;
  double get amount;
}

@Zorphy(generateJson: true)
abstract class $CreditCard implements $$PaymentMethod {
  String get cardNumber;
  String get expiryDate;
  @override
  String get displayName => 'Credit Card';
}

@Zorphy(generateJson: true)
abstract class $PayPal implements $$PaymentMethod {
  String get email;
  String get transactionId;
  @override
  String get displayName => 'PayPal';
}

@Zorphy(generateJson: true)
abstract class $BankTransfer implements $$PaymentMethod {
  String get accountNumber;
  String get routingNumber;
  String get bankName;
  @override
  String get displayName => 'Bank Transfer';
}
```

```dart
final payments = <PaymentMethod>[
  CreditCard(displayName: 'John', cardNumber: '****1234', expiryDate: '12/25', amount: 100),
  PayPal(displayName: 'Jane', email: 'jane@example.com', transactionId: 'txn_123', amount: 50),
];

for (final payment in payments) {
  payment.when(
    creditCard: (cc) => print(cc.cardNumber),
    payPal: (pp) => print(pp.email),
    bankTransfer: (bt) => print(bt.bankName),
  );
}
```

### Polymorphism: Non-Sealed

```dart
@Zorphy(
  generateJson: true,
  explicitSubTypes: [$FileAttachment, $LinkAttachment],
  nonSealed: true,
)
abstract class $$Attachment {
  String get name;
  String get mimeType;
  List<int> get bytes;
}

@Zorphy(generateJson: true)
abstract class $FileAttachment implements $$Attachment {
  String get filePath;
  int get fileSize;
  @override
  String get name => 'File';
}

@Zorphy(generateJson: true)
abstract class $LinkAttachment implements $$Attachment {
  String get url;
  String get title;
  @override
  String get name => 'Link';
}
```

### Type-Safe Switch

```dart
void processPayment(PaymentMethod method) {
  switch (method) {
    case CreditCard cc:
      print(cc.cardNumber);
      break;
    case PayPal pp:
      print(pp.email);
      break;
    case BankTransfer bt:
      print(bt.bankName);
      break;
  }
}
```

### Polymorphic JSON

```dart
final json = CreditCard(
  displayName: 'John',
  cardNumber: '1234',
  expiryDate: '12/25',
  amount: 100.0,
).toJson();

final restored = PaymentMethod.fromJson(json);
print(restored.runtimeType);
```

### Factory Pattern

```dart
@Zorphy(generateJson: true)
abstract class $Chat {
  String? get id;
  String get title;
  List<$$ChatMessage> get messages;
  DateTime get createdAt;
  DateTime? get updatedAt;

  static Chat create({required String title, List<$$ChatMessage>? initialMessages}) => Chat(
    title: title,
    messages: initialMessages ?? [],
    createdAt: DateTime.now(),
  );
}
```

```dart
@Zorphy()
abstract class $Order {
  String get orderId;
  String get customerId;
  List<$OrderItem> get items;
  double get total;

  static Order create({required String customerId, required List<$OrderItem> items}) {
    final total = items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
    return Order(
      orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      items: items,
      total: total,
    );
  }
}
```

### Nested Objects

```dart
@Zorphy()
abstract class $Address {
  String get street;
  String get city;
  String get state;
  String get zipCode;
}

@Zorphy()
abstract class $Person {
  String get name;
  int get age;
  $Address get address;
}
```

### Self-Referencing Trees

```dart
@Zorphy(generateJson: true)
abstract class $CategoryNode {
  String get id;
  String get name;
  List<$CategoryNode>? get children;
  $CategoryNode? get parent;
}
```

### Nested Patching

```dart
final patched = person.patchWithPerson(
  patchInput: PersonPatch.create()
    ..withAddressPatch(
      AddressPatch.create()..withCity('Los Angeles'),
    ),
);
```

### Generics

```dart
@Zorphy(generateJson: true)
abstract class $Result<T> {
  bool get success;
  T? get data;
  String? get errorMessage;
}
```

```dart
@Zorphy(generateJson: true)
abstract class $KeyValue<K, V> {
  K get key;
  V get value;
}
```

```dart
@Zorphy(generateJson: true)
abstract class $PaginatedResponse<T> {
  List<T> get items;
  int get currentPage;
  int get totalPages;
  int get totalItems;
  bool get hasNextPage;
}
```

### JSON Serialization

```dart
@Zorphy(generateJson: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;
  DateTime get createdAt;
}
```

```dart
final json = product.toJson();
final lean = product.toJsonLean();
final restored = Product.fromJson(json);
```

### CopyWith

```dart
final updated = user.copyWith(name: 'Bob');
final changed = user.copyWith(name: 'Charlie', age: 31);
final withoutEmail = user.copyWith(email: null);
```

### Patching

```dart
final patch = UserPatch.create()
  ..withName('Alice Smith')
  ..withAge(31);

final patched = user.patchWithUser(patchInput: patch);
```

### Multiple Inheritance

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

@Zorphy()
abstract class $Post implements $Timestamped, $Identified {
  String get title;
  String get content;
  String get authorId;
}
```

### Enums

```dart
enum UserStatus { active, inactive, suspended, pending }

@Zorphy(generateJson: true)
abstract class $Account {
  String get username;
  UserStatus get status;
  DateTime get createdAt;
}
```

### Advanced: ChangeTo and CompareTo

```dart
@Zorphy(explicitSubTypes: [$Circle, $Rectangle])
abstract class $$Shape {
  String get name;
}
```

```dart
final rectangle = circle.changeToRectangle(width: 10.0, height: 15.0);
```

```dart
@Zorphy(generateCompareTo: true, generateJson: true)
abstract class $Document {
  String get title;
  String get content;
  int get version;
  List<String> get tags;
}
```

```dart
final diff = doc1.compareToDocument(doc2);
final updated = doc1.patchWithDocument(patchInput: DocumentPatch.create()..withContent(doc2.content));
```

## Best Practices

- Use $$ prefix for sealed abstract classes
- Use $ prefix for standard abstract classes
- Enable generateJson for serialization
- Use explicitSubTypes for polymorphic hierarchies
- Use nonSealed when subtypes may expand
- Prefer static factories for complex creation
- Use patching for partial updates

## File Structure

```
lib/src/domain/entities/
├── user/
│   ├── user.dart
│   ├── user.zorphy.dart
│   └── user.g.dart
├── payment_method/
│   ├── payment_method.dart
│   ├── credit_card/
│   │   └── credit_card.dart
│   ├── pay_pal/
│   │   └── pay_pal.dart
│   └── bank_transfer/
│       └── bank_transfer.dart
└── enums/
    ├── index.dart
    └── user_status.dart
```
