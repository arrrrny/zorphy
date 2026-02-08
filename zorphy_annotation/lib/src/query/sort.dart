import 'package:meta/meta.dart';
import 'field.dart';

/// Represents a sort operation on a field
@immutable
class Sort<TEntity> {
  final Field<TEntity, Object?> field;
  final bool descending;

  const Sort(this.field, {this.descending = false});

  const Sort.asc(this.field) : descending = false;
  const Sort.desc(this.field) : descending = true;

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
  Sort<TEntity> asc() => Sort(this, descending: false);
  Sort<TEntity> desc() => Sort(this, descending: true);
}
