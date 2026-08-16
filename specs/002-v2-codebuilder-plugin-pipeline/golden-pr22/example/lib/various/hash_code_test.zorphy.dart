// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'hash_code_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class LargeClass {
  final String f1;
  final String f2;
  final String f3;
  final String f4;
  final String f5;
  final String f6;
  final String f7;
  final String f8;
  final String f9;
  final String f10;
  final String f11;
  final String f12;
  final String f13;
  final String f14;
  final String f15;
  final String f16;
  final String f17;
  final String f18;
  final String f19;
  final String f20;
  final String f21;
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

  LargeClass patchWithLargeClass({LargeClassPatch? patchInput}) {
    final _patcher = patchInput ?? LargeClassPatch();
    final _patchMap = _patcher.patchMap;
    return LargeClass(
      f1: _patchMap.containsKey(LargeClass$.f1)
          ? (_patchMap[LargeClass$.f1] is Function)
                ? _patchMap[LargeClass$.f1](this.f1)
                : (_patchMap[LargeClass$.f1] is Patch)
                ? _patchMap[LargeClass$.f1].applyTo(this.f1)
                : _patchMap[LargeClass$.f1]
          : this.f1,
      f2: _patchMap.containsKey(LargeClass$.f2)
          ? (_patchMap[LargeClass$.f2] is Function)
                ? _patchMap[LargeClass$.f2](this.f2)
                : (_patchMap[LargeClass$.f2] is Patch)
                ? _patchMap[LargeClass$.f2].applyTo(this.f2)
                : _patchMap[LargeClass$.f2]
          : this.f2,
      f3: _patchMap.containsKey(LargeClass$.f3)
          ? (_patchMap[LargeClass$.f3] is Function)
                ? _patchMap[LargeClass$.f3](this.f3)
                : (_patchMap[LargeClass$.f3] is Patch)
                ? _patchMap[LargeClass$.f3].applyTo(this.f3)
                : _patchMap[LargeClass$.f3]
          : this.f3,
      f4: _patchMap.containsKey(LargeClass$.f4)
          ? (_patchMap[LargeClass$.f4] is Function)
                ? _patchMap[LargeClass$.f4](this.f4)
                : (_patchMap[LargeClass$.f4] is Patch)
                ? _patchMap[LargeClass$.f4].applyTo(this.f4)
                : _patchMap[LargeClass$.f4]
          : this.f4,
      f5: _patchMap.containsKey(LargeClass$.f5)
          ? (_patchMap[LargeClass$.f5] is Function)
                ? _patchMap[LargeClass$.f5](this.f5)
                : (_patchMap[LargeClass$.f5] is Patch)
                ? _patchMap[LargeClass$.f5].applyTo(this.f5)
                : _patchMap[LargeClass$.f5]
          : this.f5,
      f6: _patchMap.containsKey(LargeClass$.f6)
          ? (_patchMap[LargeClass$.f6] is Function)
                ? _patchMap[LargeClass$.f6](this.f6)
                : (_patchMap[LargeClass$.f6] is Patch)
                ? _patchMap[LargeClass$.f6].applyTo(this.f6)
                : _patchMap[LargeClass$.f6]
          : this.f6,
      f7: _patchMap.containsKey(LargeClass$.f7)
          ? (_patchMap[LargeClass$.f7] is Function)
                ? _patchMap[LargeClass$.f7](this.f7)
                : (_patchMap[LargeClass$.f7] is Patch)
                ? _patchMap[LargeClass$.f7].applyTo(this.f7)
                : _patchMap[LargeClass$.f7]
          : this.f7,
      f8: _patchMap.containsKey(LargeClass$.f8)
          ? (_patchMap[LargeClass$.f8] is Function)
                ? _patchMap[LargeClass$.f8](this.f8)
                : (_patchMap[LargeClass$.f8] is Patch)
                ? _patchMap[LargeClass$.f8].applyTo(this.f8)
                : _patchMap[LargeClass$.f8]
          : this.f8,
      f9: _patchMap.containsKey(LargeClass$.f9)
          ? (_patchMap[LargeClass$.f9] is Function)
                ? _patchMap[LargeClass$.f9](this.f9)
                : (_patchMap[LargeClass$.f9] is Patch)
                ? _patchMap[LargeClass$.f9].applyTo(this.f9)
                : _patchMap[LargeClass$.f9]
          : this.f9,
      f10: _patchMap.containsKey(LargeClass$.f10)
          ? (_patchMap[LargeClass$.f10] is Function)
                ? _patchMap[LargeClass$.f10](this.f10)
                : (_patchMap[LargeClass$.f10] is Patch)
                ? _patchMap[LargeClass$.f10].applyTo(this.f10)
                : _patchMap[LargeClass$.f10]
          : this.f10,
      f11: _patchMap.containsKey(LargeClass$.f11)
          ? (_patchMap[LargeClass$.f11] is Function)
                ? _patchMap[LargeClass$.f11](this.f11)
                : (_patchMap[LargeClass$.f11] is Patch)
                ? _patchMap[LargeClass$.f11].applyTo(this.f11)
                : _patchMap[LargeClass$.f11]
          : this.f11,
      f12: _patchMap.containsKey(LargeClass$.f12)
          ? (_patchMap[LargeClass$.f12] is Function)
                ? _patchMap[LargeClass$.f12](this.f12)
                : (_patchMap[LargeClass$.f12] is Patch)
                ? _patchMap[LargeClass$.f12].applyTo(this.f12)
                : _patchMap[LargeClass$.f12]
          : this.f12,
      f13: _patchMap.containsKey(LargeClass$.f13)
          ? (_patchMap[LargeClass$.f13] is Function)
                ? _patchMap[LargeClass$.f13](this.f13)
                : (_patchMap[LargeClass$.f13] is Patch)
                ? _patchMap[LargeClass$.f13].applyTo(this.f13)
                : _patchMap[LargeClass$.f13]
          : this.f13,
      f14: _patchMap.containsKey(LargeClass$.f14)
          ? (_patchMap[LargeClass$.f14] is Function)
                ? _patchMap[LargeClass$.f14](this.f14)
                : (_patchMap[LargeClass$.f14] is Patch)
                ? _patchMap[LargeClass$.f14].applyTo(this.f14)
                : _patchMap[LargeClass$.f14]
          : this.f14,
      f15: _patchMap.containsKey(LargeClass$.f15)
          ? (_patchMap[LargeClass$.f15] is Function)
                ? _patchMap[LargeClass$.f15](this.f15)
                : (_patchMap[LargeClass$.f15] is Patch)
                ? _patchMap[LargeClass$.f15].applyTo(this.f15)
                : _patchMap[LargeClass$.f15]
          : this.f15,
      f16: _patchMap.containsKey(LargeClass$.f16)
          ? (_patchMap[LargeClass$.f16] is Function)
                ? _patchMap[LargeClass$.f16](this.f16)
                : (_patchMap[LargeClass$.f16] is Patch)
                ? _patchMap[LargeClass$.f16].applyTo(this.f16)
                : _patchMap[LargeClass$.f16]
          : this.f16,
      f17: _patchMap.containsKey(LargeClass$.f17)
          ? (_patchMap[LargeClass$.f17] is Function)
                ? _patchMap[LargeClass$.f17](this.f17)
                : (_patchMap[LargeClass$.f17] is Patch)
                ? _patchMap[LargeClass$.f17].applyTo(this.f17)
                : _patchMap[LargeClass$.f17]
          : this.f17,
      f18: _patchMap.containsKey(LargeClass$.f18)
          ? (_patchMap[LargeClass$.f18] is Function)
                ? _patchMap[LargeClass$.f18](this.f18)
                : (_patchMap[LargeClass$.f18] is Patch)
                ? _patchMap[LargeClass$.f18].applyTo(this.f18)
                : _patchMap[LargeClass$.f18]
          : this.f18,
      f19: _patchMap.containsKey(LargeClass$.f19)
          ? (_patchMap[LargeClass$.f19] is Function)
                ? _patchMap[LargeClass$.f19](this.f19)
                : (_patchMap[LargeClass$.f19] is Patch)
                ? _patchMap[LargeClass$.f19].applyTo(this.f19)
                : _patchMap[LargeClass$.f19]
          : this.f19,
      f20: _patchMap.containsKey(LargeClass$.f20)
          ? (_patchMap[LargeClass$.f20] is Function)
                ? _patchMap[LargeClass$.f20](this.f20)
                : (_patchMap[LargeClass$.f20] is Patch)
                ? _patchMap[LargeClass$.f20].applyTo(this.f20)
                : _patchMap[LargeClass$.f20]
          : this.f20,
      f21: _patchMap.containsKey(LargeClass$.f21)
          ? (_patchMap[LargeClass$.f21] is Function)
                ? _patchMap[LargeClass$.f21](this.f21)
                : (_patchMap[LargeClass$.f21] is Patch)
                ? _patchMap[LargeClass$.f21].applyTo(this.f21)
                : _patchMap[LargeClass$.f21]
          : this.f21,
      f22: _patchMap.containsKey(LargeClass$.f22)
          ? (_patchMap[LargeClass$.f22] is Function)
                ? _patchMap[LargeClass$.f22](this.f22)
                : (_patchMap[LargeClass$.f22] is Patch)
                ? _patchMap[LargeClass$.f22].applyTo(this.f22)
                : _patchMap[LargeClass$.f22]
          : this.f22,
    );
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
          this.f20,
        ) ^
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

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$LargeClassToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension LargeClassPropertyHelpers on LargeClass {
  bool get hasF1 => f1.isNotEmpty;
  bool get noF1 => f1.isEmpty;
  bool get hasF2 => f2.isNotEmpty;
  bool get noF2 => f2.isEmpty;
  bool get hasF3 => f3.isNotEmpty;
  bool get noF3 => f3.isEmpty;
  bool get hasF4 => f4.isNotEmpty;
  bool get noF4 => f4.isEmpty;
  bool get hasF5 => f5.isNotEmpty;
  bool get noF5 => f5.isEmpty;
  bool get hasF6 => f6.isNotEmpty;
  bool get noF6 => f6.isEmpty;
  bool get hasF7 => f7.isNotEmpty;
  bool get noF7 => f7.isEmpty;
  bool get hasF8 => f8.isNotEmpty;
  bool get noF8 => f8.isEmpty;
  bool get hasF9 => f9.isNotEmpty;
  bool get noF9 => f9.isEmpty;
  bool get hasF10 => f10.isNotEmpty;
  bool get noF10 => f10.isEmpty;
  bool get hasF11 => f11.isNotEmpty;
  bool get noF11 => f11.isEmpty;
  bool get hasF12 => f12.isNotEmpty;
  bool get noF12 => f12.isEmpty;
  bool get hasF13 => f13.isNotEmpty;
  bool get noF13 => f13.isEmpty;
  bool get hasF14 => f14.isNotEmpty;
  bool get noF14 => f14.isEmpty;
  bool get hasF15 => f15.isNotEmpty;
  bool get noF15 => f15.isEmpty;
  bool get hasF16 => f16.isNotEmpty;
  bool get noF16 => f16.isEmpty;
  bool get hasF17 => f17.isNotEmpty;
  bool get noF17 => f17.isEmpty;
  bool get hasF18 => f18.isNotEmpty;
  bool get noF18 => f18.isEmpty;
  bool get hasF19 => f19.isNotEmpty;
  bool get noF19 => f19.isEmpty;
  bool get hasF20 => f20.isNotEmpty;
  bool get noF20 => f20.isEmpty;
  bool get hasF21 => f21.isNotEmpty;
  bool get noF21 => f21.isEmpty;
  bool get hasF22 => f22.isNotEmpty;
  bool get noF22 => f22.isEmpty;
}

