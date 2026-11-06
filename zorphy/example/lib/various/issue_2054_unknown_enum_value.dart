// Fixture for issue #2054: `@JsonKey(unknownEnumValue: ...)` must survive
// zorphy's re-emission of the user's `@JsonKey` onto the generated class.
//
// json_serializable reads `unknownEnumValue` off the generated field's
// `@JsonKey` and emits `$enumDecodeNullable(map, v, unknownValue: ...)`.
// When zorphy drops the argument, an unknown wire value throws
// `CheckedFromJsonException` instead of falling back.
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_2054_unknown_enum_value.zorphy.dart';
part 'issue_2054_unknown_enum_value.g.dart';

enum ParserType2054 { element, list, detail, empty }

@Zorphy(generateJson: true)
abstract class $Parser2054 {
  const $Parser2054();

  String get id;

  @JsonKey(
    defaultValue: ParserType2054.empty,
    unknownEnumValue: ParserType2054.empty,
  )
  ParserType2054 get type;
}
