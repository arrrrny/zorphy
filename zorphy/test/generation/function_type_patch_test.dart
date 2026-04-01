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

    final patchClass = helpers.getPatchClass(
      fields,
      'ValidationRule',
      [],
    );

    print('Generated Patch Class:');
    print(patchClass);

    // Check for the problematic pattern
    expect(patchClass, isNot(contains('bool Function(Object)Patch')));
    expect(patchClass, isNot(contains('bool Function(Object)Patch()')));
  });
}
