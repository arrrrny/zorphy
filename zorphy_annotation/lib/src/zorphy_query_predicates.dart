/// Typed query predicates over the generated `<Entity>Fields` descriptors
/// (issue #247).
///
/// A [ZorphyField] builds [ZorphyFilter] and [ZorphySort] values through its
/// `equals` / `lessThan` / `asc` / ... methods; a filter combines through
/// `and` / `or` / `not`, evaluates in memory through [ZorphyFilter.matches],
/// and travels to a remote datasource through [ZorphyFilter.toWire] — a
/// JSON-compatible map keyed by the field's JSON Pointer, so `zuraffa`
/// remote datasources and `zuraffa_ui` `store-query:` URIs serialize typed
/// predicates cleanly. [ZorphyFilter.fromWire] / [ZorphySort.fromWire]
/// reconstruct the typed predicate from that map, given a resolver that maps
/// a pointer back to its field (the generated `all` list provides one via
/// [byPointer]).
///
/// These live BESIDE the v2-era `Field` / `Filter` / `Sort` in
/// `src/query/` — the v2 types are unexported legacy surface kept for the
/// migrator; nothing in this library references them.
library;

import 'zorphy_field.dart';

/// A typed predicate over an entity [T], built from its [ZorphyField]s.
sealed class ZorphyFilter<T> {
  const ZorphyFilter();

  /// Evaluates this predicate against [instance].
  bool matches(T instance);

  /// The JSON-compatible wire form (`{"field": ..., "op": ..., "value": ...}`).
  Map<String, dynamic> toWire();

  /// Rebuilds a typed predicate from [toWire] output.
  ///
  /// [resolve] maps a field pointer (e.g. `/price`) back to its
  /// [ZorphyField]; the generated `<Entity>Fields.all` list resolves one via
  /// [byPointer]. Unknown pointers and unknown ops throw
  /// [FormatException] — a silently-mismatched remote predicate is worse
  /// than a loud one.
  static ZorphyFilter<T> fromWire<T>(
    Map<String, dynamic> wire,
    ZorphyField<T, Object?>? Function(String pointer) resolve,
  ) {
    final op = wire['op'] as String?;
    final pointer = wire['field'] as String?;
    switch (op) {
      case 'and':
      case 'or':
        final raw = wire['filters'];
        if (raw is! List) throw _badWire(wire, 'filters must be a list');
        final filters = [
          for (final f in raw)
            ZorphyFilter.fromWire<T>(
              (f as Map).cast<String, dynamic>(),
              resolve,
            ),
        ];
        return op == 'and' ? ZorphyAnd<T>(filters) : ZorphyOr<T>(filters);
      case 'not':
        final inner = wire['filter'];
        if (inner is! Map) throw _badWire(wire, 'filter must be a map');
        return ZorphyNot<T>(
          ZorphyFilter.fromWire<T>(inner.cast<String, dynamic>(), resolve),
        );
    }
    if (pointer == null) throw _badWire(wire, 'field is required');
    final field = resolve(pointer);
    if (field == null) throw _badWire(wire, 'unknown field pointer');
    final value = wire['value'];
    return switch (op) {
      'eq' => ZorphyEquals<T, Object?>(field, value),
      'neq' => ZorphyNotEquals<T, Object?>(field, value),
      'in' => ZorphyIn<T, Object?>(
        field,
        value is List
            ? List<Object?>.unmodifiable(value)
            : throw _badWire(wire, 'value must be a list'),
      ),
      'isNull' => ZorphyIsNull<T>(field),
      'isNotNull' => ZorphyIsNotNull<T>(field),
      'lt' => ZorphyLessThan<T, Object?>(field, value),
      'lte' => ZorphyLessThanOrEqual<T, Object?>(field, value),
      'gt' => ZorphyGreaterThan<T, Object?>(field, value),
      'gte' => ZorphyGreaterThanOrEqual<T, Object?>(field, value),
      'contains' => ZorphyContains<T>(
        field,
        value is String
            ? value
            : throw _badWire(wire, 'value must be a string'),
        caseSensitive: wire['caseSensitive'] is! bool || wire['caseSensitive'],
      ),
      'startsWith' => ZorphyStartsWith<T>(
        field,
        value is String
            ? value
            : throw _badWire(wire, 'value must be a string'),
      ),
      _ => throw _badWire(wire, 'unknown op'),
    };
  }

