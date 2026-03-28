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
  /// Creates a filter that matches any input.
  const AlwaysMatch();

  @override

  /// Returns an empty JSON representation.
  Map<String, dynamic> toJson() => {};

  @override

  /// Always returns true for any [item].
  bool matches(TEntity item) => true;
}

/// Equality filter (e.g., field == value)
class Eq<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;

  /// Creates a filter that matches when [field] equals [value].
  const Eq(this.field, this.value);

  @override

  /// Serializes the equality predicate to JSON.
  Map<String, dynamic> toJson() => {field.name: value};

  @override

  /// Returns true when the field value equals [value].
  bool matches(TEntity item) => field.getValue!(item) == value;
}

/// Not equal filter (e.g., field != value)
class Neq<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;

  /// Creates a filter that matches when [field] does not equal [value].
  const Neq(this.field, this.value);

  @override

  /// Serializes the inequality predicate to JSON.
  Map<String, dynamic> toJson() => {
        field.name: {'neq': value}
      };

  @override

  /// Returns true when the field value differs from [value].
  bool matches(TEntity item) => field.getValue!(item) != value;
}

/// Greater than filter
class Gt<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final TValue value;

  /// Creates a filter that matches when [field] is greater than [value].
  const Gt(this.field, this.value);

  @override

  /// Serializes the greater-than predicate to JSON.
  Map<String, dynamic> toJson() => {
        field.name: {'gt': value}
      };

  @override

  /// Returns true when the field value is greater than [value].
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

  /// Creates a filter that matches when [field] is at least [value].
  const Gte(this.field, this.value);

  @override

  /// Serializes the greater-than-or-equal predicate to JSON.
  Map<String, dynamic> toJson() => {
        field.name: {'gte': value}
      };

  @override

  /// Returns true when the field value is greater than or equal to [value].
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

  /// Creates a filter that matches when [field] is less than [value].
  const Lt(this.field, this.value);

  @override

  /// Serializes the less-than predicate to JSON.
  Map<String, dynamic> toJson() => {
        field.name: {'lt': value}
      };

  @override

  /// Returns true when the field value is less than [value].
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

  /// Creates a filter that matches when [field] is at most [value].
  const Lte(this.field, this.value);

  @override

  /// Serializes the less-than-or-equal predicate to JSON.
  Map<String, dynamic> toJson() => {
        field.name: {'lte': value}
      };

  @override

  /// Returns true when the field value is less than or equal to [value].
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

  /// Creates a filter that matches when [field] contains [value].
  const Contains(this.field, this.value);

  @override

  /// Serializes the contains predicate to JSON.
  Map<String, dynamic> toJson() => {
        field.name: {'contains': value}
      };

  @override

  /// Returns true when the field value contains [value].
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

  /// Creates a filter that matches when [field] is in [value].
  const InList(this.field, this.value);

  @override

  /// Serializes the inclusion predicate to JSON.
  Map<String, dynamic> toJson() => {
        field.name: {'in': value}
      };

  @override

  /// Returns true when the field value is contained in [value].
  bool matches(TEntity item) => value.contains(field.getValue!(item));
}

/// Logical AND combining multiple filters
class And<TEntity> extends Filter<TEntity> {
  final List<Filter<TEntity>> filters;

  /// Creates a filter that matches when all [filters] match.
  const And(this.filters);

  @override

  /// Serializes the logical AND predicate to JSON.
  Map<String, dynamic> toJson() => {
        'and': filters.map((f) => f.toJson()).toList(),
      };

  @override

  /// Returns true when every filter matches the [item].
  bool matches(TEntity item) => filters.every((f) => f.matches(item));
}

  /// Logical OR combining multiple filters
class Or<TEntity> extends Filter<TEntity> {
  final List<Filter<TEntity>> filters;

  /// Creates a filter that matches when any of the [filters] match.
  const Or(this.filters);

  @override

  /// Serializes the logical OR predicate to JSON.
  Map<String, dynamic> toJson() => {
        'or': filters.map((f) => f.toJson()).toList(),
      };

  @override

  /// Returns true when any filter matches the [item].
  bool matches(TEntity item) => filters.any((f) => f.matches(item));
}

