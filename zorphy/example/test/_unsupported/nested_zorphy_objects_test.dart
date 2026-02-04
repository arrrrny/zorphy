/// Nested Zorphy Objects Test
///
/// This demonstrates that Zorphy fully supports:
/// - Nested Zorphy objects as fields
/// - Lists of Zorphy objects
/// - Maps with Zorphy object values
/// - All with proper JSON serialization including _className_ discriminator

library;

import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:test/test.dart';

part 'nested_zorphy_objects_test.zorphy.dart';

// =============================================================================
// Basic nested Zorphy object
// =============================================================================

@Zorphy(generateJson: true)
abstract class $User {
  String get id;
  String get name;
  $Address? get address; // Nullable nested Zorphy object
}

@Zorphy(generateJson: true)
abstract class $Address {
  String get street;
  String get city;
  String get country;
}

// =============================================================================
// List of Zorphy objects
// =============================================================================

@Zorphy(generateJson: true)
abstract class $Order {
  String get orderId;
  List<$OrderItem> get items; // List of Zorphy objects
  $User get user; // Nested Zorphy object
}

@Zorphy(generateJson: true)
abstract class $OrderItem {
  String get productId;
  String get name;
  double get price;
  int get quantity;
}

// =============================================================================
// Map with Zorphy object values
// =============================================================================

@Zorphy(generateJson: true)
abstract class $ProductCatalog {
  String get catalogId;
  Map<String, $Product> get products; // Map with Zorphy object values
}

@Zorphy(generateJson: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;
}

// =============================================================================
// Complex nesting with polymorphism
// =============================================================================

@Zorphy()
abstract class $$PaymentMethod {}

@Zorphy(generateJson: true)
abstract class $CreditCard implements $$PaymentMethod {
  String get cardNumber;
  String get expiryDate;
  String get cvv;
}

@Zorphy(generateJson: true)
abstract class $PayPal implements $$PaymentMethod {
  String get email;
}

@Zorphy(generateJson: true)
abstract class $Transaction {
  String get transactionId;
  $$PaymentMethod get paymentMethod; // Polymorphic Zorphy object
  List<$$PaymentMethod>? get history; // List of polymorphic Zorphy objects
  Map<String, $$PaymentMethod>
  get availableMethods; // Map with polymorphic values
}

// =============================================================================
// Deep nesting
// =============================================================================

@Zorphy(generateJson: true)
abstract class $Company {
  String get companyId;
  $CompanyAddress get address;
  List<$Department> get departments;
  Map<String, $Employee> get employeeDirectory;
}

@Zorphy(generateJson: true)
abstract class $CompanyAddress {
  String get street;
  String get city;
  $GeoLocation? get location; // Nested nullable Zorphy object
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
  String? get phone;
}

