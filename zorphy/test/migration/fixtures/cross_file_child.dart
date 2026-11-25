// v2 fixture (Case 2, child): inherits `id` from `$Entity` across a file
// boundary. Without a whole-tree inheritance map this child is misclassified
// as `@ZorphyValue()` while its parent becomes `@ZorphyEntity(...)`.
import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'cross_file_base.dart';

@Zorphy()
abstract class $Order implements $Entity {
  String get orderNumber;
}
