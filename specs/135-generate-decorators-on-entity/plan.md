# Implementation Plan: Preserve custom decorators on generated entities

**Branch**: `feat/135-generate-decorators-on-entity` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/135-generate-decorators-on-entity/spec.md`

## Summary

Zorphy's code generator consumes `@Zorphy(...)` as a directive but drops every other class-level decorator from the generated output. This plan makes the generator capture class-level decorator source text from the raw entity element (via the analyzer), filter out build-step directives (`Zorphy`, `Zorphy2`, `JsonSerializable`), and re-emit the remaining decorators — verbatim, in source order — on **every class it emits for that entity** from `class_declaration_generator.dart`. The generated shapes depend on the raw class's prefix: a `$`-prefixed raw entity yields a single concrete class (`$Task` → `class Task`), while a `$$`-prefixed raw base yields a sealed base plus its concrete subtypes (`$$Character` + `$Hero` → `sealed class Character` + `class Hero`). Field-level annotation handling is untouched.

## Technical Context

**Language/Version**: Dart SDK >=3.8.0 (generator runs on stable 3.13.x)

**Primary Dependencies**: `analyzer` (>=13 <15) for element/metadata access, `code_builder` 4.10 for output specs, `source_gen` 4.x `Generator`/`LibraryReader` pipeline, `build` 4.x

**Storage**: N/A (build_to: source code generator)

**Testing**: `dart test` (package:test) with two complementary patterns already established in the repo: (a) fast unit tests using stub `ClassElement`s + direct generator invocation + `DartEmitter` output assertions; (b) end-to-end golden fixture tests that run `build_runner build` in `example/` and assert on the generated `.zorphy.dart` file contents.

**Target Platform**: Dart/Flutter build systems (build_runner) on Linux/macOS/Windows CI

**Project Type**: Dart code-generator package (monorepo: `zorphy/` generator, `zorphy_annotation/` annotations, `zorphy_migrator/` tool)

**Performance Goals**: No measurable regression; decorator capture is O(#annotations) per class and runs once per annotated class per build.

**Constraints**: Generated output for decorator-free inputs must be byte-identical to pre-feature output (hard non-regression constraint). Generator-only change: no edits to `zorphy_annotation`, no runtime changes, no changes to the `@Zorphy` annotation contract.

**Scale/Scope**: 3 production files (model, analyzer wiring, class-declaration generator), 2 new test files, 1 example fixture.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Modify only the code generator's decorator handling: PASS (scope limited to `zorphy/lib/src/…`).
- Never hand-edit generated `.zorphy.dart` files: PASS (all output changes come from regenerating via `build_runner`).
- All CI gates green: PASS target (`dart analyze` clean, full `dart test` suite green).
- PR to `master`, individually curated with tests: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/135-generate-decorators-on-entity/
├── spec.md
├── plan.md
├── tasks.md
└── tdd/
    ├── test-list.md
    ├── cycle-log.md
    └── verification.md
```

### Source Code (repository root)

```text
zorphy/                                  # generator package
├── lib/src/models/class_metadata.dart        # + classDecorators field (capture result)
├── lib/src/analysis/class_analyzer.dart      # capture class-level decorators into metadata
├── lib/src/common/helpers.dart               # + extractClassDecorators() helper
└── lib/src/generators/class_declaration_generator.dart   # emit decorators on $-class + concrete class
zorphy/test/generation/
├── decorator_preservation_test.dart          # unit: helper + generator wiring (stub elements)
zorphy/example/lib/various/
├── decorator_preservation.dart               # e2e fixture: raw entity with custom decorators
zorphy/test/generation/
└── decorator_preservation_e2e_test.dart      # e2e: reads generated fixture output
```

## Phase 0 — Research (completed)

Key findings that shape the design:

