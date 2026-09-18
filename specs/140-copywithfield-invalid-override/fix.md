# Bug Fix: copyWithField emits an invalid override in hierarchies deeper than 2 levels

- **Slug**: 140-copywithfield-invalid-override
- **Fixed**: 2026-09-18
- **Assessment**: ./assessment.md
- **Status**: applied
- **TDD artifacts**: ./tdd/test-list.md, ./tdd/cycle-log.md, ./tdd/verification.md
- **Branch**: `fix/140-copywithfield-invalid-override` (off `master` @ `4c827b1`)
- **Issue**: https://github.com/arrrrny/zorphy/issues/140

## Summary

`CopyWithGenerator.generateSpec` typed the `copyWithField` field-selector
parameter with the class's DIRECT parent entity (`allValueTInterfaces.first`),
but the member it overrides is inherited from the ROOT of the `$`-interface
chain. `Field`'s type argument is used covariantly, so for chains ≥ 3 levels
the emitted `Field<Mid, T>` is a subtype of the inherited `Field<Root, T>` —
an invalid override parameter, failing analysis with `invalid_override`. The
fix resolves the chain ROOT (walking the analyzer supertype elements) and
anchors every descendant's parameter to it.

## Changes

| File | Change | Notes |
|------|--------|-------|
| `zorphy/lib/src/generators/copywith_generator.dart` | modified | Replaced the `.first` interface pick with `_resolveInterfaceChainRootName(metadata)`: starts at the class's first `$`-prefixed interface (same chain selection as before), then walks upward through `element.allSupertypes` while the current interface has a `$`-prefixed (non-`$$`) parent inside the collected interface set; the final name (leading `$` stripped) becomes `parentEntityType` |
| `zorphy/test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` | added test | End-to-end pipeline test (resolved element → `Orchestrator.generate`) on the issue's 3-level hierarchy; asserts root/mid/leaf `copyWithField` signatures, `@override` placement, and that the leaf never emits `Field<Listing, T>` |
| `zorphy/test/generation/issue_140_deep_hierarchy_fixture_test.dart` | added test | Golden assertions on the regenerated example fixture (all three levels anchor the root type; leaf switch covers inherited + own fields) |
| `zorphy/example/lib/various/issue_140_listing.dart` | added fixture | `$ListingOffer` ← `$Listing` ← `$TextListing`, the issue's exact shape |

## Diff Highlights

Before — the direct parent was picked, narrowing the inherited parameter for
any chain deeper than 2:

```dart
final firstIface = metadata.allValueTInterfaces.first;
final ifaceName = firstIface.interfaceName;
if (ifaceName.startsWith(r'$') && !ifaceName.startsWith(r'$$')) {
  parentEntityType = ifaceName.substring(1); // strip leading $
}
```

After — the chain root is resolved by walking the analyzer supertype
elements (the collected interface set already contains every ancestor):

```dart
String? _resolveInterfaceChainRootName(ClassMetadata metadata) {
  final byName = {for (final i in metadata.interfaces) i.interfaceName: i};
  bool isChainInterface(String name) =>
      name.startsWith(r'$') &&
      !name.startsWith(r'$$') &&
      byName.containsKey(name);
  // ... start at the first $-interface, walk allSupertypes upward until the
  // current interface has no further $-parent in the set; return its name.
}
```

Generated result for the issue's hierarchy (all levels now consistent):

```dart
ListingOffer copyWithField<T>(Field<ListingOffer, T> field, T value) { ... }
Listing      copyWithField<T>(Field<ListingOffer, T> field, T value) { ... }  // @override
TextListing  copyWithField<T>(Field<ListingOffer, T> field, T value) { ... }  // @override
```

## Tests Added or Updated

- `issue_140_copywithfield_deep_hierarchy_test.dart` — 4 tests; RED before
  the fix (leaf + consistency), GREEN after.
- `issue_140_deep_hierarchy_fixture_test.dart` — 4 golden tests over the
  regenerated example fixture; compile-level RED demonstrated by stashing
  the fix and running `build_runner` + `dart analyze` (2 ×
  `invalid_override`, the issue's exact error), GREEN after rebuilding.

## Local Verification

- `dart test` (zorphy/) → 335 passing, 0 failing.
- `cd example && dart run build_runner build` → 172 outputs; only the new
  fixture's output differs from the pre-fix build — every pre-existing
  generated file is byte-identical (depth ≤ 2 chains resolve to the same
  name as before; deep chains rooted at sealed `$$` classes are excluded by
  the existing filter).
- `dart analyze` clean in `zorphy/` and `example/`; `dart format` stable at
  the fixed point on all changed files.

## Deviations from Assessment

None material. The assessment's proposed remediation (resolve the chain
root, keep per-class redeclaration with `@override`) was implemented as
specified; the alternative (emit only on the root, let children inherit)
remains rejected for the same API-surface reasons recorded there. The walk
uses `metadata.interfaces` (which carries the analyzer elements) instead of
`allValueTInterfaces` (name-only descriptors) — both lists are 1:1 over the
same collection, so chain selection semantics are unchanged.

## Follow-ups

- Generic polymorphic chains (`$Box<T>` → `$NamedBox<T>` → deeper) still
  render the parent name WITHOUT type arguments in `Field<..., T>` —
  pre-existing behavior outside this issue's scope; with root resolution the
  raw root name is used, which for generic chains may still mismatch the
  root's parameterized declaration. Worth a follow-up issue if generic deep
  chains are exercised.
- `assessment.md` left untouched per the guardrail.
