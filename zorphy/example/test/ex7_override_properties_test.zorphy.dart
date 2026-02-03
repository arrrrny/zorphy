// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex7_override_properties_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class A extends $A {
  @override
  final Person a;

  A({
    required this.a,
  });

  A._copyWith({
    Person? a,
  }) : 
    a = a ?? throw ArgumentError("a is required");

  A copyWith({
    Person? a,
  }) {
    return A(
      a: a ?? this.a,
    );
  }

  A copyWithA({
    Person? a,
  }) {
    return copyWith(
      a: a,
    );
  }

  A copyWithFn({
    Person? Function(Person?)? a,
  }) {
    return A(
      a: a != null ? a(this.a) : this.a,
    );
  }

  A patchWithA({
    APatch? patchInput,
  }) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return A(
      a: _patchMap.containsKey(A$.a) ? (_patchMap[A$.a] is Function) ? _patchMap[A$.a](this.a) : _patchMap[A$.a] : this.a
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A &&
        a == other.a;
  }

  @override
  int get hashCode {
    return Object.hash(a, 0);
  }

  @override
  String toString() {
    return 'A(' +
        'a: ${a})';
  }

}
enum A$ {
a
}


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
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
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

  APatch withA(Person? value) {
    _patch[A$.a] = value;
    return this;
  }

}


extension ACompareE on A {
  Map<String, dynamic> compareToA(A other) {
    final Map<String, dynamic> diff = {};

    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    return diff;
  }
}




class B extends $B implements $A {
  @override
  final Employee a;

  B({
    required this.a,
  });

  B._copyWith({
    Employee? a,
  }) : 
    a = a ?? throw ArgumentError("a is required");

  B copyWith({
    Employee? a,
  }) {
    return B(
      a: a ?? this.a,
    );
  }

  B copyWithB({
    Employee? a,
  }) {
    return copyWith(
      a: a,
    );
  }

  B copyWithFn({
    Employee? Function(Employee?)? a,
  }) {
    return B(
      a: a != null ? a(this.a) : this.a,
    );
  }

  B patchWithB({
    BPatch? patchInput,
  }) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return B(
      a: _patchMap.containsKey(B$.a) ? (_patchMap[B$.a] is Function) ? _patchMap[B$.a](this.a) : _patchMap[B$.a] : this.a
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is B &&
        a == other.a;
  }

  @override
  int get hashCode {
    return Object.hash(a, 0);
  }

  @override
  String toString() {
    return 'B(' +
        'a: ${a})';
  }

}
enum B$ {
a
}


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
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
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

  BPatch withA(Employee? value) {
    _patch[B$.a] = value;
    return this;
  }

}


extension BCompareE on B {
  Map<String, dynamic> compareToB(B other) {
    final Map<String, dynamic> diff = {};

    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    return diff;
  }
}




class C extends $C implements $B, $A {
  @override
  final Manager a;
  @override
  final Manager a;

  C({
    required this.a,
    required this.a,
  });

  C._copyWith({
    Manager? a,
    Manager? a,
  }) : 
    a = a ?? throw ArgumentError("a is required"),
    a = a ?? throw ArgumentError("a is required");

  C copyWith({
    Manager? a,
    Manager? a,
  }) {
    return C(
      a: a ?? this.a,
      a: a ?? this.a,
    );
  }

  C copyWithC({
    Manager? a,
    Manager? a,
  }) {
    return copyWith(
      a: a, a: a,
    );
  }

  C copyWithFn({
    Manager? Function(Manager?)? a,
    Manager? Function(Manager?)? a,
  }) {
    return C(
      a: a != null ? a(this.a) : this.a,
      a: a != null ? a(this.a) : this.a,
    );
  }

  C patchWithC({
    CPatch? patchInput,
  }) {
    final _patcher = patchInput ?? CPatch();
    final _patchMap = _patcher.toPatch();
    return C(
      a: _patchMap.containsKey(C$.a) ? (_patchMap[C$.a] is Function) ? _patchMap[C$.a](this.a) : _patchMap[C$.a] : this.a,
      a: _patchMap.containsKey(C$.a) ? (_patchMap[C$.a] is Function) ? _patchMap[C$.a](this.a) : _patchMap[C$.a] : this.a
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is C &&
        a == other.a &&
        a == other.a;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.a,
      this.a);
  }

  @override
  String toString() {
    return 'C(' +
        'a: ${a}' + ', ' +
        'a: ${a})';
  }

}
enum C$ {
a,a
}


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
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
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

  CPatch withA(Manager? value) {
    _patch[C$.a] = value;
    return this;
  }

  CPatch withA(Manager? value) {
    _patch[C$.a] = value;
    return this;
  }

}


extension CCompareE on C {
  Map<String, dynamic> compareToC(C other) {
    final Map<String, dynamic> diff = {};

    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    return diff;
  }
}
