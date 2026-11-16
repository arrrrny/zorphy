# Feature Specification: Zorphy 3.0.0 — Shared-Part Generation + Lean-Flavor Auto-Migration

**Feature Branch**: `142-v3-0-0-refactor`
**Created**: 2026-11-16
**Status**: Draft (pre-merge of #160)
**Input**: User request — "PartBuilder is definitely 3.0.0 … a new migration tool for zorphy would scan the existing zorphy project like zik_zak, check usage of functionality and choose a flavor automatically lean … to minimize the generated file size while maximizing the functionality."

## Summary

Zorphy 3.0.0 is a major release with two coupled deliverables:

1. **Shared-part generation.** Replace the per-class `.zorphy.dart` `PartBuilder` output with a single shared `.zorphy.part` per library, using `build`'s `LibrarySourceSink` (`BuildStep.librarySourceSink`). This collapses N files per library into one, cuts build overhead, and makes cross-entity polymorphic dispatch a single compilation unit.
2. **Lean-flavor auto-migration tool.** A new `zorphy_migrator` capability that scans an existing Zorphy project (e.g. `zik_zak`, `dart_web_scraper`), measures which generated features are actually used, and rewrites `@Zorphy(...)` annotations to the minimal `ZorphyPreset`/feature-flag set — shrinking generated code without removing used functionality.

Both are breaking (`3.0.0`) and ship together so adopters get one migration.

## Why now (evidence)

- `source_gen` 4.3.1 `PartBuilder` does **not** consume `LibrarySourceSink`; `build` 5.0.0 / `build_runner` 2.17.1 do. Adopting shared parts requires a custom `build.Builder`, which is a major-version change.
- Usage analysis of two real consumers:
  - `zik_zak`: 159 `@Zorphy` classes, ~95.4k generated lines, ~42% patch code.
  - `dart_web_scraper`: 70 `@Zorphy` classes, ~38.5k generated lines, ~39% patch code.
  - The majority of entities generate unused JSON/patch/filter/comparator plumbing under `standard`.
- `ZorphyPreset { lean, standard, full }` and per-feature flags already exist in `zorphy_annotation` — the tool automates choosing them.

## Scope

### In scope
- New builder path emitting shared parts via `LibrarySourceSink` (gated on `enhanced-parts`).
- Removal of the `@Deprecated zorphy2Builder` alias (`builder2.dart`).
- `zorphy_migrator` lean-flavor detector + rewrite pipeline + report.
- Test upgrades across `zorphy`, `zorphy_annotation`, `zorphy_migrator` for the new output layout and tool.
- `build.yaml` updates (`build_extensions`, `applies_builders`, `required_experiments` if supported).
- CHANGELOG + PUBLISH/version sync for 3.0.0.

### Out of scope
- New language features in the generator beyond shared parts (deferred).
- JSON-schema / plugin loading changes.
- Non-Dart consumers of `.zorphy.dart` outside the monorepo.

## User Scenarios

### Scenario A — Existing project adopts shared parts
A consumer upgrades `zorphy` to 3.0.0, runs `build_runner`, and gets one `.zorphy.part` per library instead of many `.zorphy.dart` files. All existing generated members (copyWith, equality, patch, JSON) remain available with identical semantics.

### Scenario B — Lean-flavor migration
A consumer runs `zorphy_migrator lean --dry-run` on `zik_zak`. The tool reports, per `@Zorphy` class, which features are unused and the minimal preset it would apply; `--apply` rewrites annotations and regenerates, reducing generated lines with no loss of used functionality.

## Requirements

### Functional
- **FR-1**: Generator emits a single shared part per library via `LibrarySourceSink.add`; no per-class `.zorphy.dart`.
- **FR-2**: All generated members from 2.x remain available with identical runtime semantics.
- **FR-3**: `enhanced-parts` experiment requirement is detected and surfaced with an actionable error if absent.
- **FR-4**: `zorphy_migrator lean` scans annotations + usage, computes minimal preset/flags per class, and emits a unified diff (dry-run default) or applies (`--apply`).
- **FR-5**: Migration never removes a feature that is referenced in the package source.
- **FR-6**: `builder2.dart` / `zorphy2Builder` removed; `build.yaml` references updated.
- **FR-7**: All tests upgraded; byte-level golden tests updated to the shared-part layout.

### Non-functional
- **NFR-1**: Shared-part output is deterministic and formatted via `dart_style`.
- **NFR-2**: Migration tool runs in bounded time on a 159-class package (< 2 min).
- **NFR-3**: No regression in `analyzer` 13.x/14.x compatibility gates.

## Success Criteria

- `zorphy` builds `zik_zak` and `dart_web_scraper` with shared parts; `flutter analyze` clean on both.
- `zorphy_migrator lean --dry-run` on `zik_zak` proposes reductions; `--apply` reduces generated line count with all tests still green.
- Full test suite green (`zorphy`, `zorphy_annotation`, `zorphy_migrator`); release-gate tests pass.

## Assumptions

- `build_runner` 2.17.1 `LibrarySourceSink` + `enhanced-parts` experiment is stable enough to depend on for a major release.
- Consumers can enable the experiment via `analysis_options.yaml` / `build.yaml` `required_experiments` (to be verified in plan).
- Lean migration is advisory by default (dry-run); `--apply` is explicit opt-in.
- Part file extension `.zorphy.part` (distinct from `.g.dart` to avoid `SharedPartBuilder` collisions).