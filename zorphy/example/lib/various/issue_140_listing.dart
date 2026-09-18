import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_140_listing.zorphy.dart';

/// Fixture for issue #140: `copyWithField` emitted an invalid override in
/// hierarchies deeper than 2 levels.
///
/// Pattern:
///   - `$ListingOffer` is the chain root with `id`, `price`.
///   - `$Listing` implements `$ListingOffer` and adds `title`.
///   - `$TextListing` implements `$Listing` and adds `body`.
///
/// The generated `TextListing.copyWithField` must declare
/// `Field<ListingOffer, T>` (the chain ROOT): the member it overrides is
/// inherited from `ListingOffer`, and Dart's covariant class generics make
/// the narrower `Field<Listing, T>` parameter an invalid override — before
/// the fix the generated file failed `dart analyze` with:
///
///   The parameter 'field' of the method 'TextListing.copyWithField' has
///   type 'Field<Listing, T>', which does not match the corresponding type,
///   'Field<ListingOffer, T>', in the overridden method,
///   'ListingOffer.copyWithField'.
@Zorphy()
abstract class $ListingOffer {
  String get id;
  int get price;
}

@Zorphy()
abstract class $Listing implements $ListingOffer {
  String get title;
}

@Zorphy()
abstract class $TextListing implements $Listing {
  String get body;
}
