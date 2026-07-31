import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    String? email,
    int? age,
  }) = _Profile;
}
