// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex63_property_shadow_global_type.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Test extends $Test {
  @override
  final Int String;
  @override
  final Int Object;
  @override
  final Int List;
  @override
  final Int Map;
  @override
  final (Int, Int)? Never;
  @override
  final (Int, {Int named}) Type;
  @override
  final _List<(Int, Int)>? int;
  @override
  final _List<dynamic> bool;
  @override
  final IntList hashObjects;
  @override
  final _List<Int> identical;

  Test({
    required this.String,
    required this.Object,
    required this.List,
    required this.Map,
    this.Never,
    required this.Type,
    this.int,
    required this.bool,
    required this.hashObjects,
    required this.identical,
  });

  Test copyWith({
    Int? String,
    Int? Object,
    Int? List,
    Int? Map,
    (Int, Int)? Never,
    (Int, {Int named})? Type,
    _List<(Int, Int)>? int,
    _List<dynamic>? bool,
    IntList? hashObjects,
    _List<Int>? identical,
  }) {
    return Test(
      String: String ?? this.String,
      Object: Object ?? this.Object,
      List: List ?? this.List,
      Map: Map ?? this.Map,
      Never: Never ?? this.Never,
      Type: Type ?? this.Type,
      int: int ?? this.int,
      bool: bool ?? this.bool,
      hashObjects: hashObjects ?? this.hashObjects,
      identical: identical ?? this.identical,
    );
  }

  Test copyWithTest({
    Int? String,
    Int? Object,
    Int? List,
    Int? Map,
    (Int, Int)? Never,
    (Int, {Int named})? Type,
    _List<(Int, Int)>? int,
    _List<dynamic>? bool,
    IntList? hashObjects,
    _List<Int>? identical,
  }) {
    return copyWith(
      String: String,
      Object: Object,
      List: List,
      Map: Map,
      Never: Never,
      Type: Type,
      int: int,
      bool: bool,
      hashObjects: hashObjects,
      identical: identical,
    );
  }

  Test patchWithTest({TestPatch? patchInput}) {
    final _patcher = patchInput ?? TestPatch();
    final _patchMap = _patcher.toPatch();
    return Test(
      String: _patchMap.containsKey(Test$.String)
          ? (_patchMap[Test$.String] is Function)
                ? _patchMap[Test$.String](this.String)
                : _patchMap[Test$.String]
          : this.String,
      Object: _patchMap.containsKey(Test$.Object)
          ? (_patchMap[Test$.Object] is Function)
                ? _patchMap[Test$.Object](this.Object)
                : _patchMap[Test$.Object]
          : this.Object,
      List: _patchMap.containsKey(Test$.List)
          ? (_patchMap[Test$.List] is Function)
                ? _patchMap[Test$.List](this.List)
                : _patchMap[Test$.List]
          : this.List,
      Map: _patchMap.containsKey(Test$.Map)
          ? (_patchMap[Test$.Map] is Function)
                ? _patchMap[Test$.Map](this.Map)
                : _patchMap[Test$.Map]
          : this.Map,
      Never: _patchMap.containsKey(Test$.Never)
          ? (_patchMap[Test$.Never] is Function)
                ? _patchMap[Test$.Never](this.Never)
                : _patchMap[Test$.Never]
          : this.Never,
      Type: _patchMap.containsKey(Test$.Type)
          ? (_patchMap[Test$.Type] is Function)
                ? _patchMap[Test$.Type](this.Type)
                : _patchMap[Test$.Type]
          : this.Type,
      int: _patchMap.containsKey(Test$.int)
          ? (_patchMap[Test$.int] is Function)
                ? _patchMap[Test$.int](this.int)
                : _patchMap[Test$.int]
          : this.int,
      bool: _patchMap.containsKey(Test$.bool)
          ? (_patchMap[Test$.bool] is Function)
                ? _patchMap[Test$.bool](this.bool)
                : _patchMap[Test$.bool]
          : this.bool,
      hashObjects: _patchMap.containsKey(Test$.hashObjects)
          ? (_patchMap[Test$.hashObjects] is Function)
                ? _patchMap[Test$.hashObjects](this.hashObjects)
                : _patchMap[Test$.hashObjects]
          : this.hashObjects,
      identical: _patchMap.containsKey(Test$.identical)
          ? (_patchMap[Test$.identical] is Function)
                ? _patchMap[Test$.identical](this.identical)
                : _patchMap[Test$.identical]
          : this.identical,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Test &&
        String == other.String &&
        Object == other.Object &&
        List == other.List &&
        Map == other.Map &&
        Never == other.Never &&
        Type == other.Type &&
        int == other.int &&
        bool == other.bool &&
        hashObjects == other.hashObjects &&
        identical == other.identical;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.String,
      this.Object,
      this.List,
      this.Map,
      this.Never,
      this.Type,
      this.int,
      this.bool,
      this.hashObjects,
      this.identical,
    );
  }

  @override
  String toString() {
    return 'Test(' +
        'String: ${String}' +
        ', ' +
        'Object: ${Object}' +
        ', ' +
        'List: ${List}' +
        ', ' +
        'Map: ${Map}' +
        ', ' +
        'Never: ${Never}' +
        ', ' +
        'Type: ${Type}' +
        ', ' +
        'int: ${int}' +
        ', ' +
        'bool: ${bool}' +
        ', ' +
        'hashObjects: ${hashObjects}' +
        ', ' +
        'identical: ${identical})';
  }

  /// Creates a [Test] instance from JSON
  factory Test.fromJson(Map<String, dynamic> json) => _$TestFromJson(json);
}

