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
  @JsonKey(defaultValue: 10.0)
  double get radius;

  @override
  double get area => 3.14159 * radius * radius;
}

@Zorphy(generateJson: true)
abstract class $Rectangle implements $$Shape {
  @JsonKey(defaultValue: 1.0)
  double get width;
  @JsonKey(defaultValue: 1.0)
  double get height;

  @override
  double get area => width * height;
}

// Self-referencing example
@Zorphy(generateJson: true)
abstract class $TreeNode {
  @JsonKey(defaultValue: "root")
  String get value;

  @JsonKey(defaultValue: const [])
  List<$TreeNode>? get children;

  @JsonKey(defaultValue: Duration(seconds: 5))
  Duration get timeout;

  $TreeNode? get parent;
}
