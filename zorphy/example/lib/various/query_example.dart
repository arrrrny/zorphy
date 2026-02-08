import 'package:zorphy_annotation/zorphy.dart';

part 'query_example.zorphy.dart';
part 'query_example.g.dart';

/// Example entity with filter generation enabled
@Zorphy(generateJson: true, generateFilter: true)
abstract class $Product {
  int get id;
  String get name;
  double get price;
  DateTime get createdAt;
  bool get isAvailable;
}

void main() {
  // ===== Filter Examples =====

  // Simple equality filter
  final filter1 = ProductFields.name.eq('Laptop');
  print('Filter 1: ${filter1.toJson()}');
  // Output: {name: Laptop}

  // Comparison filters
  final filter2 = ProductFields.price.gt(500.0);
  print('Filter 2: ${filter2.toJson()}');
  // Output: {price: {gt: 500.0}}

  // String operations
  final filter3 = ProductFields.name.contains('phone');
  print('Filter 3: ${filter3.toJson()}');
  // Output: {name: {contains: phone}}

  // Complex logical filters
  final filter4 = And([
    ProductFields.isAvailable.eq(true),
    ProductFields.price.lt(1000.0),
    ProductFields.name.contains('Pro'),
  ]);
  print('Filter 4: ${filter4.toJson()}');
  // Output: {and: [{isAvailable: true}, {price: {lt: 1000.0}}, {name: {contains: Pro}}]}

  // OR filters
  final filter5 = Or([
    ProductFields.price.lt(100.0),
    ProductFields.price.gt(10000.0),
  ]);
  print('Filter 5: ${filter5.toJson()}');
  // Output: {or: [{price: {lt: 100.0}}, {price: {gt: 10000.0}}]}

  // ===== Sort Examples =====

  // Ascending sort
  final sort1 = ProductFields.price.asc();
  print('Sort 1: ${sort1.toJson()}');
  // Output: {field: price, descending: false}

  // Descending sort
  final sort2 = ProductFields.createdAt.desc();
  print('Sort 2: ${sort2.toJson()}');
  // Output: {field: createdAt, descending: true}

  // Manual sort construction
  final sort3 = Sort(ProductFields.name, descending: false);
  print('Sort 3: ${sort3.toJson()}');
  // Output: {field: name, descending: false}

  // ===== Combined Example: Build a query =====

  final complexFilter = And([
    ProductFields.isAvailable.eq(true),
    Or([
      ProductFields.price.lt(50.0),
      And([
        ProductFields.price.gt(200.0),
        ProductFields.name.contains('Premium'),
      ]),
    ]),
  ]);

  final sortByPrice = ProductFields.price.desc();

  print('\n=== Complex Query ===');
  print('Filter: ${complexFilter.toJson()}');
  print('Sort: ${sortByPrice.toJson()}');

  // This is where a framework would build the actual query:
  // final queryParams = {
  //   'filter': complexFilter.toJson(),
  //   'sortBy': sortByPrice.field.name,
  //   'descending': sortByPrice.descending,
  //   'limit': 20,
  // };
}
