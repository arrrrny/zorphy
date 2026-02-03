// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex52_json_inheritance_generic_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class A<T1> extends $A {
  @override
  final T1 id;
  @override
  final Object? Function(T1)? toJson_T1;

  A({required this.id, this.toJson_T1});

  A copyWith({T1? id, Object? Function(T1)? toJson_T1}) {
    return A(id: id ?? this.id, toJson_T1: toJson_T1 ?? this.toJson_T1);
  }

  A copyWithA({T1? id, Object? Function(T1)? toJson_T1}) {
    return copyWith(id: id, toJson_T1: toJson_T1);
  }

  A patchWithA({APatch? patchInput}) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return A(
      id: _patchMap.containsKey(A$.id)
          ? (_patchMap[A$.id] is Function)
                ? _patchMap[A$.id](this.id)
                : _patchMap[A$.id]
          : this.id,
      toJson_T1: _patchMap.containsKey(A$.toJson_T1)
          ? (_patchMap[A$.toJson_T1] is Function)
                ? _patchMap[A$.toJson_T1](this.toJson_T1)
                : _patchMap[A$.toJson_T1]
          : this.toJson_T1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A && id == other.id && toJson_T1 == other.toJson_T1;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.toJson_T1);
  }

  @override
  String toString() {
    return 'A(' + 'id: ${id}' + ', ' + 'toJson_T1: ${toJson_T1})';
  }

  /// Creates a [A] instance from JSON
  factory A.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$AFromJson(json);
    }
    if (json['_className_'] == "C") {
      var fn_fromJson = getFromJsonToGenericFn(C_Generics_Sing().fns, json, [
        '_T1_',
        '_T2_',
      ]);
      return fn_fromJson(json);
    } else if (json['_className_'] == "B") {
      var fn_fromJson = getFromJsonToGenericFn(B_Generics_Sing().fns, json, [
        '_T1_',
        '_T2_',
      ]);
      return fn_fromJson(json);
    } else if (json['_className_'] == "A") {
      var fn_fromJson = getFromJsonToGenericFn(A_Generics_Sing().fns, json, [
        '_T1_',
      ]);
      return fn_fromJson(json);
    }
    throw UnsupportedError(
      "The _className_ '${json['_className_']}' is not supported by the A.fromJson constructor.",
    );
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum A$ { id, toJson_T1 }

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

  APatch withId(dynamic value) {
    _patch[A$.id] = value;
    return this;
  }

  APatch withToJson_T1(Object? Function(T1)? value) {
    _patch[A$.toJson_T1] = value;
    return this;
  }
}

extension ASerialization on A<T1> {
  Map<String, dynamic> toJson() => _$AToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
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
  C changeToC({
    required String xyz,
    required T1 valT1,
    required T2 valT2,
    Object? Function(T2)? toJson_T2,
    required T blah,
    Object? Function(T)? toJson_T,
    Object? Function(T1)? toJson_T1,
  }) {
    final _patcher = CPatch();
    _patcher.withXyz(xyz);
    _patcher.withValT1(valT1);
    _patcher.withValT2(valT2);
    if (toJson_T2 != null) {
      _patcher.withToJson_T2(toJson_T2);
    }
    _patcher.withBlah(blah);
    if (toJson_T != null) {
      _patcher.withToJson_T(toJson_T);
    }
    if (toJson_T1 != null) {
      _patcher.withToJson_T1(toJson_T1);
    }
    final _patchMap = _patcher.toPatch();
    return C(
      xyz: _patchMap[C$.xyz],
      valT1: _patchMap[C$.valT1],
      valT2: _patchMap[C$.valT2],
      toJson_T1: _patchMap.containsKey(C$.toJson_T1)
          ? (_patchMap[C$.toJson_T1] is Function)
                ? _patchMap[C$.toJson_T1](toJson_T1)
                : _patchMap[C$.toJson_T1]
          : toJson_T1,
      toJson_T2: _patchMap.containsKey(C$.toJson_T2)
          ? (_patchMap[C$.toJson_T2] is Function)
                ? _patchMap[C$.toJson_T2](toJson_T2)
                : _patchMap[C$.toJson_T2]
          : toJson_T2,
      id: _patchMap.containsKey(C$.id)
          ? (_patchMap[C$.id] is Function)
                ? _patchMap[C$.id](id)
                : _patchMap[C$.id]
          : id,
      blah: _patchMap[C$.blah],
      toJson_T: _patchMap.containsKey(C$.toJson_T)
          ? (_patchMap[C$.toJson_T] is Function)
                ? _patchMap[C$.toJson_T](toJson_T)
                : _patchMap[C$.toJson_T]
          : toJson_T,
    );
  }

