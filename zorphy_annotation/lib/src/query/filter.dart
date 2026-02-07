import 'package:meta/meta.dart';
import 'field.dart';

/// Base class for all filters
@immutable
sealed class Filter<TEntity> {
  const Filter();

  /// Serializes the filter to a JSON-compatible map.
  Map<String, dynamic> toJson();

  /// Evaluates the filter against an [item].
  /// Requires [Field.getValue] to be defined for all fields in the filter.
  bool matches(TEntity item);

  /// A filter that matches everything.
  static Filter<T> always<T>() => AlwaysMatch<T>();
}

/// A filter that always evaluates to true.
class AlwaysMatch<TEntity> extends Filter<TEntity> {
  const AlwaysMatch();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  bool matches(TEntity item) => true;
}

/// Equality filter (e.g., field == value)
class Eq<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Eq(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => {field.name: value};

  @override
  bool matches(TEntity item) => field.getValue!(item) == value;
}

/// Not equal filter (e.g., field != value)
class Neq<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Neq(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => {
        field.name: {'neq': value}
      };

  @override
  bool matches(TEntity item) => field.getValue!(item) != value;
}

/// Greater than filter
class Gt<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Gt(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => {
        field.name: {'gt': value}
      };

  @override
  bool matches(TEntity item) {
    final val = field.getValue!(item);
    if (val is Comparable && value is Comparable) {
      return val.compareTo(value) > 0;
    }
    return false;
  }
}

/// Greater than or equal filter
class Gte<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Gte(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => {
        field.name: {'gte': value}
      };

  @override
  bool matches(TEntity item) {
    final val = field.getValue!(item);
    if (val is Comparable && value is Comparable) {
      return val.compareTo(value) >= 0;
    }
    return false;
  }
}

/// Less than filter
class Lt<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Lt(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => {
        field.name: {'lt': value}
      };

  @override
  bool matches(TEntity item) {
    final val = field.getValue!(item);
    if (val is Comparable && value is Comparable) {
      return val.compareTo(value) < 0;
    }
    return false;
  }
}

/// Less than or equal filter
class Lte<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Lte(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => {
        field.name: {'lte': value}
      };

  @override
  bool matches(TEntity item) {
    final val = field.getValue!(item);
    if (val is Comparable && value is Comparable) {
      return val.compareTo(value) <= 0;
    }
    return false;
  }
}

/// Contains filter (e.g., for strings or lists)
class Contains<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;
  const Contains(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => {
        field.name: {'contains': value}
      };

  @override
  bool matches(TEntity item) {
    final val = field.getValue!(item);
    if (val is String && value is String) {
      return val.contains(value as String);
    }
    if (val is Iterable) {
      return val.contains(value);
    }
    return false;
  }
}

/// In list filter
class InList<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final List<TValue> value;
  const InList(this.field, this.value);

  @override
  Map<String, dynamic> toJson() => {
        field.name: {'in': value}
      };

  @override
  bool matches(TEntity item) => value.contains(field.getValue!(item));
}

/// Logical AND combining multiple filters
class And<TEntity> extends Filter<TEntity> {
  final List<Filter<TEntity>> filters;
  const And(this.filters);

  @override
  Map<String, dynamic> toJson() => {
        'and': filters.map((f) => f.toJson()).toList(),
      };

  @override
  bool matches(TEntity item) => filters.every((f) => f.matches(item));
}

/// Logical OR combining multiple filters
class Or<TEntity> extends Filter<TEntity> {
  final List<Filter<TEntity>> filters;
  const Or(this.filters);

  @override
  Map<String, dynamic> toJson() => {
        'or': filters.map((f) => f.toJson()).toList(),
      };

  @override
  bool matches(TEntity item) => filters.any((f) => f.matches(item));
}

/// Extension methods for in-memory filtering of iterables
extension FilterIterableExt<T> on Iterable<T> {
  /// Filters the iterable using the given [filter].
  /// If [filter] is null, returns the original iterable.
  Iterable<T> filter(Filter<T>? filter) {
    if (filter == null) return this;
    return where((item) => filter.matches(item));
  }
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
