import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'nested_example.zorphy.dart';
part 'nested_example.g.dart';

/// Example demonstrating nested object support.
///
/// This example shows:
/// - Entities containing other entities
/// - Nested patching
/// - Tree structures with self-referencing types
/// - Deep object manipulation
@zorphy
abstract class $Address {
  String get street;
  String get city;
  String get state;
  String get zipCode;
}

@zorphy
abstract class $Person {
  String get name;
  int get age;
  $Address get address;
}

/// Self-referencing entity for tree structures
@Zorphy(generateJson: true)
abstract class $CategoryNode {
  String get id;
  String get name;
  List<$CategoryNode>? get children;
  $CategoryNode? get parent;
}

@zorphy
abstract class $Company {
  String get name;
  $Address get headquarters;
  List<$Department>? get departments;
}

@zorphy
abstract class $Department {
  String get name;
  $Person get manager;
  int get employeeCount;
}

void main() {
  print('=== Nested Objects Example ===\n');

  // Create nested objects
  final address = Address(
    street: '123 Main St',
    city: 'San Francisco',
    state: 'CA',
    zipCode: '94102',
  );

  final person = Person(
    name: 'Alice Johnson',
    age: 30,
    address: address,
  );

  print('Person with nested address:');
  print('$person');
  print('');

  // Nested patching - update only the city in the address
  final personPatch = PersonPatch.create()
    ..withAddressPatch(
      AddressPatch.create()..withCity('Los Angeles'),
    );

  final updatedPerson = person.patchWithPerson(patchInput: personPatch);

  print('After nested patching (city changed to Los Angeles):');
  print('$updatedPerson');
  print('');

  // copyWith with nested objects
  final samePersonNewAddress = person.copyWith(
    address: Address(
      street: '456 Oak Ave',
      city: 'Seattle',
      state: 'WA',
      zipCode: '98101',
    ),
  );

  print('Same person, new address:');
  print('$samePersonNewAddress');
  print('');

  // Tree structure example
  final techCategory = CategoryNode(
    id: 'tech',
    name: 'Technology',
    children: [
      CategoryNode(
        id: 'dart',
        name: 'Dart',
        parent: null, // Will be set by parent
        children: [
          CategoryNode(
              id: 'flutter', name: 'Flutter', parent: null, children: []),
          CategoryNode(
              id: 'angular', name: 'Angular', parent: null, children: []),
        ],
      ),
      CategoryNode(
        id: 'js',
        name: 'JavaScript',
        parent: null,
        children: [
          CategoryNode(id: 'react', name: 'React', parent: null, children: []),
          CategoryNode(id: 'vue', name: 'Vue', parent: null, children: []),
        ],
      ),
    ],
  );

  print('Category tree structure:');
  printCategoryTree(techCategory, 0);
  print('');

  // JSON serialization of nested structures
  final techJson = techCategory.toJson();
  print('JSON serialization of nested tree:');
  print(techJson);
}

void printCategoryTree(CategoryNode node, int depth) {
  final indent = '  ' * depth;
  print('$indent${node.name} (${node.id})');
  node.children.forEach((child) => printCategoryTree(child, depth + 1));
}
