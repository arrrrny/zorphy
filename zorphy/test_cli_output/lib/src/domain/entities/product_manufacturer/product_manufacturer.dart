import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'product_manufacturer.zorphy.dart';
part 'product_manufacturer.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $ProductManufacturer {
  String get name;
  String get country;
}
