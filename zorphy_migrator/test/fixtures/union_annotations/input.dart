import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@freezed
class Event with _$Event {
  const factory Event.named({
    @JsonKey(name: 'wire_label') required String label,
    @Default(7) int retryCount,
    @JsonKey(name: 'priority_wire') @Default(3) int priority,
  }) = NamedEvent;
}
