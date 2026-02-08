import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'static_method_test.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $Category {
  String get id;
  String get name;
  String? get description;

  static Category undefined() => Category(
    id: 'undefined',
    name: 'undefined',
    description: 'Used for passing barcode etc',
  );

  static Category create({
    required String id,
    required String name,
    String? description,
  }) => Category(
    id: id,
    name: name,
    description: description,
  );
  
  static Category createWithName(String name) => Category(
    id: 'generated',
    name: name,
    description: null,
  );
}
