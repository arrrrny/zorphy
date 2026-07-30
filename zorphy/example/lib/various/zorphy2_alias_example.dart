import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'zorphy2_alias_example.zorphy.dart';

/// Verifies the deprecated `@zorphy2` alias keeps working through the
/// unified single-pass builder (2.0): it must behave exactly like
/// `@zorphy` and emit into the standard `.zorphy.dart` part.
// ignore: deprecated_member_use
@zorphy2
abstract class $LegacyShape {
  String get label;
}

// ignore: deprecated_member_use
@Zorphy2(generateJson: false)
abstract class $LegacyPoint {
  double get x;
  double get y;
}
