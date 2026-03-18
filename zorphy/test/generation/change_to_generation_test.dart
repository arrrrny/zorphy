import 'package:test/test.dart';
import 'package:zorphy/src/helpers.dart' as helpers;
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/classes.dart';

void main() {
  group('changeTo extension generation', () {
    test('requires field in changeTo if it is non-nullable in target but nullable in source', () {
      // Source class: Listing with nullable barcode
      final sourceFields = <NameTypeClassComment>[
        NameTypeClassComment('id', 'String', 'Listing'),
        NameTypeClassComment('barcode', 'String?', 'Listing'),
      ];
      
      // Target class: BarcodeListing with required barcode
      final targetFields = <NameType>[
        NameType('id', 'String'),
        NameType('barcode', 'String'), // Non-nullable here
      ];
      
      final explicitSubTypes = [
        Interface('BarcodeListing', [], [], targetFields, true)
      ];
      
      final code = helpers.getChangeToExtension(
        sourceFields: sourceFields,
        sourceClassName: 'Listing',
        explicitSubTypes: explicitSubTypes,
        knownClasses: [],
      );
      
      // The bug: barcode should be required in changeToBarcodeListing
      // because it is non-nullable in BarcodeListing but nullable in Listing.
      expect(code, contains('required String barcode'));
    });

    test('retains field in changeTo if it is non-nullable in both source and target (optional override)', () {
      final sourceFields = <NameTypeClassComment>[
        NameTypeClassComment('id', 'String', 'Listing'),
      ];
      
      final targetFields = <NameType>[
        NameType('id', 'String'),
        NameType('type', 'String'),
      ];
      
      final explicitSubTypes = [
        Interface('TypedListing', [], [], targetFields, true)
      ];
      
      final code = helpers.getChangeToExtension(
        sourceFields: sourceFields,
        sourceClassName: 'Listing',
        explicitSubTypes: explicitSubTypes,
        knownClasses: [],
      );
      
      // 'id' is in both and non-nullable. 
      // Current logic says if it's in both, it's NOT in params UNLESS it's nullable in target.
      // UPDATE: We now allow override even if non-nullable in both.
      // After fix for "too eager" issue, it should be 'String? id' even if it's 'String' in both.
      expect(code, contains('String? id')); 
      expect(code, contains('required String type'));
      
      // Verify the generated code: it should use the value from 'this' if not patched
      expect(code, contains(r': (this as dynamic).id'));
    });

    test('makes field optional in changeTo if it is nullable in target', () {
      final sourceFields = <NameTypeClassComment>[
        NameTypeClassComment('id', 'String', 'Listing'),
      ];
      
      final targetFields = <NameType>[
        NameType('id', 'String'),
        NameType('name', 'String?'),
      ];
      
      final explicitSubTypes = [
        Interface('NamedListing', [], [], targetFields, true)
      ];
      
      final code = helpers.getChangeToExtension(
        sourceFields: sourceFields,
        sourceClassName: 'Listing',
        explicitSubTypes: explicitSubTypes,
        knownClasses: [],
      );
      
      expect(code, contains('String? name'));
      expect(code, isNot(contains('required String? name')));
    });
  });
}
