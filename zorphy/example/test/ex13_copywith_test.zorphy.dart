// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex13_copywith_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class A extends $A {
  @override
  final String a;

  A({
    required this.a,
  });

  A._copyWith({
    String? a,
  }) : 
    a = a ?? throw ArgumentError("a is required");

  A copyWith({
    String? a,
  }) {
    return A(
      a: a ?? this.a,
    );
  }

  A copyWithA({
    String? a,
  }) {
    return copyWith(
      a: a,
    );
  }

  A copyWithFn({
    String? Function(String?)? a,
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

  APatch withA(String? value) {
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
  final String a;
  @override
  final int b;

  B({
    required this.a,
    required this.b,
  });

  B._copyWith({
    String? a,
    int? b,
  }) : 
    a = a ?? throw ArgumentError("a is required"),
    b = b ?? throw ArgumentError("b is required");

  B copyWith({
    String? a,
    int? b,
  }) {
    return B(
      a: a ?? this.a,
      b: b ?? this.b,
    );
  }

  B copyWithB({
    String? a,
    int? b,
  }) {
    return copyWith(
      a: a, b: b,
    );
  }

  B copyWithFn({
    String? Function(String?)? a,
    int? Function(int?)? b,
  }) {
    return B(
      a: a != null ? a(this.a) : this.a,
      b: b != null ? b(this.b) : this.b,
    );
  }

  B patchWithB({
    BPatch? patchInput,
  }) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return B(
      a: _patchMap.containsKey(B$.a) ? (_patchMap[B$.a] is Function) ? _patchMap[B$.a](this.a) : _patchMap[B$.a] : this.a,
      b: _patchMap.containsKey(B$.b) ? (_patchMap[B$.b] is Function) ? _patchMap[B$.b](this.b) : _patchMap[B$.b] : this.b
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is B &&
        a == other.a &&
        b == other.b;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.a,
      this.b);
  }

  @override
  String toString() {
    return 'B(' +
        'a: ${a}' + ', ' +
        'b: ${b})';
  }

}
enum B$ {
a,b
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

  BPatch withA(String? value) {
    _patch[B$.a] = value;
    return this;
  }

  BPatch withB(int? value) {
    _patch[B$.b] = value;
    return this;
  }

}


extension BCompareE on B {
  Map<String, dynamic> compareToB(B other) {
    final Map<String, dynamic> diff = {};

    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    if (b != other.b) {
      diff['b'] = () => other.b;
    }
    return diff;
  }
}




class C extends $C implements $B, $A {
  @override
  final int b;
  @override
  final String a;
  @override
  final bool c;

  C({
    required this.b,
    required this.a,
    required this.c,
  });

  C._copyWith({
    int? b,
    String? a,
    bool? c,
  }) : 
    b = b ?? throw ArgumentError("b is required"),
    a = a ?? throw ArgumentError("a is required"),
    c = c ?? throw ArgumentError("c is required");

  C copyWith({
    int? b,
    String? a,
    bool? c,
  }) {
    return C(
      b: b ?? this.b,
      a: a ?? this.a,
      c: c ?? this.c,
    );
  }

  C copyWithC({
    int? b,
    String? a,
    bool? c,
  }) {
    return copyWith(
      b: b, a: a, c: c,
    );
  }

  C copyWithFn({
    int? Function(int?)? b,
    String? Function(String?)? a,
    bool? Function(bool?)? c,
  }) {
    return C(
      b: b != null ? b(this.b) : this.b,
      a: a != null ? a(this.a) : this.a,
      c: c != null ? c(this.c) : this.c,
    );
  }

  C patchWithC({
    CPatch? patchInput,
  }) {
    final _patcher = patchInput ?? CPatch();
    final _patchMap = _patcher.toPatch();
    return C(
      b: _patchMap.containsKey(C$.b) ? (_patchMap[C$.b] is Function) ? _patchMap[C$.b](this.b) : _patchMap[C$.b] : this.b,
      a: _patchMap.containsKey(C$.a) ? (_patchMap[C$.a] is Function) ? _patchMap[C$.a](this.a) : _patchMap[C$.a] : this.a,
      c: _patchMap.containsKey(C$.c) ? (_patchMap[C$.c] is Function) ? _patchMap[C$.c](this.c) : _patchMap[C$.c] : this.c
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is C &&
        b == other.b &&
        a == other.a &&
        c == other.c;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.b,
      this.a,
      this.c);
  }

  @override
  String toString() {
    return 'C(' +
        'b: ${b}' + ', ' +
        'a: ${a}' + ', ' +
        'c: ${c})';
  }

}
enum C$ {
b,a,c
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

  CPatch withB(int? value) {
    _patch[C$.b] = value;
    return this;
  }

  CPatch withA(String? value) {
    _patch[C$.a] = value;
    return this;
  }

  CPatch withC(bool? value) {
    _patch[C$.c] = value;
    return this;
  }

}


extension CCompareE on C {
  Map<String, dynamic> compareToC(C other) {
    final Map<String, dynamic> diff = {};

    if (b != other.b) {
      diff['b'] = () => other.b;
    }
    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    if (c != other.c) {
      diff['c'] = () => other.c;
    }
    return diff;
  }
}
