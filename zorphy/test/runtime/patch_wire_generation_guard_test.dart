// Generation-time guard for #215: a field named after an envelope key would
// make a bare `toWire()` map indistinguishable from an envelope, so both
// emitters refuse it instead of shipping a silently ambiguous codec.

import 'package:test/test.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/patch_emitter.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

void main() {
  group('reserved envelope field names', () {
    for (final reserved in const [
      'ops',
      'patchKind',
      'entityType',
      'principalKey',
    ]) {
      test('PatchEmitter refuses a field named $reserved', () {
        expect(
          () => const PatchEmitter().emit(
            className: 'Doc',
            fields: [NameTypeClassComment(reserved, 'String', '')],
          ),
          throwsArgumentError,
        );
      });

      test('PolymorphicPatchEmitter refuses a field named $reserved', () {
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
        const PatchEmitter().emit(
          className: 'Doc',
          fields: [NameTypeClassComment('title', 'String', '')],
        ),
        contains('class DocPatch'),
      );
    });
  });

  group('nested generic types keep their full argument', () {
    test('a nested map keeps Map<String, int> as its value type', () {
      final source = const PatchEmitter().emit(
        className: 'Doc',
        fields: [
          NameTypeClassComment('matrix', 'Map<String, Map<String, int>>', ''),
        ],
      );
      expect(source, contains('mapDelta<String, Map<String, int>>'));
      expect(source, contains('final out = <String, int>{}'));
      expect(source, isNot(contains('mapDelta<String, Object?>')));
    });

    test('a nested list decodes a typed list, not a bare as<List>', () {
      final source = const PatchEmitter().emit(
        className: 'Doc',
        fields: [NameTypeClassComment('grid', 'List<List<int>>', '')],
      );
      expect(source, contains('listValue<List<int>>'));
      expect(source, contains('final out = <int>[]'));
      expect(source, isNot(contains('listValue<List>')));
    });
  });
}
