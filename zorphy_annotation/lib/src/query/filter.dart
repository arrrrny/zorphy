import 'package:meta/meta.dart';
import 'field.dart';

/// Base class for all filters
@immutable
sealed class Filter<TEntity> {
  const Filter();
  Map<String, dynamic> toJson();
}

/// Equality filter (e.g., field == value)
class Eq<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Eq(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => { field.name: value };
}

/// Not equal filter (e.g., field != value)
class Neq<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Neq(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => { field.name: {'neq': value} };
}

/// Greater than filter
class Gt<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Gt(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => { field.name: {'gt': value} };
}

/// Greater than or equal filter
class Gte<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Gte(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => { field.name: {'gte': value} };
}

/// Less than filter
class Lt<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Lt(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => { field.name: {'lt': value} };
}

/// Less than or equal filter
class Lte<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Lte(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => { field.name: {'lte': value} };
}

/// Contains filter (e.g., for strings or lists)
class Contains<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Contains(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => { field.name: {'contains': value} };
}

/// In list filter
class InList<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final List<TValue> value;
  const InList(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => { field.name: {'in': value} };
}

/// Logical AND combining multiple filters
class And<TEntity> extends Filter<TEntity> {
  final List<Filter<TEntity>> filters;
  const And(this.filters);

  @override
  Map<String, dynamic> toJson() => {
    'and': filters.map((f) => f.toJson()).toList(),
  };
}

/// Logical OR combining multiple filters
class Or<TEntity> extends Filter<TEntity> {
  final List<Filter<TEntity>> filters;
  const Or(this.filters);

  @override
  Map<String, dynamic> toJson() => {
    'or': filters.map((f) => f.toJson()).toList(),
  };
}

/// Extension methods for easier filter creation
extension FieldOps<TEntity, TValue> on Field<TEntity, TValue> {
  Eq<TEntity, TValue> eq(TValue value) => Eq(this, value);
  Neq<TEntity, TValue> neq(TValue value) => Neq(this, value);
  Gt<TEntity, TValue> gt(TValue value) => Gt(this, value);
  Gte<TEntity, TValue> gte(TValue value) => Gte(this, value);
  Lt<TEntity, TValue> lt(TValue value) => Lt(this, value);
  Lte<TEntity, TValue> lte(TValue value) => Lte(this, value);
  InList<TEntity, TValue> isIn(List<TValue> values) => InList(this, values);
}

extension StringFieldOps<TEntity> on Field<TEntity, String> {
   Contains<TEntity, String> contains(String value) => Contains(this, value);
}

extension NullableStringFieldOps<TEntity> on Field<TEntity, String?> {
   Contains<TEntity, String?> contains(String value) => Contains(this, value);
}
