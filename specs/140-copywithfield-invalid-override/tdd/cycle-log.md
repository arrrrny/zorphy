# TDD Cycle Log — Issue #140

## Cycle 1 — reproduce through the real pipeline

- Built the issue's exact hierarchy in an in-process fixture
  (`issue_140_copywithfield_deep_hierarchy_test.dart`):
  `$ListingOffer` (root) ← `$Listing` ← `$TextListing`, each level
  `implements` the previous one.
- Drove the REAL pipeline (resolved ClassElement → ClassAnalyzer →
  `Orchestrator.generate`) per level.
- RED: with the pre-fix generator, 2 of 4 tests fail — the leaf emitted
  `TextListing copyWithField<T>(Field<Listing, T> field, T value)`
  (direct parent), and the all-levels consistency test failed with it.
  The root and mid-level tests were green (2-level case works because the
  direct parent IS the root there), exactly matching the issue's report.

## Cycle 2 — root cause + fix

- Root cause: `CopyWithGenerator.generateSpec` picked
  `metadata.allValueTInterfaces.first` — the DIRECT parent — as the
  `Field<..., T>` entity type of `copyWithField`. `InterfaceCollector`
  populates that list recursively (direct parent first, ancestors later),
  so the chain root is present but `.first` never reaches it for depth ≥ 3.
  Since `Field`'s type argument is used covariantly, `Field<Mid, T>` is a
  SUBTYPE of the inherited `Field<Root, T>` — an invalid override
  parameter (overriding parameter types must be supertypes).
- GREEN: replaced `.first` with `_resolveInterfaceChainRootName` — start
  at the class's first `$`-prefixed interface (same chain selection as
  before), then walk upward through the analyzer supertype elements while
  the current interface has a `$`-prefixed (non-`$$`) parent inside the
  collected interface set; the final name is the root. Sealed (`$$`) roots
  stay excluded, matching the existing interface-scoped rules.
- All 4 in-process tests pass. Depth ≤ 2 chains resolve to the same name
  as before (direct child of root ⇒ root), so their output is unchanged.

## Cycle 3 — compile-level proof + no-regression sweep

- Added the permanent example fixture
  (`example/lib/various/issue_140_listing.dart`, three levels mirroring
  the issue).
- Compile-level RED: with the fix stashed,
  `dart run build_runner build` (example) regenerated the fixture and
  `dart analyze` reported exactly the issue's errors —
  `TextListing.copyWithField ('... Field<Listing, T> ...')` isn't a valid
  override of `Listing.copyWithField` / `ListingOffer.copyWithField`
  (2 × `invalid_override`).
- GREEN: with the fix restored and rebuilt, `dart analyze` on the fixture
  reports `No issues found!`; all three generated `copyWithField`
  declarations anchor `Field<ListingOffer, T>`.
- No other generated file changed between the pre-fix and post-fix builds
  (`git status`: only the new fixture + the generator) — the regression
  bar (byte-identical output for unaffected entities) holds.
- Full `dart test` in `zorphy/`: 335 passing, 0 failing (includes the 8
  new #140 tests and the #131/#138 regression suites).
- `dart analyze` clean in `zorphy/` and `example/`;
  `dart format` at the fixed point on all changed files.
