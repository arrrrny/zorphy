import 'package:test/test.dart';
import 'package:zorphy/src/helpers.dart' as helpers;
import 'package:zorphy/src/common/NameType.dart';

void main() {
  group('copyWith generation', () {
    test('uses sentinel parameters and casts to field type', () {
      final fields = <NameTypeClassComment>[
        NameTypeClassComment('name', 'String', ''),
        NameTypeClassComment('age', 'int', ''),
        NameTypeClassComment('email', 'String?', ''),
      ];

      final code = helpers.getCopyWith(fields, 'User', false);

      expect(code.contains('Object? name = _copyWithSentinel'), isTrue);
      expect(code.contains('Object? age = _copyWithSentinel'), isTrue);
      expect(code.contains('Object? email = _copyWithSentinel'), isTrue);

      expect(
        code.contains(
          "name: identical(name, _copyWithSentinel) ? this.name : name as String,",
        ),
        isTrue,
      );
      expect(
        code.contains(
          "age: identical(age, _copyWithSentinel) ? this.age : age as int,",
        ),
        isTrue,
      );
      expect(
        code.contains(
          "email: identical(email, _copyWithSentinel) ? this.email : email as String?,",
        ),
        isTrue,
      );
    });
  });
}
