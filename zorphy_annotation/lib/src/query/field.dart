import 'package:meta/meta.dart';

/// Represents a field in a Zorphy entity [TEntity] with value type [TValue].
/// Used for type-safe query construction and runtime evaluation.
@immutable
class Field<TEntity, TValue> {
  final String name;

  /// Function to extract the field value from an entity instance.
  /// Optional, but required for in-memory filtering/sorting.
  final TValue Function(TEntity)? getValue;

  /// Creates a field descriptor with optional value extractor.
  const Field(this.name, [this.getValue]);
}
