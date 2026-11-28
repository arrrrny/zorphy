# Chore Assessment: Make example generation explicit before analysis

- **Slug**: example-analysis-prerequisite
- **Created**: 2026-11-28
- **Source**: https://github.com/arrrrny/zorphy/issues/338
- **Verdict**: in scope
- **Size**: small

## Report

A fresh checkout fails package-wide `dart analyze --fatal-infos` from `zorphy/` because the nested `zorphy/example` package declares generated `.zorphy.dart` parts that are intentionally absent until `build_runner` runs. The requested chore is to make that generation prerequisite explicit in the repository's documented setup, or otherwise make fresh-checkout analysis succeed.

## Summary

This is a bounded documentation chore with a structural regression test. It changes no generator behavior, package API, dependency, or generated output.

## Constitution Check

No `.specify/constitution.md` exists. The repository's `AGENTS.md` requires deterministic structural assertions and clean analysis; a README regression test follows that convention. The change does not touch emitter code, generated files, version locks, or release behavior.

## Affected Paths

- `README.md` — the repository-level setup documentation is the natural place to describe the nested example prerequisite before package-wide analysis.
- `zorphy/test/release/issue_338_analysis_prerequisite_test.dart` — pins the documented command order so the prerequisite cannot silently disappear.

## Proposed Approach

**Preferred**: Add a repository-analysis section to the root README that tells contributors to resolve and generate `zorphy/example` before running `dart analyze --fatal-infos` from `zorphy/`. Also document the scoped analysis alternative when example generation is intentionally skipped. Add a release test that reads the README section and asserts generation is documented before package-wide analysis.

**Alternatives**:

- Exclude `example/` from the parent analysis configuration. This avoids the fresh-checkout failure but weakens analysis coverage and does not explain the nested package's setup.
- Commit generated example output. This violates the repository's generated-file policy and still leaves setup implicit.

**Paths likely to change**:

- `README.md`
- `zorphy/test/release/issue_338_analysis_prerequisite_test.dart`
- `.specify/chores/example-analysis-prerequisite/assessment.md`

**Verification to run**:

- Run the new regression test before the README edit and retain the failing evidence.
- Run the same test after the README edit and retain the passing evidence.
- Run formatting, package analysis, and the capped Dart test suite.
- Generate the example and verify its analysis and tests as applicable.

## Risks & Considerations

- Documentation can drift; the structural test prevents the command order from regressing.
- Package-wide analysis still requires example generation by design; the README must distinguish that path from scoped analysis without generation.

## Open Questions

None.
