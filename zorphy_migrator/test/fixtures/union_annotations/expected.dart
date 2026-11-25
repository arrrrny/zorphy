import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@ZorphyUnion()
abstract class $$Event {
  factory $$Event.named(String label, int retryCount, int priority) =
      $NamedEvent;
}

@ZorphyValue()
class $NamedEvent implements $$Event {
  @JsonKey(name: 'wire_label')
  final String label;
  @JsonKey(defaultValue: 7)
  final int retryCount;
  @JsonKey(defaultValue: 3, name: 'priority_wire')
  final int priority;
  const $NamedEvent(this.label, this.retryCount, this.priority);
}
