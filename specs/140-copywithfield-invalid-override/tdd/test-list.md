# TDD Test List — Issue #140

Bug: `copyWithField` is emitted with the class's DIRECT parent entity type,
but the member it overrides is inherited from the ROOT of the polymorphic
`$`-interface chain. In hierarchies ≥ 3 levels the child's parameter type
(`Field<Mid, T>`) is a subtype of the inherited one (`Field<Root, T>`) and
the generated file fails analysis with `invalid_override`.

## Behavior to pin (acceptance criteria)

1. The chain ROOT declares `copyWithField` with its own type
   (`Field<Root, T>`) and no `@override`.
2. Every descendant (mid-level and leaf) declares `copyWithField` with the
   ROOT's type (`Field<Root, T>`) and `@override` — never its direct
   parent's type when that differs from the root.
3. The leaf's `copyWithField` still handles inherited AND own fields
   (the switch covers all settable fields).
4. Depth ≤ 2 chains are unaffected: for a direct child of the root the
   resolved root IS the direct parent, so output is byte-identical.

## Tests

| Test | File | Status before fix |
|------|------|-------------------|
| root declares copyWithField with its own type, no override | `zorphy/test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` | green (pins root shape) |
| mid-level entity copies with the ROOT field type | `zorphy/test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` | green (2-level case already worked) |
| leaf entity copies with the ROOT field type, not its parent (#140) | `zorphy/test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` | RED (`Field<Listing, T>`) |
| deep chain stays consistent: all levels declare the same field type | `zorphy/test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` | RED |
| root declares copyWithField with its own type (golden) | `zorphy/test/generation/issue_140_deep_hierarchy_fixture_test.dart` | green |
| mid-level entity anchors the field type to the ROOT (golden) | `zorphy/test/generation/issue_140_deep_hierarchy_fixture_test.dart` | green |
| leaf entity anchors the field type to the ROOT (golden) | `zorphy/test/generation/issue_140_deep_hierarchy_fixture_test.dart` | RED (fixture had `Field<Listing, T>` at line 364) |
| leaf copyWithField handles inherited AND own fields (golden) | `zorphy/test/generation/issue_140_deep_hierarchy_fixture_test.dart` | green |
| build_runner end-to-end on `example/lib/various/issue_140_listing.dart` | manual/CI smoke | RED (`dart analyze`: 2 × `invalid_override`, exactly the issue's error) |
