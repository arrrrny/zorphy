// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex48_json_with_subtype_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

/// Every subtype needs to also implement toJson & fromJson
@JsonSerializable(explicitToJson: true)
class A extends $A {
  @override
  final String id;
  @override
  final X x;
  @override
  final List<X> xs;

  A({
    required this.id,
    required this.x,
    required this.xs,
  });

  A copyWith({
    String? id,
    X? x,
    List<X>? xs,
  }) {
    return A(
      id: id ?? this.id,
      x: x ?? this.x,
      xs: xs ?? this.xs,
    );
  }

  A copyWithA({
    String? id,
    X? x,
    List<X>? xs,
  }) {
    return copyWith(
      id: id,
      x: x,
      xs: xs,
    );
  }

  A patchWithA({
    APatch? patchInput,
  }) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return A(
        id: _patchMap.containsKey(A$.id)
            ? (_patchMap[A$.id] is Function)
                ? _patchMap[A$.id](this.id)
                : _patchMap[A$.id]
            : this.id,
        x: _patchMap.containsKey(A$.x)
            ? (_patchMap[A$.x] is Function)
                ? _patchMap[A$.x](this.x)
                : _patchMap[A$.x]
            : this.x,
        xs: _patchMap.containsKey(A$.xs)
            ? (_patchMap[A$.xs] is Function)
                ? _patchMap[A$.xs](this.xs)
                : _patchMap[A$.xs]
            : this.xs);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A && id == other.id && x == other.x && xs == other.xs;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.x, this.xs);
  }

  @override
  String toString() {
    return 'A(' + 'id: ${id}' + ', ' + 'x: ${x}' + ', ' + 'xs: ${xs})';
  }

  /// Creates a [A] instance from JSON
  factory A.fromJson(Map<String, dynamic> json) => _$AFromJson(json);
}

enum A$ { id, x, xs }

class APatch implements Patch<A> {
  final Map<A$, dynamic> _patch = {};

  static APatch create([Map<String, dynamic>? diff]) {
    final patch = APatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = A$.values.firstWhere((e) => e.name == key);
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static APatch fromPatch(Map<A$, dynamic> patch) {
    final _patch = APatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<A$, dynamic> toPatch() => Map.from(_patch);

  A applyTo(A entity) {
    return entity.patchWithA(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static APatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  APatch withId(String? value) {
    _patch[A$.id] = value;
    return this;
  }

  APatch withX(X? value) {
    _patch[A$.x] = value;
    return this;
  }

  APatch withXs(List<X>? value) {
    _patch[A$.xs] = value;
    return this;
  }
}

extension ASerialization on A {
  Map<String, dynamic> toJson() => _$AToJson(this);
}

extension ACompareE on A {
  Map<String, dynamic> compareToA(A other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (x != other.x) {
      diff['x'] = () => other.x;
    }
    if (xs != other.xs) {
      diff['xs'] = () => other.xs;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class X extends $X {
  @override
  final List<int> items;

  X({
    required this.items,
  });

  X copyWith({
    List<int>? items,
  }) {
    return X(
      items: items ?? this.items,
    );
  }

  X copyWithX({
    List<int>? items,
  }) {
    return copyWith(
      items: items,
    );
  }

  X patchWithX({
    XPatch? patchInput,
  }) {
    final _patcher = patchInput ?? XPatch();
    final _patchMap = _patcher.toPatch();
    return X(
        items: _patchMap.containsKey(X$.items)
            ? (_patchMap[X$.items] is Function)
                ? _patchMap[X$.items](this.items)
                : _patchMap[X$.items]
            : this.items);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is X && items == other.items;
  }

  @override
  int get hashCode {
    return Object.hash(items, 0);
  }

  @override
  String toString() {
    return 'X(' + 'items: ${items})';
  }

  /// Creates a [X] instance from JSON
  factory X.fromJson(Map<String, dynamic> json) => _$XFromJson(json);
}

enum X$ { items }

class XPatch implements Patch<X> {
  final Map<X$, dynamic> _patch = {};

  static XPatch create([Map<String, dynamic>? diff]) {
    final patch = XPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = X$.values.firstWhere((e) => e.name == key);
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static XPatch fromPatch(Map<X$, dynamic> patch) {
    final _patch = XPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<X$, dynamic> toPatch() => Map.from(_patch);

  X applyTo(X entity) {
    return entity.patchWithX(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static XPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  XPatch withItems(List<int>? value) {
    _patch[X$.items] = value;
    return this;
  }
}

extension XSerialization on X {
  Map<String, dynamic> toJson() => _$XToJson(this);
}

extension XCompareE on X {
  Map<String, dynamic> compareToX(X other) {
    final Map<String, dynamic> diff = {};

    if (items != other.items) {
      diff['items'] = () => other.items;
    }
    return diff;
  }
}
