/// Comprehensive Zorphy Example
///
/// This file demonstrates all major features of Zorphy with working examples
/// that can be run and tested.
library;

import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'comprehensive_example.zorphy.dart';
part 'comprehensive_example.g.dart';

// =============================================================================
// FEATURE 1: Basic Class Definition
// =============================================================================

/// A simple user class demonstrating basic Zorphy features
@Zorphy()
abstract class $User {
  String get name;
  int get age;
  String? get email;
}

// =============================================================================
// FEATURE 2: JSON Serialization
// =============================================================================

/// Product class with JSON serialization enabled
@Zorphy(generateJson: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;
  bool get inStock;
}

// =============================================================================
// FEATURE 3: Sealed Classes & Polymorphism
// =============================================================================

/// Sealed abstract class for payment methods
/// Enables exhaustiveness checking in switch statements
@Zorphy(generateJson: true, explicitSubTypes: [$CreditCard, $PayPal])
abstract class $$PaymentMethod {
  String get displayName;
}

/// Credit card payment method
@Zorphy(generateJson: true)
abstract class $CreditCard implements $$PaymentMethod {
  String get cardNumber;
  String get expiryDate;

  @override
  String get displayName => 'Credit Card';
}

/// PayPal payment method
@Zorphy(generateJson: true)
abstract class $PayPal implements $$PaymentMethod {
  String get email;

  @override
  String get displayName => 'PayPal';
}

// =============================================================================
// FEATURE 4: Enum Support
// =============================================================================

/// User status enumeration
enum UserStatus { active, inactive, suspended, pending }

/// User with enum field and JSON support
@Zorphy(generateJson: true)
abstract class $Account {
  String get username;
  UserStatus get status;
  DateTime get createdAt;
}

// =============================================================================
// FEATURE 5: Function-based CopyWith
// =============================================================================

/// Counter demonstrating function-based copyWith
@Zorphy(generateCopyWithFn: true)
abstract class $Counter {
  int get value;
  String get label;
}

// =============================================================================
// FEATURE 6: Nested Objects & Patching
// =============================================================================

/// Address class for nesting
@Zorphy()
abstract class $Address {
  String get street;
  String get city;
  String get country;
  String get postalCode;
}

/// Person with nested address
@Zorphy()
abstract class $PersonWithAddress {
  String get name;
  $Address get address;
  String? get phone;
}

// =============================================================================
// FEATURE 7: Self-Referencing Types (Tree Structure)
// =============================================================================

/// Category node in a category tree
@Zorphy(generateJson: true)
abstract class $CategoryNode {
  String get id;
  String get name;
  List<$CategoryNode>? get children;
  $CategoryNode? get parent;
}

// =============================================================================
// FEATURE 8: Multiple Inheritance
// =============================================================================

/// Timestamped entity
@Zorphy()
abstract class $Timestamped {
  DateTime get createdAt;
  DateTime? get updatedAt;
}

/// Entity with ID
@Zorphy()
abstract class $Identified {
  String get id;
}

/// Post combining multiple interfaces
@Zorphy()
abstract class $Post implements $Timestamped, $Identified {
  String get title;
  String get content;
  String get authorId;
}

// =============================================================================
// FEATURE 9: CompareTo Feature
// =============================================================================

/// Document with comparison support
@Zorphy(generateCompareTo: true, generateJson: true)
abstract class $Document {
  String get title;
  String get content;
  int get version;
  List<String> get tags;
}

// =============================================================================
// FEATURE 10: Generic Classes
// =============================================================================

/// Generic result wrapper
@Zorphy(generateJson: false)
abstract class $Result<T> {
  bool get success;
  T? get data;
  String? get errorMessage;
}

/// Generic list response
@Zorphy()
abstract class $ListResponse<T> {
  int get total;
  List<T> get items;
  int get page;
  int get pageSize;
}

// =============================================================================
// FEATURE 11: Explicit Subtypes & ChangeTo
// =============================================================================

/// Shape with explicit subtypes for polymorphism
@Zorphy(explicitSubTypes: [$Circle, $Rectangle])
abstract class $Shape {
  String get name;
}

@Zorphy()
abstract class $Circle implements $Shape {
  double get radius;

  @override
  String get name => 'Circle';
}

@Zorphy()
abstract class $Rectangle implements $Shape {
  double get width;
  double get height;

  @override
  String get name => 'Rectangle';
}

// =============================================================================
// FEATURE 12: Constant Constructor
// =============================================================================

/// Color with constant constructor support
@Zorphy()
abstract class $Color {
  int get red;
  int get green;
  int get blue;

  const $Color();
}

