// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex29_copywith_subclasses_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

///Copywith from subclass to superclass & superclass to subclass
sealed class $A {
  String get a;

  const $A._internal();

  factory $A._copyWith({
    String? a,
  }) = _$$ACopyWith;

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

  A copyWithAFn({
    String? Function()? a,
  }) {
    return A(
      a: a != null ? a() : this.a,
    );
  }

}



class B<T1> implements $$A {
  final String a;
  final T1 b;

  B({
    required this.a,
    required this.b,
  });

  B._copyWith({
    String? a,
    T1? b,
  }) : 
    a = a ?? (() { throw ArgumentError("a is required"); })(),
    b = b ?? (() { throw ArgumentError("b is required"); })();

  B copyWith({
    String? a,
    T1? b,
  }) {
    return B(
      a: a ?? this.a,
      b: b ?? this.b,
    );
  }

  B copyWithB({
    String? a,
    T1? b,
  }) {
    return copyWith(
      a: a, b: b,
    );
  }

  B copyWithBFn({
    String? Function()? a,
    T1? Function()? b,
  }) {
    return B(
      a: a != null ? a() : this.a,
      b: b != null ? b() : this.b,
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


  B copyWithA({
    String? a,
  }) {
    return copyWith(
      a: a,
    );
  }


  B copyWithAFn({
    String? Function()? a,
  }) {
    return copyWith(
      a: a != null ? a() : this.a,
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

  BPatch withB(dynamic value) {
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




class C<T1> implements $$A {
  final String a;
  final T1 b;
  final String a;
  final bool c;

  C({
    required this.a,
    required this.b,
    required this.a,
    required this.c,
  });

  C._copyWith({
    String? a,
    T1? b,
    String? a,
    bool? c,
  }) : 
    a = a ?? (() { throw ArgumentError("a is required"); })(),
    b = b ?? (() { throw ArgumentError("b is required"); })(),
    a = a ?? (() { throw ArgumentError("a is required"); })(),
    c = c ?? (() { throw ArgumentError("c is required"); })();

  C copyWith({
    String? a,
    T1? b,
    String? a,
    bool? c,
  }) {
    return C(
      a: a ?? this.a,
      b: b ?? this.b,
      a: a ?? this.a,
      c: c ?? this.c,
    );
  }

  C copyWithC({
    String? a,
    T1? b,
    String? a,
    bool? c,
  }) {
    return copyWith(
      a: a, b: b, a: a, c: c,
    );
  }

  C copyWithCFn({
    String? Function()? a,
    T1? Function()? b,
    String? Function()? a,
    bool? Function()? c,
  }) {
    return C(
      a: a != null ? a() : this.a,
      b: b != null ? b() : this.b,
      a: a != null ? a() : this.a,
      c: c != null ? c() : this.c,
    );
  }

  C patchWithC({
    CPatch? patchInput,
  }) {
    final _patcher = patchInput ?? CPatch();
    final _patchMap = _patcher.toPatch();
    return C(
      a: _patchMap.containsKey(C$.a) ? (_patchMap[C$.a] is Function) ? _patchMap[C$.a](this.a) : _patchMap[C$.a] : this.a,
      b: _patchMap.containsKey(C$.b) ? (_patchMap[C$.b] is Function) ? _patchMap[C$.b](this.b) : _patchMap[C$.b] : this.b,
      a: _patchMap.containsKey(C$.a) ? (_patchMap[C$.a] is Function) ? _patchMap[C$.a](this.a) : _patchMap[C$.a] : this.a,
      c: _patchMap.containsKey(C$.c) ? (_patchMap[C$.c] is Function) ? _patchMap[C$.c](this.c) : _patchMap[C$.c] : this.c
    );
  }


  C copyWithB({
    String? a,
    T1? b,
  }) {
    return copyWith(
      a: a, b: b,
    );
  }

  C copyWithA({
    String? a,
  }) {
    return copyWith(
      a: a,
    );
  }


  C copyWithBFn({
    String? Function()? a,
    T1? Function()? b,
    String? Function()? a,
  }) {
    return copyWith(
      a: a != null ? a() : this.a,
      b: b != null ? b() : this.b,
      a: a != null ? a() : this.a,
    );
  }

  C copyWithAFn({
    String? Function()? a,
    T1? Function()? b,
    String? Function()? a,
  }) {
    return copyWith(
      a: a != null ? a() : this.a,
      b: b != null ? b() : this.b,
      a: a != null ? a() : this.a,
    );
  }


  C patchWithB({
    BPatch? patchInput,
  }) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return C(
      a: _patchMap.containsKey(B$.a) ? (_patchMap[B$.a] is Function) ? _patchMap[B$.a](this.a) : _patchMap[B$.a] : this.a,
      b: _patchMap.containsKey(B$.b) ? (_patchMap[B$.b] is Function) ? _patchMap[B$.b](this.b) : _patchMap[B$.b] : this.b,
      a: _patchMap.containsKey(B$.a) ? (_patchMap[B$.a] is Function) ? _patchMap[B$.a](this.a) : _patchMap[B$.a] : this.a,
      c: this.c,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is C &&
        a == other.a &&
        b == other.b &&
        a == other.a &&
        c == other.c;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.a,
      this.b,
      this.a,
      this.c);
  }

  @override
  String toString() {
    return 'C(' +
        'a: ${a}' + ', ' +
        'b: ${b}' + ', ' +
        'a: ${a}' + ', ' +
        'c: ${c})';
  }

}
enum C$ {
a,b,a,c
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

  CPatch withA(String? value) {
    _patch[C$.a] = value;
    return this;
  }

  CPatch withB(dynamic value) {
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

    if (a != other.a) {
      diff['a'] = () => other.a;
    }
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




class D<T1> implements $$A {
  final String a;
  final T1 b;
  final String a;

  D({
    required this.a,
    required this.b,
    required this.a,
  });

  D._copyWith({
    String? a,
    T1? b,
    String? a,
  }) : 
    a = a ?? (() { throw ArgumentError("a is required"); })(),
    b = b ?? (() { throw ArgumentError("b is required"); })(),
    a = a ?? (() { throw ArgumentError("a is required"); })();

  D copyWith({
    String? a,
    T1? b,
    String? a,
  }) {
    return D(
      a: a ?? this.a,
      b: b ?? this.b,
      a: a ?? this.a,
    );
  }

  D copyWithD({
    String? a,
    T1? b,
    String? a,
  }) {
    return copyWith(
      a: a, b: b, a: a,
    );
  }

  D copyWithDFn({
    String? Function()? a,
    T1? Function()? b,
    String? Function()? a,
  }) {
    return D(
      a: a != null ? a() : this.a,
      b: b != null ? b() : this.b,
      a: a != null ? a() : this.a,
    );
  }

  D patchWithD({
    DPatch? patchInput,
  }) {
    final _patcher = patchInput ?? DPatch();
    final _patchMap = _patcher.toPatch();
    return D(
      a: _patchMap.containsKey(D$.a) ? (_patchMap[D$.a] is Function) ? _patchMap[D$.a](this.a) : _patchMap[D$.a] : this.a,
      b: _patchMap.containsKey(D$.b) ? (_patchMap[D$.b] is Function) ? _patchMap[D$.b](this.b) : _patchMap[D$.b] : this.b,
      a: _patchMap.containsKey(D$.a) ? (_patchMap[D$.a] is Function) ? _patchMap[D$.a](this.a) : _patchMap[D$.a] : this.a
    );
  }


  D copyWithB({
    String? a,
    T1? b,
  }) {
    return copyWith(
      a: a, b: b,
    );
  }

  D copyWithA({
    String? a,
  }) {
    return copyWith(
      a: a,
    );
  }


  D copyWithBFn({
    String? Function()? a,
    T1? Function()? b,
    String? Function()? a,
  }) {
    return copyWith(
      a: a != null ? a() : this.a,
      b: b != null ? b() : this.b,
      a: a != null ? a() : this.a,
    );
  }

  D copyWithAFn({
    String? Function()? a,
    T1? Function()? b,
    String? Function()? a,
  }) {
    return copyWith(
      a: a != null ? a() : this.a,
      b: b != null ? b() : this.b,
      a: a != null ? a() : this.a,
    );
  }


  D patchWithB({
    BPatch? patchInput,
  }) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return D(
      a: _patchMap.containsKey(B$.a) ? (_patchMap[B$.a] is Function) ? _patchMap[B$.a](this.a) : _patchMap[B$.a] : this.a,
      b: _patchMap.containsKey(B$.b) ? (_patchMap[B$.b] is Function) ? _patchMap[B$.b](this.b) : _patchMap[B$.b] : this.b,
      a: _patchMap.containsKey(B$.a) ? (_patchMap[B$.a] is Function) ? _patchMap[B$.a](this.a) : _patchMap[B$.a] : this.a,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is D &&
        a == other.a &&
        b == other.b &&
        a == other.a;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.a,
      this.b,
      this.a);
  }

  @override
  String toString() {
    return 'D(' +
        'a: ${a}' + ', ' +
        'b: ${b}' + ', ' +
        'a: ${a})';
  }

}
enum D$ {
a,b,a
}


class DPatch implements Patch<D> {
  final Map<D$, dynamic> _patch = {};

  static DPatch create([Map<String, dynamic>? diff]) {
    final patch = DPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = D$.values.firstWhere((e) => e.name == key);
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

  static DPatch fromPatch(Map<D$, dynamic> patch) {
    final _patch = DPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<D$, dynamic> toPatch() => Map.from(_patch);

  D applyTo(D entity) {
    return entity.patchWithD(patchInput: this);
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

  static DPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  DPatch withA(String? value) {
    _patch[D$.a] = value;
    return this;
  }

  DPatch withB(dynamic value) {
    _patch[D$.b] = value;
    return this;
  }

  DPatch withA(String? value) {
    _patch[D$.a] = value;
    return this;
  }

}


extension DCompareE on D {
  Map<String, dynamic> compareToD(D other) {
    final Map<String, dynamic> diff = {};

    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    if (b != other.b) {
      diff['b'] = () => other.b;
    }
    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    return diff;
  }
}




sealed class $X {

  const $X._internal();

  factory $X._copyWith({
  }) = _$$XCopyWith;

  X copyWith({
  }) {
    return X();
  }

}



class Y implements $$X {
  final String a;

  Y({
    required this.a,
  });

  Y._copyWith({
    String? a,
  }) : 
    a = a ?? (() { throw ArgumentError("a is required"); })();

  Y copyWith({
    String? a,
  }) {
    return Y(
      a: a ?? this.a,
    );
  }

  Y copyWithY({
    String? a,
  }) {
    return copyWith(
      a: a,
    );
  }

  Y copyWithYFn({
    String? Function()? a,
  }) {
    return Y(
      a: a != null ? a() : this.a,
    );
  }

  Y patchWithY({
    YPatch? patchInput,
  }) {
    final _patcher = patchInput ?? YPatch();
    final _patchMap = _patcher.toPatch();
    return Y(
      a: _patchMap.containsKey(Y$.a) ? (_patchMap[Y$.a] is Function) ? _patchMap[Y$.a](this.a) : _patchMap[Y$.a] : this.a
    );
  }




  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Y &&
        a == other.a;
  }

  @override
  int get hashCode {
    return Object.hash(a, 0);
  }

  @override
  String toString() {
    return 'Y(' +
        'a: ${a})';
  }

}
enum Y$ {
a
}


class YPatch implements Patch<Y> {
  final Map<Y$, dynamic> _patch = {};

  static YPatch create([Map<String, dynamic>? diff]) {
    final patch = YPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Y$.values.firstWhere((e) => e.name == key);
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

  static YPatch fromPatch(Map<Y$, dynamic> patch) {
    final _patch = YPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Y$, dynamic> toPatch() => Map.from(_patch);

  Y applyTo(Y entity) {
    return entity.patchWithY(patchInput: this);
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

  static YPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  YPatch withA(String? value) {
    _patch[Y$.a] = value;
    return this;
  }

}


extension YCompareE on Y {
  Map<String, dynamic> compareToY(Y other) {
    final Map<String, dynamic> diff = {};

    if (a != other.a) {
      diff['a'] = () => other.a;
    }
    return diff;
  }
}
