import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'display_mode.dart';

part 'default_mode.zorphy.dart';
part 'default_mode.g.dart';

/// Default TWA display mode — wire value `DEFAULT_MODE`.
@Zorphy(generateJson: true, subtypeWireValue: 'DEFAULT_MODE')
abstract class $DefaultMode implements $DisplayMode {
  @override
  String get name => 'DEFAULT_MODE';
}
