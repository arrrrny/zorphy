// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex57_change_to_parent_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class A extends $A {
  @override
  final String id;

  A({
    required this.id,
  });

  A copyWith({
    String? id,
  }) {
    return A(
      id: id ?? this.id,
    );
  }

  A copyWithA({
    String? id,
  }) {
    return copyWith(
      id: id,
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
            : this.id);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A && id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(id, 0);
  }

  @override
  String toString() {
    return 'A(' + 'id: ${id})';
  }
}

enum A$ { id }

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
}

extension ACompareE on A {
  Map<String, dynamic> compareToA(A other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    return diff;
  }
}

extension AChangeToE on A {
  B changeToB({required String blah}) {
    final _patcher = BPatch();
    _patcher.withBlah(blah);
    final _patchMap = _patcher.toPatch();
    return B(
        blah: _patchMap[B$.blah],
        id: _patchMap.containsKey(B$.id)
            ? (_patchMap[B$.id] is Function)
                ? _patchMap[B$.id](this.id)
                : _patchMap[B$.id]
            : this.id);
  }

  C changeToC({required String xyz}) {
    final _patcher = CPatch();
    _patcher.withXyz(xyz);
    final _patchMap = _patcher.toPatch();
    return C(
        xyz: _patchMap[C$.xyz],
        id: _patchMap.containsKey(C$.id)
            ? (_patchMap[C$.id] is Function)
                ? _patchMap[C$.id](this.id)
                : _patchMap[C$.id]
            : this.id);
  }
}

class B extends $B implements $A {
  @override
  final String id;
  @override
  final String blah;

  B({
    required this.id,
    required this.blah,
  });

  B copyWith({
    String? id,
    String? blah,
  }) {
    return B(
      id: id ?? this.id,
      blah: blah ?? this.blah,
    );
  }

  B copyWithB({
    String? id,
    String? blah,
  }) {
    return copyWith(
      id: id,
      blah: blah,
    );
  }

  B patchWithB({
    BPatch? patchInput,
  }) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return B(
        id: _patchMap.containsKey(B$.id)
            ? (_patchMap[B$.id] is Function)
                ? _patchMap[B$.id](this.id)
                : _patchMap[B$.id]
            : this.id,
        blah: _patchMap.containsKey(B$.blah)
            ? (_patchMap[B$.blah] is Function)
                ? _patchMap[B$.blah](this.blah)
                : _patchMap[B$.blah]
            : this.blah);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is B && id == other.id && blah == other.blah;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.blah);
  }

  @override
  String toString() {
    return 'B(' + 'id: ${id}' + ', ' + 'blah: ${blah})';
  }
}

enum B$ { id, blah }

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

  BPatch withId(String? value) {
    _patch[B$.id] = value;
    return this;
  }

  BPatch withBlah(String? value) {
    _patch[B$.blah] = value;
    return this;
  }
}

extension BCompareE on B {
  Map<String, dynamic> compareToB(B other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (blah != other.blah) {
      diff['blah'] = () => other.blah;
    }
    return diff;
  }
}

class C extends $C implements $A {
  @override
  final String id;
  @override
  final String xyz;

  C({
    required this.id,
    required this.xyz,
  });

  C copyWith({
    String? id,
    String? xyz,
  }) {
    return C(
      id: id ?? this.id,
      xyz: xyz ?? this.xyz,
    );
  }

  C copyWithC({
    String? id,
    String? xyz,
  }) {
    return copyWith(
      id: id,
      xyz: xyz,
    );
  }

  C patchWithC({
    CPatch? patchInput,
  }) {
    final _patcher = patchInput ?? CPatch();
    final _patchMap = _patcher.toPatch();
    return C(
        id: _patchMap.containsKey(C$.id)
            ? (_patchMap[C$.id] is Function)
                ? _patchMap[C$.id](this.id)
                : _patchMap[C$.id]
            : this.id,
        xyz: _patchMap.containsKey(C$.xyz)
            ? (_patchMap[C$.xyz] is Function)
                ? _patchMap[C$.xyz](this.xyz)
                : _patchMap[C$.xyz]
            : this.xyz);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is C && id == other.id && xyz == other.xyz;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.xyz);
  }

  @override
  String toString() {
    return 'C(' + 'id: ${id}' + ', ' + 'xyz: ${xyz})';
  }
}

enum C$ { id, xyz }

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

  CPatch withId(String? value) {
    _patch[C$.id] = value;
    return this;
  }

  CPatch withXyz(String? value) {
    _patch[C$.xyz] = value;
    return this;
  }
}

extension CCompareE on C {
  Map<String, dynamic> compareToC(C other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (xyz != other.xyz) {
      diff['xyz'] = () => other.xyz;
    }
    return diff;
  }
}
