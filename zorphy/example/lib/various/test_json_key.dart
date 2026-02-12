import 'package:json_annotation/json_annotation.dart';
import 'converters/locale_converter.dart';
import 'locale.dart';

part 'test_json_key.g.dart';

@JsonSerializable()
class TestClass {
  @JsonKey(toJson: LocaleConverter.toJson, fromJson: LocaleConverter.fromJson)
  final Locale? locale;

  TestClass({this.locale});

  factory TestClass.fromJson(Map<String, dynamic> json) => _$TestClassFromJson(json);
  Map<String, dynamic> toJson() => _$TestClassToJson(this);
}
