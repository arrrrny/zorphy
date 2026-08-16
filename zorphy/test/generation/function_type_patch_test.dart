import 'package:test/test.dart';
import 'package:zorphy/src/helpers.dart' as helpers;
import 'package:zorphy/src/common/NameType.dart';

void main() {
  test('Patch generation should handle function types correctly', () {
    final fields = [
      NameTypeClassComment(
        'customValidator',
        'bool Function(Object)?',
        '',
        isGetterOnly: true,
      ),
    ];

    final patchClass = helpers.getPatchClass(fields, 'ValidationRule', []);

    print('Generated Patch Class:');
    print(patchClass);

    // Check for the problematic pattern
    expect(patchClass, isNot(contains('bool Function(Object)Patch')));
    expect(patchClass, isNot(contains('bool Function(Object)Patch()')));
  });

  test(
    'Patch.applyTo calls patchWithX positionally, not via named patchInput',
    () {
      final patchClass = helpers.getPatchClass(
        [NameTypeClassComment('name', 'String', '')],
        'User',
        [],
      );

      // applyTo must forward the entity positionally to match the
      // positional [X? patchInput] signature emitted by patch_generator.
      // Regression guard for the named-vs-positional mismatch fixed in #59/#66.
      expect(patchClass, contains('return entity.patchWithUser(this);'));
      expect(patchClass, isNot(contains('patchInput: this')));
    },
  );
}
