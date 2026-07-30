import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'vs_freezed_simple.zorphy.dart';
part 'vs_freezed_simple.g.dart';

/// Example 1 — a simple data class in zorphy.
///
/// The freezed equivalent is:
/// ```dart
/// @freezed
/// class User with _$User {
///   const factory User({
///     required String id,
///     required String name,
///     String? email,
///   }) = _User;
///   factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
/// }
/// ```
///
/// With the lean preset, zorphy emits only what this class needs:
/// constructor, copyWith, ==/hashCode, toString, and JSON — no patch
/// classes, filter descriptors, or compareTo machinery.
@Zorphy(preset: ZorphyPreset.lean, generateJson: true)
abstract class $User {
  String get id;
  String get name;
  String? get email;
}