enum Test$ {
  String,
  Object,
  List,
  Map,
  Never,
  Type,
  int,
  bool,
  hashObjects,
  identical,
}

class TestPatch implements Patch<Test> {
  final Map<Test$, dynamic> _patch = {};

  static TestPatch create([Map<String, dynamic>? diff]) {
    final patch = TestPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Test$.values.firstWhere((e) => e.name == key);
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

  static TestPatch fromPatch(Map<Test$, dynamic> patch) {
    final _patch = TestPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Test$, dynamic> toPatch() => Map.from(_patch);

  Test applyTo(Test entity) {
    return entity.patchWithTest(patchInput: this);
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

  static TestPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  TestPatch withString(Int? value) {
    _patch[Test$.String] = value;
    return this;
  }

  TestPatch withObject(Int? value) {
    _patch[Test$.Object] = value;
    return this;
  }

  TestPatch withList(Int? value) {
    _patch[Test$.List] = value;
    return this;
  }

  TestPatch withMap(Int? value) {
    _patch[Test$.Map] = value;
    return this;
  }

  TestPatch withNever((Int, Int)? value) {
    _patch[Test$.Never] = value;
    return this;
  }

  TestPatch withType((Int, {Int named})? value) {
    _patch[Test$.Type] = value;
    return this;
  }

  TestPatch withInt(_List<(Int, Int)>? value) {
    _patch[Test$.int] = value;
    return this;
  }

  TestPatch withBool(_List<dynamic>? value) {
    _patch[Test$.bool] = value;
    return this;
  }

  TestPatch withHashObjects(IntList? value) {
    _patch[Test$.hashObjects] = value;
    return this;
  }

  TestPatch withIdentical(_List<Int>? value) {
    _patch[Test$.identical] = value;
    return this;
  }
}

extension TestSerialization on Test {
  Map<String, dynamic> toJson() => _$TestToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TestToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension TestCompareE on Test {
  Map<String, dynamic> compareToTest(Test other) {
    final Map<String, dynamic> diff = {};

    if (String != other.String) {
      diff['String'] = () => other.String;
    }
    if (Object != other.Object) {
      diff['Object'] = () => other.Object;
    }
    if (List != other.List) {
      diff['List'] = () => other.List;
    }
    if (Map != other.Map) {
      diff['Map'] = () => other.Map;
    }
    if (Never != other.Never) {
      diff['Never'] = () => other.Never;
    }
    if (Type != other.Type) {
      diff['Type'] = () => other.Type;
    }
    if (int != other.int) {
      diff['int'] = () => other.int;
    }
    if (bool != other.bool) {
      diff['bool'] = () => other.bool;
    }
    if (hashObjects != other.hashObjects) {
      diff['hashObjects'] = () => other.hashObjects;
    }
    if (identical != other.identical) {
      diff['identical'] = () => other.identical;
    }
    return diff;
  }
}

class Test2 extends $Test2 {
  @override
  final Int Function(Int p1, {Int n1, required Int n2})? Function;
  @override
  final Int Function(Int p1, [Int p2, Int p3]) PositionalFunction;

  Test2({this.Function, required this.PositionalFunction});

  Test2 copyWith({
    Int Function(Int p1, {Int n1, required Int n2})? Function,
    Int Function(Int p1, [Int p2, Int p3])? PositionalFunction,
  }) {
    return Test2(
      Function: Function ?? this.Function,
      PositionalFunction: PositionalFunction ?? this.PositionalFunction,
    );
  }

  Test2 copyWithTest2({
    Int Function(Int p1, {Int n1, required Int n2})? Function,
    Int Function(Int p1, [Int p2, Int p3])? PositionalFunction,
  }) {
    return copyWith(Function: Function, PositionalFunction: PositionalFunction);
  }

  Test2 patchWithTest2({Test2Patch? patchInput}) {
    final _patcher = patchInput ?? Test2Patch();
    final _patchMap = _patcher.toPatch();
    return Test2(
      Function: _patchMap.containsKey(Test2$.Function)
          ? (_patchMap[Test2$.Function] is Function)
                ? _patchMap[Test2$.Function](this.Function)
                : _patchMap[Test2$.Function]
          : this.Function,
      PositionalFunction: _patchMap.containsKey(Test2$.PositionalFunction)
          ? (_patchMap[Test2$.PositionalFunction] is Function)
                ? _patchMap[Test2$.PositionalFunction](this.PositionalFunction)
                : _patchMap[Test2$.PositionalFunction]
          : this.PositionalFunction,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Test2 &&
        Function == other.Function &&
        PositionalFunction == other.PositionalFunction;
  }

  @override
  int get hashCode {
    return Object.hash(this.Function, this.PositionalFunction);
  }

  @override
  String toString() {
    return 'Test2(' +
        'Function: ${Function}' +
        ', ' +
        'PositionalFunction: ${PositionalFunction})';
  }
}

enum Test2$ { Function, PositionalFunction }

class Test2Patch implements Patch<Test2> {
  final Map<Test2$, dynamic> _patch = {};

  static Test2Patch create([Map<String, dynamic>? diff]) {
    final patch = Test2Patch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Test2$.values.firstWhere((e) => e.name == key);
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

  static Test2Patch fromPatch(Map<Test2$, dynamic> patch) {
    final _patch = Test2Patch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Test2$, dynamic> toPatch() => Map.from(_patch);

  Test2 applyTo(Test2 entity) {
    return entity.patchWithTest2(patchInput: this);
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

  static Test2Patch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  Test2Patch withFunction(
    Int Function(Int p1, {Int n1, required Int n2})? value,
  ) {
    _patch[Test2$.Function] = value;
    return this;
  }

  Test2Patch withPositionalFunction(
    Int Function(Int p1, [Int p2, Int p3])? value,
  ) {
    _patch[Test2$.PositionalFunction] = value;
    return this;
  }
}

extension Test2CompareE on Test2 {
  Map<String, dynamic> compareToTest2(Test2 other) {
    final Map<String, dynamic> diff = {};

    return diff;
  }
}
