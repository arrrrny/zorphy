import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'display_mode.dart';

part 'immersive_mode.g.dart';
part '../../../../_br_/src/domain/entities/display_mode/immersive_mode.part.dart';

/// Immersive TWA display mode — wire value `IMMERSIVE_MODE`.
@Zorphy(generateJson: true, subtypeWireValue: 'IMMERSIVE_MODE')
abstract class $ImmersiveMode implements $DisplayMode {
  @override
  String get name => 'IMMERSIVE_MODE';
}