1. **Emission pipeline**: `ZorphyGenerator.generate` (lib/src/zorphy_generator.dart:62) scans ALL library classes for `@Zorphy`/`@Zorphy2`, builds `ClassMetadata` via `ClassAnalyzer.analyze`, then `Orchestrator.generate` collects `Spec`s from 13 generators and emits through code_builder. Output class headers are built ONLY in `ClassDeclarationGenerator._buildAbstractClassSpec` (lib/src/generators/class_declaration_generator.dart:32–93) and `_buildConcreteClassSpec` (:96–214). Neither touches `c.annotations` from source metadata today (concrete class gets a hard-coded `@JsonSerializable(...)`, :144–150).
2. **Recursive-generation hazard**: generated classes are elements of the same library (part file). `generate()` has no `$`-name skip (zorphy_generator.dart:71–85), so re-emitting `@Zorphy` on `$Task` would make the next build pass treat `$Task` as an input entity and emit `$$Task`, cascading. Directive annotations must therefore be filtered from porting (spec US4).
3. **Metadata access**: `ClassMetadata` already carries the original `ClassElement` (lib/src/models/class_metadata.dart:70). Class-level annotations are accessible via `ClassElement.metadata`, which the repo already accesses through a dual-API shim (`_extractAnnotations`, lib/src/common/helpers.dart:48–59) covering both `List<ElementAnnotation>` and the new `Metadata` object style. `ElementAnnotation.toSource()` yields the full annotation source including `@` and arguments — verbatim argument fidelity for free.
4. **Annotation emission convention**: code_builder's `DartEmitter` adds the `@` automatically for `c.annotations.add(CodeExpression(Code(...)))` entries (documented comment at class_declaration_generator.dart:131–132); ported decorator source must have the leading `@` stripped.
5. **Plugin-pipeline preservation**: `Orchestrator._runPluginPass` (orchestrator.dart:190) and `_mergeMembersIntoClass` (:300) already copy `c.annotations.addAll(originalClass.annotations)` when rebuilding class specs, so decorators added by the declaration generator survive plugin transforms without further work. The dormant `classDecorators` set at orchestrator.dart:146 stays as-is (plugin scoping is out of scope).
6. **Test patterns**: no `build_test` in the repo. Unit tests use `_StubClassElement implements ClassElement` with `noSuchMethod(_) => null` (test/generation/spec_pipeline_constructor_this_prefix_test.dart:33–41) and assert on `DartEmitter`-emitted specs. E2E tests read `example/lib/various/*.zorphy.dart` produced by `dart run build_runner build` (test/generation/issue_109_extends_test.dart:37–51, which `fail()`s with the build command when the artifact is missing). Both patterns will be used: unit tests for red/green speed, e2e fixture for end-to-end proof.
7. **Existing field-level handling** (untouched, for reference): `@JsonKey` via `extractJsonKeyInfo` (helpers.dart:62+), other field annotations via `_collectAdditionalAnnotations` (helpers.dart:344–397) into `NameTypeClassComment.additionalAnnotations`.

## Phase 1 — Design

### Data model change (generator-internal)

`ClassMetadata` gains one optional field:

```dart
/// Class-level decorators captured from the raw entity source, with the
/// leading `@` stripped (code_builder re-adds it). Directives excluded.
/// Empty for decorator-free entities — guarantees no-op output (FR-5).
final List<String> classDecorators;
```

Default `const []` keeps every existing construction site (including test stubs) source-compatible.

### Capture (ClassAnalyzer.analyze)

At the top of `analyze()`, read `classElement.metadata` through a new public helper `extractClassDecorators(ClassElement?)` in `helpers.dart`:

- dual-API metadata access (reuse `_extractAnnotations` semantics),
- for each `ElementAnnotation`: resolve the annotation element name (`annotation.element?.name`, with enclosing-element and source fallbacks like `findAnnotation` does) and SKIP names in the directive set {`Zorphy`, `Zorphy2`, `JsonSerializable`},
- otherwise take `toSource()`, strip one leading `@` (and any space after it), append.

### Emission (ClassDeclarationGenerator)

- `_buildAbstractClassSpec`: inside the `Class((c) {…})` builder, before adding members: `for (final d in metadata.classDecorators) { c.annotations.add(CodeExpression(Code(d))); }`
- `_buildConcreteClassSpec`: same loop placed immediately before the existing `@JsonSerializable` block, so emitted order is [user decorators…] then [generator-added JsonSerializable].
- Emitted annotation text = captured source (no `@`); `DartEmitter` prepends `@`. Import prefixes inside the captured text resolve within the same library (part file) — no import bookkeeping needed.

### Edge cases handled

- Stub `ClassElement`s in tests (every member throws → helper must be try/catch-safe and return `const []`).
- Decorator-free classes → `classDecorators` empty → generator body unchanged → byte-identical output (SC-4).
- Import-prefixed decorators (`@meta.Cacheable(...)`) → source text kept whole (FR-6).
- Multiple decorators → source order preserved (SC-3).
- Sealed/`$$`-interface entities → the same code path in `_buildAbstractClassSpec` applies; decorators on `$$Base` raw classes port to the emitted base class as well.

### Risks & mitigations

| Risk | Mitigation |
|---|---|
| Re-emitted `@Zorphy` causes recursive generation | Directive filter set; SC-5 asserts no `@Zorphy` on generated classes; e2e double-build stability check (US4.2) |
| `@JsonSerializable` on a raw class gets re-emitted on a generated class and breaks json_serializable | `JsonSerializable` in the directive filter set (FR-4) |
| Output drift for decorator-free entities | `classDecorators` defaults empty; emission loop adds nothing; SC-4 no-op assertion |
| Analyzer API drift (`List<ElementAnnotation>` vs `Metadata`) | Reuse of the established dual-API shim pattern |

## Verification Strategy

1. Unit tests (`dart test test/generation/decorator_preservation_test.dart`): stub-element red/green cycles covering SC-1..SC-5 mechanics (order, verbatim args, directive exclusion, no-op).
2. E2E fixture (`cd zorphy/example && dart run build_runner build`, then `dart test test/generation/decorator_preservation_e2e_test.dart`): real analyzer + real build over a fixture with `@Cacheable`, `@Throttle`, `@Audited` decorators; asserts on the actual `.zorphy.dart` artifact; includes a no-decorator fixture asserting absence of ported annotations.
3. Regression: full `dart analyze` on changed files + full existing `dart test` suite in `zorphy/`.
