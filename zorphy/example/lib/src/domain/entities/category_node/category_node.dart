import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'category_node.zorphy.dart';
part 'category_node.g.dart';

@Zorphy(generateJson: true)
abstract class $CategoryNode {
  String get id;
  String get name;
  List<$CategoryNode>? get children;
  $CategoryNode? get parent;
}
