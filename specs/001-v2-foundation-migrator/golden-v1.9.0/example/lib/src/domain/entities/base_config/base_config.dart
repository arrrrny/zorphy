import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../options/options.dart';

part 'base_config.zorphy.dart';

@zorphy
abstract class $BaseConfig {
  String get name;
  $Options? get options;
}
