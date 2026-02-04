// Complex example demonstrating polymorphism and self-reference with Zorphy
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'complex_example.zorphy.dart';
part 'complex_example.g.dart';

// Sealed class example
@Zorphy()
abstract class $$Shape {
  double get area;
}

// Implementation of the sealed class
@Zorphy(generateJson: true)
abstract class $Circle implements $$Shape {
  double get radius;

  @override
  double get area => 3.14159 * radius * radius;
}

@Zorphy(generateJson: true)
abstract class $Rectangle implements $$Shape {
  double get width;
  double get height;

  @override
  double get area => width * height;
}

// Self-referencing example
@Zorphy(generateJson: true)
abstract class $TreeNode {
  String get value;
  List<$TreeNode>? get children;
  $TreeNode? get parent;
}
