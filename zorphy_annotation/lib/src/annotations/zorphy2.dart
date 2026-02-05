import 'zorphy_x.dart';

/// Zorphy2 annotation for dependency-ordered code generation
///
/// This annotation is used when you need a related class to be built
/// before another. Zorphy2 runs in the first pass of the build process,
/// before Zorphy, allowing for handling circular dependencies.
///
/// ## When to Use Zorphy2
///
/// Use Zorphy2 when:
/// - Class A needs to reference Class B in its JSON serialization
/// - Class B needs to reference Class A in its JSON serialization
/// - You have circular dependencies between classes
///
/// ## Usage Example
///
/// ```dart
/// // First pass - generates basic structure without complex dependencies
/// @Zorphy2()
/// class Node {
///   final String id;
///   final List<Node> children;  // Will be properly resolved in second pass
///
///   Node({required this.id, required this.children});
/// }
///
/// // Second pass - completes JSON generation with proper type handling
/// @Zorphy(generateJson: true)
/// class Node {
///   // ... (same definition)
/// }
/// ```
///
/// ## Differences from Zorphy
///
/// - Zorphy2 runs first (zorphy2 builder)
/// - Zorphy runs second (zorphy builder)
/// - Both produce identical output structure
/// - Use both annotations on the same class for two-pass generation
class Zorphy2 implements ZorphyX {
  /// Explicit subtypes for polymorphic JSON serialization
  ///
  /// Same as [Zorphy.explicitSubTypes] but used in the first build pass.
  final List<Type>? explicitSubTypes;

  /// Whether to generate JSON serialization methods
  ///
  /// Same as [Zorphy.generateJson] but used in the first build pass.
  final bool generateJson;

  /// Whether toJson methods should have explicit parameter
  ///
  /// Same as [Zorphy.explicitToJson] but used in the first build pass.
  final bool explicitToJson;

  /// Whether to hide the public constructor
  ///
  /// Same as [Zorphy.hidePublicConstructor] but used in the first build pass.
  final bool hidePublicConstructor;

  /// Whether abstract class should be non-sealed
  ///
  /// Same as [Zorphy.nonSealed] but used in the first build pass.
  final bool nonSealed;

  /// Whether to generate compareTo extension method
  ///
  /// Same as [Zorphy.generateCompareTo] but used in the first build pass.
  final bool generateCompareTo;

  /// Whether to generate function-based copyWith methods
  ///
  /// Same as [Zorphy.generateCopyWithFn] but used in the first build pass.
  final bool generateCopyWithFn;

  const Zorphy2({
    this.explicitSubTypes,
    this.generateJson = false,
    this.explicitToJson = true,
    this.hidePublicConstructor = false,
    this.nonSealed = false,
    this.generateCompareTo = true,
    this.generateCopyWithFn = false,
  });
}