void main() {
  group('Nested Zorphy Objects', () {
    test('Single nested Zorphy object with JSON', () {
      final user = User(
        id: 'user1',
        name: 'Alice',
        address: Address(
          street: '123 Main St',
          city: 'New York',
          country: 'USA',
        ),
      );

      final json = user.toJson();

      // Verify nested object is serialized with _className_
      expect(json, {
        'id': 'user1',
        'name': 'Alice',
        'address': {
          'street': '123 Main St',
          'city': 'New York',
          'country': 'USA',
          '_className_': 'Address',
        },
        '_className_': 'User',
      });

      // Verify deserialization
      final fromJson = User.fromJson(json);
      expect(fromJson.id, user.id);
      expect(fromJson.name, user.name);
      expect(fromJson.address?.street, user.address?.street);
      expect(fromJson.address?.city, user.address?.city);
    });

    test('List of Zorphy objects with JSON', () {
      final order = Order(
        orderId: 'order1',
        user: User(id: 'user1', name: 'Alice', address: null),
        items: [
          OrderItem(
            productId: 'prod1',
            name: 'Laptop',
            price: 999.99,
            quantity: 1,
          ),
          OrderItem(
            productId: 'prod2',
            name: 'Mouse',
            price: 29.99,
            quantity: 2,
          ),
        ],
      );

      final json = order.toJson();

      // Verify list items are serialized with _className_
      expect(json['items'], [
        {
          'productId': 'prod1',
          'name': 'Laptop',
          'price': 999.99,
          'quantity': 1,
          '_className_': 'OrderItem',
        },
        {
          'productId': 'prod2',
          'name': 'Mouse',
          'price': 29.99,
          'quantity': 2,
          '_className_': 'OrderItem',
        },
      ]);

      // Verify nested user is serialized
      expect(json['user']['_className_'], 'User');

      // Verify deserialization
      final fromJson = Order.fromJson(json);
      expect(fromJson.items.length, 2);
      expect(fromJson.items[0].name, 'Laptop');
      expect(fromJson.items[1].name, 'Mouse');
    });

    test('Map with Zorphy object values with JSON', () {
      final catalog = ProductCatalog(
        catalogId: 'catalog1',
        products: {
          'prod1': Product(id: 'prod1', name: 'Laptop', price: 999.99),
          'prod2': Product(id: 'prod2', name: 'Mouse', price: 29.99),
        },
      );

      final json = catalog.toJson();

      // Verify map values are serialized with _className_
      expect(json['products']['prod1'], {
        'id': 'prod1',
        'name': 'Laptop',
        'price': 999.99,
        '_className_': 'Product',
      });
      expect(json['products']['prod2']['_className_'], 'Product');

      // Verify deserialization
      final fromJson = ProductCatalog.fromJson(json);
      expect(fromJson.products.length, 2);
      expect(fromJson.products['prod1']?.name, 'Laptop');
      expect(fromJson.products['prod2']?.price, 29.99);
    });

    test('Polymorphic nested Zorphy objects', () {
      final transaction = Transaction(
        transactionId: 'txn1',
        paymentMethod: CreditCard(
          cardNumber: '4111111111111111',
          expiryDate: '12/25',
          cvv: '123',
        ),
        history: [
          CreditCard(
            cardNumber: '4111111111111111',
            expiryDate: '12/25',
            cvv: '123',
          ),
          PayPal(email: 'user@example.com'),
        ],
        availableMethods: {
          'credit_card': CreditCard(
            cardNumber: '4111111111111111',
            expiryDate: '12/25',
            cvv: '123',
          ),
          'paypal': PayPal(email: 'user@example.com'),
        },
      );

      final json = transaction.toJson();

      // Verify polymorphic serialization
      expect(json['paymentMethod']['_className_'], 'CreditCard');
      expect(json['history'][0]['_className_'], 'CreditCard');
      expect(json['history'][1]['_className_'], 'PayPal');
      expect(
        json['availableMethods']['credit_card']['_className_'],
        'CreditCard',
      );
      expect(json['availableMethods']['paypal']['_className_'], 'PayPal');

      // Verify deserialization
      final fromJson = Transaction.fromJson(json);
      expect(fromJson.paymentMethod, isA<CreditCard>());
      expect(fromJson.history?.length, 2);
      expect(fromJson.history?[0], isA<CreditCard>());
      expect(fromJson.history?[1], isA<PayPal>());
    });

    test('Deeply nested Zorphy objects', () {
      final company = Company(
        companyId: 'comp1',
        address: CompanyAddress(
          street: '123 Business Ave',
          city: 'San Francisco',
          country: 'USA',
          location: GeoLocation(latitude: 37.7749, longitude: -122.4194),
        ),
        departments: [
          Department(
            departmentId: 'dept1',
            name: 'Engineering',
            manager: Employee(
              employeeId: 'emp1',
              name: 'Alice',
              contactInfo: ContactInfo(
                email: 'alice@example.com',
                phone: '555-0100',
              ),
            ),
            members: [
              Employee(
                employeeId: 'emp2',
                name: 'Bob',
                contactInfo: ContactInfo(email: 'bob@example.com', phone: null),
              ),
            ],
          ),
        ],
        employeeDirectory: {
          'emp1': Employee(
            employeeId: 'emp1',
            name: 'Alice',
            contactInfo: ContactInfo(
              email: 'alice@example.com',
              phone: '555-0100',
            ),
          ),
        },
      );

      final json = company.toJson();

      // Verify deep nesting with _className_ at every level
      expect(json['address']['_className_'], 'CompanyAddress');
      expect(json['address']['location']['_className_'], 'GeoLocation');
      expect(json['departments'][0]['_className_'], 'Department');
      expect(json['departments'][0]['manager']['_className_'], 'Employee');
      expect(
        json['departments'][0]['manager']['contactInfo']['_className_'],
        'ContactInfo',
      );
      expect(
        json['departments'][0]['members'][0]['contactInfo']['_className_'],
        'ContactInfo',
      );
      expect(json['employeeDirectory']['emp1']['_className_'], 'Employee');

      // Verify deserialization
      final fromJson = Company.fromJson(json);
      expect(fromJson.address.location?.latitude, 37.7749);
      expect(fromJson.departments[0].manager.name, 'Alice');
      expect(fromJson.departments[0].members[0].name, 'Bob');
      expect(fromJson.employeeDirectory['emp1']?.name, 'Alice');
    });

    test('Nullable nested Zorphy object', () {
      final withAddress = User(
        id: 'user1',
        name: 'Alice',
        address: Address(
          street: '123 Main St',
          city: 'New York',
          country: 'USA',
        ),
      );

      final withoutAddress = User(id: 'user2', name: 'Bob', address: null);

      // With address
      final json1 = withAddress.toJson();
      expect(json1['address'], isNotNull);
      expect(json1['address']['_className_'], 'Address');

      // Without address
      final json2 = withoutAddress.toJson();
      expect(json2['address'], isNull);

      // Verify deserialization
      final fromJson1 = User.fromJson(json1);
      expect(fromJson1.address, isNotNull);
      expect(fromJson1.address?.city, 'New York');

      final fromJson2 = User.fromJson(json2);
      expect(fromJson2.address, isNull);
    });

    test('Empty list and map of Zorphy objects', () {
      final order = Order(
        orderId: 'order1',
        user: User(id: 'user1', name: 'Alice', address: null),
        items: [],
      );

      final catalog = ProductCatalog(catalogId: 'catalog1', products: {});

      expect(order.items.isEmpty, isTrue);
      expect(catalog.products.isEmpty, isTrue);

      // JSON serialization/deserialization should work
      final orderJson = order.toJson();
      final orderFromJson = Order.fromJson(orderJson);
      expect(orderFromJson.items.isEmpty, isTrue);

      final catalogJson = catalog.toJson();
      final catalogFromJson = ProductCatalog.fromJson(catalogJson);
      expect(catalogFromJson.products.isEmpty, isTrue);
    });

    test('CopyWith with nested Zorphy objects', () {
      final user = User(
        id: 'user1',
        name: 'Alice',
        address: Address(
          street: '123 Main St',
          city: 'New York',
          country: 'USA',
        ),
      );

      // Update nested object using copyWith
      final updated = user.copyWith(
        address: Address(
          street: '456 Oak Ave',
          city: 'Los Angeles',
          country: 'USA',
        ),
      );

      expect(updated.address?.street, '456 Oak Ave');
      expect(updated.address?.city, 'Los Angeles');
      expect(updated.name, 'Alice'); // Unchanged
    });

    test('Patch with nested Zorphy objects', () {
      final company = Company(
        companyId: 'comp1',
        address: CompanyAddress(
          street: '123 Business Ave',
          city: 'San Francisco',
          country: 'USA',
          location: null,
        ),
        departments: [],
        employeeDirectory: {},
      );

      // Add location using patch
      final patched = company.patchWithCompany(
        patchInput: CompanyPatch.create()
          ..withAddressPatch(
            (addrPatch) => addrPatch
              ..withLocationPatch(
                (locPatch) => locPatch
                  ..withLatitude(37.7749)
                  ..withLongitude(-122.4194),
              ),
          ),
      );

      expect(patched.address.location?.latitude, 37.7749);
      expect(patched.address.location?.longitude, -122.4194);
    });
  });
}
