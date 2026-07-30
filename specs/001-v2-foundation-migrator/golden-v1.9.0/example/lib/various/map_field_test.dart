import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'map_field_test.zorphy.dart';
part 'map_field_test.g.dart';

/// Regression test for typed Map field deserialization.
///
/// Reproduces the original bug where `Map<String, String>?` fields failed with:
///   type '_Map<String, dynamic>' is not a subtype of type 'Map<String, String>?'
/// With the native `checked: true` approach, json_serializable handles the
/// recursive map value conversion in the generated `.g.dart`.
@Zorphy(generateJson: true)
abstract class $MapHolder {
  String get id;

  /// Typed map — the field that originally broke inline casting.
  Map<String, String>? get replacements;

  /// Non-nullable typed map.
  Map<String, int> get counts;

  /// Map with nested entity values.
  Map<String, $Tag>? get tags;
}

@Zorphy(generateJson: true)
abstract class $Tag {
  String get label;
}