extension LargeClassSerialization on LargeClass {
  Map<String, dynamic> toJson() => _$LargeClassToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$LargeClassToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
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
  f22,
}

class LargeClassPatch extends PatchBase<LargeClass, LargeClass$> {
  LargeClass applyTo(LargeClass entity) {
    return entity.patchWithLargeClass(patchInput: this);
  }

  LargeClassPatch withF1(String? value) {
    patchMap[LargeClass$.f1] = value;
    return this;
  }

  LargeClassPatch withF2(String? value) {
    patchMap[LargeClass$.f2] = value;
    return this;
  }

  LargeClassPatch withF3(String? value) {
    patchMap[LargeClass$.f3] = value;
    return this;
  }

  LargeClassPatch withF4(String? value) {
    patchMap[LargeClass$.f4] = value;
    return this;
  }

  LargeClassPatch withF5(String? value) {
    patchMap[LargeClass$.f5] = value;
    return this;
  }

  LargeClassPatch withF6(String? value) {
    patchMap[LargeClass$.f6] = value;
    return this;
  }

  LargeClassPatch withF7(String? value) {
    patchMap[LargeClass$.f7] = value;
    return this;
  }

  LargeClassPatch withF8(String? value) {
    patchMap[LargeClass$.f8] = value;
    return this;
  }

