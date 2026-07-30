import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'preset_example.zorphy.dart';

/// Lean preset: only class, constructor, copyWith, ==/hashCode, toString.
/// Must NOT emit patch, filter, compareTo, property helpers, field enum,
/// fields class, or changeTo symbols.
@Zorphy(preset: ZorphyPreset.lean)
abstract class $LeanUser {
  String get id;
  String get name;
}

/// Lean preset with a single granular override: lean output plus the
/// patch API only.
@Zorphy(preset: ZorphyPreset.lean, generatePatch: true)
abstract class $LeanPatchedTodo {
  String get title;
  bool get completed;
}

/// Full preset: standard output plus function-based copyWith.
@Zorphy(preset: ZorphyPreset.full)
abstract class $FullConfig {
  String get key;
  String? get value;
}
