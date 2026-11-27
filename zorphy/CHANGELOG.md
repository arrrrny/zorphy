## [3.0.0-dev.5] - 2026-11-27

### Change
- ZorphyNested, fromJson/toJson aliases, enum boundary wire, colocated .zorphy.dart (retires _br_), wire-capability matrix, stacked-PR integrity, clean-checkout release gate
- Removed the dead `ZorphyGenerator`/plugin option surface; `zorphyBuilder` is the only pipeline and rejects unsupported builder options instead of ignoring them
- Removed `PatchEmitter`, the Account/Profile/ProgressBox v2 fixtures, the tracked v2 golden tree, ignored CLI v2 output, and all `_br_/` mirror trees; runtime patch laws now run against v3-generated fixtures
- Moved shallow collection equality/hash into `zorphy_annotation` and added `ZorphyPatchAlgebra` (`changedPaths`, `conflictingPaths`, `composePatches`) for v3 patches
- Corrected the wire matrix to document current v3 atomic nested/non-String-map patch omissions, and fixed DateTime/enum patch encoding to match its decoders

## [3.0.0-dev.4] - 2026-11-27

### Changed (BREAKING — v3.0.0)

- **`EntityConfig.autoId` removed (#300).** The v2 identity toggle on the CLI's
  `EntityConfig` (`zorphy/lib/src/cli/models/entity_config.dart`) is gone — the
  field, its constructor parameter and its `copyWith` parameter. v3 identity is
  never a toggle: `_buildAnnotation` derives the archetype purely from
  `kind` / `isSealed` / `extendsInterface`, and `_ownsIdentity` decides whether
  the scaffold declares `String get id;`, so nothing ever read `autoId`. A field
  that looked like it controlled identity but was silently ignored was a trap for
  the next caller. Anyone constructing `EntityConfig` by hand must drop the
  `autoId:` argument; downstream `zuraffa` already stopped passing it
  (arrrrny/zuraffa#2179).

### Fixed

- **A type-parameter field compares by content (#294).** A field whose declared
  type is one of the node's own type parameters (`P data`, `T payload`) can hold
  a `List`/`Set`/`Map` at runtime, and `==` compared it by identity — so two
  values with equal `Map` payloads were never equal and `value ==
  value.copyWith()` failed. The same defect #285 fixed for DECLARED
  collections, resurfacing through a generic. Such fields now route through the
  dynamic `_zorphyCollectionEquals` / `_zorphyCollectionHash` helpers (which
  fall back to `==` / `hashCode` for a non-collection), and the helpers are
  emitted for them.

- **A union root's body factories can construct their variants (#293).** A
  user body factory on a `@ZorphyUnion()` root is written against the SOURCE
  variant (`return $NetworkFailure(message: message)` — the only constructor
  it has), but the generated leaf exposes the trusted constructor as
  `fromTrusted` (#178) and no unnamed one, so the forwarded body did not
  compile. `$Variant(...)` constructor invocations in forwarded bodies are now
  rewritten to `Variant.fromTrusted(...)` for the variants whose source lacks
  `fromTrusted`; type positions, member accesses, string literals and comments
  are untouched. The variant set is computed from the union's hierarchy edges,
  so a union that declares every variant as a body factory (no redirects) is
  covered too.

- **Union variant factories honour the source declaration (#290).** The factory
  a `@ZorphyUnion()` root re-emits per variant (`factory $AppFailure.network(…)
  = $NetworkFailure;`, #271) now carries the SOURCE factory's own parameter
  list — names, requiredness and defaults exactly as written — instead of a list
  re-derived from the variant's fields, where every non-nullable field turned
  `required` and the author's `bool isRetryable = false` was silently lost.
  Dart constrains a redirecting factory to the target's exact signature and
  forbids defaults on it, so the emitted shape is decided per variant: a `const`
  redirect when the declaration is already the target's signature and the
  target's `fromTrusted` is const; a body factory forwarding each declared
  parameter to the field of the same name otherwise (a declared default, a
  positional declaration such as `ready(String value) = $Ready;`, or a
  collection field whose defensive copy makes `fromTrusted` non-const, #284).
  Previously a collection-bearing variant emitted a const redirect to a
  non-const constructor (`redirect_to_non_const_constructor`).
  `ZorphyVariantFactoryIr` gains `parameters`; the parser fills it from the
  analyzer element, and an IR built without one keeps the field-derived list.

## [3.0.0-dev.3] - 2026-11-26

### Added

- **Union roots re-emit redirecting variant factories and forward user
  static/factory members (#271, ZRP-008).** A `@ZorphyUnion()` root now emits a
  `const factory Root.variant(...) = Variant.fromTrusted;` per variant, so a
  variant is constructible through the root (and via Dart 3 dot-shorthand,
  `.variant(...)`), and the user-declared `static` methods / body `factory`
  constructors on the source `$Union` are copied onto the generated `sealed`
  root (rewriting `$Variant` → `Variant`). A forwarded member never shadows a
  name the root already declares.
- **Codec-parameterized `toWire` / `fromWire` on generic classes (#272,
  ZRP-009).** A generic `@ZorphyValue` / `@ZorphyEntity` / `@ZorphyUnion` leaf
  `<T, …>` now gets one codec parameter per type parameter, in declaration
  order: `Map<String, Object?> toWire(Map<String, Object?> Function(T) encodeT)`
  routes every field that mentions `T` through the encoder (a nullable `T?`
  passes `null` through), and `static ZorphyBoundaryResult<Foo<T>> fromWire<T>(
  Map<String, Object?> raw, ZorphyBoundaryResult<T> Function(Map<String,
  Object?>) decodeT)` merges the decoder's field violations with the wrapper's
  own. A generic abstract intermediate still emits no codec (its `fromWire`
  would have to forward to a leaf).

### Fixed

- **Nullable generic type parameters no longer emit `T?` (#273, ZRP-010).** A
  type parameter whose bound is already nullable (`Object?`, the implicit
  bound) is emitted as `I fieldName` rather than `I? fieldName`, so generated
  code no longer trips `unnecessary_question_mark` under `dart analyze
  --fatal-infos`.

### Documentation (#275, ZRP-006)

- Finished the v2 → v3 documentation pass: the README body now teaches the five
  v3 archetypes (the legacy `@Zorphy` / `ZorphyPreset` / `generate*` surface is
  gone outside the migration table), and the website's generics and polymorphism
  pages document the dev.3 forms above.

## [3.0.0-dev.2] - 2026-11-26

### Migration guide (#236)

This release closes the #175 re-audit release gate (#236): 3.0.0 is the agreed
v3 artifact, and the codemod plus the notes below are the supported path from
2.x. The full side-by-side table (`@Zorphy` → the archetypes, `copyWith` →
`ZorphyPatch`, `toJson`/`fromJson` → `toWire`/`fromWire`, `ProductFields` /
`Product.descriptor`, and the `migrate_v3` codemod) lives in the README's
[Migrating v2 → v3](#v3-migration) section. The short version:

1. Bump `zorphy` and `zorphy_annotation` to `^3.0.0` (they move in lockstep),
   then `dart pub get`. The `migrate_v3` executable ships with 3.0, not 2.x.
2. Preview with `dart run zorphy:migrate_v3 <path>`, then rewrite in place with
   `dart run zorphy:migrate_v3 <path> --apply`. The codemod strips every
   `preset:` / `generate*` argument, emits the zero-preset archetypes
   (`@ZorphyEntity(principalKey: #id)` / `@ZorphyValue()` / `@ZorphyUnion()` /
   `@ZorphyState()` / `@ZorphyIntent(replaySafe: …)`), and moves codec call
   sites to `.fromWire(...)` / `.toWire()`.
3. Delete the 2.x `<file>.zorphy.dart` files and any hand-written
   `part '*.zorphy.dart';` line — 3.0 emits one shared `<library>.part.dart`
   under `lib/_br_/` and `build_runner` inserts the `part` directive itself.
4. Run `dart run build_runner build` (no `--delete-conflicting-outputs` — the
   flag was removed in build_runner 2.17), then `dart analyze`.

### Changed (BREAKING — v3.0.0)

- **List patch fields are replaced atomically (#248).** A generated `<Name>Patch`
  now carries a changed `List<E>` field as the whole new list value (a bare JSON
  array on the wire), never as positional index ops (`ListPatchOp` /
  `ListPatchDelta`). Concurrent edits to the same list are therefore an exact
  `/tags` conflict instead of silent index corruption. The `ListPatchDelta` /
  `ListPatchOp` types remain in `zorphy_annotation` for direct use but are no
  longer emitted for entity list fields; the list wire form changes from
  `{'ops': [...]}` to a bare array. Map fields keep their `MapPatchDelta`.
- **Legacy `@Zorphy` / `@Zorphy2` generation path removed (#233).** After the
  v3 migration gate the generator runs only the zero-preset archetype pass
  (`@ZorphyEntity` / `@ZorphyValue` / `@ZorphyUnion` / `@ZorphyState` /
  `@ZorphyIntent`). The legacy orchestrator, the 14 legacy generators, the
  legacy hierarchy emitters and the plugin pipeline are deleted, along with the
  dead legacy analyzer layer (`class_analyzer`, `annotation_parser`,
  `class_graph`, `field_resolver`, `interface_collector`, `generation_config`).
  The production shared-part builder emits only the v3 surface.
- **No generated archetype emits `fromJson` / `toJson` (#188, #233).** The v3
  wire codecs (`fromWire` / `toWire`) are unconditional; the legacy JSON codec
  generation is gone.
- The cross-entity import detector now recognizes every v3 archetype
  annotation, not just the legacy `@Zorphy` / `@Zorphy2`.
- The CLI entity scaffolder emits v3 archetypes (`@ZorphyEntity(principalKey:
  #id)` / `@ZorphyValue()` / `@ZorphyUnion()`) and no longer writes a
  json_serializable `.g.dart` part; `project_validator` scans for the v3
  archetypes.

### Added

- **Three-way merge primitives on every generated patch (#248).**
  `<Name>Patch` now exposes `Set<String> get changedPaths` (the JSON pointers it
  touches, e.g. `{'/price', '/title'}`, with nested edits expanded to the leaf),
  `Set<String> conflictingPaths(other)` (the exact intersection — disjoint edits
  return `{}`, an overlapping scalar or concurrent list replacement returns the
  shared pointer), and `composePatches(next)` (an alias of `compose` with the
  same left-to-right semantics, so three-way sync has one composition behaviour
  under its own name). They live on `PatchBase` in `zorphy_annotation`, so every
  generated patch inherits one implementation.
- `dart run zorphy:migrate_v3 <path>` — a v2 → v3 AST migration codemod
  (#194). It strips every v2 `preset:` and `generate*` boolean argument and
  rewrites the zero-preset archetypes: `@Zorphy` / `@Zorphy2` on an
  `id`-bearing class becomes `@ZorphyEntity(principalKey: #id)`, on an
  `id`-less class `@ZorphyValue()`, and `@ZorphySealed` becomes
  `@ZorphyUnion`. Codec call sites move to the wire codecs —
  `.fromJson(map)` → `.fromWire(map)` (with a `// TODO(trust-boundary): handle
  BoundaryErr` marker) and `.toJson()` → `.toWire()` — but only when the
  receiver is a zorphy-generated type, so unrelated serializers are untouched.
  An `id` inherited from a supertype is recognised; the trust-boundary TODO is
  indented with the call and emitted once per line. Span-based over the
  analyzer parse tree, so only the matched annotation / method spans change;
  dry-run by default, `--apply` rewrites in place.

### Changed

- Patch wire codecs hardened from the #215 review: generated `toWire()` writes
  enum NAMES (so `jsonEncode(toEnvelope())` survives a transport hop),
  `toEnvelope({principalKey: ...})` carries caller-supplied row identity beside
  `ops`, a nested whole-value replacement is wrapped so it is never decoded as
  an edit of the old value, explicit nulls are handled before shape dispatch,
  a `num` field keeps integers, and nested `List<List<T>>` / `Map<K, Map<...>>`
  decoders keep their full type arguments. Generating a patch with a field
  named after an envelope key (`ops`, `patchKind`, `entityType`,
  `principalKey`) is now refused — the bare/envelope dual shape cannot tell
  such a field apart from metadata. A nested class inside a collection that
  arrives as a JSON map still needs the entity's own boundary codec; the
  emitted decoder documents that limitation.

### Added

- Generated patches now carry a trust-boundary codec (#192). Every concrete
  `<Name>Patch` gets `static ZorphyBoundaryResult<X> fromWire(Map<String,
  Object?> raw)` — decoding each field it carries per shape (scalar, enum by
  NAME, `DateTime` from ISO-8601, `PatchNested`, `ListPatchOp` /
  `MapPatchOp` deltas) and collecting `FieldViolation`s at JSON pointers
  instead of throwing, plus `toEnvelope()` rendering
  `{entityType, patchKind, ops}` for the polymorphic transport. A nullable
  field's deliberate `null` decodes as a clear, never as a failed read
  (the guard is the violation count). Polymorphic roots get a dispatching
  `fromWire` keyed on `patchKind` (`shared` vs subtype) that rejects a
  missing/unknown kind and a foreign `entityType`, and rejects any op the
  root patch cannot express rather than silently dropping it.
- Generated `<Name>Patch` classes now patch nested and collection fields
  deeply instead of overwriting them (#183). `diff` carries a
  `PatchNested<Sub, SubPatch>` built from `SubPatch.diff(previous.x, next.x)`
  for a nested `@ZorphyEntity` / `@ZorphyState` field, and a
  `ListPatchDelta<E>` / `MapPatchDelta<K, V>` for a `List<E>` / `Map<K, V>`
  field — granular `ListPatchOp` / `MapPatchOp` steps rather than a
  whole-collection replace. `invert` inverts the value the patch actually
  carried, and `toWire` renders a delta as its `ops` list. A nullable nested
  field treats a null on either side as a whole-value transition, since there
  is no sub-patch to apply. Scalar fields are unchanged.
- `PatchBase` implements `ZorphyPatch<TEntity>`, so a generated
  `<Name>Patch` satisfies the bound a `PatchNested<Sub, SubPatch>` declares
  and supplies `isNotEmpty` as the negation of `isEmpty` (#183).

- Generated `<Name>Patch` classes now carry the v3 patch algebra (#182):
  `static diff(previous, next)` (O(1) and allocation-free when the two are
  `identical`), `apply(target)` (returns `target` itself when the patch is
  empty), `compose(next)` (coalesces bursts left-to-right),
  `invert(before)` (captures prior values for undo), `isEmpty`, and
  `toWire()` (field-name keyed). Emission lives in
  `lib/src/emission/patch_emitter.dart` and is built entirely from
  `package:code_builder` specs — no presets, no toggles, no string assembly.
  The legacy fluent `with*` builders and cross-entity helpers are unchanged.
- `PatchBase` gained a const `PatchBase.empty()` constructor so a generated
  patch can expose `const <Name>Patch.empty()` alongside its mutable default
  constructor (#182).

### Change

- **BREAKING: generated output is now a shared part.** The builder declares
  `adds_to_library: true` and emits one `<library>.part.dart` per library under
  `lib/_br_/`, instead of a `<file>.zorphy.dart` beside every source file.
  `build_runner` inserts the `part` directive itself, so a consumer writes no
  directive for zorphy at all — a project with 71 annotated libraries goes from
  71 generated files to 71 parts in one directory, and `import`/`part` churn in
  diffs disappears. Consumers must delete the 2.x `<file>.zorphy.dart` files
  and drop any hand-written `part '*.zorphy.dart';` line, then run
  `build_runner build`. (`--delete-conflicting-outputs` is no longer that
  cleanup step: build_runner 2.17 removed the flag and only warns about it.)
  This is the breaking change of the major.
- Removed the deprecated `zorphy2Builder` (`lib/builder2.dart`). `builder2`
  had been a no-op alias since 2.0; `zorphy2Builder` now fails loudly instead
  of resolving to nothing.
- `zorphy_annotation` moves to 3.0.0 in lockstep (`check_version_sync.sh`);
  its legacy annotation surface is removed in this major (see Changed above).
- `zorphy_migrator` moves to 3.0.0; its `lean` subcommand is removed and
  `migrate` now emits the v3 archetypes (see its CHANGELOG).

### Fix

- `update<Type>At` no longer emits an always-redundant `as <Type>` cast: the
  receiver is already `List<Type>`, so every consumer used to get an
  `unnecessary_cast` warning. The example project masked this because it
  excludes `lib/_br_/**` from analysis.

## [2.5.0] - 2026-11-16

### Change

- **SDK floor corrected to `>=3.11.0 <4.0.0`** (was `>=3.8.0`). The declared
  dependency set cannot resolve on Dart 3.8–3.10 at all — `analyzer` 14.x,
  `source_gen` 4.3.1, `build` 5.0.0 and `dart_style` 3.1.14 all require
  `^3.11.0` — so 2.4.6 was already unsatisfiable there and the old floor was
  misleading rather than a supported range. Dart 3.11/3.12 consumers resolve
  `analyzer` 14.0.0–14.5.x inside `^14.0.0`; the committed lock keeps 14.7.0
  for development (that single version needs `^3.13.0`).
- `zorphy_migrator` receives the same SDK-floor correction
  (`>=3.8.0` → `>=3.11.0`); its version line is unchanged (2.0.0).
- Third-party dependency constraints are **unchanged** from 2.4.6 — the declared ranges
  already resolve to the latest published versions (analyzer 14.7.0,
  build 5.0.0, source_gen 4.3.1, code_builder 4.13.0, dart_style 3.1.14,
  build_runner 2.17.1). In `zorphy/pubspec.yaml`, `zorphy_annotation` is declared
  as `^2.5.0` (with local development using `pubspec_overrides.yaml`). Only
  `zorphy_migrator/pubspec.lock` moved: its committed lock still named
  `zorphy_annotation` 2.4.5 while the tree is 2.4.6.

### Test

- New release gate `test/release/analyze_clean_gate_test.dart`: generates
  `.zorphy.dart` for one fixture per feature family (plain, `full` preset,
  inheritance, sealed polymorphism, enum fields, plus JSON variants), then
  re-analyzes the output in process with the analyzer version pinned in
  `pubspec.lock` and asserts **zero** diagnostics. Goldens prove the emitted
  bytes did not change; only re-analysis proves the emitted code still
  compiles under the analyzer 14.6+ `undefined_*_read` / `undefined_*_write`
  diagnostics. JSON fixtures are allowed exactly the unresolved
  json_serializable part symbols (`_$XToJson` / `_$XFromJson`), which a
  consumer build generates.
- New `test/release/sdk_floor_alignment_test.dart`,
  `test/release/dependency_constraints_unchanged_test.dart` and
  `test/release/version_sync_test.dart` pin the published contract: the SDK
  floor admits 3.11.0 and rejects 3.10.9, the declared dependency constraints
  equal the 2.4.6 set, and both packages sit at the same version.
- The gate documents arrrrny/zorphy#159 as a characterization test: a sealed
  base with `explicitSubTypes` emits subtype `toJson`/`fromJson` calls even
  with JSON generation off, so that generated part does not compile. Output is
  byte-identical in 2.5.0, so the defect is tracked separately.

## [2.4.6] - 2026-11-15

### Change

- Maintenance release: no generator source changes; Dependabot dependency bumps — `analyzer` (constraint normalized to caret form `^14.0.0`, same `>=14.0.0 <15.0.0` range), `code_builder`, `dart_style`, `glob` (#152–#157)

## [2.4.5] - 2026-11-10

### Fix

- fix #142: generated `$$` bases stay implementable across libraries (cross-library sealed-base rejection resolved by PR #146)
- fix #148: generator no longer hard-casts `List<Map<String, dynamic>>` fields at copyWithField/patch arms (raw JSON payloads no longer TypeError)

## [2.4.4] - 2026-10-20

### Change

- Support `build` 5.x so the latest `build_runner` resolves. `zorphy` pinned `build: ^4.0.4`, but `build_runner` 2.17.1 requires `build >=5.0.0 <5.1.0`, so no consumer could use zorphy together with the current build_runner — pub version solving failed outright. The blocker was zorphy's own `build` constraint, not `source_gen`: `source_gen` 4.3.1 already allows `build >=3.0.2 <6.0.0`. The constraint is now `build: ">=4.0.4 <6.0.0"`, with `source_gen: ^4.3.1` and `analyzer: ">=14.0.0 <15.0.0"` (what `source_gen` 4.3.x requires), and the dev dependency on `build_runner` moves to `^2.17.1`. Verified against build 5.0.0 / build_runner 2.17.1 / source_gen 4.3.1 / analyzer 14.5.0: the generator test suite is green and the emitted code is unchanged (#143)

## [2.4.3] - 2026-09-18

### Fix

- Anchor `copyWithField` to the polymorphic chain root (#140)

### Style

- Format the pipeline test to the CI formatter's fixed point (#140)

## [2.4.2] - 2026-09-18

### Fix

- Publish script now handles two-line path dependencies and strips `dependency_overrides` during release.

### Change

- Published archive slimmed from 9 MB to 223 KB via `.pubignore` (excludes coverage/ and prebuilt MCP binary).

## [2.4.1] - 2026-09-18

### Fix

- Stop source recovery from swallowing sibling factory params (#138)
- Address review comments on #139

### Style

- Format to the stable SDK 3.13.4 formatter's fixed point (#138)

## [2.4.0] - 2026-09-13

### Feat

- Generators: custom decorators on entities are now preserved during code generation, enabling integration with third-party annotation libraries.
- Gym: real exercises framework for zorphy with warmup phases (dependencies, build, smoke tests) and lift-json-payload benchmark.
- Generators: value-equality surface, interface copyWith support, and agent annotations fully integrated into the generation pipeline.

### Fix

- CI: fixed archive prepare-workspace race condition and pub get failures in CI Gate jobs.
- CLI: addressed review comments on entity creation and error handling.

### Chore

- Restored monorepo dependency_overrides with full test suite verification.

### Docs

- Speckit analysis: verified 3/3 mutation testing passing; tdd verification complete.

## [2.3.1] - 2026-08-27

### Fix

- CLI: escape special characters (apostrophes, backslashes, dollar signs) in
  `@JsonKey(name:)` annotations when generating entity code (PR #133).
- Generators: `copyWithField` on child classes with interfaces now uses the
  parent's `Field<Parent, T>` type with `@override` instead of `covariant`,
  keeping LSP-safe polymorphic dispatch via Dart's declaration-site covariance.
- Generators: `copyWithField` on child classes handles ALL fields (parent + own)
  — no need for separate `copyWith{Interface}Field` methods.

## [2.3.0] - 2026-08-23

### Feat

- Generators: value-comparison surface for `autoId` entities (issue
  #127, proposal #2). Every `@Zorphy(autoId: true)` concrete class now
  gets two NEW methods on the generated class:
    - `bool valueEquals(Object other)` — `true` iff `other` is the same
      concrete type AND every field EXCEPT the autoId field (`id`) is
      equal to this instance's. Identity equality (the default
      `==`/`hashCode`) is preserved; `valueEquals` is an additive
      surface for consumers that need value comparison.
    - `Map<String, dynamic> toJsonValue()` — the full `toJson()`
      output with the autoId field (`id`) key removed. Stable across
      two instances with the same field values; use a canonical
      serialized representation (e.g., `toJsonValue().toString()`) or
      an explicit value-key type for deduplication. Emitted only when
      `generateJson: true` (it calls `_$XToJson(this)`).
  Both methods also drop any field listed in `equalityExcludes` (see
  below). The autoId `id` is always dropped by these methods.
- Annotation: field-level equality exclusion via
  `@Zorphy(equalityExcludes: ['id'])` (issue #127, proposal #1).
  Fields listed in `equalityExcludes` are dropped from four generated
  surfaces: `operator ==`, `hashCode`, `toJsonLean()` and
  `compareToX()`. `toJson()` and `toString()` keep every field — the
  entity still round-trips through JSON for persistence and the id
  stays in debug output. Defaults to an empty list (the v2.2.0
  byte-for-byte output is preserved for non-autoId entities and for
  autoId entities that already existed — those now gain the NEW
  `valueEquals()`/`toJsonValue()` methods while their existing
  `==`/`hashCode`/`toJsonLean()`/`compareToX()` behavior is unchanged).
  Field names are matched against the Dart field name (NOT a
  `@JsonKey(name: ...)` alias).
- `zorphy_annotation` bumped to 2.3.0 (new `equalityExcludes` field on
  `@Zorphy` / `@Zorphy2` / `ZorphyX`; backward-compatible — defaults to
  `const []`). `zorphy` depends on `^2.3.0` and uses a
  `dependency_overrides` path to `../zorphy_annotation` for in-tree
  development (matches the `zorphy_migrator` pattern).

### Docs

- Annotation: `Zorphy.autoId` now documents the value-semantics caveat
  (the minted uuid is identity noise — two instances with the same
  field values compare unequal by default) and points to the two
  opt-outs (`equalityExcludes` for full field-level exclusion,
  `valueEquals`/`toJsonValue` for additive value comparison without
  changing identity equality).

### Test

- Add regression test `test/regression/issue_127_value_equality_test.dart`
  (21 assertions) exercising three fixtures in
  `example/lib/various/issue127_value_equality_example.dart`:
    1. `$AutoIdDefault` — back-compat default: `==`/`hashCode`/
       `toJsonLean()`/`compareToX()` still include `id`, and the NEW
       `valueEquals`/`toJsonValue` methods drop it.
    2. `$AutoIdExcludesId` — opt-out: `==`/`hashCode`/`toJsonLean()`/
       `compareToX()` drop `id`; `toJson()` keeps it; `valueEquals`/
       `toJsonValue` also drop it.
    3. `$NonAutoIdExcludesCreatedAt` — non-autoId opt-out: `createdAt`
       is dropped from the four surfaces; no `valueEquals`/`toJsonValue`
       methods (autoId-only surface).
  All assertions pass; full test suite (253 tests) passes; `dart
  analyze` is clean on `zorphy`, `zorphy_annotation`, and `example`.

## [2.2.0] - 2026-08-21

### Refactor

- Generators: extract the cross-entity import guidance detector (issue #117)
  into a public, testable, analyzer-free helper — `CrossEntityImportDetector`
  at `package:zorphy/src/analysis/cross_entity_import_detector.dart`. The
  `ZorphyGenerator` still emits the same guidance comment; the detector is now
  unit-tested directly.

### Test

- Add regression tests for issue #117 (cross-entity `patchWith`/`fromJson` cast
  targets the concrete entity type) and issue #119 (subtype `patchWith` cast
  strips the leading `$`), with `example/lib/various` fixtures.
- Add unit tests for `CrossEntityImportDetector` (pre-filter, self-reference
  skip, missing-import detection, generic type arguments, snake_case
  conversion, and comment/string-literal-safe import scanning).

## [2.1.1] - 2026-08-21

### Feat

- CLI: `--static` flag emits static class members on generated entities
  (closes #107).
- Generators: `Patch` + `FieldEnum` generation for nonSealed abstract base
  classes (closes #111).
- Generators: bare `Function`/`Function?` callback fields on value-object
  entities no longer break json_serializable (closes #105).

## [2.1.0] - 2026-08-21

### Feat

- Polymorphic dispatch: `EntityConfig` gains `typeKey` (default `__typename`)
  and `subtypeWireValue` for custom polymorphic JSON keys/values, and the
  generated `ChangeTo` extension now serializes sealed subtypes via a
  `switch (this)` that calls the correct `toJson()` per subtype (fixes
  malformed polymorphic payloads for explicit-subtype hierarchies).

### Fix

- Generators: strip the leading `$` from `patchWith`/`fromJson` cast types for
  explicit-subtype fields — the generated `as $Credentials?` cast (undefined
  in the consuming file) now resolves to `as Credentials?`
  (fixes arrrrny/zorphy#119).

## [2.0.1] - 2026-08-19

### Fix

- Generators: typed `patchWith` — the generated `_patchMap` ternary chains
  collapse to `dynamic`; patched values are now cast with postfix `as T`
  (valid for nullable types too) instead of invalid prefix `(T)?` casts.
- Generators: `toJsonLean` sanitizes the map in place and returns the typed
  `Map<String, dynamic>` instead of returning the `dynamic` sanitizer result.
- CLI: `ImportResolver` emits relative sibling-entity imports for `!Type`
  (external) fields when the referenced entity exists on disk — cross-entity
  references now generate resolvable code (fixes json_serializable
  `InvalidType` failures).

Generated code from both fixes passes `dart analyze` with zero findings.

## [2.0.0] - 2026-08-16

### Feat

- `autoId` support: a `@Zorphy(autoId: true)` class whose source declares
  `String get id;` gets an optional `String? id` constructor parameter
  defaulting to `const Uuid().v4()` — the generated class is
  constructible without an explicit identity (zuraffa#307). The
  `@ZValueObject` / `ZorphyKind.valueObject` kind is parsed and threaded
  into `GenerationConfig` for framework consumers.
- `EntityConfig`/template: `autoId` and `kind` options — `zfa entity
  create --auto-id` emits the `id` getter, the uuid import and the
  `autoId: true` annotation option; `--kind=value_object` emits
  `kind: ZorphyKind.valueObject`.
- `zorphy_annotation` bumped to 2.2.0 (new `ZorphyKind`, `autoId`,
  `ZValueObject` annotation surface).

## [2.1.0] - 2026-08-03

### Feat

- AST-based smart regeneration engine — non-destructive merge of
  generated output with user edits (region markers, structural diff,
  conflict reporting)
- Plugin API & registry (`ZorphyPlugin`, `PluginContext`,
  `PluginRegistry`) — post-spec transform hooks with topological
  ordering, import injection, and diagnostic accumulation
- `MergeMode` enum (`smart` / `force`) and `isForce` builder/
  generator flag to bypass smart merge
- `ZorphyPlugin` abstract class exported from `zorphy.dart`

### Change

- Version synced with `zorphy_annotation` 2.1.0
- `zorphy_annotation` dependency bumped to `^2.1.0`

## [2.0.0] - 2026-07-30

### Break

- `analyzer` constraint widened to `>=13.0.0 <15.0.0` — consumers on modern Dart toolchains (analyzer 14.x) now resolve without overrides
- `build.yaml` consolidated to a single builder: one generation pass per library (roughly 2x faster consumer builds). The second pass (`zorphy2` builder) no longer exists; `@zorphy2`/`@Zorphy2` keep working as deprecated aliases of `@zorphy`
- Removed process-global static cross-asset state (`_allAnnotatedClasses`) — annotated-class graphs are now built per library, so build_runner caching/invalidation works correctly
- Fieldless explicit subtypes now emit a minimal patch class and identity `patchWith` — `changeTo` extensions reference them (previously produced undefined-method errors)

### Feat

- `ZorphyPreset` (`lean` / `standard` / `full`) plus per-feature `bool?` flags (`generateCopyWith`, `generatePropertyHelpers`, `generateEqualsToString`, `generateChangeTo`, and existing flags now nullable) — `null` inherits from the preset, explicit values override it
- `standard` preset reproduces 1.9.0 output semantics — upgrading with no annotation changes keeps full output (see note on `generateFilter` below)
- `lean` preset emits only class + constructor + copyWith + `==`/hashCode/toString; `full` adds `copyWithFn`
- All flag resolution is centralized in `GenerationConfig`; generators no longer read annotations directly
- CI matrix verifies `dart test` against analyzer 13.x and 14.x

### Note

- The deprecated `const zorphy`/`const zorphy2` top-level constants previously carried `generateFilter: false` (while the class default was `true`); in 2.0 both paths resolve consistently to the `standard` preset (`generateFilter: true`). Affected files gain `Fields` filter descriptors on regeneration. Pin `generateFilter: false` explicitly to opt out.

See MIGRATION-v2.md for the upgrade path.

## [1.9.0] - 2026-07-21

### Breaking

- Replaced inline `_zc`/`ZorphyJsonHelper` safe-cast approach with native `json_serializable` deserialization using `checked: true` — field-level error messages are now provided by `CheckedFromJsonException` from the `json_serializable` package rather than custom `ZorphyJsonCastError`
- Removed `zorphy_annotation` source files: `json_helper.dart` and `json_cast_error.dart` — these are no longer needed; all JSON deserialization is handled by `json_serializable` directly

### Fix

- `Map<K, V>` fields (e.g. `Map<String, String>?`, `Map<String, Entity>?`) now correctly deserialize because `checked: true` + native generation produces recursive `.map((k, e) => MapEntry(k, e as String))` conversions in the `.g.dart` file, resolving runtime `type '_Map<String, dynamic>' is not a subtype of type 'Map<String, String>'` errors

### Chore

- Upgraded `build_runner` to ^2.15.2, `source_gen` to ^4.2.3, `json_annotation` to ^4.12.0
- Removed `dependency_overrides` for `analyzer` and `meta` — packages now resolve coherently against the SDK

### Features preserved from earlier releases (cherry-picked)

- Refined nullable-string property helpers: `text?.isNotEmpty == true` instead of `text != null && text.isNotEmpty`
- Const constructor support for non-sealed abstract classes

## [1.8.10] - 2026-07-21

### Fix

- Replaced deprecated `@JsonKey(ignore: true)` with `@JsonKey(includeToJson: false, includeFromJson: false)` on `hashCode` getter
- `Map<K,V>` fields now use direct `(json['f'] as Map<K,V>?)` cast instead of `ZorphyJsonHelper.cast` to avoid runtime type erasure issues (e.g. `Map<String, dynamic>` vs `Map<String, String>`)

## [1.8.9] - 2026-07-21

### Fix

- Replaced deprecated `@JsonKey(ignore: true)` with `@JsonKey(includeToJson: false, includeFromJson: false)` on `hashCode` getter

## [1.8.8] - 2026-07-21

### Fix

- `hashCode` getter is now annotated with `@JsonKey(ignore: true)` to prevent json_serializable from including it in `toJson` output (regression from `createFactory: false` changes)

## [1.8.7] - 2026-07-21

### Fix

- `List<Object>` and other identity-cast list fields now cast directly to the target type (`as List<Object>?`) instead of going through `List<dynamic>` which isn't assignable in Dart 3
- Fields like `List<Object>? get match` now generate `(json['match'] as List<Object>?)`

## [1.8.6] - 2026-07-20

### Fix

- Reverted `List`/`Set` field casts from `ZorphyJsonHelper.cast<List<dynamic>>` back to `(json['f'] as List<dynamic>)` — generic function return types don't satisfy Dart 3's type system for downstream typed list parameters
- Enum detection now scans analyzer-level type arguments, catching enums that only appear inside generic types like `List<TransformationType>` without a bare `TransformationType` field

## [1.8.5] - 2026-07-20

### Fix

- `List<EnumType>` fields in fromJson now use `$enumDecode(_$EnumTypeEnumMap, e)` for element conversion instead of incorrectly calling `EnumType.fromJson(e as Map<String, dynamic>)`

## [1.8.4] - 2026-07-20

### Fix

- Fields with `@JsonKey(fromJson: someConverter)` but no `includeFromJson: false` now correctly call the converter instead of falling through to `.fromJson()` on the raw type

## [1.8.3] - 2026-07-20

### Fix

- Non-sealed abstract classes with `const` constructors now correctly generate `const ClassName();` instead of `ClassName();`

## [1.8.2] - 2026-07-20

### Refactor

- Simplified nullable string property helpers: `hasText` now uses `text?.isNotEmpty == true` instead of `text != null && text.isNotEmpty`

### Chore

- Removed CI-based pub.dev publishing; publish script now publishes directly via `dart pub publish --force`

## [1.8.1] - 2026-07-20

### Fix

- Replaced per-class `_zc<T>()` static helpers with shared `ZorphyJsonHelper.cast<T>()` from `zorphy_annotation` for Dart 3.12+ compatibility
- Added `ZorphyJsonCastError` with field-level context in error messages

## [1.8.0] - 2026-07-20

### Feature

- Safe fromJson casts with field-level error messages — replaces json_serializable delegates with inline `_zc<T>()` wrapper that throws `TypeError.withStackTrace` including field name, expected type, actual type, and the value itself
- Example error: `Zorphy: Field 'id' expected String, got int (42)`

## [1.7.1] - 2026-05-02

### Change

- updated dependencies

## [1.7.0] - 2026-04-30

### Change

- Upgrade to analyzer 13 and update dependencies

## [1.6.9] - 2026-04-27

### Change

- Revert property helper generation to ownFields and fix automated publishing flow

## [1.6.8] - 2026-04-27

### Change

- Streamline release process and fix PropertyHelpers extension generation for inherited fields

## [1.6.7] - 2026-04-06

### Fix

- Factory method parameter types now preserve import prefixes (`as` clauses) in generated code

## [1.6.6] - 2026-04-05

### Feature

- Extracted Patch class boilerplate into `PatchBase` to drastically reduce generated code size.
- Fixed `toJson()` bug on abstract base classes in explicit subtypes `changeTo` extension.

## [1.6.5] - 2026-04-01

### Change

- Analyzer 12 compabilities

## [1.6.4] - 2026-02-15

### Fix

- Have to upgrade Analyzer package due to bug in 10.0.0

## [1.6.3] - 2026-02-15

###

-

## [1.6.2] - 2026-02-15

### Fix

- works with analyzer 10.0.0 that dont require meta 1.18

## [1.6.1] - 2026-02-15

### Change

- Refactored CLI code to be more robust and consumable

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2026-02-14

### Change

- Update Zorphy CLI to be more extensible and consumable by other CLIs

## [1.5.8] - 2026-02-14

### Fix

- Nonsealed classes with explicit subtypes can have their own fromJson

## [1.5.7] - 2026-02-14

### Fix

- Modified skip logic in `getProperties()` to not skip fields that exist in both parentFields and ownFields (overridden fields)
- Prevents duplicate `@override` annotation when source already has it
- Constructor generation `isParentField` check now excludes fields in ownFields so overridden fields use `this.field` syntax
- Added `_getCovariantFields()` helper to detect fields where class type differs from interface type
- `getInterfaceCopyWithMethods()` now uses class field types (not interface types) for parameters and adds covariant where needed
- `getInterfaceCopyWithFnMethods()` now uses class field types for parameters

## [1.5.6] - 2026-02-14

### Chore

- Updated docs and created docusaurus website
- Create public constructors by default and only create private when hidden

## [1.5.5] - 2026-02-13

### Fix

- Fixed null type issue on custom toJson

## [1.5.4] - 2026-02-13

### Change

- Allow hybrid serialization with json_serializable for generic field types

## [1.5.3] - 2026-02-13

### Fix

- Fixed JsonKey and other annotations not being caught due to Analyzer 10 changes

## [1.5.2] - 2026-02-12

### Fix

- Updated copyWith generation to use a sentinel parameter pattern, preserving non-nullable fields while allowing explicit nulls for nullable fields

## [1.5.1] - 2026-02-11

### Fix

- Fixed issue with nested entity

## [1.5.0] - 2026-02-09

### Feat

- Added property helpers extension

## [1.4.1] - 2026-02-09

### Chore

- Bumped example versions

## [1.4.0] - 2026-02-07

### Feat

- Added [feature description needed]

## [1.3.4] - 2026-02-07

### Fix

- Referencing issues

## [1.3.3] - 2026-02-07

### Fix

- Upgraded dependencies

## [1.3.2] - 2026-02-06

### Fix

- Analyzer compatibility improvements

## [1.3.1] - 2026-02-06

### Fix

- Improved type handling

## [1.3.0] - 2026-02-06

### Changed

- Updated to new Zorphy API

## [1.2.1] - 2026-02-05

### Chore

- Updated test dependency

## [1.2.0] - 2026-02-05

### Chore

- Downgraded analyzer version to match latest Flutter SDK

## [1.1.1] - 2026-02-05

### Fix

- Fixed copyWith method name generation

## [1.1.0] - 2026-02-05

### Change

- Fixed edge case where a class extends a sealed class and implements another class causing parameters not passed in super constructor

## [1.0.0] - 2026-02-04

### Added

- Initial release of zorphy_annotation package
- Core `@Zorphy()` annotation with full configuration support
- `generateJson` option for JSON serialization
- `generateCompareTo` option for diff generation
- `generateCopyWithFn` option for function-based copyWith
- `explicitSubTypes` option for sealed class hierarchies
- Support for generic type parameters
- Support for nested object patching
- Support for self-referencing types
- Support for multiple inheritance via interfaces
- Support for enum fields
- Support for constant constructors
- Full TypeScript-style type safety

### Features

- Immutable data class generation
- Automatic constructor generation
- Smart copyWith methods
- Advanced patching system with fluent API
- JSON serialization with lean JSON option
- Sealed classes with polymorphic serialization
- Multiple inheritance support
- Generic class support
- Enum integration
- Self-referencing type support
- Comparison and diff generation
- Equality and hashCode generation
- ToString generation
- Type-safe field enums

### Documentation

- Comprehensive README with examples
- Quick start guide
- Feature reference
- Real-world usage examples

[Unreleased]: https://github.com/arrrrny/zorphy/compare/v1.6.5...HEAD
[1.5.6]: https://github.com/arrrrny/zorphy/compare/v1.5.5...v1.5.6
[1.6.1]: https://github.com/arrrrny/zorphy/compare/v1.5.6...v1.6.1
[1.6.2]: https://github.com/arrrrny/zorphy/compare/v1.6.1...v1.6.2
[1.6.3]: https://github.com/arrrrny/zorphy/compare/v1.6.2...v1.6.3
[1.6.4]: https://github.com/arrrrny/zorphy/compare/v1.6.3...v1.6.4
[1.6.5]: https://github.com/arrrrny/zorphy/compare/v1.6.4...v1.6.5
[1.5.5]: https://github.com/arrrrny/zorphy/compare/v1.5.4...v1.5.5
[1.5.4]: https://github.com/arrrrny/zorphy/compare/v1.5.3...v1.5.4
[1.5.3]: https://github.com/arrrrny/zorphy/compare/v1.5.2...v1.5.3
[1.5.2]: https://github.com/arrrrny/zorphy/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/arrrrny/zorphy/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/arrrrny/zorphy/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/arrrrny/zorphy/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/arrrrny/zorphy/compare/v1.3.4...v1.4.0
[1.3.4]: https://github.com/arrrrny/zorphy/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/arrrrny/zorphy/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/arrrrny/zorphy/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/arrrrny/zorphy/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/arrrrny/zorphy/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/arrrrny/zorphy/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/arrrrny/zorphy/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/arrrrny/zorphy/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/arrrrny/zorphy/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/arrrrny/zorphy/releases/tag/v1.0.0
