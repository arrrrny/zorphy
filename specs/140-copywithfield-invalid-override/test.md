# Bug Verification: copyWithField emits an invalid override in hierarchies deeper than 2 levels

- **Slug**: 140-copywithfield-invalid-override
- **Tested**: 2026-09-18
- **Assessment**: ./assessment.md
- **Fix**: ./fix.md
- **Result**: verified
- **TDD verification**: ./tdd/verification.md (PASS)

## Summary

The original symptom no longer reproduces: regenerating the issue's
three-level hierarchy (`$ListingOffer` → `$Listing` → `$TextListing`) emits
`Field<ListingOffer, T>` (the chain root) on every level, and the generated
fixture passes `dart analyze` — pre-fix it failed with exactly the issue's
`invalid_override` errors. No regressions: full zorphy test suite (335
tests), both package analyzers, and the all-outputs-regenerated comparison
(byte-identical outside the new fixture) are green.

## Checks Performed

| Check | Command / Action | Result | Notes |
|-------|------------------|--------|-------|
| Reproduction (pre-fix, pipeline) | `dart test test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` (fix stashed) | pass | Leaf emitted `Field<Listing, T>` — the narrowed parameter |
| Reproduction (pre-fix, compile) | `cd example && dart run build_runner build && dart analyze lib/various/issue_140_listing.zorphy.dart` (fix stashed) | pass | 2 × `invalid_override`, matching the issue's error text |
| Reproduction (post-fix, compile) | same regeneration + analyze with the fix | pass | `No issues found!` |
| New tests | `dart test test/generation/issue_140_copywithfield_deep_hierarchy_test.dart test/generation/issue_140_deep_hierarchy_fixture_test.dart` | pass | 8/8 pass |
| Regression suite | `dart test` (zorphy/) | pass | 335 passing, 0 failing (incl. #131 copyWithField + #138 factory suites) |
| Output preservation | post-fix `build_runner` rebuild of all 172 example outputs, `git status` | pass | Only the NEW fixture differs; all pre-existing generated files byte-identical |
| Lint / type-check | `dart analyze` (zorphy/, example/) | pass | No issues |
| Format | `dart format --output=none --set-exit-if-changed` on changed files | pass | Stable at the formatter's fixed point |

## Output Excerpts

Post-fix generated output for the issue's hierarchy:

```dart
ListingOffer copyWithField<T>(Field<ListingOffer, T> field, T value) { ... }
Listing copyWithField<T>(Field<ListingOffer, T> field, T value) { ... }      // @override
TextListing copyWithField<T>(Field<ListingOffer, T> field, T value) { ... }  // @override
```

Pre-fix the leaf declared `Field<Listing, T>` and `dart analyze` reported:

```
error - 'TextListing.copyWithField' ('TextListing Function<T>(Field<Listing, T>, T)')
isn't a valid override of 'ListingOffer.copyWithField'
('ListingOffer Function<T>(Field<ListingOffer, T>, T)'). - invalid_override
```

## Residual Risks

- Generic deep chains (`$Box<T>` → deeper) keep the pre-existing raw-name
  rendering of the `Field<..., T>` entity type; root resolution does not add
  type arguments (unchanged from the direct-parent behavior). See the
  follow-up note in `fix.md`.
- CI Gate's format job resolves the SDK formatter at run time; all changed
  files are at the local 3.13.x fixed point, the same standard as the merged
  #138 change.

## Recommendation

Close the bug — verified end-to-end (pipeline + golden + compile-level
analyze, RED-before/GREEN-after) with no output drift for unaffected
entities.
