import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@ZorphyEntity(principalKey: #id)
abstract class $Event {
  String get id;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
}
