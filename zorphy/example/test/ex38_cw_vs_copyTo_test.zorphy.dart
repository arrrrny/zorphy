// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex38_cw_vs_copyTo_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

///copyToX converts the class to that new X class
///cwX, if actually a Y class, copies the new class but only specifies the X fields
sealed class $Super {
  String get x;

  const $Super._internal();
}

class SubA implements $$Super {
  final String x;

  SubA({required this.x});

  SubA copyWith({String? x}) {
    return SubA(x: x ?? this.x);
  }

  SubA copyWithSubA({String? x}) {
    return copyWith(x: x);
  }

  SubA patchWithSubA({SubAPatch? patchInput}) {
    final _patcher = patchInput ?? SubAPatch();
    final _patchMap = _patcher.toPatch();
    return SubA(
      x: _patchMap.containsKey(SubA$.x)
          ? (_patchMap[SubA$.x] is Function)
                ? _patchMap[SubA$.x](this.x)
                : _patchMap[SubA$.x]
          : this.x,
    );
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
  SubB changeToSubB({required String z, required List<C> cs}) {
    final _patcher = SubBPatch();
    _patcher.withZ(z);
    _patcher.withCs(cs);
    final _patchMap = _patcher.toPatch();
    return SubB(
      z: _patchMap[SubB$.z],
      cs: _patchMap[SubB$.cs],
      x: _patchMap.containsKey(SubB$.x)
          ? (_patchMap[SubB$.x] is Function)
                ? _patchMap[SubB$.x](x)
                : _patchMap[SubB$.x]
          : x,
    );
  }
}

class SubB implements $$Super {
  final String x;
  final String z;
  final List<C> cs;

  SubB({required this.x, required this.z, required this.cs});

  SubB._copyWith({String? x, String? z, List<C>? cs})
    : x =
          x ??
          (() {
            throw ArgumentError("x is required");
          })(),
      z =
          z ??
          (() {
            throw ArgumentError("z is required");
          })(),
      cs =
          cs ??
          (() {
            throw ArgumentError("cs is required");
          })();

  SubB copyWith({String? x, String? z, List<C>? cs}) {
    return SubB(x: x ?? this.x, z: z ?? this.z, cs: cs ?? this.cs);
  }

  SubB copyWithSubB({String? x, String? z, List<C>? cs}) {
    return copyWith(x: x, z: z, cs: cs);
  }

  SubB copyWithFn({
    String? Function(String?)? x,
    String? Function(String?)? z,
    List<C>? Function(List<C>?)? cs,
  }) {
    return SubB(
      x: x != null ? x(this.x) : this.x,
      z: z != null ? z(this.z) : this.z,
      cs: cs != null ? cs(this.cs) : this.cs,
    );
  }

  SubB patchWithSubB({SubBPatch? patchInput}) {
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
          : this.z,
      cs: _patchMap.containsKey(SubB$.cs)
          ? (_patchMap[SubB$.cs] is Function)
                ? _patchMap[SubB$.cs](this.cs)
                : _patchMap[SubB$.cs]
          : this.cs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubB && x == other.x && z == other.z && cs == other.cs;
  }

  @override
  int get hashCode {
    return Object.hash(this.x, this.z, this.cs);
  }

  @override
  String toString() {
    return 'SubB(' + 'x: ${x}' + ', ' + 'z: ${z}' + ', ' + 'cs: ${cs})';
  }
}

enum SubB$ { x, z, cs }

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

  SubBPatch withCs(List<C>? value) {
    _patch[SubB$.cs] = value;
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
    if (cs != other.cs) {
      diff['cs'] = () => other.cs;
    }
    return diff;
  }
}

class C extends $C {
  @override
  final String m;

  C({required this.m});

  C copyWith({String? m}) {
    return C(m: m ?? this.m);
  }

  C copyWithC({String? m}) {
    return copyWith(m: m);
  }

  C patchWithC({CPatch? patchInput}) {
    final _patcher = patchInput ?? CPatch();
    final _patchMap = _patcher.toPatch();
    return C(
      m: _patchMap.containsKey(C$.m)
          ? (_patchMap[C$.m] is Function)
                ? _patchMap[C$.m](this.m)
                : _patchMap[C$.m]
          : this.m,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is C && m == other.m;
  }

  @override
  int get hashCode {
    return Object.hash(m, 0);
  }

  @override
  String toString() {
    return 'C(' + 'm: ${m})';
  }
}

enum C$ { m }

class CPatch implements Patch<C> {
  final Map<C$, dynamic> _patch = {};

  static CPatch create([Map<String, dynamic>? diff]) {
    final patch = CPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = C$.values.firstWhere((e) => e.name == key);
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

  static CPatch fromPatch(Map<C$, dynamic> patch) {
    final _patch = CPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<C$, dynamic> toPatch() => Map.from(_patch);

  C applyTo(C entity) {
    return entity.patchWithC(patchInput: this);
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

  static CPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  CPatch withM(String? value) {
    _patch[C$.m] = value;
    return this;
  }
}

extension CCompareE on C {
  Map<String, dynamic> compareToC(C other) {
    final Map<String, dynamic> diff = {};

    if (m != other.m) {
      diff['m'] = () => other.m;
    }
    return diff;
  }
}
