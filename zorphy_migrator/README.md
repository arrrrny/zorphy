# zorphy_migrator

A codemod that migrates model classes to [zorphy](https://pub.dev/packages/zorphy)
using **resolved AST analysis** — not regex — so union variants, generics,
defaults, and `@JsonKey` renames are converted correctly.

It emits the **zero-preset v3 archetypes** (issue #176 / #233): a class is
annotated with exactly one archetype that names what it IS
(`@ZorphyEntity` / `@ZorphyValue` / `@ZorphyUnion`), with no `preset:` and no
`generate*` toggles — the wire codecs (`fromWire`/`toWire`) are generated
unconditionally.

Two input dialects are supported:

- **[freezed](https://pub.dev/packages/freezed)** model classes (the original
  target), and
- **`@ExchangeableObject` / `@ExchangeableEnum`** custom codegen models — the
  annotations used by flutter_inappwebview forks (e.g.
  zikzak_inappwebview) that do not use Freezed at all. Without this dialect
  the tool silently no-ops on such packages (see
  [zorphy #86](https://github.com/arrrrny/zorphy/issues/86)); with it, the
  same seamless migration path applies.

Part of the zorphy 3.0 release. See the
[comparison](../README.md#%EF%B8%8F-zorphy-vs-freezed) for why teams switch.

## Usage

```bash
dart pub global activate zorphy_migrator
# or: dart run zorphy_migrator ... (as a dev dependency)

zorphy_migrator migrate lib/ --dry-run                    # preview unified diff (default)
zorphy_migrator migrate lib/ --apply --report MIGRATION.md
zorphy_migrator migrate lib/ --apply --fail-on-manual     # CI: exit 1 if a human is needed
```

Exit codes: `0` = clean migration, `1` = items need manual attention (or
nothing to migrate was found), `2` = analysis error.

## Mapping

| freezed construct | zorphy v3 output |
| --- | --- |
| `@freezed class Foo with _$Foo { const factory Foo({required String id, int? b}) = _Foo; }` | `@ZorphyEntity(principalKey: #id) abstract class $Foo { String get id; int? get b; }` |
| a plain class with no `String id` field | `@ZorphyValue() abstract class $Foo { … }` |
| Union: `factory Foo.ok(T v) = Ok;` | `@ZorphyUnion() abstract class $$Foo { factory $$Foo.ok(T v) = $Ok; }` + `@ZorphyValue() class $Ok implements $$Foo { final T v; const $Ok(this.v); }` |
| `factory Foo.fromJson(...) => _$FooFromJson(json);` | no annotation change — the wire codecs are generated unconditionally |
| `@Default(expr)` | `@JsonKey(defaultValue: expr)` on the getter (never silently dropped) |
| `@JsonKey(...)` | preserved verbatim on the getter |
| Field types referencing other migrated classes | rewritten to `$`-prefixed form (`List<CartItem>` → `List<$CartItem>`) |

| `@ExchangeableObject` construct | zorphy v3 output |
| --- | --- |
| `@ExchangeableObject() class Foo_ { T x; Foo_({required this.x}); }` | `@ZorphyValue() abstract class $Foo { T get x; }` |
| `this.x = expr` constructor default | `@JsonKey(defaultValue: expr)` on the getter |
| `@ExchangeableEnum() class Foo_ { static const A = Foo_._internal(0); }` | plain `enum Foo { A }` (member names + declaration order preserved) |
| Field type `Bar_` where `Bar` is converted in the same run | `Bar` (the codegen `_` suffix is dropped; concrete sibling form, recovered by zorphy #351) |

Archetype inference: a class carrying a `String id` field is an aggregate
root and is emitted as `@ZorphyEntity(principalKey: #id)`; everything else is
a `@ZorphyValue()`. A freezed union becomes a `@ZorphyUnion()` root with
redirecting factories plus one concrete `@ZorphyValue()` variant class each.

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
2. Delete `*.freezed.dart` (and any stale `*.g.dart`).
3. Update `part` directives: drop `.freezed.dart`. Add no zorphy directive —
   as of 3.0 `build_runner` inserts the shared-part `part` line itself, and no
   `.g.dart` part is needed because the wire codecs are generated
   unconditionally.
4. Replace `when`/`map` calls with Dart 3 `switch` expressions on the
   sealed base.
5. `dart run build_runner build`, then `dart analyze`. build_runner 2.17
   removed `--delete-conflicting-outputs` and ignores it with a warning, so
   delete any stale `*.zorphy.dart` from the 2.x layout yourself.

### `@ExchangeableObject` / `@ExchangeableEnum` sources

1. Swap the internal-annotations import for
   `package:zorphy_annotation/zorphy_annotation.dart`. No zorphy `part` line is
   needed: `build_runner` writes the shared-part directive for you.
2. Delete the stale codegen `.g.dart`. If the package's `build.yaml` scopes
   entity generation to a specific directory (e.g.
   `lib/src/domain/entities/**`), move the converted files there first.
3. Update barrels to re-export the entity under the `_`-stripped public
   name, and glue platform controllers (`fromMap`→`fromWire`,
   `toMap`→`toWire`, enum wire `_value`→`.index`/name, plus any
   platform-native enum translation that used `_nativeValue`).

## Requirements

- The target project must resolve (`dart pub get` done) — the migrator
  uses the analyzer's resolved AST.
- Targets zorphy 3.0 (`zorphy_annotation ^3.0.0`).
- `@ExchangeableObject`/`@ExchangeableEnum` classes are matched by
  annotation name (any library), so no dependency on the fork's internal
  annotations package is needed.