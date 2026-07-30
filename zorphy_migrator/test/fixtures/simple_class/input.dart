import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;
}
