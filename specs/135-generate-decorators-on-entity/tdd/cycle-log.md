# Cycle Log — 135: Preserve custom decorators on generated entities

Append-only evidence. One entry per red-green-refactor cycle. Companion to
`tdd/test-list.md` (the plan). Recorded 2026-09-13.

---

## Cycle 1 — capture + port, abstract and concrete classes (U1–U5, U6–U8, U10, U10b, U11)

**Test-first step.** Wrote `zorphy/test/generation/decorator_preservation_test.dart`
(20 tests) and `zorphy/test/generation/decorator_preservation_e2e_test.dart` (7 tests)
plus fixture `zorphy/example/lib/various/decorator_preservation.dart` BEFORE any
production change.

**RED evidence (commands run, outputs excerpted):**

- `cd zorphy && dart test test/generation/decorator_preservation_test.dart`
  → compile errors, loader failure (`00:00 +0 -1: Some tests failed`):
  - `Error: Method not found: 'extractClassDecorators'` (×12 call sites)
  - `Error: No named parameter with the name 'classDecorators'`
- `cd zorphy/example && dart run build_runner build` (unmodified generator) then
  `cd zorphy && dart test test/generation/decorator_preservation_e2e_test.dart`
  → `00:00 +1 -4: Some tests failed`:
  - `custom decorator @Cacheable was dropped from concrete Task`
  - `generated $Report not found` era failures for Report/Plain assertions
  - artifact inspection: generated `class Task` carried only the hard-coded
    `@JsonSerializable(...)` — no ported decorators anywhere in output.
  - (SC-5 passed trivially pre-change: nothing re-emitted `@Zorphy` yet.)

**GREEN step.** Implemented (smallest change set):

- `lib/src/models/class_metadata.dart`: `classDecorators` optional field
  (default `const []`, `@`-stripped source contract documented).
- `lib/src/common/helpers.dart`: `kGeneratorDirectiveAnnotations`,
  `_annotationName` (constructor-aware, source fallback),
  `extractClassDecorators` (dual-API metadata read, try/catch-safe).
- `lib/src/analysis/class_analyzer.dart`: `ClassMetadata(..., classDecorators:
  common_helpers.extractClassDecorators(classElement))`.
- `lib/src/generators/class_declaration_generator.dart`: decorator emission
  loop in `_buildAbstractClassSpec` and `_buildConcreteClassSpec` (ahead of
  the generator-added `@JsonSerializable`).

**GREEN evidence:**

- `dart test test/generation/decorator_preservation_test.dart`
  → `00:00 +20: All tests passed!`
- `cd zorphy/example && dart run build_runner build` then
  `dart test test/generation/decorator_preservation_e2e_test.dart`
  → `00:00 +7: All tests passed!`
- artifact now shows, verbatim:
  `@Cacheable(ttl: Duration(hours: 1))` / `@JsonSerializable(explicitToJson:
  true, checked: true)` above `class Task {`, and `@Throttle(30, per:
  Duration(seconds: 5))` / `@Audited()` above `class Report {`.

**Refactor:** none needed beyond test-harness corrections (below, cycle 2).

**Mid-cycle corrections (test defects, not behaviour changes):**

- Stale e2e patterns: first e2e draft asserted `abstract class $Task` shapes.
  Artifact inspection proved plain entities emit a single concrete class;
  sealed-base/subtype shapes emit `sealed class Character` / `class Hero`.
  e2e assertions rewritten to the real shapes; sealed hierarchy added to the
  fixture (spec "Assumptions" updated accordingly — cross-artifact drift fix
  from `/speckit.analyze`).
- `List.indexOf` vs prefix matching in order assertions (exact-match indexOf
  returned -1) → replaced with `indexWhere(startsWith)`.
- Stub mechanics: dynamic dispatch enforces the declared `Metadata` return
  type of `Element.metadata`, so stubs return a `_FakeMetadata implements
  Metadata`; enclosing-element fakes implement `InterfaceElement` (the type
  `ConstructorElement.enclosingElement` actually returns); named-constructor
  directives (`@Zorphy.named()`) exposed the need for constructor-aware name
  resolution in `_annotationName` — implemented, then covered by test.

---

## Cycle 2 — toolchain discovery: bare annotations (A-behaviors)

**Discovery during RED:** the example build failed with
`Could not resolve annotation for 'abstract class Report'` raised by
source_gen/build_resolvers for the bare `@Audited` (no parentheses)
annotation — before any generator code runs (bisected: `@Cacheable` ✓,
`@Throttle(...)` ✓, bare `@Audited` ✗, `@Audited()` ✓). Pre-existing
toolchain limitation, out of scope; documented in spec "Assumptions".
Fixture switched to the semantically identical `@Audited()`.

**Double-build stability (US4.2 / SC-5):**

- `dart run build_runner build` (second pass, warm): `192 skipped` — no
  outputs, no cascade classes.
- Cold rebuild (`rm -rf .dart_tool/build` + full rebuild): 163 outputs;
  grep proves zero `$$Task`/`$$Report`/`$$Plain`/`$$Character` and zero
  `$`-abstract classes in the artifact.

---

## Regression + hardening (US5, SC-6)

- `dart analyze` (changed files): `No issues found!`
- `dart analyze` (whole `zorphy` package): `No issues found!`
- Full suite: `cd zorphy && dart test` → `00:18 +317: All tests passed!`
- `dart format` on the 7 touched files → 4 reformatted (test files only);
  suite re-run after formatting: `+27: All tests passed!`
- Dart-test cache hygiene per repo protocol (`rm -rf .dart_tool/test/`).
