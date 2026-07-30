import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'vs_freezed_union.zorphy.dart';
part 'vs_freezed_union.g.dart';

/// Example 2 — a sealed union in zorphy.
///
/// The freezed equivalent is:
/// ```dart
/// @freezed
/// class Result with _$Result {
///   const factory Result.ok(String value) = Ok;
///   const factory Result.err(String message) = Err;
/// }
/// ```
///
/// freezed gives you `when`/`map` helper methods; zorphy generates a real
/// sealed hierarchy so Dart 3's native pattern matching is exhaustive:
/// ```dart
/// String describe(Result r) => switch (r) {
///   Ok(:final value) => 'ok: $value',
///   Err(:final message) => 'err: $message',
/// };
/// ```
@Zorphy(generateJson: true, explicitSubTypes: [$Ok, $Err])
abstract class $$Result {}

@Zorphy(generateJson: true)
abstract class $Ok implements $$Result {
  String get value;
}

@Zorphy(generateJson: true)
abstract class $Err implements $$Result {
  String get message;
}
