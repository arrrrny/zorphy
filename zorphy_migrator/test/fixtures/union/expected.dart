import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@ZorphyUnion()
abstract class $$Result {
  factory $$Result.ok(String value) = $Ok;
  factory $$Result.err(String message, int? code) = $Err;
}

@ZorphyValue()
class $Ok implements $$Result {
  final String value;
  const $Ok(this.value);
}

@ZorphyValue()
class $Err implements $$Result {
  final String message;
  final int? code;
  const $Err(this.message, this.code);
}
