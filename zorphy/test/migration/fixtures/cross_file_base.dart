// v2 fixture (Case 2, base): an `id`-bearing entity root in its own file.
import 'package:zorphy_annotation/zorphy_annotation.dart';

@Zorphy()
abstract class $Entity {
  String get id;
}