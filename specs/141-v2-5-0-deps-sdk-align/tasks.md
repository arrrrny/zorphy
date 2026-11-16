# Tasks: zorphy 2.5.0 — Dependency & SDK-Floor Alignment Release

**Input**: Design documents from `/specs/141-v2-5-0-deps-sdk-align/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: INCLUDED — the spec mandates tests (analyze-clean gate, floor/version assertions) and the TDD flow drives them.

**Organization**: Grouped by user story; each story is independently testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable (different files, no incomplete deps)
- **[Story]**: US1–US5
- Paths are relative to the monorepo root unless noted.

---

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Confirm branch `141-v2-5-0-deps-sdk-align` is checked out and `.specify/feature.json` pins `specs/141-v2-5-0-deps-sdk-align` (already done during scaffolding)
- [x] T002 [P] Record a green baseline: `cd zorphy && dart test` and `cd zorphy_migrator && dart test` (note pass counts before changes)

---

## Phase 2: Foundational (Blocking Prerequisites)

None. This is a metadata + test release with no shared infrastructure; user stories are independent and can proceed in priority order.

---

## Phase 3: User Story 1 - Honest, resolvable SDK floor (Priority: P1) 🎯 MVP

**Goal**: `zorphy` and `zorphy_migrator` declare an SDK floor that actually resolves (`>=3.11.0`).

**Independent Test**: A test reads both `pubspec.yaml` files and asserts the `environment: sdk` constraint admits 3.11.0 and rejects 3.10.0.

### Tests for User Story 1

- [x] T003 [P] [US1] Write `zorphy/test/release/sdk_floor_alignment_test.dart` asserting `zorphy/pubspec.yaml` and `zorphy_migrator/pubspec.yaml` `environment: sdk` admit `>=3.11.0` and exclude `<3.11.0` (RED — currently `>=3.8.0`)

### Implementation for User Story 1

- [x] T004 [US1] Set `environment: sdk: ">=3.11.0 <4.0.0"` in `zorphy/pubspec.yaml` (GREEN)
- [x] T005 [US1] Set `environment: sdk: ">=3.11.0 <4.0.0"` in `zorphy_migrator/pubspec.yaml` (GREEN)
- [x] T006 [US1] Extend `zorphy/test/release/sdk_floor_alignment_test.dart` to assert no declared dependency requires an SDK floor above 3.11.0 (parse the dependency constraints / known floors)

**Checkpoint**: SDK floor is truthful and resolves on Dart 3.11+.

---

## Phase 4: User Story 2 - Reproducible, current dependency baseline (Priority: P1)

**Goal**: Committed lock is the tested baseline; constraints unchanged; deps current.

**Independent Test**: `dart pub get --no-example` produces zero lockfile diff; declared constraints diff to 2.4.6 shows only the `environment: sdk` change.

- [x] T007 [US2] Verify zero lockfile drift: `dart pub get --no-example` in `zorphy`, `zorphy_annotation`, `zorphy_migrator`, then `git diff --exit-code -- **/pubspec.lock`
- [x] T008 [US2] Add a guard test `zorphy/test/release/dependency_constraints_unchanged_test.dart` snapshotting the declared dependency constraints and asserting they equal the 2.4.6 set (no tightening/widening)
- [x] T009 [US2] Confirm `dart pub outdated` (in `zorphy`) reports all direct dependencies up-to-date

**Checkpoint**: Reproducible, drift-free, constraint-stable baseline.

---

## Phase 5: User Story 3 - Generated output stays clean under the latest analyzer (Priority: P2)

**Goal**: A permanent gate proves generated `.zorphy.dart` yields zero analyzer diagnostics.

**Independent Test**: The gate generates fixtures, runs `dart analyze` on the output under the pinned analyzer, and asserts an empty diagnostics list.

- [x] T010 [P] [US3] Write `zorphy/test/release/analyze_clean_gate_test.dart` modeled on the spawn+`dart analyze` pattern in `zorphy/test/generation/issue_140_copywithfield_deep_hierarchy_test.dart`, covering representative fixtures (basic, json, copyWith, inheritance, sealed, enum) and asserting zero diagnostics
- [x] T011 [US3] Ensure the gate runs in the default fast tier (no `slow` tag) and is concurrency-safe (uses its own temp dir per run)

**Checkpoint**: Durable guard against the analyzer 14.6+ `undefined_*_read/write` class of breakage.

---

## Phase 6: User Story 4 - Non-breaking release hygiene (Priority: P2)

**Goal**: Byte-identical generated output; no API/behavior change.

**Independent Test**: Existing generation/golden tests pass unchanged (goldens not regenerated).

- [x] T012 [US4] Run the full generation suite (`cd zorphy && dart test test/generation`) and confirm byte-identical output (no golden edits)
- [x] T013 [US4] Confirm public API unchanged: `dart analyze lib` clean and no exported-symbol changes vs 2.4.6

**Checkpoint**: 2.4.6 → 2.5.0 is non-breaking.

---

## Phase 7: User Story 5 - Release metadata & version sync (Priority: P3)

**Goal**: zorphy and zorphy_annotation at 2.5.0 with CHANGELOG entries.

**Independent Test**: A test asserts both versions equal `2.5.0`; `scripts/check_version_sync.sh` passes.

### Tests for User Story 5

- [x] T014 [P] [US5] Write `zorphy/test/release/version_sync_test.dart` asserting `zorphy/pubspec.yaml` and `zorphy_annotation/pubspec.yaml` both declare `version: 2.5.0` (RED — currently 2.4.6)

### Implementation for User Story 5

- [x] T015 [US5] Set `version: 2.5.0` in `zorphy/pubspec.yaml` (GREEN)
- [x] T016 [US5] Set `version: 2.5.0` in `zorphy_annotation/pubspec.yaml` (GREEN)
- [x] T017 [US5] Add a `2.5.0` entry to `zorphy/CHANGELOG.md` and `zorphy_annotation/CHANGELOG.md` (SDK-floor correction 3.8→3.11, analyze-clean gate, no output change; note 3.8–3.10 were already unresolvable)
- [x] T018 [US5] Run `scripts/check_version_sync.sh` → "OK: both packages at version 2.5.0"

**Checkpoint**: Release metadata coherent and synced.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T019 [P] `dart format` the new `test/release/` files; the repo-wide
  `dart format` check fails on 36 pre-existing files under Dart 3.14 (formatter
  drift, present on master) — left untouched to keep this release diff minimal
- [x] T020 Run `dart analyze lib` in `zorphy` and `zorphy_migrator` → clean
- [x] T021 Run `cd zorphy && dart test` at concurrency 2 → fully green (includes the new release/ tests)
- [x] T022 Run `./scripts/local_ci.sh` — release-relevant steps green
  (version_sync, pub get x3, build_runner, analyze annotation, run tests zorphy,
  build_runner smoke, migrator). Pre-existing failures documented in the PR:
  repo-wide `dart format` drift (Dart 3.14), the `dart analyze` path-dependency
  warning in `zorphy/pubspec.yaml`, and the matrix/artifact steps local_ci
  cannot reproduce locally
- [x] T023 Execute `specs/141-v2-5-0-deps-sdk-align/quickstart.md` validation end-to-end
- [ ] T024 Commit the release on `141-v2-5-0-deps-sdk-align`, push, and open a PR to `master` (forklift pool reviews/merges)

---

## Dependencies & Execution Order

- **Setup (Phase 1)**: no deps.
- **Foundational (Phase 2)**: none.
- **US1 (P1)**: MVP — do first; blocks nothing else but is the core fix.
- **US2 (P1)**: after US1 (shares pubspec files).
- **US3 (P2)**: independent of US1/US2 (test-only); can run in parallel.
- **US4 (P2)**: after US1/US5 edits (verifies non-breakage of the final tree).
- **US5 (P3)**: after US1 (shares pubspec files); CHANGELOG last.
- **Polish (Phase 8)**: after all stories.

### Parallel Opportunities

- T003 (US1 test) and T014 (US5 test) and T010 (US3 test) touch different files → parallel.
- T019 (format) is [P].

### Within Each Story

- Test first (RED) → implement (GREEN). US3/US4 are guards/characterization (pass immediately) — that is expected.

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup → 2. US1 (SDK floor) → **STOP & VALIDATE** (floor resolves on 3.11+). This alone is the "align to latest" fix.

### Incremental Delivery

1. US1 (floor) → validate.
2. US2 (baseline) → validate.
3. US3 (analyze-clean gate) → validate.
4. US4 (non-breaking) → validate.
5. US5 (version + changelog) → validate.
6. Polish → local_ci → PR.

---

## Notes

- [P] = different files, no incomplete deps.
- Red-green applies to US1 and US5 (metadata changes). US2/US3/US4 are verification/guard tasks.
- No `lib/` changes; goldens are not regenerated.
- Commit at logical checkpoints; the forklift pool owns review + merge of the PR.