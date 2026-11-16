import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../options/options.dart';

part '../../../../_br_/src/domain/entities/base_config/base_config.part.dart';

@zorphy
abstract class $BaseConfig {
  String get name;
  $Options? get options;
}
