// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex50_json_inheritance_generic_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class A extends $A {
  @override
  final String id;

  A({required this.id});

  A copyWith({String? id}) {
    return A(id: id ?? this.id);
  }

  A copyWithA({String? id}) {
    return copyWith(id: id);
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
    );
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

  /// Creates a [A] instance from JSON
  factory A.fromJson(Map<String, dynamic> json) => _$AFromJson(json);

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

extension ASerialization on A {
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

@JsonSerializable(explicitToJson: true)
class B<T> extends $B implements A {
  @override
  final String id;
  @override
  final T blah;
  @override
  final Object? Function(T)? toJson_T;

  B({required this.id, required this.blah, this.toJson_T});

  B copyWith({String? id, T? blah, Object? Function(T)? toJson_T}) {
    return B(
      id: id ?? this.id,
      blah: blah ?? this.blah,
      toJson_T: toJson_T ?? this.toJson_T,
    );
  }

  B copyWithB({String? id, T? blah, Object? Function(T)? toJson_T}) {
    return copyWith(id: id, blah: blah, toJson_T: toJson_T);
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
      blah: _patchMap.containsKey(B$.blah)
          ? (_patchMap[B$.blah] is Function)
                ? _patchMap[B$.blah](this.blah)
                : _patchMap[B$.blah]
          : this.blah,
      toJson_T: _patchMap.containsKey(B$.toJson_T)
          ? (_patchMap[B$.toJson_T] is Function)
                ? _patchMap[B$.toJson_T](this.toJson_T)
                : _patchMap[B$.toJson_T]
          : this.toJson_T,
    );
  }

  B copyWithA({String? id}) {
    return copyWith(id: id);
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
      blah: this.blah,
      toJson_T: this.toJson_T,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is B &&
        id == other.id &&
        blah == other.blah &&
        toJson_T == other.toJson_T;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.blah, this.toJson_T);
  }

  @override
  String toString() {
    return 'B(' +
        'id: ${id}' +
        ', ' +
        'blah: ${blah}' +
        ', ' +
        'toJson_T: ${toJson_T})';
  }

  /// Creates a [B] instance from JSON
  factory B.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$BFromJson(json);
    }
    if (json['_className_'] == "B") {
      var fn_fromJson = getFromJsonToGenericFn(B_Generics_Sing().fns, json, [
        '_T_',
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

enum B$ { id, blah, toJson_T }

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

  BPatch withBlah(dynamic value) {
    _patch[B$.blah] = value;
    return this;
  }

  BPatch withToJson_T(Object? Function(T)? value) {
    _patch[B$.toJson_T] = value;
    return this;
  }
}

extension BSerialization on B<T> {
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
    if (blah != other.blah) {
      diff['blah'] = () => other.blah;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class X extends $X {
  @override
  final String xyz;

  X({required this.xyz});

  X copyWith({String? xyz}) {
    return X(xyz: xyz ?? this.xyz);
  }

  X copyWithX({String? xyz}) {
    return copyWith(xyz: xyz);
  }

  X patchWithX({XPatch? patchInput}) {
    final _patcher = patchInput ?? XPatch();
    final _patchMap = _patcher.toPatch();
    return X(
      xyz: _patchMap.containsKey(X$.xyz)
          ? (_patchMap[X$.xyz] is Function)
                ? _patchMap[X$.xyz](this.xyz)
                : _patchMap[X$.xyz]
          : this.xyz,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is X && xyz == other.xyz;
  }

  @override
  int get hashCode {
    return Object.hash(xyz, 0);
  }

  @override
  String toString() {
    return 'X(' + 'xyz: ${xyz})';
  }

  /// Creates a [X] instance from JSON
  factory X.fromJson(Map<String, dynamic> json) => _$XFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$XToJson(this);
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

enum X$ { xyz }

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

  XPatch withXyz(String? value) {
    _patch[X$.xyz] = value;
    return this;
  }
}

extension XSerialization on X {
  Map<String, dynamic> toJson() => _$XToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$XToJson(this);
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

extension XCompareE on X {
  Map<String, dynamic> compareToX(X other) {
    final Map<String, dynamic> diff = {};

    if (xyz != other.xyz) {
      diff['xyz'] = () => other.xyz;
    }
    return diff;
  }
}
