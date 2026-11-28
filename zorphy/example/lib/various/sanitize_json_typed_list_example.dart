// Fixture for PR #349: `_sanitizeJson` must preserve a typed list value
// type when it recurses into a typed inner map.
//
// A manual `toJson` converter returns a typed
// `Map<String, List<Map<String, dynamic>>>` (mirrors zik_zak's
// `VariationsParserOptions.cleaners`). The generated `_sanitizeJson`
// recurses into that typed inner map and reassigns each value back into
// its typed slot. The old list branch returned `json.map(...).toList()`
// — a `List<dynamic>` — which threw
// `type 'List<dynamic>' is not a subtype of
//  type 'List<Map<String, dynamic>>'` on that assignment. The fix walks
// the list in place without reassigning its slots, so the typed list (and
// an unmodifiable list) survives sanitization.

import 'package:zorphy/zorphy.dart';

part 'sanitize_json_typed_list_example.zorphy.dart';
part 'sanitize_json_typed_list_example.g.dart';

/// Converter that hands back a typed inner map, exercising the typed
/// `List<Map<String, dynamic>>` slot inside `_sanitizeJson`.
class TypedCleanersConverter {
  TypedCleanersConverter._();

  static Map<String, List<Map<String, dynamic>>>? toJson(
    Map<String, List<Map<String, dynamic>>>? value,
  ) => value;

  static Map<String, List<Map<String, dynamic>>>? fromJson(
    Map<String, List<Map<String, dynamic>>>? json,
  ) => json;
}

@Zorphy(generateJson: true)
abstract class $SanitizeTypedListExample {
  @JsonKey(
    toJson: TypedCleanersConverter.toJson,
    fromJson: TypedCleanersConverter.fromJson,
  )
  Map<String, List<Map<String, dynamic>>>? get cleaners;
}