// =============================================================================
// FEATURE 13: Complex Nested Structure
// =============================================================================

/// Employee in a company
@Zorphy()
abstract class $Employee {
  String get id;
  String get name;
  String? get title;
  String? get department;
}

/// Company with nested departments and employees
@Zorphy()
abstract class $Company {
  String get name;
  String get industry;
  List<String> get locations;
  List<Employee> get employees;
}

// =============================================================================
// DEMONSTRATION FUNCTIONS
// These functions show how to use the generated classes
// =============================================================================

/// Demonstrates basic usage
void demonstrateBasicUsage() {
  final user = User(name: 'Alice', age: 30);
  print('Created user: $user');

  // CopyWith
  final olderUser = user.copyWith(age: 31);
  print('Updated age: ${olderUser.age}');

  // Patch
  final patched = user.patchWithUser(
    patchInput: UserPatch.create()..withName('Bob'),
  );
  print('Patched name: ${patched.name}');
}

/// Demonstrates JSON serialization
void demonstrateJsonSerialization() {
  final product = Product(
    id: '1',
    name: 'Laptop',
    price: 999.99,
    inStock: true,
  );

  // To JSON
  final json = product.toJson();
  print('Product JSON: $json');

  // Lean JSON (without metadata)
  final leanJson = product.toJsonLean();
  print('Lean JSON: $leanJson');

  // From JSON
  final fromJson = Product.fromJson(json);
  print('Deserialized: ${fromJson.name}');
}

/// Demonstrates sealed classes and exhaustiveness
void demonstrateSealedClasses() {
  final creditCard = CreditCard(
    displayName: 'John Doe',
    cardNumber: '****1234',
    expiryDate: '12/25',
  );

  final payPal = PayPal(displayName: 'John Doe', email: 'user@example.com');

  // Polymorphic usage
  PaymentMethod payment = creditCard;
  print('Payment method: ${payment.displayName}');

  // JSON serialization with type discriminator
  final json = creditCard.toJson();
  print('Credit Card JSON: $json');

  // Deserialization handles type automatically
  final deserialized = PaymentMethod.fromJson(json);
  print('Deserialized type: ${deserialized.runtimeType}');
}

/// Demonstrates enum support
void demonstrateEnumSupport() {
  final account = Account(
    username: 'alice',
    status: UserStatus.active,
    createdAt: DateTime.now(),
  );

  // Enum serializes to string
  final json = account.toJson();
  print('Account JSON: $json');

  // Deserialization
  final fromJson = Account.fromJson(json);
  print('Status: ${fromJson.status}');
}

/// Demonstrates function-based copyWith
void demonstrateFunctionCopyWith() {
  final counter = Counter(value: 0, label: 'Clicks');

  // Increment using function
  final incremented = counter.copyWithCounterFn(value: () => counter.value + 1);

  print('Original: ${counter.value}');
  print('Incremented: ${incremented.value}');

  // Double value
  final doubled = counter.copyWithCounterFn(
    value: () => counter.value * 2,
    label: () => '${counter.label} (doubled)',
  );

  print('Doubled: ${doubled.value}');
}

/// Demonstrates nested patching
void demonstrateNestedPatching() {
  final person = PersonWithAddress(
    name: 'John Doe',
    address: Address(
      street: '123 Main St',
      city: 'New York',
      country: 'USA',
      postalCode: '10001',
    ),
  );

  // Nested patching
  final patched = person.patchWithPersonWithAddress(
    patchInput: PersonWithAddressPatch.create()
      ..withName('Jane Doe')
      ..withAddressPatch(
        AddressPatch.create()
          ..withCity('Moscow')
          ..withCountry('Russia'),
      ),
  );

  print('Updated name: ${patched.name}');
  print('Updated city: ${patched.address.city}');
}

/// Demonstrates self-referencing types
void demonstrateTreeStructure() {
  final root = CategoryNode(
    id: '1',
    name: 'Technology',
    children: [
      CategoryNode(
        id: '2',
        name: 'Programming',
        children: [
          CategoryNode(id: '3', name: 'Dart'),
          CategoryNode(id: '4', name: 'Flutter'),
        ],
      ),
      CategoryNode(id: '5', name: 'Hardware'),
    ],
  );

  // JSON serialization handles circular references
  final json = root.toJsonLean();
  print('Category tree JSON: ${json['name']}');

  // Count nodes
  int countNodes(CategoryNode node) {
    int count = 1;
    if (node.children != null) {
      for (var child in node.children!) {
        count += countNodes(child);
      }
    }
    return count;
  }

  print('Total nodes: ${countNodes(root)}');
}