  B changeToB({
    required T1 valT1,
    required T2 valT2,
    Object? Function(T2)? toJson_T2,
    Object? Function(T1)? toJson_T1,
  }) {
    final _patcher = BPatch();
    _patcher.withValT1(valT1);
    _patcher.withValT2(valT2);
    if (toJson_T2 != null) {
      _patcher.withToJson_T2(toJson_T2);
    }
    if (toJson_T1 != null) {
      _patcher.withToJson_T1(toJson_T1);
    }
    final _patchMap = _patcher.toPatch();
    return B(
      valT1: _patchMap[B$.valT1],
      valT2: _patchMap[B$.valT2],
      toJson_T1: _patchMap.containsKey(B$.toJson_T1)
          ? (_patchMap[B$.toJson_T1] is Function)
                ? _patchMap[B$.toJson_T1](toJson_T1)
                : _patchMap[B$.toJson_T1]
          : toJson_T1,
      toJson_T2: _patchMap.containsKey(B$.toJson_T2)
          ? (_patchMap[B$.toJson_T2] is Function)
                ? _patchMap[B$.toJson_T2](toJson_T2)
                : _patchMap[B$.toJson_T2]
          : toJson_T2,
      id: _patchMap.containsKey(B$.id)
          ? (_patchMap[B$.id] is Function)
                ? _patchMap[B$.id](id)
                : _patchMap[B$.id]
          : id,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class B<T1, T2> extends $B implements A {
  @override
  final T1 id;
  @override
  final Object? Function(T1)? toJson_T1;
  @override
  final T1 valT1;
  @override
  final T2 valT2;
  @override
  final Object? Function(T2)? toJson_T2;

  B({
    required this.id,
    this.toJson_T1,
    required this.valT1,
    required this.valT2,
    this.toJson_T2,
  });

  B copyWith({
    T1? id,
    Object? Function(T1)? toJson_T1,
    T1? valT1,
    T2? valT2,
    Object? Function(T2)? toJson_T2,
  }) {
    return B(
      id: id ?? this.id,
      toJson_T1: toJson_T1 ?? this.toJson_T1,
      valT1: valT1 ?? this.valT1,
      valT2: valT2 ?? this.valT2,
      toJson_T2: toJson_T2 ?? this.toJson_T2,
    );
  }

  B copyWithB({
    T1? id,
    Object? Function(T1)? toJson_T1,
    T1? valT1,
    T2? valT2,
    Object? Function(T2)? toJson_T2,
  }) {
    return copyWith(
      id: id,
      toJson_T1: toJson_T1,
      valT1: valT1,
      valT2: valT2,
      toJson_T2: toJson_T2,
    );
  }

  B patchWithB({BPatch? patchInput}) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return B(
      id: _patchMap.containsKey(B$.id)
          ? (_patchMap[B$.id] is Function)
                ? _patchMap[B$.id](this.id)
                : _patchMap[B$.id]
          : this.id,
      toJson_T1: _patchMap.containsKey(B$.toJson_T1)
          ? (_patchMap[B$.toJson_T1] is Function)
                ? _patchMap[B$.toJson_T1](this.toJson_T1)
                : _patchMap[B$.toJson_T1]
          : this.toJson_T1,
      valT1: _patchMap.containsKey(B$.valT1)
          ? (_patchMap[B$.valT1] is Function)
                ? _patchMap[B$.valT1](this.valT1)
                : _patchMap[B$.valT1]
          : this.valT1,
      valT2: _patchMap.containsKey(B$.valT2)
          ? (_patchMap[B$.valT2] is Function)
                ? _patchMap[B$.valT2](this.valT2)
                : _patchMap[B$.valT2]
          : this.valT2,
      toJson_T2: _patchMap.containsKey(B$.toJson_T2)
          ? (_patchMap[B$.toJson_T2] is Function)
                ? _patchMap[B$.toJson_T2](this.toJson_T2)
                : _patchMap[B$.toJson_T2]
          : this.toJson_T2,
    );
  }

  B copyWithA({T1? id, Object? Function(T1)? toJson_T1}) {
    return copyWith(id: id, toJson_T1: toJson_T1);
  }

  B patchWithA({APatch? patchInput}) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return B(
      id: _patchMap.containsKey(A$.id)
          ? (_patchMap[A$.id] is Function)
                ? _patchMap[A$.id](this.id)
                : _patchMap[A$.id]
          : this.id,
      toJson_T1: _patchMap.containsKey(A$.toJson_T1)
          ? (_patchMap[A$.toJson_T1] is Function)
                ? _patchMap[A$.toJson_T1](this.toJson_T1)
                : _patchMap[A$.toJson_T1]
          : this.toJson_T1,
      valT1: this.valT1,
      valT2: this.valT2,
      toJson_T2: this.toJson_T2,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is B &&
        id == other.id &&
        toJson_T1 == other.toJson_T1 &&
        valT1 == other.valT1 &&
        valT2 == other.valT2 &&
        toJson_T2 == other.toJson_T2;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.toJson_T1,
      this.valT1,
      this.valT2,
      this.toJson_T2,
    );
  }

  @override
  String toString() {
    return 'B(' +
        'id: ${id}' +
        ', ' +
        'toJson_T1: ${toJson_T1}' +
        ', ' +
        'valT1: ${valT1}' +
        ', ' +
        'valT2: ${valT2}' +
        ', ' +
        'toJson_T2: ${toJson_T2})';
  }

  /// Creates a [B] instance from JSON
  factory B.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$BFromJson(json);
    }
    if (json['_className_'] == "C") {
      var fn_fromJson = getFromJsonToGenericFn(C_Generics_Sing().fns, json, [
        '_T1_',
        '_T2_',
      ]);
      return fn_fromJson(json);
    } else if (json['_className_'] == "B") {
      var fn_fromJson = getFromJsonToGenericFn(B_Generics_Sing().fns, json, [
        '_T1_',
        '_T2_',
      ]);
      return fn_fromJson(json);
    }
    throw UnsupportedError(
      "The _className_ '${json['_className_']}' is not supported by the B.fromJson constructor.",
    );
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum B$ { id, toJson_T1, valT1, valT2, toJson_T2 }

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

