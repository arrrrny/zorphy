# TDD Cycle Log — Issue #138

## Cycle 1 — reproduce through the real pipeline

- Built the issue's entity shape in the example app
  (`issue138_spark.dart`, `issue138_endpoint.dart`,
  `issue138_zik.dart`): factory parameters reference the CONCRETE names of
  sibling entities, which do not exist on a first-generation build.
- `dart run build_runner build` (code_builder 4.11.1, the locked version)
  reproduced the corruption exactly:
  `factory Issue138Zik.create` got 6 parameters (growing prefixes of the
  real 3) and `fromUrlSpark` got 3 (real 2), with the synthesized
  `$Issue138Zik.create(...)` delegation body.
- Earlier hypotheses ruled out empirically:
  - code_builder 4.12.0 vs 4.11.1 — rebuilt with a 4.12.0 override; same
    correct output for shapes that resolve; same corruption for shapes
    that don't. Not a code_builder regression.
  - `FactoryMethodGenerator._buildFactoryConstructor` / `_mergeMembersIntoClass`
    / `ZorphyEmitter` specs — instrumented `ZorphyEmitter.emit` and dumped
    the frozen `Constructor` specs from `library.body`: all correct
    (3/2 params, correct names), yet raw emission polluted. (Matches the
    reporter's instrumentation.)
- Deep dump of `metadata.factoryMethods` revealed the truth: the
  parameter list was polluted BEFORE generation —
  `urlEndpoint`'s recovered type was
  `String url,\n     Issue138UrlEndpoint` — the "emission corruption"
  was the emitter faithfully printing polluted type text.

## Cycle 2 — root cause + fix

- Root cause: `helpers.recoverTypeFromSource` (executable-anchored
  parameter branch) captured the type with `([\w<>,?.\s]+?)` — a class
  admitting commas and newlines — so the lazy match swallowed every
  preceding sibling parameter between `(` and the target name.
- RED: with the fix stashed, the new regression tests fail
  (3 failing tests: both "exactly once" tests + recovered-type test).
- GREEN: replaced the regex capture with a boundary-aware backward walk
  (`_collectTypeTokenBefore`): anchor at the enclosing executable's `(`,
  locate the first `\bname\b`, walk backwards, stop at top-level `,`
  (parameter separator) and structural characters, admit whitespace and
  commas only inside `<...>` so `Map<String, int>` stays whole.
- All 4 tests in `issue_138_static_factory_params_test.dart` pass;
  all 3 recovery unit tests pass (incl. the two pre-existing
  polymorphic-recovery expectations `SubType`, `BaseType?`).

## Cycle 3 — no-regression sweep

- Full `dart test` in `zorphy/`: 324 passing, 0 failing
  (after generating the example-app fixtures the E2E tests consume).
- Full `dart run build_runner build` in `example/`: 171 outputs,
  regenerated `issue138_zik.zorphy.dart` now correct; `dart analyze`
  clean in `zorphy/`, `example/`.
- `dart format` at fixed point on all changed files.
