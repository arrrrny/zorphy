import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@ZorphyEntity(principalKey: #id)
abstract class $Doc {
  String get id;
  String get title;
}
