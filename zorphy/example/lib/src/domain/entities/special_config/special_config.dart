import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../base_config/base_config.dart';
import '../advanced_options/advanced_options.dart';

part 'special_config.zorphy.dart';

/// A config that overrides options with a more specific type.
@zorphy
abstract class $SpecialConfig implements $BaseConfig {
  int get priority;
  @override
  $AdvancedOptions? get options;
}
