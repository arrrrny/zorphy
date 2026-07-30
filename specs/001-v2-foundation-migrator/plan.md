# Implementation Plan: Zorphy 2.0 Foundation + Freezed Migrator

**Branch**: `001-v2-foundation-migrator` | **Date**: 2026-07-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-v2-foundation-migrator/spec.md` (GitHub issues #20 + #21)

## Summary

Deliver the zorphy 2.0 foundation and a freezed migration tool in one coordinated change:

1. **Analyzer 14** — widen `analyzer` to `>=13.0.0 <15.0.0`, fix any compile breaks (none expected — verified by grep), add CI matrix.
2. **Single-pass builder** — consolidate `zorphy` + `zorphy2` builders into one `PartBuilder`; resolve polymorphic ordering inside a single library pass via topological sort; eliminate process-global static maps; keep `@zorphy2` as a deprecated alias of `@zorphy`.
3. **Presets + granular flags** — add `ZorphyPreset { lean, standard, full }` and four new `bool?` flags; centralize resolution in `GenerationConfig`; `standard` reproduces v1.9.0 output byte-for-byte.
4. **Freezed comparison docs** — README section + `website/docs` page with matrix and three compilable examples.
5. **zorphy_migrator** — new monorepo package: resolved-AST codemod (freezed → zorphy) with CLI (`--dry-run`/`--apply`/`--report`/`--fail-on-manual`), markdown report, golden fixture tests.

**Technical approach**: all flag resolution flows through one rewritten `GenerationConfig.fromAnnotation()`; ordering uses a per-library topological sort over the `implements $$Base` graph computed inside the single generator pass (no statics); the migrator uses `AnalysisContextCollection` for resolved AST and source-span replacement (never full-file rewrites).

## Technical Context

**Language/Version**: Dart SDK >=3.8.0 <4.0.0 (repo toolchain 3.12.2)

**Primary Dependencies**: `analyzer >=13.0.0 <15.0.0`, `build ^4.0.4`, `source_gen ^4.2.3`, `code_builder`, `dart_style`, `zorphy_annotation` (path); migrator adds `analyzer >=14.0.0 <15.0.0`, `args`, `path`, `diff`-style output via handwritten unified-diff emitter (no new runtime deps beyond analyzer/args/path/collection)

**Storage**: N/A (code generation + file rewrites)

**Testing**: `dart test`; golden-file fixtures under `zorphy/test/generation/` and `zorphy_migrator/test/fixtures/`

**Target Platform**: Dart CLI / build_runner (all platforms)

**Project Type**: library + CLI tool (monorepo: `zorphy/`, `zorphy_annotation/`, new `zorphy_migrator/`)

**Performance Goals**: one analysis+generation pass per library (≈2× faster consumer builds vs double pass)

**Constraints**: default `@Zorphy()` output byte-identical to v1.9.0; `@zorphy2` byte-identical alias; no new runtime deps in `zorphy`/`zorphy_annotation`; flag resolution in exactly one place (`GenerationConfig`); migrator never deletes user files, never silently drops constructs

**Scale/Scope**: 2 existing packages modified, 1 new package (~8 lib files), 13 sub-generators re-gated, CI matrix, 2 docs surfaces (README + docusaurus)

## Constitution Check

*GATE: No project constitution is defined (`.specify/memory/constitution.md` is an unfilled template) — no gates to violate. Project hard rules from the workflow profile apply:*

| Rule | Plan compliance |
| --- | --- |
| Never hand-edit generated files | ✅ Only generator source changes; outputs regenerated via build_runner |
| Default output byte-identical | ✅ `standard` preset == v1.9.0 defaults; golden test enforces |
| No new runtime deps in existing packages | ✅ Only constraint widening; new deps confined to new `zorphy_migrator` package |
| Docs in README + website kept in sync | ✅ Workstream D/E both touch both surfaces |
| Golden test conventions | ✅ Fixtures follow `zorphy/test/generation/` layout |

## Project Structure

### Documentation (this feature)

```text
specs/001-v2-foundation-migrator/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── checklists/
│   └── requirements.md  # Specify-phase checklist
└── tasks.md             # /speckit-tasks output
```

### Source Code (repository root)

```text
zorphy_annotation/
└── lib/src/annotations.dart        # +ZorphyPreset, +preset param, +4 flags, all flags bool?

