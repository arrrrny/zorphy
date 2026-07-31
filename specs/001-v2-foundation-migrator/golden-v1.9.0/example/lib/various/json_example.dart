import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'json_example.zorphy.dart';
part 'json_example.g.dart';

/// Example demonstrating JSON serialization capabilities.
///
/// This example shows:
/// - Enabling JSON generation with generateJson: true
/// - toJson() for serializing objects to JSON
/// - fromJson() for deserializing JSON to objects
/// - Lean JSON that excludes metadata fields
@Zorphy(generateJson: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;

  /// This metadata field will be included in full JSON
  /// but excluded from lean JSON
  DateTime get createdAt;
}

@Zorphy(generateJson: true)
abstract class $Order {
  String get orderId;
  DateTime get orderDate;
  List<$ProductItem> get items;
  double get total;
}

@Zorphy(generateJson: true)
abstract class $ProductItem {
  String get productId;
  String get name;
  int get quantity;
  double get unitPrice;
}

void main() {
  print('=== JSON Serialization Example ===\n');

  // Create a product
  final product = Product(
    id: 'prod-001',
    name: 'Wireless Mouse',
    price: 29.99,
    createdAt: DateTime(2024, 1, 15),
  );

  print('Product object: $product\n');

  // Serialize to JSON
  final json = product.toJson();
  print('Full JSON (includes metadata):');
  print(json);
  print('');

  // Lean JSON excludes the createdAt metadata field
  final leanJson = product.toJsonLean();
  print('Lean JSON (excludes metadata):');
  print(leanJson);
  print('');

  // Deserialize from JSON
  final restoredProduct = Product.fromJson(json);
  print('Restored product: $restoredProduct');
  print('Are they equal? ${product == restoredProduct}'); // true
  print('');

  // Complex nested example
  final order = Order(
    orderId: 'order-123',
    orderDate: DateTime(2024, 2, 1),
    items: [
      ProductItem(
        productId: 'prod-001',
        name: 'Wireless Mouse',
        quantity: 2,
        unitPrice: 29.99,
      ),
      ProductItem(
        productId: 'prod-002',
        name: 'USB-C Cable',
        quantity: 3,
        unitPrice: 9.99,
      ),
    ],
    total: 89.95,
  );

  print('Order object:');
  print(order);
  print('');

  final orderJson = order.toJson();
  print('Order JSON:');
  print(orderJson);
  print('');

  final restoredOrder = Order.fromJson(orderJson);
  print('Restored order: $restoredOrder');
  print('Are they equal? ${order == restoredOrder}'); // true
}
