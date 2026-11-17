import 'package:zorphy_annotation/zorphy_annotation.dart';

part '../_br_/various/filter_non_generic_example.part.dart';

@Zorphy(generateFilter: true)
abstract class $SimpleFilterEntity {
  String get name;
  int get count;
  bool get isActive;
}

void main() {
  final filter = SimpleFilterEntityFields.name.eq('demo');
  final combined = And([
    filter,
    SimpleFilterEntityFields.count.gt(0),
    SimpleFilterEntityFields.isActive.eq(true),
  ]);
  print(combined.toJson());
}
