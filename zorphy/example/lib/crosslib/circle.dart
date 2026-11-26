import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'base_shape.dart';

part '../_br_/crosslib/circle.part.dart';

@ZorphyValue()
abstract class $Circle implements $Shape {
  double get radius;
}
