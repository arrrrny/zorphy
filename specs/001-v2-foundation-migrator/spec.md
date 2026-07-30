# Feature Specification: Zorphy 2.0 Foundation + Freezed Migrator

**Feature Branch**: `001-v2-foundation-migrator`

**Created**: 2026-07-30

**Status**: Draft

**Input**: User description: "https://github.com/arrrrny/zorphy/issues/20 and https://github.com/arrrrny/zorphy/issues/21 tackle both together, since we are launching v2 it is acceptable to have some breaking changes with a clear migration path"

This spec combines two coordinated workstreams for the zorphy 2.0 release:

- **Issue #20** — v2.0 foundation: analyzer 14 support, single-pass builder consolidation, `ZorphyPreset` + granular feature flags, freezed comparison docs.
- **Issue #21** — new `zorphy_migrator` package: resolved-AST codemod converting freezed classes to zorphy classes.

Because v2 is a major release, breaking changes are acceptable **with a clear migration path** — but the hard invariant stands: default `@Zorphy()` output must remain byte-identical to v1.9.0 (`standard` preset == today), and `@zorphy2` must keep working as a deprecated alias.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Modern toolchain compatibility (Priority: P1)

A Dart developer on a modern toolchain (analyzer 14.x, current build_runner/source_gen) adds `zorphy` to their project. `dart pub get` resolves without constraint conflicts and code generation works.

**Why this priority**: The `analyzer: ^13.0.0` pin currently blocks consumers on modern Dart toolchains. This is the single most impactful adoption blocker and gates everything else in v2.

**Independent Test**: `cd zorphy && dart pub get` resolves with analyzer 14.1.0 without overrides in the published constraint; `dart analyze` and `dart test` pass on both analyzer 13.x and 14.x resolutions.

**Acceptance Scenarios**:

1. **Given** a consumer project requiring analyzer 14.x, **When** they depend on zorphy 2.0, **Then** `dart pub get` resolves with no overrides.
2. **Given** the zorphy repo, **When** CI runs the analyzer 13/14 matrix, **Then** `dart test` is green on both.

---

### User Story 2 - Faster, single-pass builds (Priority: P1)

A developer with a large project using zorphy runs `build_runner build`. Every library is analyzed and generated exactly **once** (not twice via the `zorphy` + `zorphy2` double pass), and polymorphic sealed hierarchies generate correctly using only `@zorphy` — no `@zorphy2` ordering annotation needed.

**Why this priority**: The double `PartBuilder` pass doubles generation time for every consumer, and the process-global static state defeats build caching. Build performance is the top day-to-day pain.

**Independent Test**: `build.yaml` exposes exactly one builder; the sealed-hierarchy fixture (`$$Shape` + `$Circle` + `$Rectangle`) generates correctly with only `@zorphy`, and `switch` exhaustiveness holds. A project using `@zorphy2` today regenerates byte-identical output after upgrading (alias compatibility).

**Acceptance Scenarios**:

1. **Given** a library with a sealed hierarchy annotated only with `@zorphy`, **When** build_runner runs, **Then** output is correct with base interfaces generated before subtypes (topological order).
2. **Given** a v1.9.0 project using `@zorphy2`, **When** it upgrades to 2.0 and regenerates, **Then** output is byte-identical and a deprecation notice exists in `zorphy2` dartdoc.
3. **Given** the generator source, **When** grepped for `static` mutable cross-asset maps, **Then** none remain in `zorphy_generator.dart` / `builder2.dart`.

---

### User Story 3 - Lean output via presets and granular flags (Priority: P2)

A developer defining a plain DTO writes `@Zorphy(preset: ZorphyPreset.lean, generateJson: true)` and gets only: class, constructor, `copyWith`, `==`/`hashCode`, `toString`, JSON — no patch API, filter descriptors, compareTo, property helpers, field enum, fields class, or changeTo. Another developer uses `@Zorphy(preset: ZorphyPreset.lean, generatePatch: true)` to get the lean set plus patch only.

**Why this priority**: Generated-code bloat for simple types is a standing complaint; lean output also makes the migrator's output clean (Story 5).

