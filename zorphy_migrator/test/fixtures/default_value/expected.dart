import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@ZorphyEntity(principalKey: #id)
abstract class $Account {
  String get id;
  @JsonKey(defaultValue: 0)
  int get loginCount;
}
