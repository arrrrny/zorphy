# Bug Verification: Factory constructors emit duplicated parameters (invalid Dart)

- **Slug**: 138-static-factory-duplicated-params
- **Tested**: 2026-09-17
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: verified
- **TDD verification**: ./tdd/verification.md (PASS)

## Summary

The original symptom no longer reproduces: regenerating the issue's entity
shape (static factories whose parameter types are unresolved on a
first-generation build) now emits each parameter exactly once with
`required` preserved, through both the direct `Orchestrator.generate`
pipeline and the real build_runner flow. No regressions: full zorphy test
suite (324 tests) and both package analyzers are green.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (pre-fix) | `cd example && dart run build_runner build` | pass | Corrupted 6/3-param factories reproduced exactly as reported |
| RED (fix stashed) | `git stash push -- lib/src/common/helpers.dart && dart test test/generation/issue_138_static_factory_params_test.dart` | pass | 3 tests fail without the fix |
| Reproduction (post-fix) | `cd example && dart run build_runner build` | pass | `create` has 3 params, `fromUrlSpark` has 2, `required` preserved |
| New / updated tests | `dart test test/generation/issue_138_static_factory_params_test.dart test/generation/polymorphic_factory_param_recovery_test.dart` | pass | 7/7 pass |
| Regression suite | `dart test` (zorphy/) | pass | 324 passing, 0 failing |
| Lint / type-check | `dart analyze` (zorphy/, example/) | pass | No issues |
| Format | `dart format --output=none --set-exit-if-changed` on changed files | pass | Stable at the formatter's fixed point |

## Output Excerpts

Post-fix generated output (example app, first-generation build):

```dart
factory Issue138Zik.create({
  required String url,
  required Issue138UrlEndpoint urlEndpoint,
  Issue138Spark? spark,
}) => $Issue138Zik.create(url: url, urlEndpoint: urlEndpoint, spark: spark);
```

Pre-fix the same constructor declared 6 parameters and failed analysis
with `Error: Duplicated parameter name 'url'.`

## Residual Risks

- Recovery of function-typed parameters (`void Function(int) cb`) now
  yields no match (the walk stops at `(`), so such factories are skipped
  instead of emitted with polluted types — safer, but the factory is
  dropped. Same practical outcome as before the fix (output did not
  compile), tracked as a potential follow-up if a use case appears.
- CI Gate's format job runs `dart format` with the SDK stable resolves at
  run time; the 12 pre-existing files flagged by the local 3.13.3 macOS
  formatter were left untouched (CI's linux run accepted the same content
  on Sep 13). If the gate flags them, it is environmental and unrelated to
  this change.

## Recommendation

Close the bug — verified end-to-end (unit + pipeline + real build_runner)
with the regression tests pinned RED-before/GREEN-after.