  LargeClassPatch withF9(String? value) {
    patchMap[LargeClass$.f9] = value;
    return this;
  }

  LargeClassPatch withF10(String? value) {
    patchMap[LargeClass$.f10] = value;
    return this;
  }

  LargeClassPatch withF11(String? value) {
    patchMap[LargeClass$.f11] = value;
    return this;
  }

  LargeClassPatch withF12(String? value) {
    patchMap[LargeClass$.f12] = value;
    return this;
  }

  LargeClassPatch withF13(String? value) {
    patchMap[LargeClass$.f13] = value;
    return this;
  }

  LargeClassPatch withF14(String? value) {
    patchMap[LargeClass$.f14] = value;
    return this;
  }

  LargeClassPatch withF15(String? value) {
    patchMap[LargeClass$.f15] = value;
    return this;
  }

  LargeClassPatch withF16(String? value) {
    patchMap[LargeClass$.f16] = value;
    return this;
  }

  LargeClassPatch withF17(String? value) {
    patchMap[LargeClass$.f17] = value;
    return this;
  }

  LargeClassPatch withF18(String? value) {
    patchMap[LargeClass$.f18] = value;
    return this;
  }

  LargeClassPatch withF19(String? value) {
    patchMap[LargeClass$.f19] = value;
    return this;
  }

