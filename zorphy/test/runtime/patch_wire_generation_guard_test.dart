import 'package:test/test.dart';
import 'package:zorphy/src/common/name_type.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

void main() {
  group('reserved envelope field names', () {
    for (final reserved in const [
      'ops',
      'patchKind',
      'entityType',
      'principalKey',
    ]) {
      test('standalone v3 patch refuses a field named $reserved', () {
        expect(
          () => PolymorphicPatchEmitter().emitStandalone(
            name: 'Doc',
            fields: [NameTypeClassComment(reserved, 'String', '')],
          ),
          throwsArgumentError,
        );
      });

      test('polymorphic v3 patch refuses a field named $reserved', () {
        expect(
          () => PolymorphicPatchEmitter().emitRoot(
            rootName: 'Doc',
            fields: [NameTypeClassComment(reserved, 'String', '')],
            subtypeNames: const ['Leaf'],
          ),
          throwsArgumentError,
        );
      });
    }

    test('an ordinary field name is still emitted', () {
      expect(
        PolymorphicPatchEmitter().emitStandalone(
          name: 'Doc',
          fields: [NameTypeClassComment('title', 'String', '')],
        ),
        contains('final class DocPatch implements ZorphyPatch<Doc>'),
      );
    });
  });

  group('nested generic types keep their full argument', () {
    test('a nested map keeps Map<String, Map<String, int>>', () {
      final source = PolymorphicPatchEmitter().emitStandalone(
        name: 'Doc',
        fields: [
          NameTypeClassComment('matrix', 'Map<String, Map<String, int>>', ''),
        ],
      );
      expect(source, contains('PatchValue<Map<String, Map<String, int>>>'));
      expect(source, isNot(contains('PatchValue<Map<String, Object?>>')));
    });

    test('a nested list keeps List<List<int>>', () {
      final source = PolymorphicPatchEmitter().emitStandalone(
        name: 'Doc',
        fields: [NameTypeClassComment('grid', 'List<List<int>>', '')],
      );
      expect(source, contains('PatchValue<List<List<int>>>'));
      expect(source, isNot(contains('PatchValue<List>')));
    });
  });
}
