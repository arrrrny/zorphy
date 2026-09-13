# TDD Verification — 135: Preserve custom decorators on generated entities

**Branch**: `feat/135-generate-decorators-on-entity` | **Date**: 2026-09-13 | **Auditor**: cold-context review of artifacts + live command re-runs

## Verdict: PASS

The feature was delivered test-first with recorded red evidence, every
behavior in `tdd/test-list.md` is green against live commands, the suite
kills all three targeted mutants, and the full pre-existing suite passes
with `dart analyze` clean.

## 1. Test-first evidence (git history)

| Commit | Content |
|---|---|
| `48ee4bb` | "WIP: tdd red — failing decorator-preservation tests + e2e fixture (evidence: unit compile errors; e2e +1 -4)" — tests + fixture committed BEFORE the implementation commit |
| `f7cfd8a` | implementation + green runs |

The red commit contains the tests and the fixture but none of the four
production files' feature changes, which is verifiable via
`git show 48ee4bb --stat`.

## 2. Red-phase evidence (excerpted from `tdd/cycle-log.md`)

- Unit: `dart test test/generation/decorator_preservation_test.dart` →
  compile failure (`Method not found: 'extractClassDecorators'`,
  `No named parameter with the name 'classDecorators'`) — tests could not
  even load, the strongest form of red for a new API.
- E2E: build over the unmodified generator produced artifacts without any
  custom decorator; `dart test …e2e…` → `+1 -4` with
  `custom decorator @Cacheable was dropped from concrete Task`.

## 3. Green-phase evidence (live re-runs at audit time)

| Command | Result |
|---|---|
| `dart test test/generation/decorator_preservation_test.dart` | `+23: All tests passed!` |
| `dart test test/generation/decorator_preservation_e2e_test.dart` | `+6: All tests passed!` |
| `cd example && dart run build_runner build` (2nd pass) | `94 skipped, 1 same` — stable, no regeneration |
| `cd example && dart run build_runner build --delete-conflicting-outputs` (cold) | 163 outputs; artifact contains ported decorators, zero directive re-emissions, zero cascade (`$$Task` etc.) classes |
| `dart analyze` (changed files) | `No issues found!` |
| `dart analyze` (package) | `No issues found!` |
| `dart test` (full suite) | `+319: All tests passed!` |
| `dart format --output=none --set-exit-if-changed .` (run without `dart pub get`, as the CI `format` job does) | `0 changed`, exit 0 |
| `dart analyze` in `example/` with `**/*.zorphy.dart` un-excluded | zero errors attributable to `decorator_preservation.*` (was 38) |

## 4. Test-strength audit (mutation spot-check)

Three hand-written mutants, each killed by the suite:

| Mutant | Change | Killed by |
|---|---|---|
| M1 | Remove `Zorphy` from `kGeneratorDirectiveAnnotations` | Unit: 4 failures (`filters Zorphy…`, `returns empty for directive-only…`, …) |
| M2 | Delete concrete-class emission loop | Unit: 6 failures; E2E after rebuild: 5 failures |
| M3 | Delete abstract-class emission loop | Unit: 6 failures (sealed-base shape test among them) |

All mutants were reverted; final state re-verified green (`+20` unit,
analyzer clean).

## 5. Test-smell review

- No sleeps, no ordering dependencies, no shared mutable state between tests.
- Stub-based unit tests are exception-safe by contract (they assert the
  contract: unreadable metadata yields `[]`), and every stub type-checks
  against the real analyzer interfaces (`Metadata`, `InterfaceElement`,
  `ConstructorElement`), so the fakes track the real API surface.
- E2E tests fail loudly with the exact build command when the artifact is
  missing (repo pattern from `issue_109_extends_test.dart`).
- Known limitation (accepted): e2e assertions run against committed-state
  artifacts produced by `build_runner`; a mutated generator is only caught
  by e2e after a rebuild (proven in M2). This matches the repo's existing
  fixture-test architecture.

## 6. Acceptance-criteria coverage

| Criterion (spec.md) | Covered by |
|---|---|
| SC-1 Cacheable ports to the generated class | U2, U4, U5; A1 (e2e concrete `class Task`) |
| SC-2 mixed positional/named/const args verbatim | U6, U7; A5 (e2e `@Throttle(30, per: Duration(seconds: 5))` on `Report`) |
| SC-3 N decorators, every generated shape, source order | U3, U4, U5; A1, A5, A6 (e2e: concrete `Task`/`Report`, sealed base `Character`, subtype `Hero`) |
| SC-4 no-op without decorators | U10, U10b; A3 (e2e decorator-free `Plain`); full suite 319/319 |
| SC-5 no directive re-emission | U3, U9; A2 (e2e); cold-rebuild cascade check |
| SC-6 analyze + suites | both `dart analyze` runs clean; 319/319 + 29 new tests (23 unit, 6 e2e) |

## 7. Remediation tasks

None blocking. Optional follow-ups (out of scope for #135):

1. Investigate the bare-annotation constant-evaluation limitation upstream
   (analyzer/build_resolvers) — affects all source_gen users, not just zorphy.
2. When `@Zorphy` grows a `decorators:` field (see dormant plugin-scoping
   code in `orchestrator.dart`), feed `metadata.classDecorators` into
   `ZorphyPlugin.decoratorNames` scoping so plugins can subscribe to
   specific decorators.
