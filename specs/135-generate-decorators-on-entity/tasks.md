---
description: "Task list for feature 135 — preserve custom decorators on generated entities"
---

# Tasks: Preserve custom decorators on generated entities

**Input**: Design documents from `/specs/135-generate-decorators-on-entity/`

**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: MANDATORY — this feature is delivered TDD-first (red → green evidence recorded in `tdd/cycle-log.md`).

**Organization**: Tasks grouped by user story, MVP-first: the smallest end-to-end slice (capture + port one decorator) lands before argument-fidelity and no-op hardening.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- Generator package: `zorphy/` (monorepo root)
- Feature spec artifacts: `specs/135-generate-decorators-on-entity/`

## Phase 1: MVP — one decorator ports to the generated abstract class (US1)

^- [ ] **T001** [P] [Setup] Add `classDecorators` optional field (default `const []`) to `ClassMetadata` in `zorphy/lib/src/models/class_metadata.dart` with doc comment explaining `@`-stripped source form.
^- [ ] **T002** [Setup] Add `extractClassDecorators(ClassElement? element)` helper to `zorphy/lib/src/common/helpers.dart`: dual-API metadata access, directive filter {Zorphy, Zorphy2, JsonSerializable}, `toSource()` capture with leading `@` stripped, exception-safe (returns `const []` on any analyzer API error).
^- [ ] **T003** [US1] **TEST-FIRST** Write failing unit test `decorator is ported to generated abstract class` in `zorphy/test/generation/decorator_preservation_test.dart` (stub ClassElement carrying a fake `@Cacheable(ttl: Duration(hours: 1))` annotation; drive `ClassAnalyzer.analyze` capture OR construct metadata with `classDecorators`; emit via `ClassDeclarationGenerator._buildAbstractClassSpec` + `DartEmitter`; assert `@Cacheable(ttl: Duration(hours: 1))` present on `$Task`). Prove RED.
^- [ ] **T004** [US1] Wire capture in `zorphy/lib/src/analysis/class_analyzer.dart` (`ClassAnalyzer.analyze` → `helpers.extractClassDecorators(classElement)` → `ClassMetadata.classDecorators`) and emission in `zorphy/lib/src/generators/class_declaration_generator.dart` `_buildAbstractClassSpec`. Make T003 GREEN.

## Phase 2: Verbatim argument fidelity (US2)

^- [ ] **T005** [US2] **TEST-FIRST** Failing unit tests in `zorphy/test/generation/decorator_preservation_test.dart`: (a) mixed positional+named `@Throttle(30, per: Duration(seconds: 5))` preserved character-for-character; (b) const list literal `@Endpoint(const ['a', 'b'], name: 'x')` preserved; (c) parameterless `@Audited` emitted without synthesised parentheses. Prove RED where applicable (these may pass immediately once porting exists — record as such; the assertions lock in FR-3).
^- [ ] **T006** [US2] Confirm capture uses verbatim source (no re-synthesis) — adjust helper if any assertion from T005 fails; make GREEN.

## Phase 3: Concrete-class porting + directive exclusion (US3, US4)

^- [ ] **T007** [US3] **TEST-FIRST** Failing unit test: decorator appears on generated concrete class (`_buildConcreteClassSpec`) alongside the generator-added `@JsonSerializable(...)`; decorator precedes `@JsonSerializable` in emission order. Make GREEN by adding the same emission loop to `_buildConcreteClassSpec`.
^- [ ] **T008** [US4] **TEST-FIRST** Failing unit tests: directive annotations `@Zorphy(...)`, `@Zorphy2(...)`, `@JsonSerializable(...)` on the RAW class do NOT appear on either generated class; multiple custom decorators preserved in source order on both generated classes. Make GREEN via the directive filter in `extractClassDecorators`.

## Phase 4: End-to-end fixture proof (US1–US4)

^- [ ] **T009** [P] [Setup] Add e2e fixture `zorphy/example/lib/various/decorator_preservation.dart`: custom decorator classes (`Cacheable`, `Throttle`, `Immutable`, `Audited`, `Endpoint`) + raw entities: one with `@Cacheable(ttl: Duration(hours: 1)) @Zorphy(generateJson: true)`, one mixing decorators, one with NO custom decorators; plus a dummy importable decorator library for an import-prefixed decorator case if feasible within fixture constraints.
^- [ ] **T010** [US1–US4] **TEST-FIRST** Failing e2e test `zorphy/test/generation/decorator_preservation_e2e_test.dart` following the `issue_109_extends_test.dart` pattern (fail with build command if artifact missing): assert `@Cacheable(ttl: Duration(hours: 1))` on `$Task` and on concrete `Task`; assert `@Zorphy` absent from generated classes; assert decorator-free entity emits no ported annotations. Run `cd zorphy/example && dart run build_runner build` to regenerate fixtures and make GREEN.

## Phase 5: Non-behavioural hardening + regression (US5)

^- [ ] **T011** [US5] **TEST-FIRST** No-op regression unit test: metadata with empty `classDecorators` emits output identical to a baseline spec built before porting (no annotation lines added); plus directive-only raw class (`@Zorphy` only) emits no class annotations. Make GREEN (expected already-green — locks FR-5).
^- [ ] **T012** [P] [US5] Run `dart analyze` on all changed files — zero new warnings; fix any issues found.
^- [ ] **T013** [P] [US5] Run FULL existing suite `dart test` in `zorphy/` — all previously passing tests still pass.
^- [ ] **T014** [P] [US5] `dart format` changed files; confirm no formatting drift in untouched files.
^- [ ] **T015** [Verify] Execute `/speckit.tdd.verify`: audit red-first evidence, test strength, acceptance coverage; write `specs/135-generate-decorators-on-entity/tdd/verification.md`.

## Dependencies

- T001, T002 before T004 (model + helper precede wiring).
- T003 before T004 (red before green).
- T005 before T006; T007, T008 independent of T005/T006 but sequential within the file.
- T009 before T010; T010 after T004 (fixture regeneration needs the generator change).
- T012–T014 after all green; T015 last.

## Parallel Execution Examples

- T001 + T009 can start immediately in parallel.
- T012 + T013 + T014 run in parallel after Phase 4.
