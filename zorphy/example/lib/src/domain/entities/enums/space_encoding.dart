import 'package:json_annotation/json_annotation.dart';

enum SpaceEncoding {
  @JsonValue('ENCODED')
  encoded,
  @JsonValue('PLUS')
  plus,
}
