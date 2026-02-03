// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex60_copywith_generic_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class A<T> extends $A {
  @override
  final T x;
  @override
  final T y;

  A({required this.x, required this.y});

  A._copyWith({T? x, T? y})
    : x =
          x ??
          (() {
            throw ArgumentError("x is required");
          })(),
      y =
          y ??
          (() {
            throw ArgumentError("y is required");
          })();

  A copyWith({T? x, T? y}) {
    return A(x: x ?? this.x, y: y ?? this.y);
  }

  A copyWithA({T? x, T? y}) {
    return copyWith(x: x, y: y);
  }

  A copyWithFn({T? Function(T?)? x, T? Function(T?)? y}) {
    return A(
      x: x != null ? x(this.x) : this.x,
      y: y != null ? y(this.y) : this.y,
    );
  }

  A patchWithA({APatch? patchInput}) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return A(
      x: _patchMap.containsKey(A$.x)
          ? (_patchMap[A$.x] is Function)
                ? _patchMap[A$.x](this.x)
                : _patchMap[A$.x]
          : this.x,
      y: _patchMap.containsKey(A$.y)
          ? (_patchMap[A$.y] is Function)
                ? _patchMap[A$.y](this.y)
                : _patchMap[A$.y]
          : this.y,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A && x == other.x && y == other.y;
  }

  @override
  int get hashCode {
    return Object.hash(this.x, this.y);
  }

  @override
  String toString() {
    return 'A(' + 'x: ${x}' + ', ' + 'y: ${y})';
  }
}

enum A$ { x, y }

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

  APatch withX(dynamic value) {
    _patch[A$.x] = value;
    return this;
  }

  APatch withY(dynamic value) {
    _patch[A$.y] = value;
    return this;
  }
}

extension ACompareE on A {
  Map<String, dynamic> compareToA(A other) {
    final Map<String, dynamic> diff = {};

    if (x != other.x) {
      diff['x'] = () => other.x;
    }
    if (y != other.y) {
      diff['y'] = () => other.y;
    }
    return diff;
  }
}
