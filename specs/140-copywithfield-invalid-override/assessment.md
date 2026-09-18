# Bug Assessment: copyWithField emits an invalid override in hierarchies deeper than 2 levels

- **Slug**: 140-copywithfield-invalid-override
- **Created**: 2026-09-18
- **Source**: https://github.com/arrrrny/zorphy/issues/140
- **Verdict**: likely valid, needs reproduction (in-repo fixture)
- **Severity**: critical — generated code does not compile for any entity 3+ levels
  deep in a polymorphic `$`-interface chain

## Report (summarized; see issue.md for verbatim)

`copyWithField` is emitted with the class's **direct** parent entity type, but the
member it overrides is inherited from the **root** of the polymorphic chain. Dart
class type arguments are covariant, so in any hierarchy ≥ 3 levels the child's
parameter type is a *subtype* of the inherited one and the generated file fails to
compile:

```
Error: The parameter 'field' of the method 'TextListing.copyWithField' has type
'Field<Listing, T>', which does not match the corresponding type,
'Field<ListingOffer, T>', in the overridden method, 'ListingOffer.copyWithField'.
```

Environment: zorphy 2.4.2 (hosted, also reproducible on 2.4.0), code_builder 4.12.0,
Dart 3.13.2. A single `ListingOffer → Listing → TextListing/...` chain breaks 6
entities in the reporter's app and fails `Target kernel_snapshot_program`.

## Symptom

For a `$`-interface chain of depth ≥ 3 (`$Root` → `$Mid` → `$Leaf`), the generated
concrete `Mid.copyWithField` declares `Field<Root, T>` (valid: its direct parent IS
the root), but `Leaf.copyWithField` declares `Field<Mid, T>` — a *narrower*
parameter type than the inherited `Field<Root, T>`. Overriding parameter types must
be supertypes (contravariance); since `Field`'s type argument is covariant,
`Field<Mid, T> <: Field<Root, T>` and the override is invalid — the generated
`.zorphy.dart` fails analysis/compilation.

## Reproduction

1. Declare a three-level polymorphic hierarchy:
   `abstract class $ListingOffer` (root), `$Listing implements $ListingOffer`,
   `$TextListing implements $Listing`.
2. Run the real pipeline (`dart run build_runner build`, or resolved element →
   `Orchestrator.generate`).
3. Inspect `ListingText`'s generated `copyWithField`: parameter is
   `Field<Listing, T>` (direct parent) instead of `Field<ListingOffer, T>` (chain
   root). `dart analyze` reports the invalid-override error above.

## Suspected Code Paths

- `zorphy/lib/src/generators/copywith_generator.dart`, `generateSpec` (~lines
  93–100): picks `metadata.allValueTInterfaces.first` as the "parent entity type"
  for the `Field<..., T>` parameter of `copyWithField` and passes it as
  `parentEntityType` into `_buildCopyWithFieldMethod`.
- `InterfaceCollector.collect` recursively gathers ALL chain ancestors into
  `allValueTInterfaces` (direct parent first, root later), so the root is present in
  the list — `.first` just selects the shallowest one.

## Root Cause Hypothesis

`generateSpec` assumes the first `$`-interface of a class is the declaring owner of
the `copyWithField` member it overrides. That only holds for depth ≤ 2 (the direct
parent IS the root). For depth ≥ 3 the overridden member is inherited from the
chain root, so the parameter must be typed `Field<Root, T>`; emitting
`Field<Mid, T>` narrows an overriding parameter type — invalid under Dart's
covariant class generics. The design comment at lines 132–136 ("child classes
inherit copyWithField from the parent") already describes the intended single-member
chain; the emitted type must anchor to that chain root.

## Proposed Remediation

Resolve the **root** of the `$`-interface chain instead of `.first`: starting from
the class's first `$`-interface (same chain selection as today), walk upward
through the analyzer supertype elements while the current interface itself has a
`$`-prefixed (non-`$$`) parent that is part of the collected interface set; use the
final name as `parentEntityType` for every descendant.

- Depth ≤ 2 chains are unaffected (the direct parent is already the root) — the
  regression bar is byte-identical output for those entities.
- Sealed `$$` roots stay excluded (existing filter), matching today's behavior.
- Alternative rejected for this fix: emitting `copyWithField` only on the root and
  letting children inherit — larger API-surface change; the root-typed override
  keeps each class's member declared, consistent with the current design.

## Risks & Considerations

- Any entity ≥ 3 levels deep currently generates uncompilable code — high blast
  radius, but the fix must not change output for depth ≤ 2 chains (byte-identical
  generated output is the regression bar). Existing example fixtures with deep
  chains are rooted at sealed `$$` classes (excluded by the existing `$$` filter),
  so they must not change.
- Generic hierarchies (`$Box<T>` → `$NamedBox<T>` → deeper) type the parameter with
  the bare parent name today (no type arguments) — pre-existing behavior outside
  this issue's scope; root resolution must not alter how type arguments are (not)
  rendered.

## Tests to add or update

- `zorphy/test/generation/issue_140_copywithfield_deep_hierarchy_test.dart` —
  end-to-end (resolved element → `Orchestrator.generate`) on a three-level
  hierarchy asserting:
  - Root (`ListingOffer`) declares `copyWithField` with `Field<ListingOffer, T>`
    and no `@override`.
  - Mid (`Listing`) and Leaf (`TextListing`) both declare `Field<ListingOffer, T>`
    (root type) with `@override`; Leaf must NOT emit `Field<Listing, T>`.
- `zorphy/example/lib/various/issue_140_listing.dart` — permanent fixture mirroring
  the issue's hierarchy, regenerated into `.zorphy.dart`; golden assertions in the
  same test file + `dart analyze example` must pass (compile-level proof).

## Open Questions

- Resolved during fix: none blocking; exact walk mechanics recorded in `fix.md`.
