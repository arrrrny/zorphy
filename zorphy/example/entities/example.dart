// Example usage of the Zorphy package
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'example.zorphy.dart';
part 'example.g.dart';

@Zorphy(generateJson: true)
abstract class $Person {
  String get name;
  int get age;
  String? get email;
}
