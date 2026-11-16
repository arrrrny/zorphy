import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'display_mode.dart';

part 'default_mode.g.dart';
part '../../../../_br_/src/domain/entities/display_mode/default_mode.part.dart';

/// Default TWA display mode — wire value `DEFAULT_MODE`.
@Zorphy(generateJson: true, subtypeWireValue: 'DEFAULT_MODE')
abstract class $DefaultMode implements $DisplayMode {
  @override
  String get name => 'DEFAULT_MODE';
}
