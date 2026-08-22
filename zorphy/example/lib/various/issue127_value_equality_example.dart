// Regression fixture for issue #127:
// "autoId entities cannot be compared by value — generated uuid leaks
//  into ==, hashCode, toJson and toJsonLean (silently breaks dedup/
//  Set/Map-key logic)".
//
// Three concrete entities exercising every code path the fix touches:
//
//   1. `$AutoIdDefault` — `autoId: true` with NO `equalityExcludes`.
//      Verifies the back-compat default: `==`/`hashCode`/`toJsonLean()`
//      /`compareToAutoIdDefault()` still include `id` (so existing
//      code is unchanged) AND the new value-comparison surface
//      (`valueEquals`, `toJsonValue`) drops `id`.
//
//   2. `$AutoIdExcludesId` — `autoId: true` with `equalityExcludes:
//      ['id']`. Verifies the opt-out: `==`/`hashCode`/`toJsonLean()`
//      /`compareToAutoIdExcludesId()` all drop `id`; `toJson()` keeps
//      `id` (for persistence round-trip); `valueEquals` and
//      `toJsonValue` also drop `id`.
//
//   3. `$NonAutoIdExcludesCreatedAt` — non-autoId entity with
//      `equalityExcludes: ['createdAt']`. Verifies that the field-level
//      opt-out works for any field, not just the literal `id`, and that
//      `valueEquals`/`toJsonValue` are NOT emitted when `autoId` is
//      false (they are an autoId-only surface).
//
// The fixture source is read by
// `test/regression/issue_127_value_equality_test.dart` and the
// generated `.zorphy.dart` part is asserted by the same test.
library; // ignore: directives_ordering

import 'package:uuid/uuid.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue127_value_equality_example.zorphy.dart';
part 'issue127_value_equality_example.g.dart';

// 1. Back-compat default — autoId with no exclusion. The minted uuid
//    is still in ==/hashCode/toJsonLean/compareTo (unchanged), and the
//    new valueEquals/toJsonValue methods drop it.
@Zorphy(
  generateJson: true,
  autoId: true,
  generateCompareTo: true,
)
abstract class $AutoIdDefault {
  String get id;
  String get toolName;
  String get normalizedArgs;
}

// 2. Field-level opt-out — autoId with equalityExcludes: ['id']. The
//    minted uuid is now dropped from ==/hashCode/toJsonLean/compareTo,
//    AND valueEquals/toJsonValue also drop it. toJson() still keeps
//    id for persistence round-trip.
@Zorphy(
  generateJson: true,
  autoId: true,
  generateCompareTo: true,
  equalityExcludes: ['id'],
)
abstract class $AutoIdExcludesId {
  String get id;
  String get toolName;
  String get normalizedArgs;
}

// 3. Field-level opt-out on a non-autoId entity. The `createdAt`
//    metadata field is dropped from ==/hashCode/toJsonLean/compareTo.
//    No valueEquals/toJsonValue methods are emitted (autoId is false).
@Zorphy(
  generateJson: true,
  generateCompareTo: true,
  equalityExcludes: ['createdAt'],
)
abstract class $NonAutoIdExcludesCreatedAt {
  String get name;
  int get score;
  String get createdAt;
}
