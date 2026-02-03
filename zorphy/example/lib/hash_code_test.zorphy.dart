// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'hash_code_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class LargeClass extends $LargeClass {
  @override
  final String f1;
  @override
  final String f2;
  @override
  final String f3;
  @override
  final String f4;
  @override
  final String f5;
  @override
  final String f6;
  @override
  final String f7;
  @override
  final String f8;
  @override
  final String f9;
  @override
  final String f10;
  @override
  final String f11;
  @override
  final String f12;
  @override
  final String f13;
  @override
  final String f14;
  @override
  final String f15;
  @override
  final String f16;
  @override
  final String f17;
  @override
  final String f18;
  @override
  final String f19;
  @override
  final String f20;
  @override
  final String f21;
  @override
  final String f22;

  LargeClass({
    required this.f1,
    required this.f2,
    required this.f3,
    required this.f4,
    required this.f5,
    required this.f6,
    required this.f7,
    required this.f8,
    required this.f9,
    required this.f10,
    required this.f11,
    required this.f12,
    required this.f13,
    required this.f14,
    required this.f15,
    required this.f16,
    required this.f17,
    required this.f18,
    required this.f19,
    required this.f20,
    required this.f21,
    required this.f22,
  });

  LargeClass copyWith({
    String? f1,
    String? f2,
    String? f3,
    String? f4,
    String? f5,
    String? f6,
    String? f7,
    String? f8,
    String? f9,
    String? f10,
    String? f11,
    String? f12,
    String? f13,
    String? f14,
    String? f15,
    String? f16,
    String? f17,
    String? f18,
    String? f19,
    String? f20,
    String? f21,
    String? f22,
  }) {
    return LargeClass(
      f1: f1 ?? this.f1,
      f2: f2 ?? this.f2,
      f3: f3 ?? this.f3,
      f4: f4 ?? this.f4,
      f5: f5 ?? this.f5,
      f6: f6 ?? this.f6,
      f7: f7 ?? this.f7,
      f8: f8 ?? this.f8,
      f9: f9 ?? this.f9,
      f10: f10 ?? this.f10,
      f11: f11 ?? this.f11,
      f12: f12 ?? this.f12,
      f13: f13 ?? this.f13,
      f14: f14 ?? this.f14,
      f15: f15 ?? this.f15,
      f16: f16 ?? this.f16,
      f17: f17 ?? this.f17,
      f18: f18 ?? this.f18,
      f19: f19 ?? this.f19,
      f20: f20 ?? this.f20,
      f21: f21 ?? this.f21,
      f22: f22 ?? this.f22,
    );
  }

  LargeClass copyWithLargeClass({
    String? f1,
    String? f2,
    String? f3,
    String? f4,
    String? f5,
    String? f6,
    String? f7,
    String? f8,
    String? f9,
    String? f10,
    String? f11,
    String? f12,
    String? f13,
    String? f14,
    String? f15,
    String? f16,
    String? f17,
    String? f18,
    String? f19,
    String? f20,
    String? f21,
    String? f22,
  }) {
    return copyWith(
      f1: f1,
      f2: f2,
      f3: f3,
      f4: f4,
      f5: f5,
      f6: f6,
      f7: f7,
      f8: f8,
      f9: f9,
      f10: f10,
      f11: f11,
      f12: f12,
      f13: f13,
      f14: f14,
      f15: f15,
      f16: f16,
      f17: f17,
      f18: f18,
      f19: f19,
      f20: f20,
      f21: f21,
      f22: f22,
    );
  }

  LargeClass patchWithLargeClass({
    LargeClassPatch? patchInput,
  }) {
    final _patcher = patchInput ?? LargeClassPatch();
    final _patchMap = _patcher.toPatch();
    return LargeClass(
        f1: _patchMap.containsKey(LargeClass$.f1)
            ? (_patchMap[LargeClass$.f1] is Function)
                ? _patchMap[LargeClass$.f1](this.f1)
                : _patchMap[LargeClass$.f1]
            : this.f1,
        f2: _patchMap.containsKey(LargeClass$.f2)
            ? (_patchMap[LargeClass$.f2] is Function)
                ? _patchMap[LargeClass$.f2](this.f2)
                : _patchMap[LargeClass$.f2]
            : this.f2,
        f3: _patchMap.containsKey(LargeClass$.f3)
            ? (_patchMap[LargeClass$.f3] is Function)
                ? _patchMap[LargeClass$.f3](this.f3)
                : _patchMap[LargeClass$.f3]
            : this.f3,
        f4: _patchMap.containsKey(LargeClass$.f4)
            ? (_patchMap[LargeClass$.f4] is Function)
                ? _patchMap[LargeClass$.f4](this.f4)
                : _patchMap[LargeClass$.f4]
            : this.f4,
        f5: _patchMap.containsKey(LargeClass$.f5)
            ? (_patchMap[LargeClass$.f5] is Function)
                ? _patchMap[LargeClass$.f5](this.f5)
                : _patchMap[LargeClass$.f5]
            : this.f5,
        f6: _patchMap.containsKey(LargeClass$.f6)
            ? (_patchMap[LargeClass$.f6] is Function)
                ? _patchMap[LargeClass$.f6](this.f6)
                : _patchMap[LargeClass$.f6]
            : this.f6,
        f7: _patchMap.containsKey(LargeClass$.f7)
            ? (_patchMap[LargeClass$.f7] is Function)
                ? _patchMap[LargeClass$.f7](this.f7)
                : _patchMap[LargeClass$.f7]
            : this.f7,
        f8: _patchMap.containsKey(LargeClass$.f8)
            ? (_patchMap[LargeClass$.f8] is Function)
                ? _patchMap[LargeClass$.f8](this.f8)
                : _patchMap[LargeClass$.f8]
            : this.f8,
        f9: _patchMap.containsKey(LargeClass$.f9)
            ? (_patchMap[LargeClass$.f9] is Function)
                ? _patchMap[LargeClass$.f9](this.f9)
                : _patchMap[LargeClass$.f9]
            : this.f9,
        f10: _patchMap.containsKey(LargeClass$.f10)
            ? (_patchMap[LargeClass$.f10] is Function)
                ? _patchMap[LargeClass$.f10](this.f10)
                : _patchMap[LargeClass$.f10]
            : this.f10,
        f11: _patchMap.containsKey(LargeClass$.f11)
            ? (_patchMap[LargeClass$.f11] is Function)
                ? _patchMap[LargeClass$.f11](this.f11)
                : _patchMap[LargeClass$.f11]
            : this.f11,
        f12: _patchMap.containsKey(LargeClass$.f12)
            ? (_patchMap[LargeClass$.f12] is Function)
                ? _patchMap[LargeClass$.f12](this.f12)
                : _patchMap[LargeClass$.f12]
            : this.f12,
        f13: _patchMap.containsKey(LargeClass$.f13)
            ? (_patchMap[LargeClass$.f13] is Function)
                ? _patchMap[LargeClass$.f13](this.f13)
                : _patchMap[LargeClass$.f13]
            : this.f13,
        f14: _patchMap.containsKey(LargeClass$.f14)
            ? (_patchMap[LargeClass$.f14] is Function)
                ? _patchMap[LargeClass$.f14](this.f14)
                : _patchMap[LargeClass$.f14]
            : this.f14,
        f15: _patchMap.containsKey(LargeClass$.f15)
            ? (_patchMap[LargeClass$.f15] is Function)
                ? _patchMap[LargeClass$.f15](this.f15)
                : _patchMap[LargeClass$.f15]
            : this.f15,
        f16: _patchMap.containsKey(LargeClass$.f16)
            ? (_patchMap[LargeClass$.f16] is Function)
                ? _patchMap[LargeClass$.f16](this.f16)
                : _patchMap[LargeClass$.f16]
            : this.f16,
        f17: _patchMap.containsKey(LargeClass$.f17)
            ? (_patchMap[LargeClass$.f17] is Function)
                ? _patchMap[LargeClass$.f17](this.f17)
                : _patchMap[LargeClass$.f17]
            : this.f17,
        f18: _patchMap.containsKey(LargeClass$.f18)
            ? (_patchMap[LargeClass$.f18] is Function)
                ? _patchMap[LargeClass$.f18](this.f18)
                : _patchMap[LargeClass$.f18]
            : this.f18,
        f19: _patchMap.containsKey(LargeClass$.f19)
            ? (_patchMap[LargeClass$.f19] is Function)
                ? _patchMap[LargeClass$.f19](this.f19)
                : _patchMap[LargeClass$.f19]
            : this.f19,
        f20: _patchMap.containsKey(LargeClass$.f20)
            ? (_patchMap[LargeClass$.f20] is Function)
                ? _patchMap[LargeClass$.f20](this.f20)
                : _patchMap[LargeClass$.f20]
            : this.f20,
        f21: _patchMap.containsKey(LargeClass$.f21)
            ? (_patchMap[LargeClass$.f21] is Function)
                ? _patchMap[LargeClass$.f21](this.f21)
                : _patchMap[LargeClass$.f21]
            : this.f21,
        f22: _patchMap.containsKey(LargeClass$.f22)
            ? (_patchMap[LargeClass$.f22] is Function)
                ? _patchMap[LargeClass$.f22](this.f22)
                : _patchMap[LargeClass$.f22]
            : this.f22);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LargeClass &&
        f1 == other.f1 &&
        f2 == other.f2 &&
        f3 == other.f3 &&
        f4 == other.f4 &&
        f5 == other.f5 &&
        f6 == other.f6 &&
        f7 == other.f7 &&
        f8 == other.f8 &&
        f9 == other.f9 &&
        f10 == other.f10 &&
        f11 == other.f11 &&
        f12 == other.f12 &&
        f13 == other.f13 &&
        f14 == other.f14 &&
        f15 == other.f15 &&
        f16 == other.f16 &&
        f17 == other.f17 &&
        f18 == other.f18 &&
        f19 == other.f19 &&
        f20 == other.f20 &&
        f21 == other.f21 &&
        f22 == other.f22;
  }

  @override
  int get hashCode {
    return Object.hash(
            this.f1,
            this.f2,
            this.f3,
            this.f4,
            this.f5,
            this.f6,
            this.f7,
            this.f8,
            this.f9,
            this.f10,
            this.f11,
            this.f12,
            this.f13,
            this.f14,
            this.f15,
            this.f16,
            this.f17,
            this.f18,
            this.f19,
            this.f20) ^
        Object.hash(this.f21, this.f22);
  }

  @override
  String toString() {
    return 'LargeClass(' +
        'f1: ${f1}' +
        ', ' +
        'f2: ${f2}' +
        ', ' +
        'f3: ${f3}' +
        ', ' +
        'f4: ${f4}' +
        ', ' +
        'f5: ${f5}' +
        ', ' +
        'f6: ${f6}' +
        ', ' +
        'f7: ${f7}' +
        ', ' +
        'f8: ${f8}' +
        ', ' +
        'f9: ${f9}' +
        ', ' +
        'f10: ${f10}' +
        ', ' +
        'f11: ${f11}' +
        ', ' +
        'f12: ${f12}' +
        ', ' +
        'f13: ${f13}' +
        ', ' +
        'f14: ${f14}' +
        ', ' +
        'f15: ${f15}' +
        ', ' +
        'f16: ${f16}' +
        ', ' +
        'f17: ${f17}' +
        ', ' +
        'f18: ${f18}' +
        ', ' +
        'f19: ${f19}' +
        ', ' +
        'f20: ${f20}' +
        ', ' +
        'f21: ${f21}' +
        ', ' +
        'f22: ${f22})';
  }

  /// Creates a [LargeClass] instance from JSON
  factory LargeClass.fromJson(Map<String, dynamic> json) =>
      _$LargeClassFromJson(json);
}

