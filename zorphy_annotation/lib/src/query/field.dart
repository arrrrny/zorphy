import 'package:meta/meta.dart';

/// Represents a field in a Zorphy entity [TEntity] with value type [TValue].
/// Used for type-safe query construction.
@immutable
class Field<TEntity, TValue> {
  final String name;
  const Field(this.name);
}
