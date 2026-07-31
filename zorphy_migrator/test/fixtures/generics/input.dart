import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@freezed
class Box<T> with _$Box<T> {
  const factory Box({
    required T value,
    List<T>? history,
  }) = _Box<T>;
}
