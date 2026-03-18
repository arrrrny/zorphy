import 'package:test/test.dart';
import 'package:zorphy/src/helpers.dart' as helpers;
import 'package:zorphy/src/common/NameType.dart';

void main() {
  group('getter with default value', () {
    test('includes getter-only field in constructor if it has a defaultValue', () {
      final fields = <NameTypeClassComment>[
        NameTypeClassComment(
          'timeout', 
          'Duration', 
          'MyClass',
          isGetterOnly: true,
          jsonKeyInfo: const JsonKeyInfo(defaultValue: 'Duration(seconds: 5)'),
        ),
      ];

      final code = helpers.getProperties(
        fields, 
        'MyClass', 
        false, // isAbstract
        false, // hidePublicConstructor
        true,  // generateCopyWithFn
        true,  // generateJson
        false, // hasConstConstructor
        false, // hasExtends
        ownFields: {'timeout'},
      );

      // Should contain a final field for timeout since it has a default value
      expect(code.contains('final Duration timeout;'), isTrue);

      // Should contain timeout in constructor parameters as optional
      // Since it has a default value, it's NOT 'this.timeout' but 'Duration? timeout'
      // WAIT, if it's a field-backed getter now, it SHOULD use 'this.timeout'
      // But the logic for defaultValue in getProperties uses:
      // var paramType = isNullable ? fieldType : "$fieldType?";
      // sb.writeln("    ${paramType} ${f.name},");
      // AND initializers.add("this.${f.name} = ${f.name} ?? ${defaultValueString}");
      
      expect(code.contains('Duration? timeout'), isTrue);
      expect(code.contains('this.timeout = timeout ?? const Duration(seconds: 5)'), isTrue);
    });
  });
}
