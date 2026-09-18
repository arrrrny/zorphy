## Summary

`copyWithField` is emitted with the class's **direct** parent entity type, but the member it overrides is inherited from the **root** of the polymorphic chain. Dart class type arguments are covariant, so in any hierarchy ≥ 3 levels the child's parameter type is a *subtype* of the inherited one and the generated file fails to compile:

```
Error: The parameter 'field' of the method 'TextListing.copyWithField' has type
'Field<Listing, T>', which does not match the corresponding type,
'Field<ListingOffer, T>', in the overridden method, 'ListingOffer.copyWithField'.
Change to a supertype of 'Field<ListingOffer, T>', or, for a covariant parameter, a subtype.
```

## Environment

| | |
|---|---|
| zorphy | 2.4.2 (hosted) — also reproducible on 2.4.0 |
| zorphy_annotation | 2.4.2 |
| code_builder | 4.12.0 |
| Dart SDK | 3.13.2 (stable), Flutter 3.47.2, macOS x64 |

## Reproduction

A three-level polymorphic hierarchy:

```dart
abstract class $ListingOffer { /* fields */ }                       // root

abstract class $Listing implements $ListingOffer { /* fields */ }   // level 2

abstract class $TextListing implements $Listing { /* fields */ }    // level 3
```

Regenerating emits:

```dart
class Listing extends ListingOffer {
  ListingOffer copyWithField<T>(Field<ListingOffer, T> field, T value) { ... }  // ok
}

class TextListing extends Listing implements ListingOffer {
  TextListing copyWithField<T>(Field<Listing, T> field, T value) { ... }        // ERROR
}
```

`ListingOffer` is the root, so every descendant must accept `Field<ListingOffer, T>` (or wider). `Field<Listing, T>` is narrower, so the override is invalid.

In our project this single hierarchy (`ListingOffer` → `Listing` → `TextListing` / `BarcodeListing` / `UrlListing` / `GoogleShoppingListing` / `BulkListing` / `BundleListing`) breaks **6 entities** and the whole app fails `Target kernel_snapshot_program`.

## Root cause

`lib/src/generators/copywith_generator.dart` (function `generateSpec`, ~lines 93–100):

```dart
String? parentEntityType;
if (metadata.allValueTInterfaces.isNotEmpty) {
  final firstIface = metadata.allValueTInterfaces.first;
  final ifaceName = firstIface.interfaceName;
  if (ifaceName.startsWith(r'$') && !ifaceName.startsWith(r'$$')) {
    parentEntityType = ifaceName.substring(1); // strip leading $
  }
}
```

It takes **`.first`** of the class's `$` interfaces. For `TextListing` that is `$Listing`, so the emitted parameter is `Field<Listing, T>`. But the member being overridden is inherited from the chain root (`ListingOffer`, whose own `copyWithField` uses `Field<ListingOffer, T>`).

Because `Field`'s type argument is used covariantly (Dart class generics are covariant), `Field<Listing, T> <: Field<ListingOffer, T>` — a child may only narrow the *return* type, never a *parameter* type. The two-level case (`Listing` itself) works only because its parent *is* the root, making the parameter identical.

The comment at lines 132–136 already states the intended design — child classes inherit `copyWithField` from the parent — but the generator still emits one per class.

## Suggested fix

Resolve the **root** of the interface chain instead of `.first`: walk `allValueTInterfaces`/`allAnnotatedClasses` from the class upward until an entry declares no further `$` parent, and use that name for every descendant. Alternatively, emit `copyWithField` only on the root entity and let children inherit it (which is what the removed "4b. Interface-scoped copyWithField" block already documents).

Both are behaviour-preserving for the two-level case, which currently works.

## Notes

- `copyWithField` is emitted unconditionally (issue #131); there is no annotation flag to turn it off, so affected projects cannot work around it in their own code.
- Related but distinct from #138 (the duplicated-parameter emission), which 2.4.2 fixed — that one is confirmed resolved in 2.4.2.

