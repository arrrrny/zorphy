# Bug Fix: Factory constructors emit duplicated parameters (invalid Dart)

- **Slug**: 138-static-factory-duplicated-params
- **Fixed**: 2026-09-17
- **Assessment**: ./assessment.md
- **Status**: applied
- **TDD artifacts**: ./tdd/test-list.md, ./tdd/cycle-log.md, ./tdd/verification.md
- **Branch**: `fix/138-static-factory-duplicated-params` (off `master` @ `de4e4e3`)
- **Issue**: https://github.com/arrrrny/zorphy/issues/138

## Summary

The growing-prefix parameter duplication in generated factory constructors
was not an emission bug: the InvalidType source-recovery path
(`helpers.recoverTypeFromSource`, executable-anchored parameter branch)
captured a later parameter's "type" with a regex class that admits commas
and newlines, swallowing every preceding sibling parameter. The factory
spec kept one entry per parameter NAME (which is why the #129 dedup and
the reporter's spec instrumentation looked clean) — but each polluted type
text emitted extra `Type name,` fragments. The fix anchors recovery to the
enclosing executable, locates the parameter name, and walks backwards to
collect only the immediately-preceding type token.

## Changes

| File | Change | Notes |
|------|--------|-------|
| `zorphy/lib/src/common/helpers.dart` | modified | Parameter branch of `recoverTypeFromSource`: replaced `([\w<>,?.\s]+?)` lazy capture with anchor + backward token walk; added `_collectTypeTokenBefore` |
| `zorphy/test/generation/issue_138_static_factory_params_test.dart` | added test | End-to-end: resolved element → `Orchestrator.generate` on an InvalidType fixture mirroring the issue; asserts each factory parameter appears exactly once, in order, `required` preserved, and recovered types match the source |
| `zorphy/test/generation/polymorphic_factory_param_recovery_test.dart` | added test | Unit guard: later param of a multi-param factory recovers only its own type (`UrlEndpoint`, `Spark?`, `String`); helper parameterized by source/class |
| `zorphy/example/lib/various/issue138_spark.dart` | added fixture | Sibling entities (`$Issue138Spark`, `$Issue138UrlSpark`) |
| `zorphy/example/lib/various/issue138_endpoint.dart` | added fixture | Sibling entity (`$Issue138UrlEndpoint`) |
| `zorphy/example/lib/various/issue138_zik.dart` | added fixture | The issue's entity shape: factory params reference concrete sibling names (InvalidType on first generation), multi-line bodies |

## Diff Highlights

Before — recovering `urlEndpoint` from
`create({required String url, required UrlEndpoint urlEndpoint, ...})`
captured every preceding sibling:

```
params=(String url, String url,\n     UrlEndpoint urlEndpoint, String url,\n     UrlEndpoint urlEndpoint,\n    Spark? spark)
```

After — the backward walk stops at the top-level parameter separator:

```
params=(String url, UrlEndpoint urlEndpoint, Spark? spark)
```

```dart
final anchorPattern = execName.isNotEmpty
    ? RegExp('\\b' + RegExp.escape(execName) + r'\b\s*\(')
    : null;
final anchorMatch = anchorPattern?.firstMatch(commentFreeSource);
final searchStart = anchorMatch == null ? 0 : anchorMatch.end;
final nameMatch = RegExp('\\b' + RegExp.escape(entityName) + r'\b')
    .firstMatch(commentFreeSource.substring(searchStart));
if (nameMatch != null) {
  final rawType = _collectTypeTokenBefore(commentFreeSource,
      searchStart + nameMatch.start);
  ...
}
```

`_collectTypeTokenBefore` walks backwards from the name, stopping at
top-level `,` and `(`/`)`/`{`/`}`/`=`/`;`, and admitting whitespace/commas
only inside `<...>` so `Map<String, int>` is recovered whole.

## Tests Added or Updated

- `issue_138_static_factory_params_test.dart` — 4 tests driving the real
  pipeline on the issue's exact trigger; RED before the fix (verified by
  stashing it), GREEN after.
- `polymorphic_factory_param_recovery_test.dart::later param of
  multi-param factory does not swallow siblings (#138)` — pins
  `UrlEndpoint` / `Spark?` / `String` recovery in a multi-param factory;
  keeps the two pre-existing expectations (`SubType`, `BaseType?`) green.

## Local Verification

- `dart test` (zorphy/) → 324 passing, 0 failing.
- `cd example && dart run build_runner build` → 171 outputs; regenerated
  `issue138_zik.zorphy.dart` declares `create` with exactly
  `url`, `urlEndpoint`, `spark` and `fromUrlSpark` with
  `spark`, `urlEndpoint`; `dart analyze` clean in `zorphy/` and `example/`.
- Also verified not-a-code_builder-version issue: rebuild with a
  `code_builder: 4.12.0` override reproduced/behaved identically
  (experiment reverted).

## Deviations from Assessment

The assessment's leading hypotheses (shared spec instances across
constructors; a list rebuilt during emission; code_builder caching) were
wrong — the reporter's instrumentation was consistent with them, but the
deep dump showed the pollution already present in
`metadata.factoryMethods`. The defect is in the source-recovery regex,
upstream of the emitter; the "corruption is introduced in the emission
step" claim in the issue title is an artifact of instrumenting parameter
NAMES (correct) instead of parameter TYPES (polluted). Recorded here per
the guardrail; `assessment.md` left untouched.

## Follow-ups

- The same capture-class pattern exists in the getter/field recovery
  branches (`getterPattern` / `fieldPattern`); fields reach recovery less
  often (analyzer display strings usually suffice), but they could swallow
  sibling declarations the same way. Worth a follow-up issue.
- `lib/src/merge/` is dead code (confirmed in the issue) — delete
  separately.
