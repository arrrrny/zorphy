# zorphy_migrator

A codemod that migrates [freezed](https://pub.dev/packages/freezed) model
classes to [zorphy](https://pub.dev/packages/zorphy) using **resolved AST
analysis** — not regex — so union variants, generics, defaults, and
`@JsonKey` renames are converted correctly.

Part of the zorphy 2.0 release. See the
[comparison](../README.md#%EF%B8%8F-zorphy-vs-freezed) for why teams switch.

## Usage

```bash
dart pub global activate zorphy_migrator
# or: dart run zorphy_migrator ... (as a dev dependency)

zorphy_migrator migrate lib/ --dry-run                    # preview unified diff (default)
zorphy_migrator migrate lib/ --apply --report MIGRATION.md
zorphy_migrator migrate lib/ --apply --fail-on-manual     # CI: exit 1 if a human is needed
```

Exit codes: `0` = clean migration, `1` = items need manual attention,
`2` = analysis error.

## Mapping

| freezed construct | zorphy output |
| --- | --- |
| `@freezed class Foo with _$Foo { const factory Foo({required String a, int? b}) = _Foo; }` | `@Zorphy(preset: ZorphyPreset.lean) abstract class $Foo { String get a; int? get b; }` |
| Union: `factory Foo.ok(T v) = Ok;` | `@Zorphy(explicitSubTypes: [$Ok]) abstract class $$Foo {}` + `abstract class $Ok implements $$Foo { T get v; }` |
| `factory Foo.fromJson(...) => _$FooFromJson(json);` | `generateJson: true` on the annotation |
| `@Default(expr)` | `@JsonKey(defaultValue: expr)` on the getter (never silently dropped) |
| `@JsonKey(...)` | preserved verbatim on the getter |
| Field types referencing other migrated classes | rewritten to `$`-prefixed form (`List<CartItem>` → `List<$CartItem>`) |

Lean-preset inference: classes that provably use only lean features (no
union, no defaults) are emitted with `preset: ZorphyPreset.lean` and the
choice is noted in the report; everything else uses the standard preset
(byte-compatible with zorphy 1.x defaults).

## Not converted (always reported, never dropped)

- `@unfreezed` mutable classes — zorphy is immutable-first
- Custom getters/methods in the class body
- Non-factory constructors and asserts
- `@Default` expressions that reference their own field

Every skipped construct appears in the report with `file:line` and a
reason. The tool **never deletes files** — removing `*.freezed.dart` and
the freezed dependencies is a documented manual step.

## After `--apply`

1. Remove `freezed` / `freezed_annotation` from pubspec; add `zorphy`
   (dev) + `zorphy_annotation`.
2. Delete `*.freezed.dart`; keep `.g.dart` only where `generateJson: true`
   was emitted.
3. Update `part` directives: drop `.freezed.dart`, add `.zorphy.dart`.
4. Replace `when`/`map` calls with Dart 3 `switch` expressions on the
   sealed base.
5. `dart run build_runner build --delete-conflicting-outputs`, then
   `dart analyze`.

## Requirements

- The target project must resolve (`dart pub get` done) — the migrator
  uses the analyzer's resolved AST.
- Targets zorphy 2.0 (`zorphy_annotation ^2.0.0`).
