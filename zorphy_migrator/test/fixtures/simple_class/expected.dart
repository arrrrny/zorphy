import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@Zorphy(preset: ZorphyPreset.lean)
abstract class $User {
  String get id;
  String get name;
}
