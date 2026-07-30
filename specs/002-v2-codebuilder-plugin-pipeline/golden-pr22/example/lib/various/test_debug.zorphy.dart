// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'test_debug.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class TestDebug {
  @JsonKey(name: 'test_field')
  final String? name;
  @JsonKey(toJson: LocaleConverter.toJson, fromJson: LocaleConverter.fromJson)
  final Locale? locale;

  TestDebug({this.name, this.locale});

  TestDebug copyWith({String? name, Locale? locale}) {
    return TestDebug(name: name ?? this.name, locale: locale ?? this.locale);
  }

  TestDebug copyWithTestDebug({String? name, Locale? locale}) {
    return copyWith(name: name, locale: locale);
  }

  TestDebug patchWithTestDebug({TestDebugPatch? patchInput}) {
    final _patcher = patchInput ?? TestDebugPatch();
    final _patchMap = _patcher.patchMap;
    return TestDebug(
      name: _patchMap.containsKey(TestDebug$.name)
          ? (_patchMap[TestDebug$.name] is Function)
                ? _patchMap[TestDebug$.name](this.name)
                : (_patchMap[TestDebug$.name] is Patch)
                ? _patchMap[TestDebug$.name].applyTo(this.name)
                : _patchMap[TestDebug$.name]
          : this.name,
      locale: _patchMap.containsKey(TestDebug$.locale)
          ? (_patchMap[TestDebug$.locale] is Function)
                ? _patchMap[TestDebug$.locale](this.locale)
                : (_patchMap[TestDebug$.locale] is Patch)
                ? _patchMap[TestDebug$.locale].applyTo(this.locale)
                : _patchMap[TestDebug$.locale]
          : this.locale,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestDebug && name == other.name && locale == other.locale;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.locale);
  }

  @override
  String toString() {
    return 'TestDebug(' + 'name: ${name}' + ', ' + 'locale: ${locale})';
  }

  /// Creates a [TestDebug] instance from JSON
  factory TestDebug.fromJson(Map<String, dynamic> json) =>
      _$TestDebugFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TestDebugToJson(this);
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

extension TestDebugPropertyHelpers on TestDebug {
  bool get hasName => name?.isNotEmpty == true;
  bool get noName => name?.isEmpty ?? true;
  String get nameRequired =>
      name ?? (throw StateError('name is required but was null'));
  bool get hasLocale => locale != null;
  bool get noLocale => locale == null;
  Locale get localeRequired =>
      locale ?? (throw StateError('locale is required but was null'));
}

extension TestDebugSerialization on TestDebug {
  Map<String, dynamic> toJson() => _$TestDebugToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TestDebugToJson(this);
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

enum TestDebug$ { name, locale }

class TestDebugPatch extends PatchBase<TestDebug, TestDebug$> {
  TestDebug applyTo(TestDebug entity) {
    return entity.patchWithTestDebug(patchInput: this);
  }

  TestDebugPatch withName(String? value) {
    patchMap[TestDebug$.name] = value;
    return this;
  }

  TestDebugPatch withLocale(Locale? value) {
    patchMap[TestDebug$.locale] = value;
    return this;
  }
}

/// Field descriptors for [TestDebug] query construction
abstract final class TestDebugFields {
  static String? _$getname(TestDebug e) => e.name;
  static const name = Field<TestDebug, String?>('name', _$getname);
  static Locale? _$getlocale(TestDebug e) => e.locale;
  static const locale = Field<TestDebug, Locale?>('locale', _$getlocale);
}

extension TestDebugCompareE on TestDebug {
  Map<String, dynamic> compareToTestDebug(TestDebug other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (locale != other.locale) {
      diff['locale'] = () => other.locale;
    }
    return diff;
  }
}
