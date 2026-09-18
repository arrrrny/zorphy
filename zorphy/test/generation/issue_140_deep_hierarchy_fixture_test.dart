// Golden test for issue #140 against the regenerated example fixture
// `example/lib/various/issue_140_listing.zorphy.dart` (CI regenerates it
// with `dart run build_runner build` in zorphy/example before tests run).
//
// The fixture is a three-level polymorphic hierarchy ($ListingOffer ->
// $Listing -> $TextListing). Before the fix the generated file failed
// analysis with `invalid_override`: TextListing.copyWithField declared
// `Field<Listing, T>` (its direct parent) while the member it overrides is
// inherited from the chain root `ListingOffer`, whose copyWithField
// declares `Field<ListingOffer, T>`. Every level must anchor the
// `Field<..., T>` parameter to the chain ROOT.
library test.generation.issue_140_deep_hierarchy_fixture_test;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final fixture = File('example/lib/various/issue_140_listing.zorphy.dart');

  setUpAll(() {
    if (!fixture.existsSync()) {
      fail(
        'Fixture not generated. Run: cd example && '
        'dart run build_runner build --delete-conflicting-outputs',
      );
    }
  });

  group('golden: three-level hierarchy copyWithField', () {
    late String output;

    setUpAll(() {
      output = fixture.readAsStringSync();
    });

    test('root declares copyWithField with its own type', () {
      expect(
        output,
        contains(
          'ListingOffer copyWithField<T>(Field<ListingOffer, T> field, '
          'T value)',
        ),
      );
      expect(output, contains("case 'id':"));
      expect(output, contains("case 'price':"));
    });

    test('mid-level entity anchors the field type to the ROOT', () {
      expect(
        output,
        contains(
          'Listing copyWithField<T>(Field<ListingOffer, T> field, T value)',
        ),
      );
      expect(output, isNot(contains('Field<Listing, T>')));
    });

    test('leaf entity anchors the field type to the ROOT (#140)', () {
      // THE BUG: the leaf narrowed the inherited parameter to its direct
      // parent's type, which is an invalid override under Dart's covariant
      // class generics.
      expect(
        output,
        contains(
          'TextListing copyWithField<T>(Field<ListingOffer, T> field, '
          'T value)',
        ),
      );
      expect(output, isNot(contains('Field<Listing, T>')));
    });

    test('leaf copyWithField handles inherited AND own fields', () {
      final leafDeclStart = output.indexOf('TextListing copyWithField<T>');
      expect(leafDeclStart, greaterThanOrEqualTo(0));
      final window = output.substring(
        leafDeclStart,
        (leafDeclStart + 1200).clamp(0, output.length),
      );
      expect(window, contains("case 'id':"));
      expect(window, contains("case 'price':"));
      expect(window, contains("case 'title':"));
      expect(window, contains("case 'body':"));
    });
  });
}
