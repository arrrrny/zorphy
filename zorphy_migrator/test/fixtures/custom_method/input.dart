import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@freezed
class Money with _$Money {
  const factory Money({
    required int cents,
    required String currency,
  }) = _Money;

  String format() => '$currency ${cents / 100}';
}
