# zorphy_migrator

A codemod that migrates model classes to [zorphy](https://pub.dev/packages/zorphy)
using **resolved AST analysis** — not regex — so union variants, generics,
defaults, and `@JsonKey` renames are converted correctly.

Two input dialects are supported:

- **[freezed](https://pub.dev/packages/freezed)** model classes (the original
  target), and
- **`@ExchangeableObject` / `@ExchangeableEnum`** custom codegen models — the
  annotations used by flutter_inappwebview forks (e.g.
  zikzak_inappwebview) that do not use Freezed at all. Without this dialect
  the tool silently no-ops on such packages (see
  [zorphy #86](https://github.com/arrrrny/zorphy/issues/86)); with it, the
  same seamless migration path applies.

Part of the zorphy 2.0 release. See the
[comparison](../README.md#%EF%B8%8F-zorphy-vs-freezed) for why teams switch.

## Usage

```bash
dart pub global activate zorphy_migrator
# or: dart run zorphy_migrator ... (as a dev dependency)

zorphy_migrator migrate lib/ --dry-run                    # preview unified diff (default)
zorphy_migrator migrate lib/ --apply --report MIGRATION.md
zorphy_migrator migrate lib/ --apply --fail-on-manual     # CI: exit 1 if a human is needed

zorphy_migrator lean . --dry-run                          # slim @Zorphy annotations
zorphy_migrator lean . --apply --report LEAN.md
```

Exit codes: `0` = clean migration, `1` = items need manual attention (or
nothing to migrate was found), `2` = analysis error.

## `lean` — pick a flavor from real usage

`lean` is the other direction: the project already runs on zorphy, and the
annotations ask for more than the code consumes. It rewrites each `@Zorphy`
annotation to the smallest flavor that still covers everything the package
actually uses, so the generated code shrinks without changing behaviour.

```bash
zorphy_migrator lean . --dry-run     # unified diff + per-class report
zorphy_migrator lean . --apply       # rewrite in place, then re-run build_runner
```

How it decides, per annotated class:

- **Dropped** when the class names no consumer: `FooPatch`, `FooFields`,
  `copyWithFooFn` and the JSON factories are all named after their class, so
  an absent name is proof the generated helper is dead, and the flag that
  requests it is removed.
- **Kept** when a consumer exists: a class referenced anywhere else in the
  scanned tree is *live*, keeps the preset its author chose, and only loses
  opt-in flags it can prove unused. `toJson` and `copyWithFn` are instance
  calls with no class in the name, so they are never dropped from a live class.
- **Untouched** arguments: anything that is not one of the four feature flags
  (`autoId`, `kind`, `hidePublicConstructor`, …) is carried over verbatim.

Scan scope and safety:

- Generated files (`.g.dart`, `.zorphy.dart`, and the shared parts under
  `lib/_br_/`) are excluded — scanning them would make every class look used.
- Pointing at a package root also scans `test/` and `integration_test/`, since
  a feature used only by a test still has to be generated.
- One file that does not parse is reported and skipped, not fatal.
- The scan is syntactic (no resolution), so `zik_zak`-sized trees finish in
  seconds rather than minutes.

## Mapping

| freezed construct | zorphy output |
| --- | --- |
| `@freezed class Foo with _$Foo { const factory Foo({required String a, int? b}) = _Foo; }` | `@Zorphy(preset: ZorphyPreset.lean) abstract class $Foo { String get a; int? get b; }` |
| Union: `factory Foo.ok(T v) = Ok;` | `@Zorphy(explicitSubTypes: [$Ok]) abstract class $$Foo {}` + `abstract class $Ok implements $$Foo { T get v; }` |
| `factory Foo.fromJson(...) => _$FooFromJson(json);` | `generateJson: true` on the annotation |
| `@Default(expr)` | `@JsonKey(defaultValue: expr)` on the getter (never silently dropped) |
| `@JsonKey(...)` | preserved verbatim on the getter |
| Field types referencing other migrated classes | rewritten to `$`-prefixed form (`List<CartItem>` → `List<$CartItem>`) |

| `@ExchangeableObject` construct | zorphy output |
| --- | --- |
| `@ExchangeableObject() class Foo_ { T x; Foo_({required this.x}); }` | `@Zorphy(kind: ZorphyKind.valueObject, generateJson: true, generateCompareTo: true) abstract class $Foo { T get x; }` |
| `this.x = expr` constructor default | `@JsonKey(defaultValue: expr)` on the getter |
| `@ExchangeableEnum() class Foo_ { static const A = Foo_._internal(0); }` | plain `enum Foo { A }` (member names + declaration order preserved) |
| Field type `Bar_` where `Bar` is converted in the same run | `Bar` (the codegen `_` suffix is dropped; concrete sibling form, recovered by zorphy #351) |

Lean-preset inference: classes that provably use only lean features (no
union, no defaults) are emitted with `preset: ZorphyPreset.lean` and the
choice is noted in the report; everything else uses the standard preset
(byte-compatible with zorphy 1.x defaults).

## Not converted (always reported, never dropped)

- `@unfreezed` mutable classes — zorphy is immutable-first
- Custom getters/methods in the class body
- Non-factory constructors and asserts
- `@Default` expressions that reference their own field
- For `@ExchangeableObject`/`@ExchangeableEnum`: custom
  `@ExchangeableObjectMethod`/`@ExchangeableObjectProperty`/
  `@ExchangeableObjectConstructor` members, instance fields that are not
  constructor parameters, and enum wire values that do not map onto a plain
  enum (non-sequential ints, string values differing from the member name)

Every skipped construct appears in the report with `file:line` and a
reason. The tool **never deletes files** — removing `*.freezed.dart` and
the freezed dependencies is a documented manual step.

## After `--apply`

### freezed sources

1. Remove `freezed` / `freezed_annotation` from pubspec; add `zorphy`
   (dev) + `zorphy_annotation`.
2. Delete `*.freezed.dart`; keep `.g.dart` only where `generateJson: true`
   was emitted.
3. Update `part` directives: drop `.freezed.dart`, add `.zorphy.dart`.
4. Replace `when`/`map` calls with Dart 3 `switch` expressions on the
   sealed base.
5. `dart run build_runner build --delete-conflicting-outputs`, then
   `dart analyze`.

### `@ExchangeableObject` / `@ExchangeableEnum` sources

1. Swap the internal-annotations import for
   `package:zorphy_annotation/zorphy_annotation.dart` and add
   `part '<file>.zorphy.dart';` next to the existing `.g.dart` part.
2. Delete the stale codegen `.g.dart` (regenerated by json_serializable).
   If the package's `build.yaml` scopes entity generation to a specific
   directory (e.g. `lib/src/domain/entities/**`), move the converted files
   there first.
3. Update barrels to re-export the entity under the `_`-stripped public
   name, and glue platform controllers (`fromMap`→`fromJson`,
   `toMap`→`toJson`, enum wire `_value`→`.index`/name, plus any
   platform-native enum translation that used `_nativeValue`).

## Requirements

- The target project must resolve (`dart pub get` done) — the migrator
  uses the analyzer's resolved AST.
- Targets zorphy 2.0 (`zorphy_annotation ^2.0.0`).
- `@ExchangeableObject`/`@ExchangeableEnum` classes are matched by
  annotation name (any library), so no dependency on the fork's internal
  annotations package is needed.
