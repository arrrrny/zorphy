import 'package:test/test.dart';
import 'package:zorphy/src/emission/polymorphic_class_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

void main() {
  test('v3 class emission does not reintroduce amplified v2 helpers', () {
    final node = ZorphyNodeIr(
      className: r'$AmplificationProbe',
      cleanName: 'AmplificationProbe',
      archetype: ArchetypeKind.entity,
      isSealedRoot: false,
      isAbstractIntermediate: false,
      isConcreteLeaf: true,
      superTypes: const [],
      directSubTypes: const [],
      allConcreteLeaves: const [],
      discriminatorKey: 'kind',
      discriminatorValue: 'AmplificationProbe',
      principalKey: 'id',
      isUnion: false,
      root: null,
      fields: const [
        ZorphyFieldIr(name: 'id', type: 'String'),
        ZorphyFieldIr(name: 'name', type: 'String'),
        ZorphyFieldIr(name: 'items', type: 'List<String>'),
      ],
    );

    final source = const PolymorphicClassEmitter().emit(
      root: node,
      fields: {
        r'$AmplificationProbe': [
          PolymorphicField(name: 'id', type: 'String'),
          PolymorphicField(name: 'name', type: 'String'),
          PolymorphicField(name: 'items', type: 'List<String>'),
        ],
      },
    );

    expect(source, isNot(contains('_sanitizeJson')));
    expect(source, isNot(RegExp(r'\bbool\s+get\s+(?:has|no)[A-Z_]')));
    expect(source, isNot(contains('copyWithAmplificationProbe')));
    expect(
      source,
      isNot(RegExp(r'\brequired\s+(?:String|int|bool|double)\s+this\.')),
    );
    expect(source, contains('ZorphyCollections.equals(this.items, other.items)'));
    expect(source, contains('ZorphyCollections.hash(items)'));
    expect(source, isNot(contains('_zorphyCollectionEquals')));
    expect(source, isNot(contains('_zorphyCollectionHash')));
  });
}
