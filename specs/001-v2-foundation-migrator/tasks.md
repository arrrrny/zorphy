# Tasks: Zorphy 2.0 Foundation + Freezed Migrator

**Input**: Design documents from `/specs/001-v2-foundation-migrator/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Organization**: Tasks grouped by user story (US1–US5 from spec.md). US1/US2/US3 (issue #20) land first — US5 (migrator) depends on the 2.0 annotation API.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

- [ ] T001 Create feature branch baseline: confirm clean tree on `001-v2-foundation-migrator` (done at specify time)
- [ ] T002 [P] Snapshot v1.9.0 golden fixtures: regenerate `zorphy/example` and `zorphy/test` outputs at current HEAD and store reference copies under `specs/001-v2-foundation-migrator/golden-v1.9.0/` for byte-compat comparison

---

## Phase 2: Foundational (blocking all stories)

- [ ] T003 Widen `analyzer` constraint in `zorphy/pubspec.yaml` to `>=13.0.0 <15.0.0`; run `dart pub get` and `dart analyze`; fix any analyzer-14 compile errors (verify — none expected per research R1)
- [ ] T004 Add `ZorphyPreset` enum + `preset` param + 4 new `bool?` flags (`generateCopyWith`, `generatePropertyHelpers`, `generateEqualsToString`, `generateChangeTo`) in `zorphy_annotation/lib/src/annotations.dart`; convert existing feature flags to `bool?` with null defaults; add deprecation dartdoc to `Zorphy2`; bump both packages to `2.0.0` in pubspecs; `dart analyze` zorphy_annotation clean
- [ ] T005 Extend `AnnotationOptions` + `AnnotationParser.parse` in `zorphy/lib/src/analysis/annotation_parser.dart` to read ALL flags via `peek()` (nullable) plus `preset`; no `boolValue` for feature flags
- [ ] T006 Rewrite `zorphy/lib/src/models/generation_config.dart`: const preset table (lean/standard/full per data-model.md), `GenerationConfig.fromAnnotation(AnnotationOptions, ...)` resolving every feature to final non-nullable bool; keep legacy factories delegating to standard resolution until call sites migrate
- [ ] T007 Update `zorphy/lib/src/zorphy_generator.dart` to build config via `AnnotationParser` + `GenerationConfig.fromAnnotation` (kill ad-hoc `ConstantReader` reads)

**Checkpoint**: annotation API + config resolution complete; `cd zorphy && dart analyze` clean; existing tests still green (standard == old defaults)

---

## Phase 3: US1 — Analyzer 14 support (P1)

**Independent test**: `dart pub get` resolves with analyzer 14.1.0, no published-constraint override; analyze+test green on 13 and 14.

- [ ] T008 [US1] Add CI matrix job `analyzer_compat` in `.github/workflows/dart.yml` (`matrix.analyzer: ["13","14"]`); the 14 leg writes temporary `pubspec_overrides.yaml` (json_serializable override, comment marked temporary) before `dart pub get`; run `dart analyze` + `dart test` in `zorphy/`
- [ ] T009 [US1] Verify locally: `cd zorphy && dart pub get` resolves analyzer 14.x (with temporary local override if json_serializable still blocks); run full `dart test`

---

## Phase 4: US2 — Single-pass builder (P1)

**Independent test**: one builder in build.yaml; sealed hierarchy generates with only `@zorphy`; `@zorphy2` fixture byte-identical; no static maps.

- [ ] T010 [US2] Introduce `ClassGraph` (per-library annotated-class map + explicitSubtypes set + topological order) in `zorphy/lib/src/analysis/class_graph.dart`
- [ ] T011 [US2] Refactor `zorphy/lib/src/zorphy_generator.dart`: remove `_allAnnotatedClasses`/`_classesInExplicitSubtypes` statics; build `ClassGraph` from `allClasses` per library; thread through `Orchestrator.generate`
- [ ] T012 [US2] Merge `Zorphy2Generator` into the unified generator: single generator handles `@Zorphy` and `@Zorphy2` type-checkers, routes output to `.zorphy.dart` / `.zorphy2.dart` respectively; `zorphy/lib/builder2.dart` reduced to deprecated alias reusing the shared generator
- [ ] T013 [US2] Consolidate `zorphy/build.yaml` to one builder with `build_extensions: {".dart": [".zorphy.dart", ".zorphy2.dart"]}`; preserve `runs_before`/`applies_builders` semantics; update `zorphy/lib/builder.dart` accordingly
- [ ] T014 [US2] Apply topological emission order (bases before subtypes) within library generation
- [ ] T015 [US2] Regenerate `zorphy/example` + `zorphy/test_cli_output`; diff against T002 snapshot — existing outputs must be unchanged (except intended ordering stabilization)
- [ ] T016 [US2] Add golden test `zorphy/test/generation/zorphy2_alias_compat_test.dart` (byte-identical `.zorphy2.dart`) and sealed-hierarchy-with-only-`@zorphy` generation test
- [ ] T017 [US2] Grep gate: no `static` mutable maps in `zorphy_generator.dart`/`builder2.dart`

---

## Phase 5: US3 — Presets + granular flags (P2)

**Independent test**: lean golden has no Patch/Filter/Fields/compareTo/property-helper symbols; override golden = lean+patch; default == v1.9.0 byte-identical.

- [ ] T018 [P] [US3] Re-gate `PropertyHelperGenerator` on `config.generatePropertyHelpers` in `zorphy/lib/src/generators/property_helper_generator.dart`
- [ ] T019 [P] [US3] Re-gate `EqualsToStringGenerator` on `config.generateEqualsToString` in `zorphy/lib/src/generators/equals_tostring_generator.dart`
- [ ] T020 [P] [US3] Re-gate `CopyWithGenerator` on `config.generateCopyWith` (concrete) in `zorphy/lib/src/generators/copywith_generator.dart`
- [ ] T021 [P] [US3] Re-gate `ChangeToExtensionGenerator` on `config.generateChangeTo` in `zorphy/lib/src/generators/extension_generator.dart`
- [ ] T022 [US3] Verify `PatchGenerator`/`PatchClassGenerator`/`FieldEnumGenerator`/`FieldsClassGenerator`/`CompareToExtensionGenerator`/`JsonGenerator` read `GenerationConfig` only (no `ConstantReader` anywhere in `zorphy/lib/src/generators/`); grep gate
- [ ] T023 [US3] Golden test `zorphy/test/generation/preset_lean_test.dart` (no Patch/Filter/Fields/compareTo/property-helper symbols)
- [ ] T024 [US3] Golden test `zorphy/test/generation/preset_lean_patch_override_test.dart` (lean + generatePatch: true)
- [ ] T025 [US3] Golden test `zorphy/test/generation/standard_byte_compat_test.dart` against T002 snapshot
- [ ] T026 [US3] Golden test `zorphy/test/generation/preset_full_test.dart` (full = standard + copyWithFn)

---

## Phase 6: US5 — zorphy_migrator package (P2, depends on Phase 2 API)

**Independent test**: `cd zorphy_migrator && dart analyze && dart test` green; fixtures byte-identical; dry-run writes nothing; apply output compiles.

- [ ] T027 [US5] Scaffold `zorphy_migrator/` package: `pubspec.yaml` (v0.1.0, `analyzer >=14.0.0 <15.0.0`, path dep on `zorphy_annotation`), `README.md`, `CHANGELOG.md`, `analysis_options.yaml`
- [ ] T028 [US5] Implement `lib/src/freezed_detector.dart`: resolved-AST visitor via `AnalysisContextCollection` detecting `@freezed`/`@Freezed`/`@unfreezed` classes → `FreezedClassModel` list
- [ ] T029 [US5] Implement `lib/src/mapping.dart`: construct→construct mapping per spec table (simple class, union → `$$Base`+subtypes, fromJson/toJson → generateJson, `@Default` → `$Foo_`+factory fn, `@JsonKey` preserved, `@With`/`@Implements`, lean-preset inference); manual items for unfreezed/custom methods/asserts/non-factory constructors
- [ ] T030 [US5] Implement `lib/src/rewriter.dart`: zorphy source renderer + reverse-offset span replacement + LCS unified diff emitter
- [ ] T031 [US5] Implement `lib/src/report.dart`: markdown report (converted classes, manual items w/ file:line, post-migration instructions tail)
- [ ] T032 [US5] Implement `lib/src/cli.dart` + `bin/zorphy_migrator.dart`: `migrate <path>` with `--dry-run`/`--apply`/`--report`/`--fail-on-manual`; recursion + generated-file skipping; exit codes 0/1/2
- [ ] T033 [P] [US5] Golden fixtures: `test/fixtures/simple_class/`, `nullable_fields/`, `generics/` (input.dart → expected.dart)
- [ ] T034 [P] [US5] Golden fixtures: `union/`, `default_value/`, `json_key/`, `json_roundtrip/`
- [ ] T035 [P] [US5] Report-only fixtures: `unfreezed/`, `custom_method/` (assert report content + untouched file)
- [ ] T036 [US5] Test harness `zorphy_migrator/test/migration_test.dart`: byte-identical fixture comparison; dry-run checksum no-write verification; `--fail-on-manual` exit-code test
- [ ] T037 [US5] Real-world smoke fixture (≥10 freezed classes incl. one union) under `zorphy_migrator/test/fixtures/smoke/` + end-to-end test: migrate → `build_runner build` → `dart analyze` clean against zorphy 2.0
- [ ] T038 [US5] Add `zorphy_migrator` to `.github/workflows/dart.yml` (pub get, analyze, test)

---

## Phase 7: US4 — Freezed comparison docs (P3)

**Independent test**: README section + website page exist; example snippets analyze clean.

- [ ] T039 [P] [US4] Extract/create comparison examples in `zorphy/example/lib/comparison/` (simple class, sealed union, nested patch) — real compilable zorphy code; `dart analyze` clean
- [ ] T040 [US4] README "Zorphy vs Freezed" section: feature matrix (incl. analyzer 14 vs freezed's `<11.0.0` cap), honest "where freezed differs" notes, three side-by-side examples
- [ ] T041 [P] [US4] `website/docs` dedicated comparison page (same content, docusaurus format) + migration guide page pointing at `zorphy_migrator`
- [ ] T042 [US4] Repo README one-line pointer to migrator; `zorphy_migrator/README.md` usage + mapping table

---

## Phase 8: Polish & Release Prep

- [ ] T043 [P] CHANGELOG entries: `zorphy/CHANGELOG.md`, `zorphy_annotation/CHANGELOG.md` (2.0.0 breaking changes + migration path), `zorphy_migrator/CHANGELOG.md` (0.1.0)
- [ ] T044 Migration-path doc: `MIGRATION-v2.md` (or website page) covering: analyzer constraint, preset defaults (no action needed for byte-compat), `@zorphy2` deprecation timeline, freezed users → migrator
- [ ] T045 Full verification sweep: analyze+test all three packages; regenerate example; run all new goldens; CI workflow syntax check
- [ ] T046 Final grep gates: no statics, no ConstantReader in generators, single builder, no [NEEDS CLARIFICATION]

---

## Dependencies

```text
Phase 2 (foundational) → all stories
US1 (analyzer 14) ─ independent after T003
US2 (builder) ─ after Phase 2 (T011/T012 touch generator + config)
US3 (presets) ─ after Phase 2 (re-gating uses new config); can parallel with US2 except T022 audit last
US5 (migrator) ─ after T004 (needs 2.0 annotation API via path dep)
US4 (docs) ─ after US3/US5 content exists (examples reference presets + migrator)
Polish ─ last
```

## Parallel Execution Examples

- T018–T021 (generator re-gating) — different files, run together
- T033–T035 (fixture authoring) — different directories, run together
- T039 + T041 (examples vs website page) — different files
- T008 (CI) can run parallel with Phases 4–5

## Implementation Strategy

MVP-first: Phase 2 + US1 + US2 + US3 constitute the shippable 2.0 core (issues #20 A–C). US5 (migrator) and US4 (docs) are additive increments that don't destabilize the core. Each phase ends with `dart analyze` + focused `dart test` green before proceeding.
