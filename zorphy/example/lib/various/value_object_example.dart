import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'value_object_example.zorphy.dart';

/// Value object example — an immutable composition type with no identity.
///
/// `@ZValueObject` (alias of `@Zorphy(kind: ZorphyKind.valueObject)`) marks
/// the class as a value object: no id field is required, and the zfa `make`
/// pipeline generates no repository/usecase/controller/presenter for it.
/// Equality, copyWith, toString and JSON serialization are generated exactly
/// like an entity.
@ZValueObject
abstract class $ParserOptions {
  String get separator;
  bool get trimWhitespace;
  int get maxDepth;
}

void main() {
  final options = ParserOptions(
    separator: ',',
    trimWhitespace: true,
    maxDepth: 3,
  );
  final copy = options.copyWith(maxDepth: 5);
  print('options=$options copy=$copy options==copy: ${options == copy}');
}
