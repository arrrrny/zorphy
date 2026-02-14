import 'package:meta/meta.dart';
import 'field.dart';

/// Represents a sort operation on a field
@immutable
class Sort<TEntity> {
  final Field<TEntity, Object?> field;
  final bool descending;

  /// Creates a sort configuration for [field].
  const Sort(this.field, {this.descending = false});

  /// Creates an ascending sort for [field].
  const Sort.asc(this.field) : descending = false;

  /// Creates a descending sort for [field].
  const Sort.desc(this.field) : descending = true;

  /// Serializes this sort configuration to JSON.
  Map<String, dynamic> toJson() => {
        'field': field.name,
        'descending': descending,
      };

  /// Compares two items based on this sort configuration.
  /// Requires [field.getValue] to be defined.
  int compare(TEntity a, TEntity b) {
    var valA = field.getValue!(a);
    var valB = field.getValue!(b);

    if (valA == valB) return 0;
    if (valA == null) return descending ? 1 : -1;
    if (valB == null) return descending ? -1 : 1;

    int result = 0;
    if (valA is Comparable && valB is Comparable) {
      result = valA.compareTo(valB);
    }

    return descending ? -result : result;
  }
}

/// Extension methods for sorting on fields
extension FieldSortOps<TEntity, TValue> on Field<TEntity, TValue> {
  /// Builds an ascending sort for this field.
  Sort<TEntity> asc() => Sort(this, descending: false);

  /// Builds a descending sort for this field.
  Sort<TEntity> desc() => Sort(this, descending: true);
}
