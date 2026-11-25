import 'package:zorphy_annotation/zorphy_annotation.dart';

part '../_br_/v3_archetypes/legacy_control.part.dart';

// Issue #223 legacy control: the pre-v3 annotation must keep generating
// beside the v3 archetype surface until the #194 migration gate.
@Zorphy()
abstract class $LegacyGreeting {
  String get message;
}
