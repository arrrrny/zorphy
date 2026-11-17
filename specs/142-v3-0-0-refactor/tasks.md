# Tasks: zorphy 3.0.0

## Phase 1 — Shared-part builder

- [ ] T1. Create `zorphy/lib/src/shared_part_builder.dart` with `SharedPartBuilder extends build.Builder` calling `buildStep.librarySourceSink?.add(...)`; fallback to legacy write if sink null.
- [ ] T2. Update `zorphy/lib/builder.dart` `zorphyBuilder` to return `SharedPartBuilder`; remove `PartBuilder` import if unused.
- [ ] T3. Update `zorphy/build.yaml`: `build_extensions: {".dart": [".zorphy.part"]}`, drop `applies_builders` combining_builder if not needed, add `required_experiments: [enhanced-parts]` if imports used.
- [ ] T4. Delete `zorphy/lib/builder2.dart` (`zorphy2Builder`).
- [ ] T5. Update `zorphy/lib/src/zorphy_generator.dart` call site to emit blocks consumable by the sink (no `part of` directive in blocks).
- [ ] T6. Add `zorphy/test/shared_part_builder_test.dart`: single `.zorphy.part` per library, no `.zorphy.dart`; analyzer-clean.

## Phase 2 — Lean-flavor migrator

- [ ] T7. Create `zorphy_migrator/lib/src/lean_detector.dart` implementing detector interface: parse `@Zorphy` annotations, scan package for feature references, produce `LeanFlavorProposal` list.
- [ ] T8. Add `lean` subcommand to `zorphy_migrator/lib/src/cli.dart`: `--dry-run` (default) emits unified diff; `--apply` writes via `Rewriter`.
- [ ] T9. Extend `zorphy_migrator/lib/src/report.dart` with lean report (per-class current→proposed, lines saved).
- [ ] T10. Add `zorphy_migrator/test/lean_detector_test.dart` with a fixture package (lean/standard/full classes).

## Phase 3 — Tests, smoke, release

- [ ] T11. Upgrade `zorphy/test/` golden tests to `.zorphy.part` layout; update `analyze_clean_gate_test.dart` to analyze `.zorphy.part`.
- [ ] T12. Upgrade `zorphy/test/release/` for 3.0.0 version assertions (SDK floor unchanged at `>=3.11.0`).
- [ ] T13. Bump `zorphy`, `zorphy_annotation`, `zorphy_migrator` to `3.0.0`; CHANGELOG ×3; `check_version_sync.sh` passes.
- [ ] T14. Smoke: `build_runner build` on `zik_zak` + `dart_web_scraper` → one `.zorphy.part` per library, `dart analyze` clean.
- [ ] T15. Smoke: `zorphy_migrator lean --dry-run` on `zik_zak` proposes reductions; `--apply` reduces line count, all tests green.
- [ ] T16. `./scripts/local_ci.sh` green; open PR to `master`.