  /// Combines this predicate with [other] — both must match.
  ZorphyFilter<T> and(ZorphyFilter<T> other) => ZorphyAnd<T>([this, other]);

  /// Combines this predicate with [other] — either matching is enough.
  ZorphyFilter<T> or(ZorphyFilter<T> other) => ZorphyOr<T>([this, other]);

  /// Negates this predicate.
  ZorphyFilter<T> not() => ZorphyNot<T>(this);

  static FormatException _badWire(Map<String, dynamic> wire, String why) =>
      FormatException('Invalid ZorphyFilter wire ($why): $wire');
}

final class ZorphyEquals<T, V> extends ZorphyFilter<T> {
  final ZorphyField<T, V> field;
  final V value;

  const ZorphyEquals(this.field, this.value);

  @override
  bool matches(T instance) => field.get(instance) == value;

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'eq',
    'value': value,
  };
}

final class ZorphyNotEquals<T, V> extends ZorphyFilter<T> {
  final ZorphyField<T, V> field;
  final V value;

  const ZorphyNotEquals(this.field, this.value);

  @override
  bool matches(T instance) => field.get(instance) != value;

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'neq',
    'value': value,
  };
}

final class ZorphyIn<T, V> extends ZorphyFilter<T> {
  final ZorphyField<T, V> field;
  final List<V> values;

  const ZorphyIn(this.field, this.values);

  @override
  bool matches(T instance) => values.contains(field.get(instance));

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'in',
    'value': values,
  };
}

final class ZorphyIsNull<T> extends ZorphyFilter<T> {
  final ZorphyField<T, Object?> field;

  const ZorphyIsNull(this.field);

  @override
  bool matches(T instance) => field.get(instance) == null;

  @override
  Map<String, dynamic> toWire() => {'field': field.pointer, 'op': 'isNull'};
}

final class ZorphyIsNotNull<T> extends ZorphyFilter<T> {
  final ZorphyField<T, Object?> field;

  const ZorphyIsNotNull(this.field);

  @override
  bool matches(T instance) => field.get(instance) != null;

  @override
  Map<String, dynamic> toWire() => {'field': field.pointer, 'op': 'isNotNull'};
}

final class ZorphyLessThan<T, V> extends ZorphyFilter<T> {
  final ZorphyField<T, V> field;
  final V value;

  const ZorphyLessThan(this.field, this.value);

  @override
  bool matches(T instance) => _cmp(field.get(instance), value) < 0;

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'lt',
    'value': value,
  };
}

final class ZorphyLessThanOrEqual<T, V> extends ZorphyFilter<T> {
  final ZorphyField<T, V> field;
  final V value;

  const ZorphyLessThanOrEqual(this.field, this.value);

  @override
  bool matches(T instance) => _cmp(field.get(instance), value) <= 0;

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'lte',
    'value': value,
  };
}

final class ZorphyGreaterThan<T, V> extends ZorphyFilter<T> {
  final ZorphyField<T, V> field;
  final V value;

  const ZorphyGreaterThan(this.field, this.value);

  @override
  bool matches(T instance) => _cmp(field.get(instance), value) > 0;

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'gt',
    'value': value,
  };
}

final class ZorphyGreaterThanOrEqual<T, V> extends ZorphyFilter<T> {
  final ZorphyField<T, V> field;
  final V value;

  const ZorphyGreaterThanOrEqual(this.field, this.value);

  @override
  bool matches(T instance) => _cmp(field.get(instance), value) >= 0;

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'gte',
    'value': value,
  };
}

