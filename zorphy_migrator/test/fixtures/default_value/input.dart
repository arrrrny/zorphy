import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    @Default(0) int loginCount,
  }) = _Account;
}