/// Nested object or collection filter
class Nested<TEntity, TValue> extends Filter<TEntity> {
  final Field<TEntity, TValue> field;
  final Filter<dynamic> filter;

  /// Creates a filter that matches when [field] matches [filter].
  /// If [TValue] is an [Iterable], matches if any element in the collection matches the [filter].
  /// If [TValue] is a single object, matches if the object matches the [filter].
  const Nested(this.field, this.filter);

  @override

  /// Serializes the nested filter to JSON.
  Map<String, dynamic> toJson() => {
        field.name: filter.toJson(),
      };

  @override

  /// Returns true when the nested value (or any value in its collection) matches [filter].
  bool matches(TEntity item) {
    final value = field.getValue!(item);
    if (value == null) return false;

    if (value is Iterable) {
      return value.any((element) => filter.matches(element));
    } else {
      return filter.matches(value);
    }
  }
}

/// Logical NOT negating a filter
class Not<TEntity> extends Filter<TEntity> {
  final Filter<TEntity> filter;

  /// Creates a filter that matches when [filter] does not match.
  const Not(this.filter);

  @override

  /// Serializes the logical NOT predicate to JSON.
  Map<String, dynamic> toJson() => {'not': filter.toJson()};

  @override

  /// Returns true when the inner filter does not match the [item].
  bool matches(TEntity item) => !filter.matches(item);
}

/// Extension methods for easier filter creation
extension FieldOps<TEntity, TValue> on Field<TEntity, TValue> {
  /// Builds an equality filter for this field.
  Eq<TEntity, TValue> eq(TValue value) => Eq(this, value);

  /// Builds an inequality filter for this field.
  Neq<TEntity, TValue> neq(TValue value) => Neq(this, value);

  /// Builds a greater-than filter for this field.
  Gt<TEntity, TValue> gt(TValue value) => Gt(this, value);

  /// Builds a greater-than-or-equal filter for this field.
  Gte<TEntity, TValue> gte(TValue value) => Gte(this, value);

  /// Builds a less-than filter for this field.
  Lt<TEntity, TValue> lt(TValue value) => Lt(this, value);

  /// Builds a less-than-or-equal filter for this field.
  Lte<TEntity, TValue> lte(TValue value) => Lte(this, value);

  /// Builds an inclusion filter for this field.
  InList<TEntity, TValue> isIn(List<TValue> values) => InList(this, values);

  /// Builds a nested filter for this field.
  Nested<TEntity, TValue> filter(Filter<dynamic> filter) =>
      Nested<TEntity, TValue>(this, filter);
}

/// List-contains-element filter (e.g., List<T>.contains(value))
class Has<TEntity, TElement> extends Filter<TEntity> {
  final Field<TEntity, List<TElement>> field;
  final TElement value;

  /// Creates a filter that matches when [field] (a list) contains [value].
  const Has(this.field, this.value);

  @override

  /// Serializes the has predicate to JSON.
  Map<String, dynamic> toJson() => {
        field.name: {'has': value}
      };

  @override

  /// Returns true when the list field contains [value].
  bool matches(TEntity item) => field.getValue!(item).contains(value);
}

extension CollectionFieldOps<TEntity, TElement>
    on Field<TEntity, List<TElement>> {
  /// Builds a nested filter for a collection field.
  Nested<TEntity, List<TElement>> filter(Filter<dynamic> filter) =>
      Nested<TEntity, List<TElement>>(this, filter);

  /// Builds a has filter that matches when the list contains [value].
  Has<TEntity, TElement> has(TElement value) => Has(this, value);
}

extension StringFieldOps<TEntity> on Field<TEntity, String> {
  /// Builds a contains filter for string fields.
  Contains<TEntity, String> contains(String value) => Contains(this, value);
}

extension NullableStringFieldOps<TEntity> on Field<TEntity, String?> {
  /// Builds a contains filter for nullable string fields.
  Contains<TEntity, String?> contains(String value) => Contains(this, value);
}

extension FilterOps<TEntity> on Filter<TEntity> {
  /// Negates this filter.
  Not<TEntity> not() => Not(this);
}