  BPatch withId(dynamic value) {
    _patch[B$.id] = value;
    return this;
  }

  BPatch withToJson_T1(Object? Function(T1)? value) {
    _patch[B$.toJson_T1] = value;
    return this;
  }

  BPatch withValT1(dynamic value) {
    _patch[B$.valT1] = value;
    return this;
  }

  BPatch withValT2(dynamic value) {
    _patch[B$.valT2] = value;
    return this;
  }

  BPatch withToJson_T2(Object? Function(T2)? value) {
    _patch[B$.toJson_T2] = value;
    return this;
  }
}

extension BSerialization on B<T1, T2> {
  Map<String, dynamic> toJson() => _$BToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension BCompareE on B {
  Map<String, dynamic> compareToB(B other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (valT1 != other.valT1) {
      diff['valT1'] = () => other.valT1;
    }
    if (valT2 != other.valT2) {
      diff['valT2'] = () => other.valT2;
    }
    return diff;
  }
}

extension BChangeToE on B {
  C changeToC({
    required String xyz,
    Object? Function(T1)? toJson_T1,
    Object? Function(T2)? toJson_T2,
  }) {
    final _patcher = CPatch();
    _patcher.withXyz(xyz);
    if (toJson_T1 != null) {
      _patcher.withToJson_T1(toJson_T1);
    }
    if (toJson_T2 != null) {
      _patcher.withToJson_T2(toJson_T2);
    }
    final _patchMap = _patcher.toPatch();
    return C(
      xyz: _patchMap[C$.xyz],
      valT1: _patchMap.containsKey(C$.valT1)
          ? (_patchMap[C$.valT1] is Function)
                ? _patchMap[C$.valT1](valT1)
                : _patchMap[C$.valT1]
          : valT1,
      valT2: _patchMap.containsKey(C$.valT2)
          ? (_patchMap[C$.valT2] is Function)
                ? _patchMap[C$.valT2](valT2)
                : _patchMap[C$.valT2]
          : valT2,
      toJson_T1: _patchMap.containsKey(C$.toJson_T1)
          ? (_patchMap[C$.toJson_T1] is Function)
                ? _patchMap[C$.toJson_T1](toJson_T1)
                : _patchMap[C$.toJson_T1]
          : toJson_T1,
      toJson_T2: _patchMap.containsKey(C$.toJson_T2)
          ? (_patchMap[C$.toJson_T2] is Function)
                ? _patchMap[C$.toJson_T2](toJson_T2)
                : _patchMap[C$.toJson_T2]
          : toJson_T2,
      id: _patchMap.containsKey(C$.id)
          ? (_patchMap[C$.id] is Function)
                ? _patchMap[C$.id](id)
                : _patchMap[C$.id]
          : id,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class C<T1, T2> extends $C implements B, A {
  @override
  final T1 valT1;
  @override
  final T2 valT2;
  @override
  final Object? Function(T1)? toJson_T1;
  @override
  final Object? Function(T2)? toJson_T2;
  @override
  final T1 id;
  @override
  final Object? Function(T1)? toJson_T1;
  @override
  final String xyz;

  C({
    required this.valT1,
    required this.valT2,
    this.toJson_T1,
    this.toJson_T2,
    required this.id,
    this.toJson_T1,
    required this.xyz,
  });

  C copyWith({
    T1? valT1,
    T2? valT2,
    Object? Function(T1)? toJson_T1,
    Object? Function(T2)? toJson_T2,
    T1? id,
    Object? Function(T1)? toJson_T1,
    String? xyz,
  }) {
    return C(
      valT1: valT1 ?? this.valT1,
      valT2: valT2 ?? this.valT2,
      toJson_T1: toJson_T1 ?? this.toJson_T1,
      toJson_T2: toJson_T2 ?? this.toJson_T2,
      id: id ?? this.id,
      toJson_T1: toJson_T1 ?? this.toJson_T1,
      xyz: xyz ?? this.xyz,
    );
  }

  C copyWithC({
    T1? valT1,
    T2? valT2,
    Object? Function(T1)? toJson_T1,
    Object? Function(T2)? toJson_T2,
    T1? id,
    Object? Function(T1)? toJson_T1,
    String? xyz,
  }) {
    return copyWith(
      valT1: valT1,
      valT2: valT2,
      toJson_T1: toJson_T1,
      toJson_T2: toJson_T2,
      id: id,
      toJson_T1: toJson_T1,
      xyz: xyz,
    );
  }

  C patchWithC({CPatch? patchInput}) {
    final _patcher = patchInput ?? CPatch();
    final _patchMap = _patcher.toPatch();
    return C(
      valT1: _patchMap.containsKey(C$.valT1)
          ? (_patchMap[C$.valT1] is Function)
                ? _patchMap[C$.valT1](this.valT1)
                : _patchMap[C$.valT1]
          : this.valT1,
      valT2: _patchMap.containsKey(C$.valT2)
          ? (_patchMap[C$.valT2] is Function)
                ? _patchMap[C$.valT2](this.valT2)
                : _patchMap[C$.valT2]
          : this.valT2,
      toJson_T1: _patchMap.containsKey(C$.toJson_T1)
          ? (_patchMap[C$.toJson_T1] is Function)
                ? _patchMap[C$.toJson_T1](this.toJson_T1)
                : _patchMap[C$.toJson_T1]
          : this.toJson_T1,
      toJson_T2: _patchMap.containsKey(C$.toJson_T2)
          ? (_patchMap[C$.toJson_T2] is Function)
                ? _patchMap[C$.toJson_T2](this.toJson_T2)
                : _patchMap[C$.toJson_T2]
          : this.toJson_T2,
      id: _patchMap.containsKey(C$.id)
          ? (_patchMap[C$.id] is Function)
                ? _patchMap[C$.id](this.id)
                : _patchMap[C$.id]
          : this.id,
      toJson_T1: _patchMap.containsKey(C$.toJson_T1)
          ? (_patchMap[C$.toJson_T1] is Function)
                ? _patchMap[C$.toJson_T1](this.toJson_T1)
                : _patchMap[C$.toJson_T1]
          : this.toJson_T1,
      xyz: _patchMap.containsKey(C$.xyz)
          ? (_patchMap[C$.xyz] is Function)
                ? _patchMap[C$.xyz](this.xyz)
                : _patchMap[C$.xyz]
          : this.xyz,
    );
  }

  C copyWithB({
    T1? valT1,
    T2? valT2,
    Object? Function(T1)? toJson_T1,
    Object? Function(T2)? toJson_T2,
  }) {
    return copyWith(
      valT1: valT1,
      valT2: valT2,
      toJson_T1: toJson_T1,
      toJson_T2: toJson_T2,
    );
  }

  C copyWithA({T1? id, Object? Function(T1)? toJson_T1}) {
    return copyWith(id: id, toJson_T1: toJson_T1);
  }

  C patchWithB({BPatch? patchInput}) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return C(
      valT1: _patchMap.containsKey(B$.valT1)
          ? (_patchMap[B$.valT1] is Function)
                ? _patchMap[B$.valT1](this.valT1)
                : _patchMap[B$.valT1]
          : this.valT1,
      valT2: _patchMap.containsKey(B$.valT2)
          ? (_patchMap[B$.valT2] is Function)
                ? _patchMap[B$.valT2](this.valT2)
                : _patchMap[B$.valT2]
          : this.valT2,
      toJson_T1: _patchMap.containsKey(B$.toJson_T1)
          ? (_patchMap[B$.toJson_T1] is Function)
                ? _patchMap[B$.toJson_T1](this.toJson_T1)
                : _patchMap[B$.toJson_T1]
          : this.toJson_T1,
      toJson_T2: _patchMap.containsKey(B$.toJson_T2)
          ? (_patchMap[B$.toJson_T2] is Function)
                ? _patchMap[B$.toJson_T2](this.toJson_T2)
                : _patchMap[B$.toJson_T2]
          : this.toJson_T2,
      id: this.id,
      toJson_T1: _patchMap.containsKey(B$.toJson_T1)
          ? (_patchMap[B$.toJson_T1] is Function)
                ? _patchMap[B$.toJson_T1](this.toJson_T1)
                : _patchMap[B$.toJson_T1]
          : this.toJson_T1,
      xyz: this.xyz,
    );
  }

  C patchWithA({APatch? patchInput}) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return C(
      valT1: this.valT1,
      valT2: this.valT2,
      toJson_T1: _patchMap.containsKey(A$.toJson_T1)
          ? (_patchMap[A$.toJson_T1] is Function)
                ? _patchMap[A$.toJson_T1](this.toJson_T1)
                : _patchMap[A$.toJson_T1]
          : this.toJson_T1,
      toJson_T2: this.toJson_T2,
      id: _patchMap.containsKey(A$.id)
          ? (_patchMap[A$.id] is Function)
                ? _patchMap[A$.id](this.id)
                : _patchMap[A$.id]
          : this.id,
      toJson_T1: _patchMap.containsKey(A$.toJson_T1)
          ? (_patchMap[A$.toJson_T1] is Function)
                ? _patchMap[A$.toJson_T1](this.toJson_T1)
                : _patchMap[A$.toJson_T1]
          : this.toJson_T1,
      xyz: this.xyz,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is C &&
        valT1 == other.valT1 &&
        valT2 == other.valT2 &&
        toJson_T1 == other.toJson_T1 &&
        toJson_T2 == other.toJson_T2 &&
        id == other.id &&
        toJson_T1 == other.toJson_T1 &&
        xyz == other.xyz;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.valT1,
      this.valT2,
      this.toJson_T1,
      this.toJson_T2,
      this.id,
      this.toJson_T1,
      this.xyz,
    );
  }

  @override
  String toString() {
    return 'C(' +
        'valT1: ${valT1}' +
        ', ' +
        'valT2: ${valT2}' +
        ', ' +
        'toJson_T1: ${toJson_T1}' +
        ', ' +
        'toJson_T2: ${toJson_T2}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'toJson_T1: ${toJson_T1}' +
        ', ' +
        'xyz: ${xyz})';
  }

  /// Creates a [C] instance from JSON
  factory C.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$CFromJson(json);
    }
    if (json['_className_'] == "C") {
      var fn_fromJson = getFromJsonToGenericFn(C_Generics_Sing().fns, json, [
        '_T1_',
        '_T2_',
      ]);
      return fn_fromJson(json);
    }
    throw UnsupportedError(
      "The _className_ '${json['_className_']}' is not supported by the C.fromJson constructor.",
    );
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum C$ { valT1, valT2, toJson_T1, toJson_T2, id, toJson_T1, xyz }

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

