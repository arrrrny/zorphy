import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@Zorphy(preset: ZorphyPreset.lean, generateJson: true)
abstract class $Doc {
  String get id;
  String get title;
}
