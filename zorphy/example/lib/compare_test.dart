import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'compare_test.zorphy.dart';

@Zorphy(generateCompareTo: true)
abstract class $Person {
  String get name;
  int get age;
}
