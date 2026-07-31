# Phase 1 Data Model & Contracts

## Entities

### ZorphyPreset (zorphy_annotation)

```dart
enum ZorphyPreset { lean, standard, full }
```

Added to `zorphy_annotation/lib/src/annotations.dart`. `Zorphy`/`Zorphy2` gain `final ZorphyPreset preset;` (default `ZorphyPreset.standard`) and all feature flags change `bool` → `bool?` (default null). New flags: `generateCopyWith`, `generatePropertyHelpers`, `generateEqualsToString`, `generateChangeTo` (all `bool?`).

### GenerationConfig (zorphy) — rewritten resolution core

Final non-nullable booleans per feature:

| Field | Source |
| --- | --- |
| `generateJson` | flag ?? false (never preset-forced) |
| `explicitToJson` | flag ?? true |
| `generateCopyWith` | flag ?? preset |
| `generateCopyWithFn` | flag ?? preset |
| `generateCompareTo` | flag ?? preset |
| `generatePatch` | flag ?? preset |
| `generateFilter` | flag ?? preset |
| `generatePropertyHelpers` | flag ?? preset |
| `generateEqualsToString` | flag ?? preset |
| `generateChangeTo` | flag ?? preset |
| `hidePublicConstructor` | flag ?? false |
| `nonSealed` | flag ?? false |
| `preset` | resolved enum |
| `outputExtension` | `.zorphy.dart` / `.zorphy2.dart` |
| `factoryMethods`, `ownFields` | analysis-derived |

Static const preset table: `Map<ZorphyPreset, Map<ZorphyFeature, bool>>`.

Factory: `GenerationConfig.fromAnnotation(AnnotationOptions options, {required String outputExtension, required List<FactoryMethodInfo> factoryMethods, required Set<String> ownFields})`.

Legacy factories `GenerationConfig.zorphy(...)` / `.zorphy2()` are reimplemented on top of `fromAnnotation` with `standard` resolution to keep internal call sites compiling during migration, then removed once call sites switch (no external consumers — `zorphy/lib/src` is not exported public API beyond builder entry points; verify via exports grep).

### AnnotationOptions (zorphy) — extended

`AnnotationParser.parse` returns ALL fields as `bool?` (+ `preset` as `ZorphyPreset?`, explicitSubTypes, and doc-level flags). No `boolValue` calls remain — only `peek()`.

### ClassGraph (zorphy, per-library)

```dart
class ClassGraph {
  final Map<String, ClassElement> annotated;      // name → element
  final Set<String> classesInExplicitSubtypes;    // derived
  List<ClassElement> topological();               // bases before subtypes
}
```

Built fresh per library from `allClasses` + annotation scan; passed through `Orchestrator.generate`. Replaces both static maps.

### FreezedClassModel (zorphy_migrator)

```dart
class FreezedClassModel {
  final String name;
  final List<FreezedField> fields;        // name, type, nullable, defaultExpr, jsonKey
  final List<UnionVariant> variants;      // empty for simple classes
  final bool hasFromJson, hasToJson;
  final bool isUnfreezed;                 // → report-only
  final List<String> typeParameters;
  final List<ManualItem> manualItems;     // custom methods, asserts, etc.
  final SourceSpan span;                  // replacement target
}
```

### MigrationReport (zorphy_migrator)

```markdown
- converted: List<{class, file, presetChosen, notes}>
- manual: List<{file, line, construct, reason}>
- tail: post-migration instructions (remove deps, delete *.freezed.dart, build_runner)
```

## CLI Contract (zorphy_migrator)

```
zorphy_migrator migrate <path> [--dry-run] [--apply] [--report <file>] [--fail-on-manual]
```

- Default (neither flag): dry-run.
- `--dry-run`: unified diff to stdout; writes nothing.
- `--apply`: in-place rewrite.
- `--report <file>`: write markdown report (either mode).
- `--fail-on-manual`: exit 1 if report has manual items.
- Exit codes: 0 = clean, 1 = manual items present, 2 = analysis error.
- Skips: `*.freezed.dart`, `*.g.dart`, `*.zorphy.dart`, `*.zorphy2.dart`, hidden dirs, `build/`.

## Golden Test Contracts

- `zorphy/test/generation/preset_lean_test.dart` — lean emits no Patch/Filter/Fields/compareTo/property-helper symbols.
- `preset_lean_patch_override_test.dart` — lean + `generatePatch: true` = lean + patch only.
- `standard_byte_compat_test.dart` — v1.9.0 fixture regenerates byte-identical.
- `zorphy2_alias_compat_test.dart` — `@zorphy2` fixture regenerates byte-identical into `.zorphy2.dart`.
- `zorphy_migrator/test/fixtures/<case>/` — input.dart → expected.dart byte-identical; report-only cases assert on report content + untouched file.
