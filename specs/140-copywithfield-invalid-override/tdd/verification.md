# TDD Verification — Issue #140

- **Date**: 2026-09-18
- **Verdict**: PASS

## Evidence

| Check | Command | Result |
|-------|---------|--------|
| RED (fix stashed) | `git stash push -- lib/src/generators/copywith_generator.dart && dart test test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` | 2 of 4 tests fail (leaf emits `Field<Listing, T>`) |
| Compile-level RED (fix stashed) | `cd example && dart run build_runner build --delete-conflicting-outputs && dart analyze lib/various/issue_140_listing.zorphy.dart` | 2 × `invalid_override` — the issue's exact error |
| GREEN (fix applied) | `dart test test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` | 4/4 pass |
| GREEN compile proof | `dart run build_runner build --delete-conflicting-outputs && dart analyze lib/various/issue_140_listing.zorphy.dart` | `No issues found!`; all 3 levels emit `Field<ListingOffer, T>` |
| Golden fixture tests | `dart test test/generation/issue_140_deep_hierarchy_fixture_test.dart` | 4/4 pass |
| Full regression suite | `dart test` (zorphy/) | 335 passing, 0 failing |
| Analyzers | `dart analyze` (zorphy/, example/) | No issues |
| Output-preservation check | `git status` after post-fix regeneration of all 172 example outputs | Only the NEW fixture changed; every pre-existing generated file byte-identical |
| Format | `dart format --output=none --set-exit-if-changed <changed files>` | stable at fixed point |

## Acceptance-criteria coverage

1. Root declares `copyWithField` with its own type, no `@override` —
   pinned by `root declares copyWithField with its own type, no override`
   (pipeline) and the golden twin.
2. Every descendant anchors `Field<Root, T>` with `@override` — pinned by
   the mid/leaf tests at both layers; leaf additionally asserts
   `isNot(contains('Field<Listing, T>'))`.
3. Leaf handles inherited AND own fields — pinned by the golden switch-case
   window (`id`, `price`, `title`, `body`).
4. Depth ≤ 2 output unchanged — pinned by the mid-level tests (green before
   and after) plus the output-preservation sweep across all 172 regenerated
   example outputs.

## Test smells checked

- The regression fixtures mirror the issue's exact hierarchy
  (`ListingOffer → Listing → TextListing`), not a hand-mocked spec.
- RED was demonstrated against the real pre-fix code twice: through the
  pipeline (unit) AND at compile level (`dart analyze` on the regenerated
  fixture), not asserted.
- Generated fixture is gitignored like all others; the golden test fails
  with regeneration instructions when absent (CI builds it first), so the
  assertions can never silently skip.
