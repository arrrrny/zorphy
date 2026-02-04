// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex37_changeTo_siblings_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

/// We can also copy to a sibling class.
/// todo: y property on SubA class not properly working. This doesn't quite work yet.
/// Any properties not in the newly created sibling class, the values are lost.
sealed class $Super {
  String get x;

  const $Super._internal();
}

class SubA implements $$Super {
  final String x;

  SubA({
    required this.x,
  });

  SubA copyWith({
    String? x,
  }) {
    return SubA(
      x: x ?? this.x,
    );
  }

  SubA copyWithSubA({
    String? x,
  }) {
    return copyWith(
      x: x,
    );
  }

  SubA patchWithSubA({
    SubAPatch? patchInput,
  }) {
    final _patcher = patchInput ?? SubAPatch();
    final _patchMap = _patcher.toPatch();
    return SubA(
        x: _patchMap.containsKey(SubA$.x)
            ? (_patchMap[SubA$.x] is Function)
                ? _patchMap[SubA$.x](this.x)
                : _patchMap[SubA$.x]
            : this.x);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubA && x == other.x;
  }

  @override
  int get hashCode {
    return Object.hash(x, 0);
  }

  @override
  String toString() {
    return 'SubA(' + 'x: ${x})';
  }
}

enum SubA$ { x }

class SubAPatch implements Patch<SubA> {
  final Map<SubA$, dynamic> _patch = {};

  static SubAPatch create([Map<String, dynamic>? diff]) {
    final patch = SubAPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = SubA$.values.firstWhere((e) => e.name == key);
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

  static SubAPatch fromPatch(Map<SubA$, dynamic> patch) {
    final _patch = SubAPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<SubA$, dynamic> toPatch() => Map.from(_patch);

  SubA applyTo(SubA entity) {
    return entity.patchWithSubA(patchInput: this);
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

  static SubAPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  SubAPatch withX(String? value) {
    _patch[SubA$.x] = value;
    return this;
  }
}

extension SubACompareE on SubA {
  Map<String, dynamic> compareToSubA(SubA other) {
    final Map<String, dynamic> diff = {};

    if (x != other.x) {
      diff['x'] = () => other.x;
    }
    return diff;
  }
}

extension SubAChangeToE on SubA {
  SubB changeToSubB({required String z}) {
    final _patcher = SubBPatch();
    _patcher.withZ(z);
    final _patchMap = _patcher.toPatch();
    return SubB(
        z: _patchMap[SubB$.z],
        x: _patchMap.containsKey(SubB$.x)
            ? (_patchMap[SubB$.x] is Function)
                ? _patchMap[SubB$.x](x)
                : _patchMap[SubB$.x]
            : x);
  }
}

class SubB implements $$Super {
  final String x;
  final String z;

  SubB({
    required this.x,
    required this.z,
  });

  SubB copyWith({
    String? x,
    String? z,
  }) {
    return SubB(
      x: x ?? this.x,
      z: z ?? this.z,
    );
  }

  SubB copyWithSubB({
    String? x,
    String? z,
  }) {
    return copyWith(
      x: x,
      z: z,
    );
  }

  SubB patchWithSubB({
    SubBPatch? patchInput,
  }) {
    final _patcher = patchInput ?? SubBPatch();
    final _patchMap = _patcher.toPatch();
    return SubB(
        x: _patchMap.containsKey(SubB$.x)
            ? (_patchMap[SubB$.x] is Function)
                ? _patchMap[SubB$.x](this.x)
                : _patchMap[SubB$.x]
            : this.x,
        z: _patchMap.containsKey(SubB$.z)
            ? (_patchMap[SubB$.z] is Function)
                ? _patchMap[SubB$.z](this.z)
                : _patchMap[SubB$.z]
            : this.z);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubB && x == other.x && z == other.z;
  }

  @override
  int get hashCode {
    return Object.hash(this.x, this.z);
  }

  @override
  String toString() {
    return 'SubB(' + 'x: ${x}' + ', ' + 'z: ${z})';
  }
}

enum SubB$ { x, z }

class SubBPatch implements Patch<SubB> {
  final Map<SubB$, dynamic> _patch = {};

  static SubBPatch create([Map<String, dynamic>? diff]) {
    final patch = SubBPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = SubB$.values.firstWhere((e) => e.name == key);
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

  static SubBPatch fromPatch(Map<SubB$, dynamic> patch) {
    final _patch = SubBPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<SubB$, dynamic> toPatch() => Map.from(_patch);

  SubB applyTo(SubB entity) {
    return entity.patchWithSubB(patchInput: this);
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

  static SubBPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  SubBPatch withX(String? value) {
    _patch[SubB$.x] = value;
    return this;
  }

  SubBPatch withZ(String? value) {
    _patch[SubB$.z] = value;
    return this;
  }
}

extension SubBCompareE on SubB {
  Map<String, dynamic> compareToSubB(SubB other) {
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
