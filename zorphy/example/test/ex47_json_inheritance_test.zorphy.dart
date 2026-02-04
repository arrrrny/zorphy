// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex47_json_inheritance_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
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

  /// Creates a [A] instance from JSON
  factory A.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$AFromJson(json);
    }
    if (json['_className_'] == "B") {
      return B.fromJson(json);
    } else if (json['_className_'] == "C") {
      return C.fromJson(json);
    } else if (json['_className_'] == "A") {
      return _$AFromJson(json);
    }
    throw UnsupportedError(
        "The _className_ '${json['_className_']}' is not supported by the A.fromJson constructor.");
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
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
      return json
        ..forEach((key, value) {
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
  B changeToB() {
    final _patcher = BPatch();
    final _patchMap = _patcher.toPatch();
    return B(
        id: _patchMap.containsKey(B$.id)
            ? (_patchMap[B$.id] is Function)
                ? _patchMap[B$.id](id)
                : _patchMap[B$.id]
            : id);
  }

  C changeToC({required List<int> items}) {
    final _patcher = CPatch();
    _patcher.withItems(items);
    final _patchMap = _patcher.toPatch();
    return C(
        items: _patchMap[C$.items],
        id: _patchMap.containsKey(C$.id)
            ? (_patchMap[C$.id] is Function)
                ? _patchMap[C$.id](id)
                : _patchMap[C$.id]
            : id);
  }
}

@JsonSerializable(explicitToJson: true)
class B extends $B implements A {
  @override
  final String id;

  B({
    required this.id,
  });

  B copyWith({
    String? id,
  }) {
    return B(
      id: id ?? this.id,
    );
  }

  B copyWithB({
    String? id,
  }) {
    return copyWith(
      id: id,
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
            : this.id);
  }

  B copyWithA({
    String? id,
  }) {
    return copyWith(
      id: id,
    );
  }

  B patchWithA({
    APatch? patchInput,
  }) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return B(
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
    return other is B && id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(id, 0);
  }

  @override
  String toString() {
    return 'B(' + 'id: ${id})';
  }

  /// Creates a [B] instance from JSON
  factory B.fromJson(Map<String, dynamic> json) => _$BFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum B$ { id }

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
}

extension BSerialization on B {
  Map<String, dynamic> toJson() => _$BToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
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
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class C extends $C implements A {
  @override
  final String id;
  @override
  final List<int> items;

  C({
    required this.id,
    required this.items,
  });

  C copyWith({
    String? id,
    List<int>? items,
  }) {
    return C(
      id: id ?? this.id,
      items: items ?? this.items,
    );
  }

  C copyWithC({
    String? id,
    List<int>? items,
  }) {
    return copyWith(
      id: id,
      items: items,
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
        items: _patchMap.containsKey(C$.items)
            ? (_patchMap[C$.items] is Function)
                ? _patchMap[C$.items](this.items)
                : _patchMap[C$.items]
            : this.items);
  }

  C copyWithA({
    String? id,
  }) {
    return copyWith(
      id: id,
    );
  }

  C patchWithA({
    APatch? patchInput,
  }) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return C(
      id: _patchMap.containsKey(A$.id)
          ? (_patchMap[A$.id] is Function)
              ? _patchMap[A$.id](this.id)
              : _patchMap[A$.id]
          : this.id,
      items: this.items,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is C && id == other.id && items == other.items;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.items);
  }

  @override
  String toString() {
    return 'C(' + 'id: ${id}' + ', ' + 'items: ${items})';
  }

  /// Creates a [C] instance from JSON
  factory C.fromJson(Map<String, dynamic> json) => _$CFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum C$ { id, items }

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

  CPatch withItems(List<int>? value) {
    _patch[C$.items] = value;
    return this;
  }
}

extension CSerialization on C {
  Map<String, dynamic> toJson() => _$CToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
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

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (items != other.items) {
      diff['items'] = () => other.items;
    }
    return diff;
  }
}
