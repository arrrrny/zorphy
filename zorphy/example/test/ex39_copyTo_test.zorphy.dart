// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex39_copyTo_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

sealed class $Super {
  String get x;

  const $Super._internal();
}

class A implements $$Super {
  final String x;
  final String z;

  A({required this.x, required this.z});

  A copyWith({String? x, String? z}) {
    return A(x: x ?? this.x, z: z ?? this.z);
  }

  A copyWithA({String? x, String? z}) {
    return copyWith(x: x, z: z);
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
      z: _patchMap.containsKey(A$.z)
          ? (_patchMap[A$.z] is Function)
                ? _patchMap[A$.z](this.z)
                : _patchMap[A$.z]
          : this.z,
    );
  }

  A copyWithSuper({String? x}) {
    return copyWith(x: x);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A && x == other.x && z == other.z;
  }

  @override
  int get hashCode {
    return Object.hash(this.x, this.z);
  }

  @override
  String toString() {
    return 'A(' + 'x: ${x}' + ', ' + 'z: ${z})';
  }
}

enum A$ { x, z }

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

  APatch withX(String? value) {
    _patch[A$.x] = value;
    return this;
  }

  APatch withZ(String? value) {
    _patch[A$.z] = value;
    return this;
  }
}

extension ACompareE on A {
  Map<String, dynamic> compareToA(A other) {
    final Map<String, dynamic> diff = {};

    if (x != other.x) {
      diff['x'] = () => other.x;
    }
    if (z != other.z) {
      diff['z'] = () => other.z;
    }
    return diff;
  }
}

class B implements $$Super {
  final String x;
  final String y;

  B({required this.x, required this.y});

  B copyWith({String? x, String? y}) {
    return B(x: x ?? this.x, y: y ?? this.y);
  }

  B copyWithB({String? x, String? y}) {
    return copyWith(x: x, y: y);
  }

  B patchWithB({BPatch? patchInput}) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return B(
      x: _patchMap.containsKey(B$.x)
          ? (_patchMap[B$.x] is Function)
                ? _patchMap[B$.x](this.x)
                : _patchMap[B$.x]
          : this.x,
      y: _patchMap.containsKey(B$.y)
          ? (_patchMap[B$.y] is Function)
                ? _patchMap[B$.y](this.y)
                : _patchMap[B$.y]
          : this.y,
    );
  }

  B copyWithSuper({String? x}) {
    return copyWith(x: x);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is B && x == other.x && y == other.y;
  }

  @override
  int get hashCode {
    return Object.hash(this.x, this.y);
  }

  @override
  String toString() {
    return 'B(' + 'x: ${x}' + ', ' + 'y: ${y})';
  }
}

enum B$ { x, y }

class BPatch implements Patch<B> {
  final Map<B$, dynamic> _patch = {};

  static BPatch create([Map<String, dynamic>? diff]) {
    final patch = BPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = B$.values.firstWhere((e) => e.name == key);
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

  static BPatch fromPatch(Map<B$, dynamic> patch) {
    final _patch = BPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<B$, dynamic> toPatch() => Map.from(_patch);

  B applyTo(B entity) {
    return entity.patchWithB(patchInput: this);
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

  static BPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  BPatch withX(String? value) {
    _patch[B$.x] = value;
    return this;
  }

  BPatch withY(String? value) {
    _patch[B$.y] = value;
    return this;
  }
}

extension BCompareE on B {
  Map<String, dynamic> compareToB(B other) {
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
