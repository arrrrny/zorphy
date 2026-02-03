/// Enhanced List type for Zorphy with additional functionality
class List_E<E> {
  final List<E> _list;

  const List_E(this._list);

  List<E> get list => _list;

  /// Creates an empty List_E
  factory List_E.empty() => List_E(<E>[]);

  /// Creates a fixed-length list
  factory List_E.filled(int length, E fill) => List_E(List.filled(length, fill));

  /// Creates a growable list with the specified length
  factory List_E.growable([int length = 0]) {
    if (length == 0) {
      return List_E(<E>[]);
    }
    return List_E(List.filled(length, null as E));
  }

  /// Creates a list from an iterable
  factory List_E.from(Iterable<E> elements) => List_E(List.from(elements));

  /// Creates a list with [length] positions and fills each position with [generator]
  factory List_E.generate(int length, E Function(int index) generator) =>
      List_E(List.generate(length, generator));

  int get length => _list.length;

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) {
    _list[index] = value;
  }

  void add(E value) => _list.add(value);

  void addAll(Iterable<E> iterable) => _list.addAll(iterable);

  bool remove(Object? value) => _list.remove(value);

  void clear() => _list.clear();

  Iterator<E> get iterator => _list.iterator;

  List_E<R> map<R>(R Function(E e) f) => List_E(_list.map(f).toList());

  List_E<E> where(bool Function(E e) f) => List_E(_list.where(f).toList());

  /// Returns a new List_E with the first n elements
  List_E<E> take(int n) => List_E(_list.take(n).toList());

  /// Returns a new List_E without the first n elements
  List_E<E> skip(int n) => List_E(_list.skip(n).toList());

  /// Adds all elements of [other] to the end of this list
  void insertAll(int index, Iterable<E> iterable) => _list.insertAll(index, iterable);

  /// Removes a range of elements from [start] to [end]
  void removeRange(int start, int end) => _list.removeRange(start, end);

  /// Sorts this list according to the order specified by the [compare] function
  void sort([int Function(E a, E b)? compare]) => _list.sort(compare);

  @override
  String toString() => _list.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is List_E &&
          runtimeType == other.runtimeType &&
          _list.length == other._list.length &&
          _list.every((element) => other._list[_list.indexOf(element)] == element);

  @override
  int get hashCode => _list.hashCode;
}