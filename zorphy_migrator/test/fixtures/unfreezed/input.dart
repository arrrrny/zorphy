import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@unfreezed
class MutableCounter with _$MutableCounter {
  factory MutableCounter({
    required int count,
  }) = _MutableCounter;
}