  CPatch withValT1(dynamic value) {
    _patch[C$.valT1] = value;
    return this;
  }

  CPatch withValT2(dynamic value) {
    _patch[C$.valT2] = value;
    return this;
  }

  CPatch withToJson_T1(Object? Function(T1)? value) {
    _patch[C$.toJson_T1] = value;
    return this;
  }

  CPatch withToJson_T2(Object? Function(T2)? value) {
    _patch[C$.toJson_T2] = value;
    return this;
  }

  CPatch withId(dynamic value) {
    _patch[C$.id] = value;
    return this;
  }

  CPatch withToJson_T1(Object? Function(T1)? value) {
    _patch[C$.toJson_T1] = value;
    return this;
  }

  CPatch withXyz(String? value) {
    _patch[C$.xyz] = value;
    return this;
  }
}

extension CSerialization on C<T1, T2> {
  Map<String, dynamic> toJson() => _$CToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension CCompareE on C {
  Map<String, dynamic> compareToC(C other) {
    final Map<String, dynamic> diff = {};

    if (valT1 != other.valT1) {
      diff['valT1'] = () => other.valT1;
    }
    if (valT2 != other.valT2) {
      diff['valT2'] = () => other.valT2;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (xyz != other.xyz) {
      diff['xyz'] = () => other.xyz;
    }
    return diff;
  }
}
