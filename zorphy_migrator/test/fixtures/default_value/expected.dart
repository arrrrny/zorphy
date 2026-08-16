import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@Zorphy()
abstract class $Account {
  String get id;
  @JsonKey(defaultValue: 0)
  int get loginCount;
}
