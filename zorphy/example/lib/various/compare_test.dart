import 'package:zorphy_annotation/zorphy_annotation.dart';
part '../_br_/various/compare_test.part.dart';

@Zorphy(generateCompareTo: true)
abstract class $Person {
  String get name;
  int get age;
}
