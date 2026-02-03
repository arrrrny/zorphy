// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex41_inheritance_generics.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

sealed class $A<T> {
  const $A._internal();
}

class B<T> implements $$A {
  final T data;

  B({required this.data});

  B copyWith({T? data}) {
    return B(data: data ?? this.data);
  }

  B copyWithB({T? data}) {
    return copyWith(data: data);
  }

  B patchWithB({BPatch? patchInput}) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return B(
      data: _patchMap.containsKey(B$.data)
          ? (_patchMap[B$.data] is Function)
                ? _patchMap[B$.data](this.data)
                : _patchMap[B$.data]
          : this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is B && data == other.data;
  }

  @override
  int get hashCode {
    return Object.hash(data, 0);
  }

  @override
  String toString() {
    return 'B(' + 'data: ${data})';
  }
}

enum B$ { data }

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

  BPatch withData(dynamic value) {
    _patch[B$.data] = value;
    return this;
  }
}

extension BCompareE on B {
  Map<String, dynamic> compareToB(B other) {
    final Map<String, dynamic> diff = {};

    if (data != other.data) {
      diff['data'] = () => other.data;
    }
    return diff;
  }
}

class C<T> implements $$A {
  final eEnumExample failureCode;
  final String description;

  C({required this.failureCode, required this.description});

  C copyWith({eEnumExample? failureCode, String? description}) {
    return C(
      failureCode: failureCode ?? this.failureCode,
      description: description ?? this.description,
    );
  }

  C copyWithC({eEnumExample? failureCode, String? description}) {
    return copyWith(failureCode: failureCode, description: description);
  }

  C patchWithC({CPatch? patchInput}) {
    final _patcher = patchInput ?? CPatch();
    final _patchMap = _patcher.toPatch();
    return C(
      failureCode: _patchMap.containsKey(C$.failureCode)
          ? (_patchMap[C$.failureCode] is Function)
                ? _patchMap[C$.failureCode](this.failureCode)
                : _patchMap[C$.failureCode]
          : this.failureCode,
      description: _patchMap.containsKey(C$.description)
          ? (_patchMap[C$.description] is Function)
                ? _patchMap[C$.description](this.description)
                : _patchMap[C$.description]
          : this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is C &&
        failureCode == other.failureCode &&
        description == other.description;
  }

  @override
  int get hashCode {
    return Object.hash(this.failureCode, this.description);
  }

  @override
  String toString() {
    return 'C(' +
        'failureCode: ${failureCode}' +
        ', ' +
        'description: ${description})';
  }
}

enum C$ { failureCode, description }

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

  CPatch withFailureCode(eEnumExample? value) {
    _patch[C$.failureCode] = value;
    return this;
  }

  CPatch withDescription(String? value) {
    _patch[C$.description] = value;
    return this;
  }
}

extension CCompareE on C {
  Map<String, dynamic> compareToC(C other) {
    final Map<String, dynamic> diff = {};

    if (failureCode != other.failureCode) {
      diff['failureCode'] = () => other.failureCode;
    }
    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    return diff;
  }
}