/// Demonstrates multiple inheritance
void demonstrateMultipleInheritance() {
  final post = Post(
    id: '1',
    title: 'My First Post',
    content: 'Hello, world!',
    authorId: 'alice',
    createdAt: DateTime.now(),
    updatedAt: null,
  );

  print('Post ID: ${post.id}');
  print('Created: ${post.createdAt}');
  print('Title: ${post.title}');
}

/// Demonstrates compareTo
void demonstrateCompareTo() {
  final doc1 = Document(
    title: 'Document A',
    content: 'Original content',
    version: 1,
    tags: ['draft', 'work'],
  );

  final doc2 = Document(
    title: 'Document A',
    content: 'Updated content',
    version: 2,
    tags: ['draft', 'work', 'review'],
  );

  final diff = doc1.compareToDocument(doc2);
  print('Differences: $diff');

  // Apply patch from diff
  if (diff.isNotEmpty) {
    final patch = DocumentPatch.create();
    if (diff.containsKey('content')) {
      patch.withContent(doc2.content);
    }
    if (diff.containsKey('version')) {
      patch.withVersion(doc2.version);
    }

    final patched = doc1.patchWithDocument(patchInput: patch);
    print('Patched version: ${patched.version}');
  }
}

/// Demonstrates generic classes
void demonstrateGenerics() {
  final successResult = Result<int>(
    success: true,
    data: 42,
    errorMessage: null,
  );

  final errorResult = Result<String>(
    success: false,
    data: null,
    errorMessage: 'Something went wrong',
  );

  print('Success: ${successResult.data}');
  print('Error: ${errorResult.errorMessage}');

  final pageResponse = ListResponse<String>(
    total: 100,
    items: ['item1', 'item2', 'item3'],
    page: 1,
    pageSize: 10,
  );

  print('Items: ${pageResponse.items.length}');
}

/// Demonstrates changeTo with explicit subtypes
void demonstrateChangeTo() {
  final circle = Circle(name: 'My Circle', radius: 5.0);

  // Convert Circle to Rectangle
  final rectangle = circle.changeToRectangle(width: 10.0, height: 15.0);

  print('Original: ${circle.name}');
  print('Converted: ${rectangle.name}');
  print('Rectangle area: ${rectangle.width * rectangle.height}');
}

/// Demonstrates constant constructors
void demonstrateConstants() {
  const red = Color(red: 255, green: 0, blue: 0);
  const blue = Color(red: 0, green: 0, blue: 255);

  print('Red color: ${red.red}, ${red.green}, ${blue.blue}');

  // Constants are identical
  const red2 = Color(red: 255, green: 0, blue: 0);
  print('Same red: ${identical(red, red2)}');
}

/// Demonstrates complex nested structures
void demonstrateComplexNesting() {
  final company = Company(
    name: 'Tech Corp',
    industry: 'Software',
    locations: ['San Francisco', 'New York', 'London'],
    employees: [
      Employee(id: '1', name: 'Alice', title: 'Engineer', department: 'R&D'),
      Employee(id: '2', name: 'Bob', title: 'Designer', department: 'Product'),
      Employee(id: '3', name: 'Charlie', title: 'Manager', department: 'Sales'),
    ],
  );

  print('Company: ${company.name}');
  print('Employees: ${company.employees.length}');

  // Update employee using patch
  final updated = company.copyWith(
    employees: [
      company.employees[0].copyWith(title: 'Senior Engineer'),
      ...company.employees.sublist(1),
    ],
  );

  print('Updated title: ${updated.employees[0].title}');
}

/// Main demonstration runner
void main() {
  print('=== Zorphy Comprehensive Examples ===\n');

  print('1. Basic Usage:');
  demonstrateBasicUsage();

  print('\n2. JSON Serialization:');
  demonstrateJsonSerialization();

  print('\n3. Sealed Classes:');
  demonstrateSealedClasses();

  print('\n4. Enum Support:');
  demonstrateEnumSupport();

  print('\n5. Function CopyWith:');
  demonstrateFunctionCopyWith();

  print('\n6. Nested Patching:');
  demonstrateNestedPatching();

  print('\n7. Tree Structure:');
  demonstrateTreeStructure();

  print('\n8. Multiple Inheritance:');
  demonstrateMultipleInheritance();

  print('\n9. CompareTo:');
  demonstrateCompareTo();

  print('\n10. Generics:');
  demonstrateGenerics();

  print('\n11. ChangeTo:');
  demonstrateChangeTo();

  print('\n12. Constants:');
  demonstrateConstants();

  print('\n13. Complex Nesting:');
  demonstrateComplexNesting();

  print('\n=== All Examples Complete ===');
}
