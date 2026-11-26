/// Represents a field in a Zorphy entity [TEntity] with value type [TValue].
/// Used for type-safe query construction and runtime evaluation.
class Field<TEntity, TValue> {
  final String name;

  /// Function to extract the field value from an entity instance.
  /// Optional, but required for in-memory filtering/sorting.
  final TValue Function(TEntity)? getValue;

  /// Rebuilds an entity with this field replaced by [value].
  ///
  /// The generated descriptor widens every field to [Object?], so the closure
  /// casts [value] to the field's real type itself: a correctly typed value
  /// writes through and a mistyped one fails as a [TypeError] — the same
  /// contract `ZorphyField.set` and `copyWith` have (zorphy#301). `null` when
  /// this field carries no write bridge.
  final TEntity Function(TEntity entity, Object? value)? setValue;

  /// Creates a field descriptor with optional read/write accessors.
  const Field(this.name, [this.getValue, this.setValue]);
}