zorphy/
├── pubspec.yaml                    # analyzer >=13.0.0 <15.0.0
├── build.yaml                      # single builder
├── lib/
│   ├── builder.dart                # single entry point
│   ├── builder2.dart               # deprecated alias → same generator
│   └── src/
│       ├── zorphy_generator.dart   # no statics; per-pass class graph; topo ordering
│       ├── orchestrator.dart       # generators read config only
│       ├── analysis/annotation_parser.dart  # parses ALL flags
│       ├── models/generation_config.dart    # preset+override resolution
│       └── generators/*.dart       # shouldGenerate consults config
└── test/generation/                # preset/flag goldens + alias-compat golden

zorphy_migrator/                    # NEW package
├── pubspec.yaml                    # v0.1.0, analyzer >=14.0.0 <15.0.0
├── bin/zorphy_migrator.dart        # CLI entry
├── lib/src/
│   ├── freezed_detector.dart       # resolved-AST visitor
│   ├── mapping.dart                # freezed construct → zorphy model
│   ├── rewriter.dart               # source-span rewrite + unified diff
│   ├── report.dart                 # markdown report
│   └── cli.dart                    # arg parsing, exit codes
└── test/fixtures/<case>/{input,expected}.dart

.github/workflows/dart.yml          # analyzer 13/14 matrix + migrator package
README.md, website/docs/            # comparison + migration guide
```

## Phase 0: Research

See [research.md](research.md). All technical unknowns resolved: annotation default-value encoding for `bool?` flags, single-pass ordering strategy, builder consolidation shape, analyzer 14 API delta (none affect zorphy), migrator AST approach.

## Phase 1: Design

See [data-model.md](data-model.md) (ZorphyPreset, GenerationConfig, ClassGraph, MigrationReport) and [quickstart.md](quickstart.md) (verification walkthrough). No network contracts — contracts/ replaced by CLI contract embedded in data-model.md.

### Key design decisions

1. **One builder, one extension**: `build.yaml` keeps only `zorphy` builder producing `.zorphy.dart`. `@zorphy2`-annotated classes are handled by the same generator (`Zorphy2` type-checker added alongside `Zorphy`), emitting into the same `.zorphy.dart` part. Consumers replace `part 'x.zorphy2.dart'` — **breaking change with migration path**: the alias keeps working only if the consumer's part directive is updated; to stay truly byte-compatible we keep `.zorphy2.dart` emission for `@zorphy2` classes from the single builder (one PartBuilder emitting both extensions via a single generator that routes output by annotation type). Decision: **single PartBuilder with `build_extensions: {".dart": [".zorphy.dart", ".zorphy2.dart"]}`**, generator returns a routing wrapper — `@Zorphy2` classes emit to `.zorphy2.dart` exactly as today (byte-identical), `@Zorphy` to `.zorphy.dart`. Zero consumer breakage.
2. **Ordering without statics**: `GeneratorForAnnotationX` already receives `allClasses` per library. The generator builds a `Map<String, ClassElement>` fresh per element from `allClasses` (library-scoped), replacing `_allAnnotatedClasses`. Cross-class ordering within a part file is handled because PartBuilder aggregates all generated parts of a library before write — base-before-subtype ordering is satisfied by sorting the library's annotated classes topologically before generation (implemented in the generator's `generate` entry via `GeneratorForAnnotationX.generateForLibrary` hook if available, else by emitting base-class blocks first in each part — verified against existing tests).
3. **Nullable flags**: `bool?` in annotations round-trips through `ConstantReader.peek()` (null when unset). `GenerationConfig.fromAnnotation(options, preset)` resolves every feature to a final bool. Preset table is a const map in `GenerationConfig`.
4. **Migrator span replacement**: compute the source span of each freezed class declaration; build replacement text from the resolved AST model; apply spans in reverse offset order; emit unified diff by line-diffing original vs rewritten (simple LCS diff, no dependency).

### Constitution Check (post-design re-evaluation)

All rules still satisfied — no generated files hand-edited; byte-compat goldens planned; no new runtime deps in existing packages.

## Complexity Tracking

No constitution violations to justify.
