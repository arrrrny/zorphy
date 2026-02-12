import 'package:zorphy/zorphy.dart';
import 'converters/locale_converter.dart';
import 'locale.dart';
import 'params.dart';

part 'test_debug.zorphy.dart';
part 'test_debug.g.dart';

@Zorphy(generateJson: true, generateFilter: true)
abstract class $TestDebug {
  @JsonKey(name: 'test_field')
  String? get name;
  
  @JsonKey(toJson: LocaleConverter.toJson, fromJson: LocaleConverter.fromJson)
  Locale? get locale;
}
