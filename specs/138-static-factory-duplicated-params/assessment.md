# Bug Assessment: Factory constructors emit duplicated parameters (invalid Dart)

- **Slug**: 138-static-factory-duplicated-params
- **Created**: 2026-09-17
- **Source**: https://github.com/arrrrny/zorphy/issues/138
- **Verdict**: likely valid, needs reproduction (in-repo fixture)
- **Severity**: critical — generated code does not compile for any entity with a `static` factory method

## Report (verbatim or summarized)

Reporter regenerates an entity whose `@Zorphy` abstract base declares `static` factory
methods (`Zik.create`, `Zik.fromUrlSpark`). The generated `factory Zik.create({...})`
contains `N(N+1)/2` parameters instead of `N` — the list of growing prefixes of the real
parameter list concatenated (`[p1] ++ [p1,p2] ++ ... ++ [p1..pN]`) — producing
`Error: Duplicated parameter name 'url'.` and breaking compilation of 141 generated
files in the consuming project. See `issue.md` for the full reproduction and
instrumentation evidence. Reporter's instrumentation shows the `Constructor` spec is
correct going into the `Library`, and the corruption is already present in the raw
`library.accept(DartEmitter())` output before `dart_style` formatting.

## Symptom

Generated `factory X.y(...)` constructors for user-declared `static` factories on the
`@Zorphy` abstract base contain repeated parameter names (growing-prefix duplication),
so the generated `.zorphy.dart` files fail analysis with
`Error: Duplicated parameter name '<p>'.`

## Reproduction

1. Declare `@Zorphy(generateJson: true) abstract class $Zik` with fields
   (`id`, `spark`, `url`, `urlEndpoint`) and two `static Zik ...(...)` factories whose
   parameter names overlap the field names (`url`, `urlEndpoint`).
2. Run `dart run build_runner build` (or `Orchestrator.generate` on the resolved
   element).
3. Inspect `zik.zorphy.dart`: `factory Zik.create` has 6 parameters instead of 3;
   `factory Zik.fromUrlSpark` has 3 instead of 2.

## Suspected Code Paths

- `zorphy/lib/src/generators/factory_method_generator.dart` — `_buildFactoryConstructor`
  builds the `Constructor` spec (reporter instrumented: produces correct params).
- `zorphy/lib/src/orchestrator.dart` — `_emitViaSpecPipeline` / `_mergeMembersIntoClass`
  (reporter instrumented: final class spec correct).
- `zorphy/lib/src/emission/emitter.dart` — `ZorphyEmitter.emit` wraps
  `library.accept(DartEmitter())`; corruption visible in raw output here.
- code_builder `DartEmitter` (`visitConstructor` / `_visitParameter`) — iterates each
  parameter exactly once and does not mutate specs, so pure code_builder 4.11.1 emission
  of an immutable spec cannot duplicate parameters on its own.

## Root Cause Hypothesis

To be confirmed by in-repo reproduction. Leading hypotheses (from the issue):

1. Shared `Parameter`/`TypeReference` spec instances between a class's constructors,
   combined with code_builder caching of built specs.
2. A spec list being rebuilt/appended to while `DartEmitter` walks it, producing
   `[p1] ++ [p1,p2] ++ ... ++ [p1..pN]`.

The growing-prefix shape with partial `required`-keyword decay suggests the same
`Parameter` specs are emitted multiple times in a state-dependent way. An in-repo
fixture must pin down which layer mutates or duplicates.

## Proposed Remediation

1. Reproduce with a minimal in-repo test: abstract `@Zorphy` entity with `static`
   factory → run the real pipeline → assert emitted factory constructors declare each
   parameter exactly once.
2. Fix at whichever layer the reproduction exposes (spec sharing in zorphy's generators,
   or a defensive dedup/normalization before emission).
3. Keep `#129` dedup behavior intact; do not touch the dead `lib/src/merge/` subsystem
   (tracked separately).

## Risks & Considerations

- Any entity with a static factory currently generates uncompilable code — high blast
  radius, but the fix must not change output for entities WITHOUT static factories
  (byte-identical generated output is the regression bar).
- code_builder 4.11.1 is locked via `pubspec.lock` (constraint `^4.10.0`); a fix must
  work against the locked version, not only 4.12.0 from the reporter's environment.

## Tests to add or update

- `zorphy/test/generation/issue_138_static_factory_params_test.dart` — end-to-end
  (resolved element → `Orchestrator.generate`) asserting:
  - `factory <Name>.create` declares each parameter exactly once, in source order,
    with `required` preserved.
  - Multiple static factories each keep their own parameter set.
  - Delegating bodies compile against the declared parameters (parameter names unique).

## Open Questions

- Resolved during fix: exact layer where duplication is introduced (see `fix.md`).
