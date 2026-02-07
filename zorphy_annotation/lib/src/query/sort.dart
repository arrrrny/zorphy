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
}

/// Extension methods for sorting on fields
extension FieldSortOps<TEntity, TValue> on Field<TEntity, TValue> {
  Sort<TEntity> asc() => Sort(this, descending: false);
  Sort<TEntity> desc() => Sort(this, descending: true);
}
