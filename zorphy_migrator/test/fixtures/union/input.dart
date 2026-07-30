import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@freezed
class Result with _$Result {
  const factory Result.ok(String value) = Ok;
  const factory Result.err(String message, int? code) = Err;
}
