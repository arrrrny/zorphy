import 'package:test/test.dart';
import 'package:zorphy/src/helpers.dart' as helpers;
import 'package:zorphy/src/common/NameType.dart';

void main() {
  group('copyWith generation', () {
    test('uses typed params for non-nullable and sentinel for nullable', () {
      final fields = <NameTypeClassComment>[
        NameTypeClassComment('name', 'String', ''),
        NameTypeClassComment('age', 'int', ''),
        NameTypeClassComment('email', 'String?', ''),
      ];

      final code = helpers.getCopyWith(fields, 'User', false);

      expect(code.contains('String? name'), isTrue);
      expect(code.contains('int? age'), isTrue);
      expect(code.contains('Object? email = _copyWithSentinel'), isTrue);

      expect(
        code.contains(
          "name: name ?? this.name,",
        ),
        isTrue,
      );
      expect(
        code.contains(
          "age: age ?? this.age,",
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
