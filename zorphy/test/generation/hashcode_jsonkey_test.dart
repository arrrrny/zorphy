import 'package:test/test.dart';
import 'package:zorphy/src/helpers.dart' as helpers;
import 'package:zorphy/src/common/NameType.dart';

void main() {
  test('hashCode getter has @JsonKey(ignore: true) annotation', () {
    final fields = [
      NameTypeClassComment('id', 'String', 'Foo'),
      NameTypeClassComment('name', 'String?', 'Foo'),
    ];

    final hashCodeBlock = helpers.getEqualsAndHashCode(fields, 'Foo');

    expect(hashCodeBlock, contains('includeToJson: false, includeFromJson: false'),
        reason: 'hashCode should be annotated with @JsonKey(includeToJson: false, includeFromJson: false) '
            'to prevent json_serializable from serializing it');
    expect(hashCodeBlock, contains('int get hashCode'),
        reason: 'should still generate hashCode');
  });
}
