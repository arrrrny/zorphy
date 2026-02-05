/// ZorphyX interface defining the contract for Zorphy annotations
///
/// This interface defines the common properties shared between [Zorphy] and [Zorphy2]
/// annotations. It allows for polymorphic handling of different annotation types.
///
/// See also:
/// - [Zorphy] - Primary annotation for code generation
/// - [Zorphy2] - Secondary annotation for dependency ordering
abstract class ZorphyX {
  /// Explicit subtypes for polymorphic JSON serialization
  ///
  /// When specified, generates a fromJson factory that can deserialize
  /// any of the listed subtypes. Useful for sealed class hierarchies.
  List<Type>? get explicitSubTypes;

  /// Whether to generate JSON serialization methods (toJson/fromJson)
  ///
  /// When true, generates:
  /// - `toJson()` method
  /// - `fromJson()` factory constructor
  /// - JSON extension methods
  bool get generateJson;

  /// Whether toJson should have an explicit parameter
  ///
  /// When true, toJson methods use `explicitToJson` parameter from
  /// json_serializable package.
  bool get explicitToJson;
}
