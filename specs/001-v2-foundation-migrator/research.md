# Phase 0 Research: Zorphy 2.0 Foundation + Freezed Migrator

## R1. Analyzer 14 API delta vs zorphy codebase

**Decision**: Widen to `>=13.0.0 <15.0.0`; no source changes expected.

**Evidence**:
- analyzer 14.0.0 removals: `FormalParameterElement.isInitializingFormal`, `.isSuperFormal`, `.formalParameters`, `.typeParameters`, `PackageConfigFileBuilder` relocation.
- Grep of `zorphy/lib` finds **zero** uses of removed members. `type.formalParameters` in `lib/src/common/helpers.dart:573–596` operates on `FunctionType` (unaffected — removal is on `FormalParameterElement`).
- Stack compatibility: `source_gen 4.2.4` (`<15.0.0`), `build 4.0.9` (`<15.0.0`), `build_runner 2.15.3` (`<15.0.0`) all accept analyzer 14.
- **Only blocker**: dev-dependency `json_serializable ^6.14.0` caps `analyzer <14.0.0`. Resolution: keep published constraint clean; repo-local `dependency_overrides` (git/main of json_serializable or a published prerelease if available) marked temporary for the analyzer-14 CI leg; the analyzer-13 leg resolves stock.

**Alternatives considered**: waiting for json_serializable release (rejected — blocks v2 on a third party); splitting dev deps per leg (chosen via override file toggled in CI).

## R2. Builder consolidation shape

**Decision**: One `PartBuilder` in `build.yaml` with `build_extensions: {".dart": [".zorphy.dart", ".zorphy2.dart"]}`; a single generator instance handles both `@Zorphy` and `@Zorphy2` annotations and routes output by extension.

**Evidence**: source_gen's `PartBuilder` accepts multiple generators and multiple extensions; `GeneratorForAnnotationX` (repo's base class) dispatches per annotated element. Emitting `@Zorphy2` classes into `.zorphy2.dart` preserves existing consumers' `part` directives byte-for-byte (acceptance criterion: alias projects regenerate identically). A shared `MultiGenerator` wrapper returns `{extension: code}` per element.

**Alternatives considered**:
- Single extension only (`.zorphy.dart`): breaks every `@zorphy2` consumer's part directive — violates byte-compat invariant.
- Keep two builders, share state via buildStep: still two analysis passes — misses the perf goal.

## R3. Cross-class resolution without statics

**Decision**: Build the annotated-class map fresh per library from the `allClasses` list already threaded through `GeneratorForAnnotationX.generateForAnnotatedElement(..., List<ClassElement> allClasses)`; pass it down through `Orchestrator.generate`. Delete `static _allAnnotatedClasses` and `_classesInExplicitSubtypes` from both generators.

**Evidence**: The static maps exist only to resolve related classes (supertypes, explicitSubTypes) — all discoverable from the library's class list that source_gen already provides. `_classesInExplicitSubtypes` is recomputed per element anyway (zorphy_generator.dart:82-110), so making it a pure function of the per-library map is behavior-preserving.

**Risk**: cross-*library* hierarchies (class in lib A implements `$$Base` from lib B) currently work via process-global accumulation across build steps. Mitigation: merge per-library map with a build-step-scoped cache populated from `buildStep.resolver` libraries already imported — but keep it instance-scoped (per PartBuilder), not static. Golden + example regeneration tests cover the common cases; README hierarchies are single-library.

## R4. Polymorphic ordering in one pass

**Decision**: Topological sort over the `implements $$Base` graph within the library; generate bases before subtypes.

**Evidence**: The double pass existed because `getAllFieldsIncludingSubtypes` needed related classes "built first." With the full per-library map available up front (R3), field collection is order-independent; only emission order matters for part-file readability (Dart doesn't require declaration order). We sort anyway for stable, diff-friendly output.

## R5. Nullable flag encoding in annotations

**Decision**: All feature flags become `bool?` with `null` defaults; read via `ConstantReader.peek('flag')?.boolValue`. Preset read via `peek('preset')` → enum index from `DartObject.getField('index')`.

**Evidence**: Existing code already uses `peek('generatePatch')?.boolValue ?? true` (zorphy_generator.dart) — the pattern is proven. Changing `bool` → `bool?` in a const constructor is source-compatible for named-arg users; positional use doesn't exist (all flags are named).

**Preset resolution table** (const, in `GenerationConfig`):

| Feature | lean | standard | full |
| --- | --- | --- | --- |
| generateCopyWith | ✓ | ✓ | ✓ |
| generateEqualsToString | ✓ | ✓ | ✓ |
| generateJson | off | off | off |
| generatePropertyHelpers | ✗ | ✓ | ✓ |
| generatePatch | ✗ | ✓ | ✓ |
| generateFilter | ✗ | ✓ | ✓ |
| generateCompareTo | ✗ | ✓ | ✓ |
| generateChangeTo | ✗ | ✓ | ✓ |
| generateCopyWithFn | ✗ | ✗ | ✓ |

`standard` column == v1.9.0 defaults (generatePatch defaults true today, generateFilter true, generateCompareTo true — verified in annotations.dart:123-132).

## R6. Migrator AST approach

**Decision**: `AnalysisContextCollection` → resolved `CompilationUnit` per file; detect classes annotated `@freezed`/`@Freezed`/`@unfreezed` via resolved element annotations (not name matching); build a `FreezedClassModel` (fields from redirecting factory params, defaults from `@Default`, jsonKeys, unions from multiple redirecting factories); render zorphy source; replace exact source spans (reverse-offset application); unified diff via small LCS line differ.

**Evidence**: Requirement mandates resolved AST; type resolution is needed for union redirect targets and generics. Span replacement preserves comments/unrelated code (FR-E5).

**`@Default` handling**: emit `abstract class $Foo_` + top-level factory function per `zorphy_annotation` dartdoc pattern; if the default expression references other parameters → report-only manual item.

**Lean-preset inference**: if the class has no unions, no `@Default`, and only plain fields → emit `preset: ZorphyPreset.lean` (+ `generateJson: true` if fromJson present); else standard (omitted). Choice noted in report.

## R7. CI matrix mechanics

**Decision**: Add `strategy.matrix.analyzer: ["13", "14"]` to a new `analyzer_compat` job; the 14 leg writes a `pubspec_overrides.yaml` (json_serializable override, marked temporary) before `pub get`; both legs run analyze+test. Add `zorphy_migrator` package steps to the main job.

## R8. Docs examples source of truth

**Decision**: Lift comparison examples from `zorphy/example/lib/` (sealed `$$Shape` hierarchy and patch examples exist there per README); place extracted snippets under `zorphy/example/lib/comparison/` so `dart analyze` covers them in CI.
