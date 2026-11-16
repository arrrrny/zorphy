# Implementation Plan: zorphy 3.0.0 — Shared-Part Generation + Lean-Flavor Auto-Migration

**Branch**: `142-v3-0-0-refactor` | **Date**: 2026-11-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/142-v3-0-0-refactor/spec.md`

## Summary

Major release with two coupled deliverables. **(1) Shared-part generation**: replace the per-class `.zorphy.dart` `source_gen.PartBuilder` output with a single shared `.zorphy.part` per library, written through `build`'s `LibrarySourceSink` (`BuildStep.librarySourceSink`) via a **custom `build.Builder`** (source_gen 4.3.1 `PartBuilder` does not consume the sink — verified in source). One part per library instead of N files; cross-entity polymorphic dispatch becomes a single compilation unit. **(2) Lean-flavor auto-migration**: a new `zorphy_migrator lean` command that scans a project's `@Zorphy` annotations + real usage of generated members, computes the minimal `ZorphyPreset`/feature-flag set per class, and emits a unified diff (dry-run default) or applies (`--apply`) — shrinking generated code without removing used functionality. Both are breaking; `builder2.dart`/`zorphy2Builder` deprecated alias removed; all tests upgraded.

## Technical Context

**Language/Version**: Dart — floor `>=3.11.0 <4.0.0` (dev/CI on ≥3.13).

**Primary Dependencies**: `build` 5.0.0 (`LibrarySourceSink` in `lib/src/library_source_sink.dart`; `BuildStep.librarySourceSink` impl in `build_runner` 2.17.1 `build_step_impl.dart:68`). `source_gen` 4.3.1 (`PartBuilder` at `lib/src/builder.dart:277` — does NOT consume sink). `analyzer` ^14.0.0.

**Key API surface**:
- `LibrarySourceSink.add(String source)` — source must not contain directives.
- `LibrarySourceSink.addImport(uri, as:, show:, hide:)` — requires `enhanced-parts` experiment (StateError otherwise).
- `BuildStep.librarySourceSink` → `Future<LibrarySourceSink?>`; `partContribution`, `imports`, `languageVersion`.

**Storage**: source files + generated `.zorphy.part` + `build.yaml` + migrator detector.

**Testing**: `dart test -j 2`, `dart analyze`, `./scripts/local_ci.sh`, build_runner smoke on `zik_zak` + `dart_web_scraper`.

**Constraints**: shared-part output deterministic + `dart_style`-formatted; `enhanced-parts` experiment required; migration advisory by default; no regression on analyzer 13.x/14.x gates.

## Phase 1 — Shared-part builder (breaking)

1. New `lib/src/shared_part_builder.dart`: a `build.Builder` that, per input library, collects generator output and calls `buildStep.librarySourceSink?.add(...)`; falls back to legacy per-class output if sink is null (defensive).
2. `lib/builder.dart`: `zorphyBuilder` returns the new builder (or composes it); `build.yaml` `build_extensions` updated to emit `.zorphy.part` and declare `required_experiments: [enhanced-parts]` if supported.
3. Remove `lib/builder2.dart` (`zorphy2Builder`).
4. Update `ZorphyGenerator` call site to write to the sink instead of `buildStep.writeAsString`.

## Phase 2 — Lean-flavor migrator

5. `zorphy_migrator/lib/src/lean_detector.dart`: parse `@Zorphy`/`@Zorphy2` annotations (via analyzer), walk the package for references to generated members (`copyWith`, `patch`, `filter`, `toJson`/`fromJson`, comparators), compute minimal preset per class.
6. `zorphy_migrator/lib/src/cli.dart`: add `lean` subcommand — `--dry-run` (default) emits unified diff via `Rewriter`; `--apply` writes.
7. `zorphy_migrator/lib/src/report.dart`: lean report (per-class current→proposed, lines saved estimate).

## Phase 3 — Tests & release

8. Upgrade `zorphy/test/` golden tests to `.zorphy.part` layout; add shared-part smoke test.
9. New `zorphy_migrator/test/lean_detector_test.dart` + CLI integration test on a fixture.
10. Bump `zorphy`/`zorphy_annotation`/`zorphy_migrator` to `3.0.0`; CHANGELOG ×3; `check_version_sync.sh`.
11. Smoke: build `zik_zak` + `dart_web_scraper` with shared parts; run `zorphy_migrator lean --dry-run` on both.

## Verification

- `dart test -j 2` green across all 3 packages.
- `dart analyze` clean on `zorphy`, `zorphy_annotation`, `zorphy_migrator`, and on built `zik_zak`/`dart_web_scraper`.
- `build_runner build` on `zik_zak` produces one `.zorphy.part` per library; `flutter analyze` clean.
- `zorphy_migrator lean --dry-run` on `zik_zak` proposes reductions; `--apply` reduces generated line count with all tests green.
- Release gate: `check_version_sync.sh` passes; version `3.0.0` in sync.

## Risks

- `enhanced-parts` experiment stability — gate behind detection; if sink unavailable, fall back to legacy output with a clear error.
- Generated `.zorphy.part` may need `// ignore_for_file` headers matching legacy.
- Migrator false positives (removing a used feature) — dry-run default + conservative "referenced → keep" rule (FR-5).