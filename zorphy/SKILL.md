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

### JSON-Pointer Resolution

A generated class with at least one writable field exposes a static resolver
(issue #186):

```dart
static ZorphyLens<Post, Object?>? resolvePath(String pointer)
```

`Post` is the concrete class — the generator emits each class's own name, so no
type parameter ever appears here.

It resolves a JSON Pointer to a typed lens, one `switch` step per segment —
O(depth), no regex, no `dart:mirrors`, AOT-safe:

```dart
// A field on this class
final title = Post.resolvePath('/title');
final renamed = title?.set(post, 'New title');

// A nested class's field delegates to that class's own table
// (the parent field must be non-nullable)
final city = User.resolvePath('/address/city');

// A segment only SOME subtype carries still resolves, and its lens
// answers null on a node that does not have the field
final enabled = UiNode.resolvePath('/enabled'); // null-safe dispatch
```

- A pointer this class does not carry answers `null`.
- Nested delegation needs a **non-nullable** parent: a nullable
  `Address? get address` has nothing to delegate to, so `/address/city`
  answers `null` instead of composing a lens.
- A nullable field accepts the explicit `null` write (`lens.set(root, null)`)
  only when the preset generates `Patch` — `standard` and `full` do, while
  `lean` sets `generatePatch: false`. With no null branch the write falls
  through to `copyWith`'s `field ?? this.field` and keeps the old value.
- A class gets no resolver when it is generic (a static member cannot
  reference `T`), carries no writable field at all, or lives in a hierarchy
  where no class generated `copyWith` (e.g. a sealed root whose subtypes are
  all abstract without `generateCopyWithFn`).

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
@Zorphy(generateJson: true, explicitSubTypes: [$Circle, $Rectangle])
abstract class $$Shape {
  String get name;
}
```

```dart
final rectangle = circle.changeToRectangle(width: 10.0, height: 15.0);
```

`changeTo` converts by round-tripping through JSON, so it is generated only when
the classes it dispatches over generate JSON: `generateJson: true` on every
declared subtype, and on the base too whenever the base is not sealed — a base
that is not sealed needs `nonSealed: true` as well, or it has no `toJson()` for
the switch's default case to call.

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
- A `$$` base generates `sealed` only when the closed hierarchy is declared
  EXPLICITLY via `explicitSubTypes` on the base AND every declared subtype
  lives in the same file; without that declaration the base stays `abstract`
  (same-file subtypes alone do not seal — an unimported remote subtype would
  fail to compile), and subtypes declared in other files always generate
  `abstract`. `nonSealed: true` always opts out
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

## v3 polymorphic archetypes (3.0.0+)

The `@Zorphy(...)` surface above is the v2 API. v3 replaces every preset and
every `generate*` toggle with five zero-toggle archetypes: `@ZorphyEntity`,
`@ZorphyState`, `@ZorphyUnion`, `@ZorphyIntent` and `@ZorphyValue`. A class
carries exactly one, and polymorphism is declared by `implements $Parent`
rather than by `explicitSubTypes`.

```dart
import 'package:zorphy_annotation/zorphy_annotation.dart';

@ZorphyEntity(principalKey: #id)
abstract class $Notification {
  String get id;
  DateTime get createdAt;
}

@ZorphyEntity()
class $OrderNotification implements $Notification {
  String get orderId;
}
```

`PolymorphicClassEmitter` (ISSUE-003, #178) emits the class shape of one such
hierarchy from the resolved `PolymorphicIr`:

- a `sealed class` root and every `sealed class` intermediate, implementing the
  archetype marker base — `ZorphyEntityBase<Id>` (with `Id` taken from the
  principal-key field's real type) or `ZorphyValueBase`;
- a `final class` leaf that `extends` its NEAREST sealed ancestor, so it is a
  subtype of every level above it;
- the inherited `principalKey` getter, emitted ONCE on the root; subtypes reach
  it through `extends`, so do not redeclare it;
- `const <Leaf>.fromTrusted({required this.id, ...})`, assigning collection
  references directly — no `toList()`, no `List.unmodifiable` — so a caller
  that already owns a list pays no copy;
- `copyWith`, where an omitted argument keeps the current value and an explicit
  `null` CLEARS a nullable field (through a library-level `_sentinel`).

Field data is passed alongside the IR (`Map<String, List<PolymorphicField>>`
keyed by the node's `$`-prefixed class name), because the IR itself carries
names, hierarchy links and the principal key but no fields.

`ZorphyEntityBase<Id>` and its siblings are MARKERS: they declare no members.
A generated `principalKey` getter is therefore the archetype's documented
contract, not an `@override`.

## v3 trust-boundary wire codecs (3.0.0+)

A v3 hierarchy has exactly ONE wire entry point per direction — `fromWire` to
decode untrusted data, `toWire` to encode it. There is no `fromJson`/`toJson`
on the archetype surface, and no toggle to turn one on.

```dart
final result = Notification.fromWire(jsonDecode(body) as Map<String, Object?>);
switch (result) {
  case BoundaryOk(:final value):
    handle(value);                     // OrderNotification or PriceDropNotification
  case BoundaryErr(:final violations):
    log(violations.map((v) => '${v.path}: expected ${v.expected}, got ${v.actual}'));
}
```

`BoundaryCodecEmitter` (ISSUE-013, #188) emits those members from the resolved
`PolymorphicIr`:

- a **dispatch node** (the sealed root, or an abstract intermediate) resolves
  `raw[discriminatorKey]` — `kind` by default — against the tags of the
  concrete leaves BELOW it, and delegates to the matching leaf's `fromWire`.
  A missing or unknown tag is a `BoundaryErr` carrying one `FieldViolation` at
  `/<discriminatorKey>` whose `expected` names the tags that would have been
  accepted; it never throws.
- a **leaf** decodes each field through a total `is` test, collecting EVERY
  failure into one `BoundaryErr` before it returns, and passes the decoded
  values to `fromTrusted`. Its `toWire` re-injects the discriminator, so a
  round-trip dispatches back to the same leaf.
- **nested values** recurse: a `List<Contract>` or `Map<String, Contract>`
  field calls the element's own `fromWire` and re-paths its violations under
  the parent pointer, so a bad field inside the second element reports
  `/children[1]/contractId`.

A `DateTime` is an ISO-8601 string on the wire, `double` accepts an `int`
(a JSON `1` is a legal `1.0`), and an absent nullable field is a null value,
not a violation. Nothing is an `as`-cast, so arbitrary corrupt maps cannot
raise `TypeError` or `CastError` — the whole point of the boundary.

The emitted library must import
`package:zorphy_annotation/zorphy_annotation.dart` (where
`ZorphyBoundaryResult`/`BoundaryOk`/`BoundaryErr`/`FieldViolation` live), and
`BoundaryCodecEmitter.helperSpecs()` must be emitted ONCE per library — a
second copy is a duplicate-definition error.