enum LargeClass$ {
  f1,
  f2,
  f3,
  f4,
  f5,
  f6,
  f7,
  f8,
  f9,
  f10,
  f11,
  f12,
  f13,
  f14,
  f15,
  f16,
  f17,
  f18,
  f19,
  f20,
  f21,
  f22
}

class LargeClassPatch implements Patch<LargeClass> {
  final Map<LargeClass$, dynamic> _patch = {};

  static LargeClassPatch create([Map<String, dynamic>? diff]) {
    final patch = LargeClassPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = LargeClass$.values.firstWhere((e) => e.name == key);
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

  static LargeClassPatch fromPatch(Map<LargeClass$, dynamic> patch) {
    final _patch = LargeClassPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<LargeClass$, dynamic> toPatch() => Map.from(_patch);

  LargeClass applyTo(LargeClass entity) {
    return entity.patchWithLargeClass(patchInput: this);
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

  static LargeClassPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  LargeClassPatch withF1(String? value) {
    _patch[LargeClass$.f1] = value;
    return this;
  }

  LargeClassPatch withF2(String? value) {
    _patch[LargeClass$.f2] = value;
    return this;
  }

  LargeClassPatch withF3(String? value) {
    _patch[LargeClass$.f3] = value;
    return this;
  }

  LargeClassPatch withF4(String? value) {
    _patch[LargeClass$.f4] = value;
    return this;
  }

  LargeClassPatch withF5(String? value) {
    _patch[LargeClass$.f5] = value;
    return this;
  }

  LargeClassPatch withF6(String? value) {
    _patch[LargeClass$.f6] = value;
    return this;
  }

  LargeClassPatch withF7(String? value) {
    _patch[LargeClass$.f7] = value;
    return this;
  }

  LargeClassPatch withF8(String? value) {
    _patch[LargeClass$.f8] = value;
    return this;
  }

  LargeClassPatch withF9(String? value) {
    _patch[LargeClass$.f9] = value;
    return this;
  }

  LargeClassPatch withF10(String? value) {
    _patch[LargeClass$.f10] = value;
    return this;
  }

  LargeClassPatch withF11(String? value) {
    _patch[LargeClass$.f11] = value;
    return this;
  }

  LargeClassPatch withF12(String? value) {
    _patch[LargeClass$.f12] = value;
    return this;
  }

  LargeClassPatch withF13(String? value) {
    _patch[LargeClass$.f13] = value;
    return this;
  }

  LargeClassPatch withF14(String? value) {
    _patch[LargeClass$.f14] = value;
    return this;
  }

  LargeClassPatch withF15(String? value) {
    _patch[LargeClass$.f15] = value;
    return this;
  }

  LargeClassPatch withF16(String? value) {
    _patch[LargeClass$.f16] = value;
    return this;
  }

  LargeClassPatch withF17(String? value) {
    _patch[LargeClass$.f17] = value;
    return this;
  }

  LargeClassPatch withF18(String? value) {
    _patch[LargeClass$.f18] = value;
    return this;
  }

  LargeClassPatch withF19(String? value) {
    _patch[LargeClass$.f19] = value;
    return this;
  }

  LargeClassPatch withF20(String? value) {
    _patch[LargeClass$.f20] = value;
    return this;
  }

  LargeClassPatch withF21(String? value) {
    _patch[LargeClass$.f21] = value;
    return this;
  }

  LargeClassPatch withF22(String? value) {
    _patch[LargeClass$.f22] = value;
    return this;
  }
}

extension LargeClassSerialization on LargeClass {
  Map<String, dynamic> toJson() => _$LargeClassToJson(this);
}

extension LargeClassCompareE on LargeClass {
  Map<String, dynamic> compareToLargeClass(LargeClass other) {
    final Map<String, dynamic> diff = {};

    if (f1 != other.f1) {
      diff['f1'] = () => other.f1;
    }
    if (f2 != other.f2) {
      diff['f2'] = () => other.f2;
    }
    if (f3 != other.f3) {
      diff['f3'] = () => other.f3;
    }
    if (f4 != other.f4) {
      diff['f4'] = () => other.f4;
    }
    if (f5 != other.f5) {
      diff['f5'] = () => other.f5;
    }
    if (f6 != other.f6) {
      diff['f6'] = () => other.f6;
    }
    if (f7 != other.f7) {
      diff['f7'] = () => other.f7;
    }
    if (f8 != other.f8) {
      diff['f8'] = () => other.f8;
    }
    if (f9 != other.f9) {
      diff['f9'] = () => other.f9;
    }
    if (f10 != other.f10) {
      diff['f10'] = () => other.f10;
    }
    if (f11 != other.f11) {
      diff['f11'] = () => other.f11;
    }
    if (f12 != other.f12) {
      diff['f12'] = () => other.f12;
    }
    if (f13 != other.f13) {
      diff['f13'] = () => other.f13;
    }
    if (f14 != other.f14) {
      diff['f14'] = () => other.f14;
    }
    if (f15 != other.f15) {
      diff['f15'] = () => other.f15;
    }
    if (f16 != other.f16) {
      diff['f16'] = () => other.f16;
    }
    if (f17 != other.f17) {
      diff['f17'] = () => other.f17;
    }
    if (f18 != other.f18) {
      diff['f18'] = () => other.f18;
    }
    if (f19 != other.f19) {
      diff['f19'] = () => other.f19;
    }
    if (f20 != other.f20) {
      diff['f20'] = () => other.f20;
    }
    if (f21 != other.f21) {
      diff['f21'] = () => other.f21;
    }
    if (f22 != other.f22) {
      diff['f22'] = () => other.f22;
    }
    return diff;
  }
}
