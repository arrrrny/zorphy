/// Minimal structural-equality helpers used by the patch and boundary types.
///
/// These replace `package:collection`'s `ListEquality` / `MapEquality` so
/// `zorphy_annotation` carries no `collection` dependency (issue #233, the
/// #176 zero-dependency gate). Only the deep list/map equality the v3 surface
/// needs is implemented; the semantics match `package:collection` for the
/// `Object?` element types used here.
library;

/// Deep structural equality for [List]s.
const ListEquality<Object?> _listEquality = ListEquality<Object?>();

/// Deep structural equality for [Map]s.
const MapEquality<Object?, Object?> _mapEquality =
    MapEquality<Object?, Object?>();

/// Compares two lists element-by-element (recursively for nested lists/maps).
class ListEquality<T> {
  /// Creates a list-equality comparator.
  const ListEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  /// Whether [a] and [b] are deeply equal.
  bool equals(List<Object?>? a, List<Object?>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  /// Hash of [list] consistent with [equals].
  int hash(Object? list) => list is List
      ? Object.hashAll(list.map(_deepHash))
      : (list == null ? 0 : list.hashCode);
}

/// Compares two maps entry-by-entry (recursively for nested lists/maps).
class MapEquality<K, V> {
  /// Creates a map-equality comparator.
  const MapEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  /// Whether [a] and [b] are deeply equal.
  bool equals(Map<Object?, Object?>? a, Map<Object?, Object?>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (!_deepEquals(entry.value, b[entry.key])) return false;
    }
    return true;
  }

  /// Hash of [map] consistent with [equals].
  int hash(Object? map) => map is Map
      ? Object.hashAllUnordered(
          map.entries.map(
            (e) => Object.hash(_deepHash(e.key), _deepHash(e.value)),
          ),
        )
      : (map == null ? 0 : map.hashCode);
}

/// Shallow content equality for snapshotted outer collections.
bool zorphyCollectionEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  if (a is Set<Object?> && b is Set<Object?>) {
    if (a.length != b.length) return false;
    return a.every(b.contains);
  }
  if (a is Map<Object?, Object?> && b is Map<Object?, Object?>) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

/// Hash compatible with [zorphyCollectionEquals].
int zorphyCollectionHash(Object? value) {
  if (value is List<Object?>) return Object.hashAll(value);
  if (value is Set<Object?>) {
    return value.fold<int>(0, (hash, element) => hash + element.hashCode);
  }
  if (value is Map<Object?, Object?>) {
    return value.entries.fold<int>(
      0,
      (hash, entry) => hash + Object.hash(entry.key, entry.value),
    );
  }
  return value.hashCode;
}

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) return _listEquality.equals(a, b);
  if (a is Map && b is Map) return _mapEquality.equals(a, b);
  return a == b;
}

int _deepHash(Object? value) {
  if (value is List) return _listEquality.hash(value);
  if (value is Map) return _mapEquality.hash(value);
  return value?.hashCode ?? 0;
}
