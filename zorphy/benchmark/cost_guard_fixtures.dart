// V3-annotated sources for the Chord cost guards (arrrrny/zorphy#234).
//
// These declarations are the REAL fixtures the four cost guards measure. The
// shared part beside this file (`_br_/benchmark/cost_guard_fixtures.part.dart`)
// is produced by the production `build_runner` pipeline from these
// `@Zorphy*` annotations — it is NOT hand-written and must never be edited
// (see AGENTS.md "ZORPHY CODE GENERATION — STRICT HANDLING").
//
// Before #234 the guards measured hand-shaped lookalikes declared inline in
// `cost_guards.dart`, so the gate could stay green while the generated APIs the
// acceptance criteria name (`<Entity>Patch.diff`, `changeTo*`, `resolvePath`,
// polymorphic `fromWire`) were absent from real output. #234 moves the fixtures
// onto the real pipeline: `cost_guards_impl.dart` imports the generated classes
// below and measures THEM, and a deliberate removal of any of those surfaces
// from the generator makes the benchmark fail to compile (build/analysis time).
//
// The shapes map one-to-one onto the four guards:
//
//   * Guard 1 (defensive snapshot of collection fields) — `$Task` carries a
//     reference-typed `List<String> tags` and a `DateTime createdAt`; the
//     generated `fromTrusted` copies `tags` at construction (#284), so mutating
//     the caller's list cannot change the value and `copyWith` / the
//     `OpenTask.changeToDoneTask` / `DoneTask.changeToOpenTask` morphs carry a
//     FRESH list (proven with `identical`), while the immutable `createdAt` is
//     still shared.
//   * Guard 2 (no-op patch identity + latency) — `$Product` yields a generated
//     `ProductPatch` whose `diff(e, e)` returns the canonical empty patch and
//     whose `apply(e)` returns the SAME instance in O(1).
//   * Guard 3 (polymorphic JSON-Pointer lens) — the `$UiNode` hierarchy's
//     generated `resolvePath` dispatches on the runtime subtype (a segment the
//     receiver does not carry answers null), and `$ProductUiState.resolvePath`
//     resolves a composed pointer into the nested `$EditDraft` value.
//   * Guard 4 (boundary validation throughput) — the sealed `$Record` root's
//     generated polymorphic `fromWire` validates through the trusted
//     constructors and accumulates violations instead of throwing. `$Record`
//     carries FLAT fields (a String id plus one numeric field per branch),
//     mirroring the flat-field polymorphic entity the original 30 ms/10k budget
//     was calibrated on (#234: retain the budgets, do not relax them).

import 'package:zorphy_annotation/zorphy_annotation.dart';

part '../_br_/benchmark/cost_guard_fixtures.part.dart';

// ── Guard 1 + Guard 4: an entity hierarchy with identity + reference fields ──
//
// `tags` / `createdAt` are reference-typed, so a zero-copy `copyWith` / morph is
// provable with `identical`. The sealed root's `fromWire` is the polymorphic
// boundary codec Guard 4 drives.
@ZorphyEntity(principalKey: #id)
abstract class $Task {
  String get id;
  DateTime get createdAt;
  List<String> get tags;
}

@ZorphyEntity()
abstract class $OpenTask implements $Task {
  String get assignee;
}

@ZorphyEntity()
abstract class $DoneTask implements $Task {
  String get result;
}

// ── Guard 2: a standalone entity + its generated patch algebra ───────────────
//
// `ProductPatch.diff` has the O(1) `identical()` fast path and `apply` of the
// empty patch returns the target by reference.
@ZorphyEntity(principalKey: #id)
abstract class $Product {
  String get id;
  String get name;
}

// ── Guard 3: a polymorphic state hierarchy + a nested value ──────────────────
//
// `mode` is subtype-only (the interactive branch) and `label` belongs to the
// button, so resolving a segment a receiver does not carry answers null instead
// of throwing — the safe-dispatch case the lens lookup must get right.
@ZorphyState()
abstract class $UiNode {
  String get contractId;
}

@ZorphyState()
abstract class $InteractiveUiNode implements $UiNode {
  String get mode;
}

@ZorphyState()
abstract class $ZfaButtonNode implements $InteractiveUiNode {
  String get label;
}

@ZorphyState()
abstract class $ZfaTextNode implements $UiNode {
  String get text;
}

/// A nested value the pointer resolver descends into (`/editDraft/price`).
@ZorphyValue()
abstract class $EditDraft {
  String get title;
  double get price;
}

/// A state carrying a nested value, exercising the composed-pointer shape.
@ZorphyState()
abstract class $ProductUiState {
  $EditDraft get editDraft;
  int get selectedTab;
}

// ── Guard 4: a flat-field polymorphic entity + its boundary codec ─────────────
//
// Mirrors the original Guard 4 `Entity` (product/order): a sealed root with two
// flat-field branches (a String id plus one numeric field each), so the
// generated polymorphic `fromWire` validates through the trusted constructors
// without a `DateTime` parse or a list decode. That keeps the throughput
// profile the 30 ms/10k budget was calibrated on (#234: retain the budgets).
@ZorphyEntity(principalKey: #id)
abstract class $Record {
  String get id;
}

@ZorphyEntity()
abstract class $NumericRecord implements $Record {
  double get amount;
}

@ZorphyEntity()
abstract class $CountRecord implements $Record {
  int get count;
}
