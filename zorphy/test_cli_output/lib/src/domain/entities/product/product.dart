import 'package:zorphy_annotation/zorphy_annotation.dart';
import '../product_manufacturer/product_manufacturer.dart';
import '../product_review/product_review.dart';

part 'product.zorphy.dart';
part 'product.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $Product {
  String get id;
  String get name;
  double get price;
  bool get inStock;
  String? get description;
  List<String> get tags;
  $ProductManufacturer get manufacturer;
  List<$ProductReview> get reviews;
}