**Independent Test**: Golden test — `@Zorphy(preset: ZorphyPreset.lean)` on a 2-field class emits no `Patch`/`Filter`/`Fields`/`compareTo`/property-helper symbols; `generatePatch: true` adds exactly patch symbols; `@Zorphy()` with no preset emits byte-identical output to v1.9.0.

**Acceptance Scenarios**:

1. **Given** `@Zorphy(preset: ZorphyPreset.lean)`, **When** generation runs, **Then** only the lean feature set is emitted.
2. **Given** `@Zorphy()` (no preset/flags), **When** generation runs on a v1.9.0 fixture, **Then** output is byte-identical to v1.9.0 (`standard` == today).
3. **Given** any `bool?` flag set non-null on top of a preset, **When** generation runs, **Then** the explicit flag overrides the preset for that feature.
4. **Given** the generators, **When** flag resolution is audited, **Then** all resolution happens in `GenerationConfig` and no generator reads `ConstantReader` directly.

---

### User Story 4 - Freezed comparison documentation (Priority: P3)

A prospective user evaluating data-class generators reads the README "Zorphy vs Freezed" section (and the dedicated website page) with a feature matrix and three side-by-side compilable examples: simple data class, sealed union, nested patch update.

**Why this priority**: Positioning drives adoption but doesn't gate functionality. Analyzer 14 support (shipped in Story 1 while freezed 3.2.5 caps `analyzer <11.0.0`) is the concrete competitive win to document.

**Independent Test**: README section + `website/docs` page exist; all three examples are real zorphy code lifted from `zorphy/example/lib/` and analyze clean.

**Acceptance Scenarios**:

1. **Given** the README, **When** a reader opens the comparison section, **Then** they find the feature matrix, honest "where freezed differs" notes, and three side-by-side examples.
2. **Given** the three example snippets, **When** extracted and analyzed, **Then** `dart analyze` is clean.

---

### User Story 5 - Automated freezed-to-zorphy migration (Priority: P2)

A team invested in freezed runs `dart run zorphy_migrator migrate lib/ --dry-run` to preview a unified diff, then `--apply --report MIGRATION.md` to convert their models. Simple classes, unions, `@Default`, `@JsonKey`, and `fromJson`/`toJson` are converted; unmigratable constructs (`@unfreezed`, custom methods, non-factory constructors) are listed in the report with `file:line` and reason — never silently dropped.

**Why this priority**: Removes the biggest adoption barrier for the target audience; pairs with Story 3 (lean presets make migration output minimal). Depends on the 2.0 target API but is a fully additive new package.

**Independent Test**: Golden fixtures (`test/fixtures/<case>/input.dart` → `expected.dart`) convert byte-identical; `--apply` output compiles against zorphy 2.0 (`build_runner build` + `dart analyze` clean); `--dry-run` writes nothing; `--fail-on-manual` exits 1 when manual items exist.

**Acceptance Scenarios**:

1. **Given** a freezed simple class, **When** migrated, **Then** output is `@Zorphy() abstract class $Foo { ... }` with preserved nullability, generics, and `@JsonKey` annotations.
2. **Given** a freezed union (`factory Foo.ok(...)/factory Foo.err(...)`), **When** migrated, **Then** output is a sealed `$$Foo` base plus `$Ok`/`$Err` subtypes with `explicitSubTypes`.
3. **Given** a freezed class with `@Default(expr)`, **When** migrated, **Then** the `$Foo_` + top-level factory-function pattern is emitted (default never silently dropped); expressions referencing other fields are flagged manual.
4. **Given** an `@unfreezed` class or a class with custom methods, **When** migrated, **Then** the class is untouched and listed in the report with `file:line` and reason.
5. **Given** `--dry-run`, **When** the command runs, **Then** no files change (checksum-verified) and a unified diff prints to stdout.

---

### Edge Cases

