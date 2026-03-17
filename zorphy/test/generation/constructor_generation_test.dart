import 'package:test/test.dart';
import 'package:zorphy/src/helpers.dart' as helpers;
import 'package:zorphy/src/common/NameType.dart';

void main() {
  group('constructor generation', () {
    test('excludes getter-only overridden fields from constructor', () {
      final fields = <NameTypeClassComment>[
        NameTypeClassComment('id', 'String', 'BarcodeUrlTemplate'),
        NameTypeClassComment(
          'type', 
          'UrlPageType', 
          'BarcodeUrlTemplate',
          isGetterOnly: true,
        ),
        NameTypeClassComment('endpoints', 'List<UrlEndpoint>?', 'BarcodeUrlTemplate'),
      ];

      final code = helpers.getProperties(
        fields, 
        'BarcodeUrlTemplate', 
        false, // isAbstract
        false, // hidePublicConstructor
        true,  // generateCopyWithFn
        true,  // generateJson
        false, // hasConstConstructor
        true,  // hasExtends
        ownFields: {'id', 'type', 'endpoints'},
      );

      // Should contain id and endpoints
      expect(code.contains('required this.id'), isTrue);
      expect(code.contains('this.endpoints'), isTrue);
      
      // Should NOT contain type in constructor parameters
      expect(code.contains('this.type'), isFalse);
      expect(code.contains('required this.type'), isFalse);
      
      // Should NOT contain type field declaration (since it is getterOnly)
      expect(code.contains('final UrlPageType type;'), isFalse);
    });
  });
}
