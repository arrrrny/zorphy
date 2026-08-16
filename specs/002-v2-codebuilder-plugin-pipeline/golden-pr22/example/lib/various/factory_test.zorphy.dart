// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'factory_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true, constructor: '_')
class TestWithFactory {
  final String id;

  TestWithFactory._({required this.id});

  TestWithFactory copyWith({String? id}) {
    return TestWithFactory._(id: id ?? this.id);
  }

  TestWithFactory copyWithTestWithFactory({String? id}) {
    return copyWith(id: id);
  }

  factory TestWithFactory.create({required String id}) =>
      $TestWithFactory.create(id: id);

  TestWithFactory patchWithTestWithFactory({TestWithFactoryPatch? patchInput}) {
    final _patcher = patchInput ?? TestWithFactoryPatch();
    final _patchMap = _patcher.patchMap;
    return TestWithFactory._(
      id: _patchMap.containsKey(TestWithFactory$.id)
          ? (_patchMap[TestWithFactory$.id] is Function)
                ? _patchMap[TestWithFactory$.id](this.id)
                : (_patchMap[TestWithFactory$.id] is Patch)
                ? _patchMap[TestWithFactory$.id].applyTo(this.id)
                : _patchMap[TestWithFactory$.id]
          : this.id,
    );
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

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TestWithFactoryToJson(this);
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

extension TestWithFactoryPropertyHelpers on TestWithFactory {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
}

extension TestWithFactorySerialization on TestWithFactory {
  Map<String, dynamic> toJson() => _$TestWithFactoryToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TestWithFactoryToJson(this);
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

enum TestWithFactory$ { id }

class TestWithFactoryPatch
    extends PatchBase<TestWithFactory, TestWithFactory$> {
  TestWithFactory applyTo(TestWithFactory entity) {
    return entity.patchWithTestWithFactory(patchInput: this);
  }

  TestWithFactoryPatch withId(String? value) {
    patchMap[TestWithFactory$.id] = value;
    return this;
  }
}

/// Field descriptors for [TestWithFactory] query construction
abstract final class TestWithFactoryFields {
  static String _$getid(TestWithFactory e) => e.id;
  static const id = Field<TestWithFactory, String>('id', _$getid);
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
