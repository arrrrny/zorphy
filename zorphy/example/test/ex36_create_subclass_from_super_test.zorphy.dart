// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex36_create_subclass_from_super_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

/// Use .copyToX to create a subclass from a superclass
/// todo: whats the difference between copyToX & cwX
class A extends $A {
  @override
  final String x;

  A({
    required this.x,
  });

  A copyWith({
    String? x,
  }) {
    return A(
      x: x ?? this.x,
    );
  }

  A copyWithA({
    String? x,
  }) {
    return copyWith(
      x: x,
    );
  }

  A patchWithA({
    APatch? patchInput,
  }) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return A(
        x: _patchMap.containsKey(A$.x)
            ? (_patchMap[A$.x] is Function)
                ? _patchMap[A$.x](this.x)
                : _patchMap[A$.x]
            : this.x);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A && x == other.x;
  }

  @override
  int get hashCode {
    return Object.hash(x, 0);
  }

  @override
  String toString() {
    return 'A(' + 'x: ${x})';
  }
}

enum A$ { x }

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
}

extension ACompareE on A {
  Map<String, dynamic> compareToA(A other) {
    final Map<String, dynamic> diff = {};

    if (x != other.x) {
      diff['x'] = () => other.x;
    }
    return diff;
  }
}

extension AChangeToE on A {
  B changeToB({required String y}) {
    final _patcher = BPatch();
    _patcher.withY(y);
    final _patchMap = _patcher.toPatch();
    return B(
        x: _patchMap.containsKey(B$.x)
            ? (_patchMap[B$.x] is Function)
                ? _patchMap[B$.x](this.x)
                : _patchMap[B$.x]
            : this.x,
        y: _patchMap[B$.y],
        x: _patchMap.containsKey(B$.x)
            ? (_patchMap[B$.x] is Function)
                ? _patchMap[B$.x](this.x)
                : _patchMap[B$.x]
            : this.x);
  }
}

class B extends $B implements $A {
  @override
  final String x;
  @override
  final String y;

  B({
    required this.x,
    required this.y,
  });

  B copyWith({
    String? x,
    String? y,
  }) {
    return B(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  B copyWithB({
    String? x,
    String? y,
  }) {
    return copyWith(
      x: x,
      y: y,
    );
  }

  B patchWithB({
    BPatch? patchInput,
  }) {
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
            : this.y);
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
