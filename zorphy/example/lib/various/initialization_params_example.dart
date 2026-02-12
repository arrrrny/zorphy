// Touch for re-analysis
import 'package:zorphy/zorphy.dart';

import 'converters/locale_converter.dart';
import 'locale.dart';
import 'params.dart';

part 'initialization_params_example.zorphy.dart';
part 'initialization_params_example.g.dart';

@Zorphy(generateJson: true, generateFilter: true)
abstract class $InitializationParamsExample {
  Duration get timeout => Duration(seconds: 5);
  bool get forceRefresh => true;
  $Params? get params;
  $Params? get credentials;
  $Params? get settings;

  @deprecated
  @JsonKey(toJson: LocaleConverter.toJson, fromJson: LocaleConverter.fromJson)
  Locale? get locale;
}
