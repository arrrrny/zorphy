import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'product_review.zorphy.dart';
part 'product_review.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $ProductReview {
  int get rating;
  String get comment;
  String get author;
}