  LargeClassPatch withF20(String? value) {
    patchMap[LargeClass$.f20] = value;
    return this;
  }

  LargeClassPatch withF21(String? value) {
    patchMap[LargeClass$.f21] = value;
    return this;
  }

  LargeClassPatch withF22(String? value) {
    patchMap[LargeClass$.f22] = value;
    return this;
  }
}

/// Field descriptors for [LargeClass] query construction
abstract final class LargeClassFields {
  static String _$getf1(LargeClass e) => e.f1;
  static const f1 = Field<LargeClass, String>('f1', _$getf1);
  static String _$getf2(LargeClass e) => e.f2;
  static const f2 = Field<LargeClass, String>('f2', _$getf2);
  static String _$getf3(LargeClass e) => e.f3;
  static const f3 = Field<LargeClass, String>('f3', _$getf3);
  static String _$getf4(LargeClass e) => e.f4;
  static const f4 = Field<LargeClass, String>('f4', _$getf4);
  static String _$getf5(LargeClass e) => e.f5;
  static const f5 = Field<LargeClass, String>('f5', _$getf5);
  static String _$getf6(LargeClass e) => e.f6;
  static const f6 = Field<LargeClass, String>('f6', _$getf6);
  static String _$getf7(LargeClass e) => e.f7;
  static const f7 = Field<LargeClass, String>('f7', _$getf7);
  static String _$getf8(LargeClass e) => e.f8;
  static const f8 = Field<LargeClass, String>('f8', _$getf8);
  static String _$getf9(LargeClass e) => e.f9;
  static const f9 = Field<LargeClass, String>('f9', _$getf9);
  static String _$getf10(LargeClass e) => e.f10;
  static const f10 = Field<LargeClass, String>('f10', _$getf10);
  static String _$getf11(LargeClass e) => e.f11;
  static const f11 = Field<LargeClass, String>('f11', _$getf11);
  static String _$getf12(LargeClass e) => e.f12;
  static const f12 = Field<LargeClass, String>('f12', _$getf12);
  static String _$getf13(LargeClass e) => e.f13;
  static const f13 = Field<LargeClass, String>('f13', _$getf13);
  static String _$getf14(LargeClass e) => e.f14;
  static const f14 = Field<LargeClass, String>('f14', _$getf14);
  static String _$getf15(LargeClass e) => e.f15;
  static const f15 = Field<LargeClass, String>('f15', _$getf15);
  static String _$getf16(LargeClass e) => e.f16;
  static const f16 = Field<LargeClass, String>('f16', _$getf16);
  static String _$getf17(LargeClass e) => e.f17;
  static const f17 = Field<LargeClass, String>('f17', _$getf17);
  static String _$getf18(LargeClass e) => e.f18;
  static const f18 = Field<LargeClass, String>('f18', _$getf18);
  static String _$getf19(LargeClass e) => e.f19;
  static const f19 = Field<LargeClass, String>('f19', _$getf19);
  static String _$getf20(LargeClass e) => e.f20;
  static const f20 = Field<LargeClass, String>('f20', _$getf20);
  static String _$getf21(LargeClass e) => e.f21;
  static const f21 = Field<LargeClass, String>('f21', _$getf21);
  static String _$getf22(LargeClass e) => e.f22;
  static const f22 = Field<LargeClass, String>('f22', _$getf22);
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