- **Analyzer 13/14 dual resolution**: `json_serializable` (dev-only) caps `analyzer <14.0.0`; repo-local CI uses a temporary `dependency_overrides` entry — the published constraint must not be held back.
- **Cross-library polymorphic hierarchies**: single-pass ordering resolves within a library; hierarchies spanning libraries rely on standard source_gen library cycling (same as v1.9.0 behavior).
- **Preset + explicit flag conflicts**: non-null flags always win over the preset; resolution is centralized in `GenerationConfig`.
- **`generateCopyWithFn` default**: stays off in `lean` and `standard`, on in `full` — preserves byte-identical default output.
- **Migrator `@Default` with field-referencing expressions**: flagged as manual, not dropped.
- **Migrator on already-zorphy or non-freezed files**: no-op; not listed as manual items.
- **Migrator never deletes files**: `.freezed.dart` deletion and dependency removal are report instructions only.

## Requirements *(mandatory)*

### Functional Requirements

**A. Analyzer 14 support (from #20)**

- **FR-A1**: `zorphy/pubspec.yaml` MUST widen `analyzer` to `>=13.0.0 <15.0.0` and resolve with analyzer 14.1.0 with no override in the published constraint.
- **FR-A2**: The codebase MUST compile clean under analyzer 13.x and 14.x (verified, not assumed).
- **FR-A3**: CI MUST include a matrix job running `dart test` against analyzer 13.x and 14.x resolutions (repo-local temporary `dependency_overrides` for `json_serializable` permitted, marked temporary).

**B. Single-pass builder (from #20)**

- **FR-B1**: `build.yaml` MUST expose exactly one builder; one generation pass per library.
- **FR-B2**: Polymorphic ordering MUST be resolved inside the single pass: analyze all `@Zorphy` classes in the library, then generate base interfaces before subtypes (topological order over the `implements $$Base` graph).
- **FR-B3**: `ZorphyGenerator._allAnnotatedClasses` and `Zorphy2Generator._allAnnotatedClasses` static mutable maps MUST be eliminated; discovered classes passed through the orchestrator call chain.
- **FR-B4**: `@zorphy2`/`Zorphy2` MUST keep working as a deprecated alias behaving exactly like `@zorphy`, with a deprecation notice in dartdoc.
- **FR-B5**: `runs_before: ["json_serializable:json_serializable"]` and `applies_builders: ["source_gen|combining_builder"]` semantics MUST be preserved.

**C. Presets + granular flags (from #20)**

- **FR-C1**: `zorphy_annotation` MUST add `enum ZorphyPreset { lean, standard, full }` and a `preset` parameter on `Zorphy`/`Zorphy2` defaulting to `ZorphyPreset.standard`.
- **FR-C2**: New per-feature flags MUST be added: `generateCopyWith`, `generatePropertyHelpers`, `generateEqualsToString`, `generateChangeTo`.
- **FR-C3**: All feature flags MUST become `bool?` — null inherits from preset, non-null overrides. `const zorphy`/`const zorphy2` semantics identical to `preset: standard`.
- **FR-C4**: Flag resolution MUST live exclusively in `GenerationConfig` (final non-nullable bool per feature); `AnnotationParser` MUST parse every flag; generators MUST NOT read `ConstantReader`.
- **FR-C5**: Preset semantics MUST match the pre-decided matrix: lean = copyWith+equals/toString only; standard = byte-identical to v1.9.0 defaults; full = standard + copyWithFn. `generateJson` stays opt-in in all presets.

**D. Freezed comparison docs (from #20)**

- **FR-D1**: README MUST gain a "Zorphy vs Freezed" section and `website/docs` a dedicated page: feature matrix, honest "where freezed differs" notes, three side-by-side examples (simple class, sealed union, nested patch).
- **FR-D2**: Comparison examples MUST be real, compilable zorphy code analyzing clean.

**E. zorphy_migrator package (from #21)**

- **FR-E1**: A new independently-publishable `zorphy_migrator` package MUST exist at repo root (sibling of `zorphy/`, `zorphy_annotation/`), versioned `0.1.0` until 2.0 ships.
- **FR-E2**: Migration MUST use resolved AST via `AnalysisContextCollection` (`analyzer >=14.0.0 <15.0.0`) — no regex/text transforms.
- **FR-E3**: The full construct-mapping table MUST be implemented: simple classes, unions → `$$Base` + subtypes, `fromJson`/`toJson` → `generateJson: true`, `@Default` → `$Foo_` + factory function, `@JsonKey` preserved, `@With`/`@Implements` → `implements $Iface` (else flagged).
- **FR-E4**: Unmigratable constructs (`@unfreezed`, custom methods/getters, asserts, non-factory constructors) MUST appear in the report with `file:line` and reason — silent drops are a bug.
- **FR-E5**: Rewrites MUST preserve file order, comments, and unrelated code; only annotated class spans are replaced.
- **FR-E6**: CLI MUST provide `migrate <path>` with `--dry-run` (default), `--apply`, `--report <file>`, `--fail-on-manual`; recurse directories; skip generated files. Exit codes: 0 full migration, 1 manual items, 2 analysis errors.
- **FR-E7**: Report tail MUST include post-migration instructions (remove freezed deps, delete `*.freezed.dart`, re-run build_runner). The tool MUST never delete user files.
- **FR-E8**: Emitted annotations SHOULD use `preset: ZorphyPreset.lean` where the source class provably uses only lean features (noted in report), else standard default.
- **FR-E9**: Golden-file tests under `zorphy_migrator/test/fixtures/` MUST cover: simple class, nullable fields, generics, union (2+ variants), `@Default`, `@JsonKey`, fromJson/toJson, unfreezed (report-only), custom method (report-only).
- **FR-E10**: Dependency direction MUST be one-way: `zorphy_migrator` → `zorphy_annotation`; never reverse.

### Key Entities

- **ZorphyPreset**: enum (`lean` | `standard` | `full`) — the coarse output-bulk dial.
- **GenerationConfig**: resolved, non-nullable per-feature booleans after preset+override resolution; single source of truth for generators.
- **AnnotatedClass graph**: per-library set of `@Zorphy` classes with `implements` edges; topologically ordered within a single generation pass.
- **MigrationReport**: per-file list of converted classes and manual-attention items (`file:line`, reason), plus post-migration instructions.
- **Fixture pair**: `input.dart` (freezed source) → `expected.dart` (zorphy output) golden test unit.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart pub get` in `zorphy/` resolves with analyzer 14.1.0 with no published-constraint override; `dart analyze` clean on 13.x and 14.x.
- **SC-002**: CI matrix green for analyzer 13/14 on master/development.
- **SC-003**: Exactly one builder in `build.yaml`; sealed-hierarchy fixture generates correctly with only `@zorphy`; `@zorphy2` projects regenerate byte-identical output.
- **SC-004**: `@Zorphy()` default output byte-identical to v1.9.0 golden; lean preset emits zero `Patch`/`Filter`/`Fields`/`compareTo`/property-helper symbols.
- **SC-005**: Zero `static` mutable maps in `zorphy_generator.dart`/`builder2.dart` (grep-verified).
- **SC-006**: All migrator golden fixtures convert byte-identical; `--apply` output compiles against zorphy 2.0; `--dry-run` changes no files; `--fail-on-manual` exits 1 on manual items.
- **SC-007**: A ≥10-class real-world freezed smoke fixture (incl. one union) migrates end-to-end in CI.
- **SC-008**: README + website comparison page and migration guide merged; doc examples analyze clean.
- **SC-009**: CHANGELOG entries in `zorphy/CHANGELOG.md`, `zorphy_annotation/CHANGELOG.md`, and `zorphy_migrator/CHANGELOG.md`.

## Assumptions

- v2.0 permits breaking changes with a clear migration path, but default-output byte-compatibility and the `@zorphy2` alias are preserved — the "breaking" surface is limited to the annotation API additions (nullable flags) and builder consolidation, both backward-compatible by construction.
- `zorphy` and `zorphy_annotation` bump major together per monorepo publishing convention; `zorphy_migrator` starts at `0.1.0`.
- `json_serializable` lacking an analyzer-14 release does not block the published constraint; only the repo-local CI job uses a temporary override.
- The freezed→zorphy mapping table in #21 is pre-decided and final; no [NEEDS CLARIFICATION] markers are required — both source issues explicitly state "Open Questions: None blocking."
- Pub.dev publishing itself is out of scope (maintainer action post-merge).
