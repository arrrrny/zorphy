# Feature Specification: zorphy 2.5.0 — Dependency & SDK-Floor Alignment Release

**Feature Branch**: `141-v2-5-0-deps-sdk-align`

**Created**: 2026-11-16

**Status**: Draft

**Input**: User description: "Ship a solid, non-breaking zorphy 2.5.0 that aligns the published package metadata with the latest analyzer/build ecosystem (analyzer 14.7, build 5.0, source_gen 4.3, build_runner 2.17), corrects the unsatisfiable SDK floor, keeps generated output byte-identical, and upgrades every affected test. PartBuilder/shared-parts and all feature work are deferred to 3.0.0."

## Context & Evidence

- Resolved graph is already on the latest majors (committed `pubspec.lock`): analyzer 14.7.0, build 5.0.0, source_gen 4.3.1, build_runner 2.17.1, code_builder 4.13.0, dart_style 3.1.14. `dart pub outdated` reports all direct dependencies up-to-date; `dart pub upgrade --major-versions --dry-run` reports "No changes would be made to pubspec.yaml".
- `dart analyze lib` on the zorphy core and on `zorphy_migrator` is clean against analyzer 14.7.0 — there is **no deprecation debt** to burn down.
- The one real defect: `environment: sdk: ">=3.8.0 <4.0.0"` is **unsatisfiable**. Verified from pub.dev SDK floors: analyzer 14.0.0 `^3.11.0`, source_gen 4.3.1 `^3.11.0`, build 5.0.0 `^3.11.0`, dart_style 3.1.14 `^3.11.0`. A Dart 3.8–3.10 consumer cannot resolve zorphy at all; the declared floor is misleading.
- Therefore the honest published floor is **3.11.0** (the maximum of the declared dependencies' resolvable minimums), matching the sibling `zuraffa` policy. It is **not** 3.13.0 — that is only the locked analyzer 14.7.0's floor and would wrongly drop Dart 3.11/3.12 consumers who can still resolve an older analyzer 14.x inside `^14.0.0`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Honest, resolvable SDK floor (Priority: P1)

As a Dart/Flutter developer (or `zuraffa`) that depends on zorphy, I need the declared SDK constraint to reflect the minimum SDK that can actually resolve zorphy's declared dependencies, so `dart pub get` succeeds instead of failing or silently mis-resolving.

**Why this priority**: The current `>=3.8.0` floor is unsatisfiable. Publishing a truthful floor is the single correctness fix that makes the "align to latest" real.

**Independent Test**: Read the package's declared `environment: sdk` floor and assert it equals the maximum SDK floor required by the declared dependency set (3.11.0); confirm a representative consumer manifest resolves against it.

**Acceptance Scenarios**:

1. **Given** zorphy 2.5.0, **When** reading `zorphy/pubspec.yaml`, **Then** `environment: sdk` admits `>=3.11.0 <4.0.0`.
2. **Given** zorphy_migrator 2.5.0, **When** reading its `pubspec.yaml`, **Then** `environment: sdk` admits `>=3.11.0 <4.0.0`.
3. **Given** the declared dependency set, **When** checking each dependency's SDK floor, **Then** none requires an SDK above the package's declared floor (the floor is sufficient).

---

### User Story 2 - Reproducible, current dependency baseline (Priority: P1)

As a maintainer/CI, I need the committed lockfile to be the tested baseline and the declared constraints to preserve their supported lower bounds (per the repository `dependency-bump-rule`), so builds are reproducible and consumer compatibility is not narrowed.

**Why this priority**: A release that drifts the lock or silently narrows constraints ships a different artifact than CI tested.

**Independent Test**: Run `dart pub get --no-example` and assert the lockfile is unchanged; diff declared constraints against 2.4.6 and assert only the `environment: sdk` line changed.

**Acceptance Scenarios**:

1. **Given** the committed `pubspec.lock`, **When** running `dart pub get --no-example`, **Then** there is zero lockfile drift.
2. **Given** the 2.5.0 `pubspec.yaml`, **When** diffing declared dependency constraints against 2.4.6, **Then** only the `environment: sdk` floor changed (no dependency constraint was tightened or widened).
3. **Given** the resolved graph, **When** running `dart pub outdated`, **Then** all direct dependencies report up-to-date.

---

### User Story 3 - Generated output stays clean under the latest analyzer (Priority: P2)

As a consumer, I need zorphy's generated `.zorphy.dart` to compile with zero diagnostics under the pinned analyzer (14.6+ replaced `undefined_getter` with the `undefined_*_read`/`undefined_*_write` family), so regeneration never breaks my build — the exact class of breakage that already hit `zuraffa` (issue #1980).

**Why this priority**: This is the durable guard that keeps 2.5.0 "aligned to latest" over time; it protects every downstream consumer.

**Independent Test**: Generate `.zorphy.dart` for the standard fixtures, run `dart analyze` on the generated files under the pinned analyzer, and assert zero diagnostics.

**Acceptance Scenarios**:

1. **Given** the standard fixture set, **When** zorphy generates and `dart analyze` runs on the output, **Then** there are zero diagnostics.
2. **Given** the default test tier, **When** the suite runs, **Then** this analyze-clean gate executes as a permanent regression test.

---

### User Story 4 - Non-breaking release hygiene (Priority: P2)

As a consumer upgrading 2.4.6 → 2.5.0, I need byte-identical generated output and no public API or behavior changes.

**Why this priority**: 2.5.0 is explicitly the non-breaking release; any output drift would make it breaking.

**Independent Test**: Compare generated output for the standard fixtures against the 2.4.6 golden files and assert byte-identical; assert the exported public API is unchanged.

**Acceptance Scenarios**:

1. **Given** the standard fixtures, **When** regenerating, **Then** output is byte-identical to the 2.4.6 goldens.
2. **Given** the public API, **When** compared to 2.4.6, **Then** it is unchanged.

---

### User Story 5 - Release metadata & version sync (Priority: P3)

As a publisher, I need zorphy and zorphy_annotation bumped to 2.5.0 together with CHANGELOG entries, so `scripts/check_version_sync.sh` passes and the release is coherent.

**Acceptance Scenarios**:

1. **Given** the monorepo, **When** running `scripts/check_version_sync.sh`, **Then** zorphy and zorphy_annotation both report 2.5.0.
2. **Given** each package, **When** reading its `CHANGELOG.md`, **Then** a 2.5.0 entry exists.

---

### Edge Cases

- A consumer on Dart 3.11 resolves an older analyzer (14.0.0–14.5.x) inside `^14.0.0`; the floor must not force 3.13 on them.
- A consumer on Dart 3.8–3.10 was already unable to resolve zorphy; raising the floor changes nothing for them (documented in CHANGELOG).
- zorphy's own CI uses the committed lock (analyzer 14.7.0 needs Dart ≥ 3.13); dev/CI runs on ≥ 3.13 while the published floor stays 3.11.
- The `example/` packages depend on the Flutter SDK; resolution uses `dart pub get --no-example`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `zorphy/pubspec.yaml` MUST declare `environment: sdk` admitting `>=3.11.0 <4.0.0`.
- **FR-002**: `zorphy_migrator/pubspec.yaml` MUST declare `environment: sdk` admitting `>=3.11.0 <4.0.0`.
- **FR-003**: zorphy MUST NOT narrow or widen any dependency constraint; lower bounds are preserved (dependency-bump-rule). Only the environment SDK floor changes.
- **FR-004**: The committed `pubspec.lock` MUST match `dart pub get --no-example` (zero drift).
- **FR-005**: The test suite MUST include a gate that generates `.zorphy.dart` for the standard fixtures, runs `dart analyze` on the output under the pinned analyzer, and asserts zero diagnostics — and it MUST run in the default tier.
- **FR-006**: Generated output MUST be byte-identical to 2.4.6 for the standard fixtures (no behavior/output change).
- **FR-007**: `zorphy` and `zorphy_annotation` versions MUST both be `2.5.0`; `scripts/check_version_sync.sh` MUST pass.
- **FR-008**: `zorphy` and `zorphy_annotation` MUST each have a `2.5.0` `CHANGELOG.md` entry describing the SDK-floor correction and the analyze-clean gate.
- **FR-009**: ALL affected tests MUST be updated (version assertions, SDK-floor assertions, any test pinning 3.8) and the full suite MUST pass at concurrency 2; `./scripts/local_ci.sh` MUST pass.
- **FR-010**: `dart pub outdated` MUST report all direct dependencies up-to-date.

### Non-Functional Requirements & Constraints

- **NFR-001**: No changes to `lib/` generation logic or emitted code. This is a metadata + test + release-notes change only.
- **NFR-002**: The published floor is the minimum that resolves, not the locked version's floor — consumer compatibility MUST NOT be reduced.
- **NFR-003**: `zorphy_annotation` (no analyzer dependency) is version-bumped for sync; its own SDK floor is left unchanged unless a declared dependency requires higher.

### Key Entities

- `pubspec.yaml` (zorphy, zorphy_annotation, zorphy_migrator): `environment: sdk`, dependency constraints, `version`.
- `pubspec.lock`: the committed resolved baseline.
- Generated-output fixtures + golden files under the test tree.
- `CHANGELOG.md` (per package).
- `scripts/check_version_sync.sh`, `scripts/local_ci.sh`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart pub get --no-example` produces zero `pubspec.lock` changes.
- **SC-002**: zorphy and zorphy_migrator declare an SDK floor of `>=3.11.0`; no declared dependency requires a higher floor.
- **SC-003**: The new analyze-clean gate exists, passes, and runs in the default (fast) test tier.
- **SC-004**: Generated output for all standard fixtures is byte-identical to 2.4.6.
- **SC-005**: `dart test` (concurrency 2) is fully green and `./scripts/local_ci.sh` exits 0.
- **SC-006**: `scripts/check_version_sync.sh` passes; zorphy = zorphy_annotation = 2.5.0.

## Out of Scope (deferred to 3.0.0)

- Replacing `PartBuilder` with shared parts (`BuildStep.librarySourceSink` / `adds_to_library: true`).
- Primary-constructor analysis and emission.
- `zorphy_migrator` AST-model rework.
- `PartBuilder(writeDescriptions: false)` — deferred because it changes emitted headers (would violate byte-identical output).
- The "lean flavor" migration tool that scans a project's feature usage to minimize generated output.

## Assumptions

- The correct published floor is **3.11.0**, verified from pub.dev SDK floors (analyzer 14.0.0, source_gen 4.3.1, build 5.0.0, dart_style 3.1.14 all require `^3.11.0`), matching the `zuraffa` sibling's `^3.11.0` policy.
- Raising the minimum SDK from 3.8 to 3.11 is a non-breaking correctness fix because 3.8–3.10 were already unresolvable; this is documented in the CHANGELOG.
- No dependency constraint is tightened or widened (dependency-bump-rule); only the `environment: sdk` floor changes plus the version bump.
- zorphy's CI/dev runs on Dart ≥ 3.13 (to honor the committed lock's analyzer 14.7.0) while the published floor stays 3.11.