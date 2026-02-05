import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'sealed_class_example.zorphy.dart';

/// Example demonstrating sealed class hierarchies for polymorphism.
///
/// This example shows:
/// - Creating sealed base classes with $$ prefix
/// - Implementing subtypes
/// - Type-safe polymorphic operations
/// - Explicit subtype specification
@Zorphy(
  explicitSubTypes: [$CreditCard, $PayPal, $BankTransfer],
)
abstract class $$PaymentMethod {
  String get displayName;
  String get processPayment;
}

@Zorphy(generateJson: true)
abstract class $CreditCard implements $$PaymentMethod {
  String get cardNumber;
  String get expiryDate;
  String get cardHolderName;

  @override
  String get displayName => 'Credit Card';

  @override
  String get processPayment => 'Processing credit card payment...';
}

@Zorphy(generateJson: true)
abstract class $PayPal implements $$PaymentMethod {
  String get email;
  String get transactionId;

  @override
  String get displayName => 'PayPal';

  @override
  String get processPayment => 'Processing PayPal payment...';
}

@Zorphy(generateJson: true)
abstract class $BankTransfer implements $$PaymentMethod {
  String get accountNumber;
  String get routingNumber;
  String get bankName;

  @override
  String get displayName => 'Bank Transfer';

  @override
  String get processPayment => 'Processing bank transfer...';
}

/// Another sealed class example for shapes
@Zorphy(explicitSubTypes: [$Circle, $Rectangle, $Triangle])
abstract class $$Shape {
  double get area;
  double get perimeter;
}

@Zorphy(generateJson: true)
abstract class $Circle implements $$Shape {
  double get radius;

  @override
  double get area => 3.14159 * radius * radius;

  @override
  double get perimeter => 2 * 3.14159 * radius;
}

@Zorphy(generateJson: true)
abstract class $Rectangle implements $$Shape {
  double get width;
  double get height;

  @override
  double get area => width * height;

  @override
  double get perimeter => 2 * (width + height);
}

@Zorphy(generateJson: true)
abstract class $Triangle implements $$Shape {
  double get base;
  double get height;
  double get sideA;
  double get sideB;
  double get sideC;

  @override
  double get area => 0.5 * base * height;

  @override
  double get perimeter => sideA + sideB + sideC;
}

void main() {
  print('=== Sealed Class Example ===\n');

  // Payment methods example
  final creditCard = CreditCard(
    displayName: 'John Doe',
    cardNumber: '****1234',
    expiryDate: '12/25',
    cardHolderName: 'John Doe',
    processPayment: 'Processing CreditCard Payment',
  );

  final payPal = PayPal(
    displayName: 'John Doe',
    email: 'john.doe@example.com',
    transactionId: 'txn-789',
    processPayment: 'Processing PayPal Payment',
  );

  final bankTransfer = BankTransfer(
    displayName: 'John Doe',
    accountNumber: '****5678',
    routingNumber: '123456789',
    bankName: 'Chase Bank',
    processPayment: 'Processing BankTransfer Payment',
  );

  // Polymorphic usage
  final paymentMethods = <$$PaymentMethod>[creditCard, payPal, bankTransfer];

  print('Processing payments:');
  for (final method in paymentMethods) {
    print('  ${method.displayName}: ${method.processPayment}');
  }
  print('');

  // Shapes example
  final circle = Circle(radius: 5.0);
  final rectangle = Rectangle(width: 4.0, height: 6.0);
  final triangle = Triangle(
    base: 3.0,
    height: 4.0,
    sideA: 3.0,
    sideB: 4.0,
    sideC: 5.0,
  );

  final shapes = <$$Shape>[circle, rectangle, triangle];

  print('Shape areas:');
  for (final shape in shapes) {
    print(
        '  $shape (area: ${shape.area.toStringAsFixed(2)}, perimeter: ${shape.perimeter.toStringAsFixed(2)})');
  }
  print('');

  // JSON serialization of polymorphic types
  print('JSON serialization:');
  print('CreditCard: ${creditCard.toJson()}');
  print('Circle: ${circle.toJson()}');
}
