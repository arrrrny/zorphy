import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'category_node.g.dart';
part '../../../../_br_/src/domain/entities/category_node/category_node.part.dart';

@Zorphy(generateJson: true)
abstract class $CategoryNode {
  String get id;
  String get name;
  List<$CategoryNode>? get children;
  $CategoryNode? get parent;
}
