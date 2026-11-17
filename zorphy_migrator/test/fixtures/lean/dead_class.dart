import 'package:zorphy_annotation/zorphy_annotation.dart';

/// Nothing in the target references this class, so every generated feature it
/// asks for is dead weight.
@Zorphy(generatePatch: true, generateFilter: true, generateJson: true,
    autoId: true)
abstract class $DeadClass {
  String get title;
}
