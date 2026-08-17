import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'immersive_mode.dart';
import 'default_mode.dart';

part 'display_mode.zorphy.dart';
part 'display_mode.g.dart';

/// Polymorphic base for Android TWA display modes.
///
/// Wire contract (native Android): `{"type": "DEFAULT_MODE" | "IMMERSIVE_MODE"}`
/// — the discriminator key is `type` (NOT the zorphy default `__typename`),
/// and the wire values are upper-case constants (NOT the Dart class names).
///
/// This is the exact scenario issue #103 was filed for: the structure is
/// expressible in zorphy, but the generated `__typename` + class-name wire
/// would break the platform boundary. With `typeKey` + `subtypeWireValue`
/// the native contract is preserved verbatim.
@Zorphy(
  generateJson: true,
  explicitSubTypes: [$DefaultMode, $ImmersiveMode],
  nonSealed: true,
  typeKey: 'type',
)
abstract class $DisplayMode {
  String get name;
}
