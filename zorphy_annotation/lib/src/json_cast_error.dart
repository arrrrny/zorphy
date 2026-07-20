/// Error thrown by Zorphy-generated `ZorphyJsonHelper.cast<T>()` JSON cast helpers.
///
/// Provides field-level context when JSON deserialization fails, including
/// the field name, the expected type, and the actual runtime type and value.
class ZorphyJsonCastError extends TypeError {
  /// The JSON field name that caused the error.
  final String field;

  /// The type that was expected for this field.
  final Type expectedType;

  /// The actual value from the JSON map (may be `null`).
  final dynamic actualValue;

  /// Creates a [ZorphyJsonCastError] with debugging context.
  ZorphyJsonCastError({
    required this.field,
    required this.expectedType,
    this.actualValue,
  });

  @override
  String toString() {
    final valueStr = actualValue?.toString() ?? '';
    final truncatedValue = valueStr.length > 100
        ? '${valueStr.substring(0, 100)}...'
        : valueStr;
    final actualType =
        actualValue?.runtimeType.toString() ?? 'Null';
    return 'ZorphyJsonCastError: Field "$field" — '
        'expected $expectedType, got $actualType'
        '${truncatedValue.isNotEmpty ? ' (value: $truncatedValue)' : ''}';
  }
}
