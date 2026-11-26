/// The typed field descriptor behind the generated `<Entity>Fields` classes
/// (issue #247).
///
/// A [ZorphyField] is one field of an entity [T]: its name, wire key, JSON
/// Pointer, and the get/set pair that reads and rebuilds the entity — the
/// same accessor shape the lens layer emits, exposed as a first-class,
/// queryable descriptor. Generated code emits one `static const` per payload
/// field on `abstract final class <Entity>Fields`; the descriptor's methods
/// build [ZorphyFilter]/[ZorphySort] predicates
/// (`price.lessThan(100)`, `id.startsWith('p')`, `name.asc()`) and its
/// [lens] bridge converts it to a [ZorphyLens] so consumers of the lens API
/// can take a field where a lens is expected — this library builds on the
/// lens layer rather than duplicating it.
library;

import 'lens.dart';
import 'zorphy_query_predicates.dart';

/// A typed accessor and query handle for one value [V] inside an entity [T].
final class ZorphyField<T, V> {
  /// The field name, exactly as declared on the entity.
  final String name;

  /// The wire key the generated codec reads and writes — the v3 wire key IS
  /// the field name.
  final String jsonKey;

  /// The RFC 6901 JSON Pointer addressing the field on the wire
  /// (e.g. `/price`).
  final String pointer;

  /// Reads the field value out of [instance].
  final V Function(T instance) get;

  /// Returns a copy of [instance] with only this field replaced by [value].
  final T Function(T instance, V value) set;

  const ZorphyField({
    required this.name,
    required this.jsonKey,
    required this.pointer,
    required this.get,
    required this.set,
  });

  /// This field as a lens over the entity — the lens layer's accessor,
  /// unchanged.
  ZorphyLens<T, V> get lens =>
      ZorphyLens<T, V>(path: pointer, get: get, set: set);

  /// This field with its value type erased to [Object], so it can sit in a
  /// heterogeneous `<Entity>Fields.all` registry and still be WRITTEN through.
  ///
  /// [set] is a function-typed field, which makes this class invariant in
  /// [V]: a `ZorphyField<T, String>` is not a `ZorphyField<T, Object?>`, and
  /// Dart only reports that when `.set` is first read (zorphy#301). The
  /// erased field is a NEW descriptor whose `set` takes any value and
  /// performs the `as V` check itself, so a correctly typed value goes
  /// through and a mistyped one fails as a [TypeError] — the same contract
  /// `copyWith` has.
  ZorphyField<T, Object?> get asObject => ZorphyField<T, Object?>(
    name: name,
    jsonKey: jsonKey,
    pointer: pointer,
    get: (instance) => this.get(instance),
    set: (instance, value) => this.set(instance, value as V),
  );

  /// Matches when the field equals [value].
  ZorphyFilter<T> equals(V value) => ZorphyEquals<T, V>(this, value);

  /// Matches when the field differs from [value].
  ZorphyFilter<T> notEquals(V value) => ZorphyNotEquals<T, V>(this, value);

  /// Matches when the field is one of [values].
  ZorphyFilter<T> isIn(Iterable<V> values) =>
      ZorphyIn<T, V>(this, List<V>.unmodifiable(values));

  /// Matches when the field is absent (`null` at runtime).
  ZorphyFilter<T> isNull() => ZorphyIsNull<T>(this);

  /// Matches when the field is present (non-`null` at runtime).
  ZorphyFilter<T> isNotNull() => ZorphyIsNotNull<T>(this);

  /// An ascending order over this field.
  ZorphySort<T> asc() => ZorphySort<T>(field: this, descending: false);

  /// A descending order over this field.
  ZorphySort<T> desc() => ZorphySort<T>(field: this, descending: true);

  /// Matches when this field's value — or any element of it, when the value
  /// is an [Iterable] — matches [inner], a predicate over the nested value
  /// (issue #303).
  ///
  /// [inner]'s element type is unchecked: [ZorphyNested.filter] holds a
  /// `ZorphyFilter<dynamic>`, so a predicate built over the wrong type
  /// compiles but silently never matches at runtime. Build [inner] over the
  /// nested value's actual type (Dart cannot express its element type here).
  ZorphyFilter<T> nested(ZorphyFilter<dynamic> inner) =>
      ZorphyNested<T, V>(this, inner);

  @override
  String toString() => '$name($pointer)';
}

/// Ordering predicates for fields whose value is [Comparable] — the shapes
/// `double`, `int`, `String`, `DateTime` and friends.
extension ZorphyComparableFieldX<T, V extends Comparable<Object>>
    on ZorphyField<T, V> {
  /// Matches when the field orders before [value].
  ZorphyFilter<T> lessThan(V value) => ZorphyLessThan<T, V>(this, value);

  /// Matches when the field orders before or at [value].
  ZorphyFilter<T> lessThanOrEqual(V value) =>
      ZorphyLessThanOrEqual<T, V>(this, value);

  /// Matches when the field orders after [value].
  ZorphyFilter<T> greaterThan(V value) => ZorphyGreaterThan<T, V>(this, value);

  /// Matches when the field orders after or at [value].
  ZorphyFilter<T> greaterThanOrEqual(V value) =>
      ZorphyGreaterThanOrEqual<T, V>(this, value);
}

/// Substring predicates for `String` fields.
extension ZorphyStringFieldX<T> on ZorphyField<T, String> {
  /// Matches when the field contains [substring].
  ZorphyFilter<T> contains(String substring, {bool caseSensitive = true}) =>
      ZorphyContains<T>(this, substring, caseSensitive: caseSensitive);

  /// Matches when the field starts with [prefix].
  ZorphyFilter<T> startsWith(String prefix) =>
      ZorphyStartsWith<T>(this, prefix);
}

/// Wire resolution over a generated `<Entity>Fields.all` list.
extension ZorphyFieldListX<T> on List<ZorphyField<T, Object?>> {
  /// The field addressed by [pointer], or `null`.
  ZorphyField<T, Object?>? byPointer(String pointer) {
    for (final field in this) {
      if (field.pointer == pointer) return field;
    }
    return null;
  }
}
