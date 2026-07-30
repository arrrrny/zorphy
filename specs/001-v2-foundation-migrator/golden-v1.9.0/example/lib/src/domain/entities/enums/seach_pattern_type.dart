import 'package:json_annotation/json_annotation.dart';

enum SearchPatternType {
  @JsonValue('QUERY')
  query,

  @JsonValue('PATH')
  path,

  @JsonValue('MIXED')
  mixed,
}
