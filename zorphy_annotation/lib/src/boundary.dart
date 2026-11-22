/// Trust-boundary result types for Chord wire decoding.
///
/// Untrusted wire data decoded at a trust boundary must never leak a raw
/// [TypeError] or [CastError] to the caller. [ZorphyBoundaryResult] models the
/// outcome of such a decode as a closed result: either a [BoundaryOk] carrying
/// the decoded value, or a [BoundaryErr] carrying the target type and a
/// structured list of [FieldViolation]s describing every field that did not
/// match its expected shape.
///
/// ```dart
/// final result = decodeUser(json);
/// final user = result.getOrThrow(); // throws StateError on a malformed wire
/// ```
library;

/// The outcome of decoding untrusted data against an expected type [T].
///
/// Sealed: the only shapes are [BoundaryOk] (success) and [BoundaryErr]
/// (failure), so a `switch` over the result is exhaustive.
sealed class ZorphyBoundaryResult<T> {
  const ZorphyBoundaryResult();

  /// Whether this result is a successful [BoundaryOk].
  bool get isOk => this is BoundaryOk<T>;

  /// The decoded value when [isOk], otherwise `null`.
  T? get valueOrNull => switch (this) {
    BoundaryOk<T>(:final value) => value,
    BoundaryErr<T>() => null,
  };

  /// Bridges the boundary to a single value of type [R].
  ///
  /// Calls [onOk] with the decoded value on success, or [onErr] with the
  /// failure on error, and returns whichever result they produce.
  R fold<R>(R Function(T value) onOk, R Function(BoundaryErr<T> error) onErr) =>
      switch (this) {
        BoundaryOk<T>(:final value) => onOk(value),
        BoundaryErr<T>() => onErr(this as BoundaryErr<T>),
      };

  /// Returns the decoded value, or throws a [StateError] describing the
  /// violations when this is a [BoundaryErr].
  ///
  /// The thrown message names the target type, the violation count and each
  /// offending JSON pointer, so a boundary failure is diagnosable from the
  /// log alone.
  T getOrThrow() => switch (this) {
    BoundaryOk<T>(:final value) => value,
    BoundaryErr<T>() => throw StateError(
      _describeError(this as BoundaryErr<T>),
    ),
  };

  static String _describeError<T>(BoundaryErr<T> error) {
    final buffer = StringBuffer()
      ..write('Boundary decode failed for target type ')
      ..write(error.targetType)
      ..write(' with ')
      ..write(error.violations.length)
      ..write(error.violations.length == 1 ? ' violation:' : ' violations:');
    for (final violation in error.violations) {
      buffer
        ..write(' ')
        ..write(violation.path)
        ..write(' expected ')
        ..write(violation.expected)
        ..write(' but got ')
        ..write(violation.actual)
        ..write(';');
    }
    return buffer.toString();
  }
}

/// A successful boundary decode carrying the [value] of type [T].
final class BoundaryOk<T> extends ZorphyBoundaryResult<T> {
  /// The decoded value.
  final T value;

  const BoundaryOk(this.value);
}

/// A failed boundary decode.
///
/// [targetType] names the type the wire data was being decoded into, and
/// [violations] lists every field that did not match its expected shape.
final class BoundaryErr<T> extends ZorphyBoundaryResult<T> {
  /// The type the wire data was being decoded into.
  final String targetType;

  /// Every field that failed to decode, in traversal order.
  final List<FieldViolation> violations;

  const BoundaryErr({required this.targetType, required this.violations});
}

/// A single field-level decode failure at a trust boundary.
final class FieldViolation {
  /// JSON pointer to the offending field, e.g. `/items[2]/price`.
  final String path;

  /// The expected type/shape, e.g. `double`.
  final String expected;

  /// The actual value/type found, e.g. `String ("free")`.
  final String actual;

  const FieldViolation({
    required this.path,
    required this.expected,
    required this.actual,
  });
}
