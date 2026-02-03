// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'factory_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class TestWithFactory implements $TestWithFactory {
  final String id;

  TestWithFactory({
    required this.id,
  });

  TestWithFactory copyWith({
    String? id,
  }) {
    return TestWithFactory(
      id: id ?? this.id,
    );
  }

  TestWithFactory copyWithTestWithFactory({
    String? id,
  }) {
    return copyWith(
      id: id,
    );
  }

  TestWithFactory patchWithTestWithFactory({
    TestWithFactoryPatch? patchInput,
  }) {
    final _patcher = patchInput ?? TestWithFactoryPatch();
    final _patchMap = _patcher.toPatch();
    return TestWithFactory(
        id: _patchMap.containsKey(TestWithFactory$.id)
            ? (_patchMap[TestWithFactory$.id] is Function)
                ? _patchMap[TestWithFactory$.id](this.id)
                : _patchMap[TestWithFactory$.id]
            : this.id);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestWithFactory && id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(id, 0);
  }

  @override
  String toString() {
    return 'TestWithFactory(' + 'id: ${id})';
  }

  /// Creates a [TestWithFactory] instance from JSON
  factory TestWithFactory.fromJson(Map<String, dynamic> json) =>
      _$TestWithFactoryFromJson(json);
}

enum TestWithFactory$ { id }

class TestWithFactoryPatch implements Patch<TestWithFactory> {
  final Map<TestWithFactory$, dynamic> _patch = {};

  static TestWithFactoryPatch create([Map<String, dynamic>? diff]) {
    final patch = TestWithFactoryPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue =
              TestWithFactory$.values.firstWhere((e) => e.name == key);
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

  static TestWithFactoryPatch fromPatch(Map<TestWithFactory$, dynamic> patch) {
    final _patch = TestWithFactoryPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<TestWithFactory$, dynamic> toPatch() => Map.from(_patch);

  TestWithFactory applyTo(TestWithFactory entity) {
    return entity.patchWithTestWithFactory(patchInput: this);
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

  static TestWithFactoryPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  TestWithFactoryPatch withId(String? value) {
    _patch[TestWithFactory$.id] = value;
    return this;
  }
}

extension TestWithFactorySerialization on TestWithFactory {
  Map<String, dynamic> toJson() => _$TestWithFactoryToJson(this);
}

extension TestWithFactoryCompareE on TestWithFactory {
  Map<String, dynamic> compareToTestWithFactory(TestWithFactory other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    return diff;
  }
}
