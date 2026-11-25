import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@ZorphyEntity(principalKey: #id)
abstract class $User {
  String get id;
  String get name;
}
