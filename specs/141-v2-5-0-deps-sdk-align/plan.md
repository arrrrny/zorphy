# Implementation Plan: zorphy 2.5.0 — Dependency & SDK-Floor Alignment Release

**Branch**: `141-v2-5-0-deps-sdk-align` | **Date**: 2026-11-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/141-v2-5-0-deps-sdk-align/spec.md`

## Summary

Non-breaking metadata + test + release-notes release. The resolved dependency graph already sits on the latest analyzer/build/source_gen majors (committed `pubspec.lock`; `dart pub outdated` all up-to-date; `dart analyze lib` clean on core and migrator). The single functional defect is the unsatisfiable `environment: sdk: ">=3.8.0 <4.0.0"`. This plan raises the published SDK floor to `>=3.11.0` in `zorphy` and `zorphy_migrator`, preserves every dependency constraint (dependency-bump-rule), keeps `pubspec.lock` pinned and drift-free, adds a permanent analyze-clean regression gate over generated output, bumps `zorphy` + `zorphy_annotation` to `2.5.0` in sync, writes CHANGELOG entries, and upgrades every affected test. There are **no `lib/` or emitted-output changes** — generated code stays byte-identical.

## Technical Context

**Language/Version**: Dart — published floor `>=3.11.0 <4.0.0` (dev/CI run on ≥3.13 to honor the locked analyzer 14.7.0).

**Primary Dependencies**: analyzer `^14.0.0` (lock 14.7.0), build `>=4.0.4 <6.0.0` (lock 5.0.0), source_gen `^4.3.1`, code_builder `^4.10.0` (lock 4.13.0), dart_style `^3.1.1` (lock 3.1.14), build_runner `^2.17.1` (dev). Constraints unchanged.

**Storage**: N/A (files: `pubspec.yaml` ×3, `pubspec.lock` ×3, `CHANGELOG.md` ×2).

**Testing**: `dart test` at concurrency 2 (default fast tier), `dart analyze`, `./scripts/local_ci.sh`, `scripts/check_version_sync.sh`.

**Target Platform**: pub.dev package consumed by Dart VM and Flutter apps.

**Project Type**: library + CLI (monorepo: `zorphy`, `zorphy_annotation`, `zorphy_migrator`).

**Performance Goals**: N/A (no runtime change).

**Constraints**: byte-identical generated output; no dependency-constraint changes; zero lockfile drift; zorphy/annotation version parity.

**Scale/Scope**: 3 packages, ~6 manifest files, CHANGELOG ×2, test suite (new analyze-clean gate + floor/version assertions).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The repository `.specify/memory/constitution.md` is the **unfilled template** (placeholder tokens such as `[PRINCIPLE_1_NAME]`; no ratified principles, version, or dates). There are therefore no enforceable gates to evaluate — Constitution Check is **N/A**. No violations. Post-design re-check: still N/A (constitution remains an unfilled template). Logged as a known gap; not a blocker for this release.

## Project Structure

### Documentation (this feature)

```text
specs/141-v2-5-0-deps-sdk-align/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 — decisions & rationale
├── data-model.md        # Phase 1 — manifest/lock/fixture/release entities
├── quickstart.md        # Phase 1 — validation guide
├── contracts/           # Phase 1 — published metadata & output-stability contracts
└── tasks.md             # Phase 2 (speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
zorphy/
├── pubspec.yaml            # environment: sdk -> >=3.11.0 ; version -> 2.5.0
├── pubspec.lock            # verify: zero drift after dart pub get --no-example
├── CHANGELOG.md            # add 2.5.0 entry
└── test/**                 # add analyze-clean gate; update floor/version assertions
zorphy_migrator/
├── pubspec.yaml            # environment: sdk -> >=3.11.0
└── pubspec.lock            # verify: zero drift
zorphy_annotation/
├── pubspec.yaml            # version -> 2.5.0 (sync)
├── pubspec.lock            # verify: zero drift
└── CHANGELOG.md            # add 2.5.0 entry
scripts/check_version_sync.sh   # run: must pass (zorphy == zorphy_annotation)
```

**Structure Decision**: Existing monorepo layout; no new directories. The change is confined to manifests, lockfiles (verify-only), CHANGELOGs, and the test tree.

## Complexity Tracking

No Constitution violations (constitution is an unfilled template — N/A). No complexity justifications required.