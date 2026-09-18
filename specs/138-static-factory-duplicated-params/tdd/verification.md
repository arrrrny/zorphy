# TDD Verification — Issue #138

- **Date**: 2026-09-17
- **Verdict**: PASS

## Evidence

| Check | Command | Result |
|-------|---------|--------|
| RED (fix stashed) | `git stash push -- lib/src/common/helpers.dart && dart test test/generation/issue_138_static_factory_params_test.dart` | 3 tests fail (duplication reproduces) |
| GREEN (fix applied) | `dart test test/generation/issue_138_static_factory_params_test.dart` | 4/4 pass |
| Recovery unit contract | `dart test test/generation/polymorphic_factory_param_recovery_test.dart` | 3/3 pass (incl. `SubType`, `BaseType?`, multi-param #138 guard) |
| Full regression suite | `dart test` (zorphy/) | 324 passing, 0 failing |
| End-to-end build | `cd example && dart run build_runner build` | 171 outputs; `issue138_zik.zorphy.dart` factories correct (3/2 params, required preserved) |
| Analyzers | `dart analyze` (zorphy/, example/) | No issues |
| Format | `dart format --output=none --set-exit-if-changed <changed files>` | stable at fixed point |

## Acceptance-criteria coverage

1. Later-parameter recovery yields only its own type — pinned by
   `later param of multi-param factory does not swallow siblings (#138)`
   and `recovered parameter types match the source declarations`.
2. Generated factories declare each parameter exactly once, in order,
   with `required` — pinned by the three end-to-end tests driving
   `Orchestrator.generate` on an InvalidType fixture.
3. Pre-existing recovery shapes (`SubType`, `BaseType?`, generic
   `Map<String, int>`) — pinned by the two pre-existing polymorphic
   recovery tests plus the new multi-param expectations.

## Test smells checked

- The regression fixture mirrors the reporter's trigger (concrete types of
  not-yet-generated sibling entities), not a mocked pipeline.
- RED was demonstrated against the real pre-fix code, not asserted.
