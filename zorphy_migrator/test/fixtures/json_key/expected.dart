import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@Zorphy(preset: ZorphyPreset.lean, generateJson: true)
abstract class $Event {
  String get id;
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
}
