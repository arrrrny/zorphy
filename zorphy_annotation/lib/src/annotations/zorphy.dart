import 'zorphy_x.dart';

/// Zorphy annotation for automatic code generation
///
/// This annotation triggers the Zorphy code generator to create:
/// - Immutable class with $ prefix
/// - copyWith methods
/// - JSON serialization (when generateJson is true)
/// - compareTo extension (when generateCompareTo is true)
/// - patch system for partial updates
///
/// ## Usage Examples
///
/// ### Basic Usage
/// ```dart
/// @Zorphy()
/// class User {
///   final String name;
///   final int age;
///
///   User({required this.name, required this.age});
/// }
/// ```
///
/// ### With JSON Serialization
/// ```dart
/// @Zorphy(generateJson: true)
/// class Product {
///   final String id;
///   final String name;
///   final double price;
///
///   Product({required this.id, required this.name, required this.price});
/// }
/// ```
///
/// ### Abstract Class (sealed)
/// ```dart
/// @Zorphy()
/// abstract class $$Shape {
///   double get area;
/// }
/// ```
///
/// ### Polymorphic JSON with Explicit Subtypes
/// ```dart
/// @Zorphy(
///   generateJson: true,
///   explicitSubTypes: [CreditCardPayment, PayPalPayment],
/// )
/// abstract class $$PaymentMethod {
///   String get displayName;
/// }
/// ```
///
/// ### Non-Sealed Abstract Class
/// ```dart
/// @Zorphy(nonSealed: true)
/// abstract class $$EventHandler {
///   void handle(Event event);
/// }
/// ```
class Zorphy implements ZorphyX {
  /// Explicit subtypes for polymorphic JSON serialization
  ///
  /// When specified, the generator will create a fromJson factory that
  /// can deserialize any of the listed subtypes based on a _className_ field.
  ///
  /// Example:
  /// ```dart
  /// @Zorphy(
  ///   explicitSubTypes: [Dog, Cat, Bird],
  ///   generateJson: true,
  /// )
  /// abstract class $$Animal {
  ///   String get name;
  /// }
  /// ```
  final List<Type>? explicitSubTypes;

  /// Whether to generate JSON serialization methods
  ///
  /// When true, generates:
  /// - `toJsonLean()` method for clean JSON output
  /// - `fromJson()` factory constructor
  /// - JSON serialization extension
  ///
  /// Default: false
  final bool generateJson;

  /// Whether toJson methods should have explicit parameter
  ///
  /// This maps to the `explicitToJson` parameter from json_serializable.
  ///
  /// Default: true
  final bool explicitToJson;

  /// Whether to generate compareTo extension method
  ///
  /// When true, generates an extension that compares two instances
  /// and returns a map of differences.
  ///
  /// Default: true
  final bool generateCompareTo;

  /// Whether to hide the public constructor
  ///
  /// When true, the generated class won't have a public constructor,
  /// useful when you want to provide factory methods only.
  ///
  /// Default: false
  final bool hidePublicConstructor;

  /// Whether abstract class should be non-sealed
  ///
  /// By default, abstract classes (starting with $$) are sealed and can't
  /// be extended outside the library. Set to true to allow extension.
  ///
  /// Default: false
  final bool nonSealed;

  /// Whether to generate function-based copyWith methods
  ///
  /// When true, generates `copyWithFn` methods that accept functions
  /// for transforming values.
  ///
  /// Example:
  /// ```dart
  /// user.copyWithFn(age: (age) => age + 1)
  /// ```
  ///
  /// Default: false
  final bool generateCopyWithFn;

  const Zorphy({
    this.explicitSubTypes,
    this.generateJson = false,
    this.explicitToJson = true,
    this.hidePublicConstructor = false,
    this.generateCompareTo = true,
    this.nonSealed = false,
    this.generateCopyWithFn = false,
  });
}