final class ZorphyContains<T> extends ZorphyFilter<T> {
  final ZorphyField<T, Object?> field;
  final String substring;
  final bool caseSensitive;

  const ZorphyContains(this.field, this.substring, {this.caseSensitive = true});

  @override
  bool matches(T instance) {
    final value = field.get(instance);
    if (value is! String) return false;
    if (caseSensitive) return value.contains(substring);
    return value.toLowerCase().contains(substring.toLowerCase());
  }

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'contains',
    'value': substring,
    if (!caseSensitive) 'caseSensitive': false,
  };
}

final class ZorphyStartsWith<T> extends ZorphyFilter<T> {
  final ZorphyField<T, Object?> field;
  final String prefix;

  const ZorphyStartsWith(this.field, this.prefix);

  @override
  bool matches(T instance) {
    final value = field.get(instance);
    return value is String && value.startsWith(prefix);
  }

  @override
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'op': 'startsWith',
    'value': prefix,
  };
}

final class ZorphyAnd<T> extends ZorphyFilter<T> {
  final List<ZorphyFilter<T>> filters;

  const ZorphyAnd(this.filters);

  @override
  bool matches(T instance) => filters.every((f) => f.matches(instance));

  @override
  Map<String, dynamic> toWire() => {
    'op': 'and',
    'filters': [for (final f in filters) f.toWire()],
  };
}

final class ZorphyOr<T> extends ZorphyFilter<T> {
  final List<ZorphyFilter<T>> filters;

  const ZorphyOr(this.filters);

  @override
  bool matches(T instance) => filters.any((f) => f.matches(instance));

  @override
  Map<String, dynamic> toWire() => {
    'op': 'or',
    'filters': [for (final f in filters) f.toWire()],
  };
}

final class ZorphyNot<T> extends ZorphyFilter<T> {
  final ZorphyFilter<T> filter;

  const ZorphyNot(this.filter);

  @override
  bool matches(T instance) => !filter.matches(instance);

  @override
  Map<String, dynamic> toWire() => {'op': 'not', 'filter': filter.toWire()};
}

/// A typed ordering over an entity [T], built from a [ZorphyField].
final class ZorphySort<T> {
  final ZorphyField<T, Object?> field;
  final bool descending;

  const ZorphySort({required this.field, this.descending = false});

  /// The JSON-compatible wire form (`{"field": ..., "descending": ...}`).
  Map<String, dynamic> toWire() => {
    'field': field.pointer,
    'descending': descending,
  };

  /// Rebuilds a typed sort from [toWire] output; [resolve] as in
  /// [ZorphyFilter.fromWire].
  static ZorphySort<T> fromWire<T>(
    Map<String, dynamic> wire,
    ZorphyField<T, Object?>? Function(String pointer) resolve,
  ) {
    final pointer = wire['field'];
    if (pointer is! String) {
      throw FormatException(
        'Invalid ZorphySort wire (field is required): $wire',
      );
    }
    final field = resolve(pointer);
    if (field == null) {
      throw FormatException(
        'Invalid ZorphySort wire (unknown field pointer): $wire',
      );
    }
    return ZorphySort<T>(
      field: field,
      descending: wire['descending'] is bool && wire['descending'],
    );
  }

  /// Orders [a] against [b] by the field; nulls sort last either way.
  int compare(T a, T b) {
    final valA = field.get(a);
    final valB = field.get(b);
    if (valA == null && valB == null) return 0;
    if (valA == null) return 1;
    if (valB == null) return -1;
    var result = 0;
    if (valA is Comparable && valB is Comparable) {
      result = valA.compareTo(valB);
    }
    return descending ? -result : result;
  }

  /// A new list of [items] ordered by this sort.
  List<T> sort(Iterable<T> items) => items.toList()..sort(compare);
}

/// Both operands Comparable: their ordering. A null or non-Comparable
/// operand answers 0 — the caller's operator decides what that means.
int _cmp(Object? a, Object? b) {
  if (a is Comparable && b is Comparable) return a.compareTo(b);
  return 0;
}
