import 'package:json_annotation/json_annotation.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'generic_example.zorphy.dart';
part 'generic_example.g.dart';

@Zorphy()
abstract class $TriggerBuild {}

/// Example demonstrating generic type parameter support.
///
/// This example shows:
/// - Generic entities
/// - Type safety with generics
/// - Custom JsonConverters for generic data
/// - Reusable data structures
/// - Generic constraints and usage patterns

/// Custom converter for generic data
class GenericConverter<T> implements JsonConverter<T?, Object?> {
  const GenericConverter();

  @override
  T? fromJson(Object? json) {
    if (json == null) return null;
    if (json is T) return json as T;
    // Here you could add complex logic to map JSON to T
    return json as T;
  }

  @override
  Object? toJson(T? object) => object;
}

/// Generic result type - demonstrating JsonConverter usage
@Zorphy(generateJson: true)
abstract class $ResultWithConverter<T> {
  bool get success;

  @JsonKey(name: 'data_field')
  @GenericConverter()
  T? get data;

  String? get errorMessage;
}

/// Generic result type - using standard genericArgumentFactories (now supported!)
@Zorphy(generateJson: true)
abstract class $Result<T> {
  bool get success;
  T? get data;
  String? get errorMessage;
  int? get statusCode;
}

/// Generic wrapper for paginated data
@Zorphy(generateJson: true)
abstract class $PaginatedResponse<T> {
  List<T> get items;
  int get currentPage;
  int get totalPages;
  int get totalItems;
  bool get hasNextPage;
  bool get hasPreviousPage;
}

/// Generic key-value pair
@Zorphy(generateJson: true)
abstract class $KeyValue<K, V> {
  K get key;
  V get value;
}

/// Generic container with metadata
@Zorphy(generateJson: true)
abstract class $MetadataContainer<T> {
  T get content;
  DateTime get createdAt;
  DateTime get updatedAt;
  String get createdBy;
  Map<String, dynamic> get tags;
}

void main() {
  print('=== Generic Types Example ===\n');

  // Result<String>
  final stringResult = Result<String>(
    success: true,
    data: 'Operation completed successfully',
    errorMessage: null,
    statusCode: 200,
  );

  print('String Result: $stringResult');
  print('Data: ${stringResult.data}');
  print('');

  // Result<int>
  final intResult = Result<int>(success: true, data: 42, errorMessage: null);

  print('Int Result: $intResult');
  print('Data: ${intResult.data}');
  print('');

  // Result<Map<String, dynamic>>
  final mapResult = Result<Map<String, dynamic>>(
    success: true,
    data: {'userId': '123', 'username': 'alice'},
    errorMessage: null,
  );

  print('Map Result: $mapResult');
  print('Data: ${mapResult.data}');
  print('');

  // Error result
  final errorResult = Result<String>(
    success: false,
    data: null,
    errorMessage: 'Resource not found',
    statusCode: 404,
  );

  print('Error Result: $errorResult');
  print('');

  // Paginated response with String items
  final stringPage = PaginatedResponse<String>(
    items: ['Item 1', 'Item 2', 'Item 3'],
    currentPage: 1,
    totalPages: 5,
    totalItems: 15,
    hasNextPage: true,
    hasPreviousPage: false,
  );

  print('Paginated Strings: ${stringPage.items}');
  print('Page ${stringPage.currentPage} of ${stringPage.totalPages}');
  print('');

  // Paginated response with custom types
  final productPage = PaginatedResponse<Product>(
    items: [
      Product(id: '1', name: 'Laptop', price: 999.99),
      Product(id: '2', name: 'Mouse', price: 29.99),
    ],
    currentPage: 1,
    totalPages: 3,
    totalItems: 6,
    hasNextPage: true,
    hasPreviousPage: false,
  );

  print('Paginated Products:');
  productPage.items.forEach((p) => print('  - ${p.name}: \$${p.price}'));
  print('');

  // KeyValue pairs
  final intStringKV = KeyValue<int, String>(key: 1, value: 'One');
  final stringIntKV = KeyValue<String, int>(key: 'count', value: 100);

  print('KeyValue<int, String>: $intStringKV');
  print('KeyValue<String, int>: $stringIntKV');
  print('');

  // Metadata container
  final stringContainer = MetadataContainer<String>(
    content: 'Important document content',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 15),
    createdBy: 'alice',
    tags: {'priority': 'high', 'category': 'document'},
  );

  print('Metadata Container:');
  print('  Content: ${stringContainer.content}');
  print('  Created: ${stringContainer.createdAt}');
  print('  Tags: ${stringContainer.tags}');
  print('');

  // JSON serialization of generics
  print('JSON Serialization:');
  // Pass identity functions for String generics
  final resultJson = stringResult.toJson((s) => s);
  print('Result JSON: $resultJson');

  // For complex types, pass their toJson
  final pageJson = productPage.toJson((p) => p.toJson());
  print('Page JSON: $pageJson');

  // Demonstration of ResultWithConverter (uses identity as converter handles T)
  final converterResult = ResultWithConverter<String>(
    success: true,
    data: 'Converted data',
  );
  print('Converter Result JSON: ${converterResult.toJson((s) => s)}');
}

/// Simple product class for demonstration
@Zorphy(generateJson: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;
}
