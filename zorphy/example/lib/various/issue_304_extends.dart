// Regression fixture for issue #304.
//
// `zfa entity create -n Sub --extends Base` used to emit
//   `abstract class $Sub implements Base { ... }`
// (bare name, no `$` prefix) in the source abstract class. The analyzer
// cannot resolve `Base` at source-analysis time because `Base` is the
// GENERATED CONCRETE class name (emitted by zorphy into the .zorphy.dart
// file later). The implements clause was silently dropped, and the
// generated concrete class lost the relationship to `Base` — breaking
// `isA<Base>()` checks and union-type dispatch.
//
// This fixture exercises BOTH code paths that fix #304:
//
//   1. `$SubDollarPrefixed implements $BaseDollarPrefixed`
//      — the NEW zfa CLI behavior (emits `$`-prefixed names). The
//        analyzer resolves `$BaseDollarPrefixed` directly; no recovery
//        needed.
//
//   2. `$SubBareName implements BareBase`
//      — the OLD zfa CLI behavior (emitted bare names). The analyzer
//        cannot resolve `BareBase`; the InterfaceCollector recovery
//        logic parses the source text, resolves `BareBase` against
//        `allAnnotatedClasses` (trying `$BareBase`), and adds it to
//        `metadata.interfaces` with the source class name `$BareBase`.
//
// Both paths produce the same generated output:
//   `class SubX extends BaseX { ... }`
// making `isA<BaseX>()` hold at runtime via inheritance.
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_304_extends.zorphy.dart';
part 'issue_304_extends.g.dart';

// ── Scenario 1: $-prefixed source (NEW zfa CLI behavior) ──────────────

@Zorphy(generateJson: true)
abstract class $BaseDollarPrefixed {
  String get errorCode;
  String get message;
}

@Zorphy(generateJson: true)
abstract class $SubDollarPrefixed implements $BaseDollarPrefixed {
  String get errorCode;
  String get message;
}

// ── Scenario 2: bare-name source (OLD zfa CLI behavior) ───────────────
// The recovery logic in InterfaceCollector handles this by parsing the
// source text and resolving `BareBase` against `allAnnotatedClasses`.

@Zorphy(generateJson: true)
abstract class $BareBase {
  String get errorCode;
  String get message;
}

@Zorphy(generateJson: true)
abstract class $SubBareName implements BareBase {
  String get errorCode;
  String get message;
}
