import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@Zorphy(preset: ZorphyPreset.lean)
abstract class $Box<T> {
  T get value;
  List<T>? get history;
}
