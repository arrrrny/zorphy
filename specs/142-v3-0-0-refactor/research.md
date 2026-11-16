# Research: zorphy 3.0.0 — Shared Parts & Lean-Flavor Migration

## R1. source_gen PartBuilder vs LibrarySourceSink (RESOLVED)

**Question**: Can `source_gen` 4.3.1 `PartBuilder` emit into a shared part via `LibrarySourceSink`?

**Finding**: **No.** `source_gen/lib/src/builder.dart` `_Builder` (line 20) writes its own `part of` file via `_generateForLibrary` (line ~120). `grep librarySourceSink` across `source_gen-4.3.1/lib/` returns **zero** matches. `PartBuilder` (line 277) is a thin wrapper over `_Builder` with a `generatedExtension`; it has no sink integration.

**Implication**: 3.0.0 shared parts require a **custom `build.Builder`**, not a `PartBuilder` flag. The builder must call `buildStep.librarySourceSink?.add(source)` itself.

## R2. LibrarySourceSink API (build 5.0.0)

`build/lib/src/library_source_sink.dart`:
- `void add(String source)` — source must NOT contain directives; do not format (whitespace not preserved).
- `String get importPrefix` — reserved prefix for this sink.
- `void addImport(String uri, {required String as, Iterable<String>? show, Iterable<String>? hide})` — `as` must start with `importPrefix`; adds imports cause dependency on `enhanced-parts` feature (StateError if not enabled).

`build_runner` 2.17.1 `build_step_impl.dart:68`: `Future<LibrarySourceSink?> get librarySourceSink` — returns null if no sink; exposes `partContribution`, `imports`, `languageVersion`.

## R3. enhanced-parts experiment

`addImport` throws `StateError` unless the `enhanced-parts` experiment is enabled. For 3.0.0:
- If the generator needs NO imports in the shared part (most Zorphy output is self-contained after the `part of` header), `addImport` is not required and the experiment is not triggered.
- If imports are needed (e.g. `package:zorphy_annotation/...`), the experiment must be enabled via `analysis_options.yaml` `analyzer: enable-experiment: [enhanced-parts]` or `build.yaml` `required_experiments` (verify support in plan phase).
- **Decision**: default shared-part output avoids imports (uses fully-qualified or `part of` library imports); `addImport` only when explicitly needed, with a clear error if experiment missing.

## R4. Current builder wiring

- `zorphy/lib/builder.dart:28` `zorphyBuilder` → `source_gen.PartBuilder([...], '.zorphy.dart', header: ...)`.
- `zorphy/build.yaml`: `zorphy:zorphy` builder, `build_extensions: {".dart": [".zorphy.dart"]}`, `auto_apply: dependents`, `applies_builders: ["source_gen|combining_builder"]`.
- `zorphy/lib/builder2.dart`: `@Deprecated zorphy2Builder` alias (remove in 3.0.0).
- `zorphy/lib/src/zorphy_generator.dart:98`: emits `.zorphy.dart` / `.zorphy2.dart` via output extension.

## R5. Preset system (lean flavor target)

`zorphy_annotation/lib/src/annotations.dart:23` `enum ZorphyPreset { lean, standard, full }`.
- `lean`: class, constructor, `copyWith`, equality.
- `standard`: lean + patch + filter + comparators + JSON opt-in.
- `full`: standard + function-based copyWith.
- Per-feature overrides: `generateJson` (bool, default false), `generatePatch?`, `generateFilter?`, `generateCopyWith?`, `generateCopyWithFn?` (null = inherit preset).

**Lean-flavor tool**: for each `@Zorphy` class, detect which of {patch, filter, copyWithFn, json, comparators} are actually referenced in the package; propose `preset: lean` + explicit `generateX: true` only for referenced features. Conservative rule (FR-5): never drop a feature referenced anywhere in `lib/` or `test/`.

## R6. Usage evidence (from completed analysis — do not redo)

- `zik_zak`: 159 `@Zorphy` classes, ~95.4k generated lines, ~42% patch code.
- `dart_web_scraper`: 70 `@Zorphy` classes, ~38.5k generated lines, ~39% patch code.
- Majority of entities generate unused JSON/patch/filter/comparator plumbing under `standard`.

## R7. zorphy_migrator extension point

`zorphy_migrator/lib/src/cli.dart` `MigratorCli.run()`:
- Parses args, selects detectors (`freezed_detector`, `exchangeable_detector`), builds replacements, `Rewriter().applySpans` + `unifiedDiff`.
- New `lean_detector.dart` implements the same detector interface: scan → replacements (annotation rewrites) → diff/apply.
- `Rewriter` (span-based) already supports unified diff + apply; lean detector only needs to produce the right spans.

## R8. Output extension choice

`.zorphy.part` chosen (not `.g.dart`) to avoid collision with `source_gen|combining_builder` (`SharedPartBuilder`) outputs. `build.yaml` `build_extensions: {".dart": [".zorphy.part"]}`.