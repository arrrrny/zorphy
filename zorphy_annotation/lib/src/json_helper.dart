import 'json_cast_error.dart';

/// Shared JSON cast helpers used by Zorphy-generated `fromJson` code.
///
/// Provides field-level error messages in fromJson deserialization,
/// avoiding opaque errors like `type 'int' is not a subtype of type 'String'`
/// by surfacing the field name, expected type, actual type, and value.
///
/// Usage (generated code):
/// ```dart
/// factory Foo.fromJson(Map<String, dynamic> json) => Foo(
///   name: ZorphyJsonHelper.cast<String>(json, 'name'),
///   tags: (ZorphyJsonHelper.cast<List<dynamic>>(json, 'tags'))
///       .map((e) => e as String).toList(),
/// );
/// ```
class ZorphyJsonHelper {
  ZorphyJsonHelper._();

  /// Safely casts `json[field]` to type [T] with a descriptive error on failure.
  ///
  /// Throws [ZorphyJsonCastError] on type mismatch, including the field name,
  /// the expected type [T], and the actual runtime value for debugging.
  static T cast<T>(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) {
      if (null is T) return null as T;
      throw ZorphyJsonCastError(
        field: field,
        expectedType: T,
        actualValue: value,
      );
    }
    if (value is T) return value;
    // Common JSON number promotion: JSON has int, we need double
    // ignore: unnecessary_cast
    if (T == double && value is int) return (value as int).toDouble() as T;
    throw ZorphyJsonCastError(
      field: field,
      expectedType: T,
      actualValue: value,
    );
  }
}
