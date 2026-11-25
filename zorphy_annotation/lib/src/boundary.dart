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

import 'equality.dart';

/// The outcome of decoding untrusted data against an expected type [T].
///
/// Sealed: the only shapes are [BoundaryOk] (success) and [BoundaryErr]
/// (failure), so a `switch` over the result is exhaustive.
sealed class ZorphyBoundaryResult<T> {
  const ZorphyBoundaryResult();

  /// Whether this result is a successful [BoundaryOk].
  ///
  /// The check is safe because the hierarchy is sealed: no other variant can
  /// masquerade as a [BoundaryOk], so a third variant cannot be added without
  /// revisiting this getter.
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
        final BoundaryErr<T> err => onErr(err),
      };

  /// Returns the decoded value, or throws a [StateError] describing the
  /// violations when this is a [BoundaryErr].
  ///
  /// The thrown message names the target type and each offending JSON
  /// pointer, plus the violation count when there is at least one violation,
  /// so a boundary failure is diagnosable from the log alone.
  T getOrThrow() => switch (this) {
    BoundaryOk<T>(:final value) => value,
    final BoundaryErr<T> err => throw StateError(_describeError(err)),
  };

  static String _describeError<T>(BoundaryErr<T> error) {
    final buffer = StringBuffer()
      ..write('Boundary decode failed for target type ')
      ..write(error.targetType);
    if (error.violations.isEmpty) {
      return (buffer..write(' with no field violations.')).toString();
    }
    buffer
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

  /// Value equality on [value], using `T`'s own `==`.
  ///
  /// A collection-typed [value] therefore compares by identity, which is what
  /// `T`'s `==` says; deep-comparing an arbitrary decoded payload is the
  /// caller's choice.
  ///
  /// The [runtimeType] check is what keeps `==` symmetric across type
  /// arguments: `is BoundaryOk<T>` is directional under Dart's covariant
  /// generics, so `BoundaryOk<num>(1) == BoundaryOk<int>(1)` would be `true`
  /// while the reverse is `false`. With it, two results are equal only when
  /// they carry the same `T`, in either operand order.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundaryOk<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => Object.hash(BoundaryOk, value);
}

/// A failed boundary decode.
///
/// [targetType] names the type the wire data was being decoded into, and
/// [violations] lists every field that did not match its expected shape.
///
/// Value equality: two errors with the same [targetType] and an equal
/// [violations] list are `==`, so a decoded error can be diffed or used as a
/// map key. An error with no violations is legal — it models a decode failure
/// with no per-field detail.
final class BoundaryErr<T> extends ZorphyBoundaryResult<T> {
  /// The type the wire data was being decoded into.
  final String targetType;

  /// Every field that failed to decode, in traversal order.
  final List<FieldViolation> violations;

  const BoundaryErr({required this.targetType, required this.violations});

  static const ListEquality<FieldViolation> _violationsEquality =
      ListEquality<FieldViolation>();

  /// Equality is symmetric across type arguments via the [runtimeType] check:
  /// `BoundaryErr<num>` and `BoundaryErr<int>` are never equal, whichever
  /// operand order a caller writes.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundaryErr<T> &&
          runtimeType == other.runtimeType &&
          targetType == other.targetType &&
          _violationsEquality.equals(violations, other.violations);

  @override
  int get hashCode =>
      Object.hash(targetType, _violationsEquality.hash(violations));
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldViolation &&
          path == other.path &&
          expected == other.expected &&
          actual == other.actual;

  @override
  int get hashCode => Object.hash(path, expected, actual);
}
