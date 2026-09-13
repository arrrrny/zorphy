// Fixture for issue #135: custom decorators on raw entities must be
// preserved on generated entities.
//
// Decorator declarations first (plain const-constructible classes),
// then raw entities annotated with them alongside @Zorphy.

import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'decorator_preservation.zorphy.dart';
part 'decorator_preservation.g.dart';

// ────────────────────────────────────────────────────────────────────
// Custom decorators (user-authored, not part of zorphy)
// ────────────────────────────────────────────────────────────────────

class Cacheable {
  final Duration ttl;
  const Cacheable({required this.ttl});
}

class Throttle {
  final int maxCalls;
  final Duration per;
  const Throttle(this.maxCalls, {required this.per});
}

class Audited {
  const Audited();
}

// ────────────────────────────────────────────────────────────────────
// Raw entities
// ────────────────────────────────────────────────────────────────────

/// Single custom decorator with a named argument (spec SC-1).
///
/// Per the repo's raw-entity convention the raw class carries the `$`
/// prefix, so the generator emits exactly one concrete `class Task` —
/// the un-prefixed name would collide with that generated declaration in
/// this same library.
@Cacheable(ttl: Duration(hours: 1))
@Zorphy(generateJson: true)
abstract class $Task {
  String get id;
  String get title;
}

/// Multiple decorators, mixed positional + named arguments, plus a
/// parameterless decorator (spec SC-2, SC-3).
@Throttle(30, per: Duration(seconds: 5))
@Audited()
@Zorphy(generateJson: true)
abstract class $Report {
  String get id;
  int get count;
}

/// No custom decorators at all — output must be unchanged (spec SC-4).
@Zorphy(generateJson: true)
abstract class $Plain {
  String get id;
}

/// Sealed-base hierarchy: decorators on the raw `$$` base port to the
/// generated sealed class; decorators on the raw `$` subtype port to the
/// generated concrete subtype class.
@Audited()
@Zorphy(generateJson: true, explicitSubTypes: [$Hero])
abstract class $$Character {
  String get name;
}

@Cacheable(ttl: Duration(minutes: 5))
@Zorphy(generateJson: true)
abstract class $Hero implements $$Character {
  String get level;
}
