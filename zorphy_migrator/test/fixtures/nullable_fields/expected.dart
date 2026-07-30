import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@Zorphy(preset: ZorphyPreset.lean)
abstract class $Profile {
  String get id;
  String? get email;
  int? get age;
}
