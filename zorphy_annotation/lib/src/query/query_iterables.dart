import '../query/filter.dart';
import '../query/sort.dart';

/// Extension methods for in-memory querying of iterables
extension ZorphyQueryIterableExt<T> on Iterable<T> {
  /// Filters the iterable using the given [filter].
  /// If [filter] is null, returns the original iterable.
  Iterable<T> filter(Filter<T>? filter) {
    if (filter == null) return this;
    return where((item) => filter.matches(item));
  }

  /// Sorts the iterable using the given [sort] configuration.
  /// If [sort] is null, returns the original iterable as a list.
  /// Returns a new sorted list (non-mutating).
  List<T> orderBy(Sort<T>? sort) {
    if (sort == null) return toList();
    final list = toList();
    list.sort((a, b) => sort.compare(a, b));
    return list;
  }
}
