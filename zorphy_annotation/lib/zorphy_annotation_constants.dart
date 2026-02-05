/// Annotation instances for Zorphy
///
/// This library provides the commonly used annotation instances:
/// - **[@zorphy]** - Default @Zorphy() instance
/// - **[@zorphy2]** - Default @Zorphy2() instance
library zorphy_annotation.constants;

import 'src/annotations/annotations.dart';

/// Default @Zorphy() annotation instance
///
/// This is the most commonly used configuration for Zorphy.
/// Use this annotation when you want standard code generation
/// without JSON serialization.
///
/// Example:
/// ```dart
/// @zorphy
/// class User {
///   final String name;
///   final int age;
///
///   User({required this.name, required this.age});
/// }
/// ```
const zorphy = Zorphy(
  generateJson: false,
  explicitSubTypes: null,
  explicitToJson: true,
  generateCompareTo: true,
  generateCopyWithFn: false,
);

/// @Zorphy2 annotation instance for two-pass generation
///
/// Zorphy2 runs in the first pass of the build process, before Zorphy.
/// Use it when you have circular dependencies between classes.
///
/// Example:
/// ```dart
/// @zorphy2
/// @Zorphy(generateJson: true)
/// class Node {
///   final List<Node> children;
///
///   Node({required this.children});
/// }
/// ```
const zorphy2 = Zorphy2(
  generateJson: false,
  explicitSubTypes: null,
  explicitToJson: true,
  generateCompareTo: true,
  generateCopyWithFn: false,
);
