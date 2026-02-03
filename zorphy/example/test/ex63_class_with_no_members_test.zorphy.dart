// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex63_class_with_no_members_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class EulaState extends $EulaState {

  EulaState({
  });

  EulaState copyWith({
  }) {
    return EulaState();
  }




  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EulaState;
  }

  @override
  int get hashCode {
    return 0;
  }

  @override
  String toString() {
    return 'EulaState()';
  }

}



extension EulaStateCompareE on EulaState {
  Map<String, dynamic> compareToEulaState(EulaState other) {
    final Map<String, dynamic> diff = {};

    return diff;
  }
}


extension EulaStateChangeToE on EulaState {
  AgreedEulaState changeToAgreedEulaState({required bool test}) {
    final _patcher = AgreedEulaStatePatch();
    _patcher.withTest(test);
    final _patchMap = _patcher.toPatch();
    return AgreedEulaState(
      test: _patchMap[AgreedEulaState$.test]
    );
  }

}




class AgreedEulaState extends $AgreedEulaState implements EulaState {
  @override
  final bool test;

  AgreedEulaState({
    required this.test,
  });

  AgreedEulaState copyWith({
    bool? test,
  }) {
    return AgreedEulaState(
      test: test ?? this.test,
    );
  }

  AgreedEulaState copyWithAgreedEulaState({
    bool? test,
  }) {
    return copyWith(
      test: test,
    );
  }

  AgreedEulaState patchWithAgreedEulaState({
    AgreedEulaStatePatch? patchInput,
  }) {
    final _patcher = patchInput ?? AgreedEulaStatePatch();
    final _patchMap = _patcher.toPatch();
    return AgreedEulaState(
      test: _patchMap.containsKey(AgreedEulaState$.test) ? (_patchMap[AgreedEulaState$.test] is Function) ? _patchMap[AgreedEulaState$.test](this.test) : _patchMap[AgreedEulaState$.test] : this.test
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgreedEulaState &&
        test == other.test;
  }

  @override
  int get hashCode {
    return Object.hash(test, 0);
  }

  @override
  String toString() {
    return 'AgreedEulaState(' +
        'test: ${test})';
  }

}
enum AgreedEulaState$ {
test
}


class AgreedEulaStatePatch implements Patch<AgreedEulaState> {
  final Map<AgreedEulaState$, dynamic> _patch = {};

  static AgreedEulaStatePatch create([Map<String, dynamic>? diff]) {
    final patch = AgreedEulaStatePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = AgreedEulaState$.values.firstWhere((e) => e.name == key);
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

  static AgreedEulaStatePatch fromPatch(Map<AgreedEulaState$, dynamic> patch) {
    final _patch = AgreedEulaStatePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<AgreedEulaState$, dynamic> toPatch() => Map.from(_patch);

  AgreedEulaState applyTo(AgreedEulaState entity) {
    return entity.patchWithAgreedEulaState(patchInput: this);
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

  static AgreedEulaStatePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  AgreedEulaStatePatch withTest(bool? value) {
    _patch[AgreedEulaState$.test] = value;
    return this;
  }

}


extension AgreedEulaStateCompareE on AgreedEulaState {
  Map<String, dynamic> compareToAgreedEulaState(AgreedEulaState other) {
    final Map<String, dynamic> diff = {};

    if (test != other.test) {
      diff['test'] = () => other.test;
    }
    return diff;
  }
}
