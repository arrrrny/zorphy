import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

void main() {
  group('v3 archetype annotations (issue #176)', () {
    test('ZorphyEntity defaults to the `kind` discriminator', () {
      const entity = ZorphyEntity();
      expect(entity.discriminator, 'kind');
      expect(entity.principalKey, isNull);
      expect(entity.explicitSubTypes, isEmpty);
    });

    test('ZorphyEntity carries a principal key and explicit subtypes', () {
      const entity = ZorphyEntity(
        principalKey: #id,
        discriminator: 'type',
        explicitSubTypes: [String, int],
      );
      expect(entity.principalKey, #id);
      expect(entity.discriminator, 'type');
      expect(entity.explicitSubTypes, [String, int]);
    });

    test('ZorphyState / ZorphyValue / ZorphyUnion default discriminator', () {
      expect(const ZorphyState().discriminator, 'kind');
      expect(const ZorphyValue().discriminator, 'kind');
      expect(const ZorphyUnion().discriminator, 'kind');
      expect(const ZorphyState().explicitSubTypes, isEmpty);
      expect(const ZorphyValue().explicitSubTypes, isEmpty);
    });

    test('ZorphyIntent requires replaySafe — no default', () {
      const intent = ZorphyIntent(replaySafe: true);
      expect(intent.replaySafe, isTrue);
      expect(intent.discriminator, 'kind');
      expect(intent.explicitSubTypes, isEmpty);
    });

    test('ZorphyMock is a field-level seed hint only', () {
      const mock = ZorphyMock(preset: 'email', example: 'a@b.c');
      expect(mock.preset, 'email');
      expect(mock.example, 'a@b.c');
      expect(const ZorphyMock().preset, isNull);
      expect(const ZorphyMock().example, isNull);
    });

    test('archetype bases are implemented by the matching classes', () {
      const entity = ZorphyEntity();
      const state = ZorphyState();
      const union = ZorphyUnion();
      const intent = ZorphyIntent(replaySafe: false);
      const value = ZorphyValue();

      expect(entity, isA<ZorphyEntityBase<Symbol?>>());
      expect(entity, isA<ZorphyPolymorphicBase>());
      expect(state, isA<ZorphyStateBase>());
      expect(state, isA<ZorphyPolymorphicBase>());
      expect(union, isA<ZorphyUnionBase>());
      expect(union, isA<ZorphyPolymorphicBase>());
      expect(intent, isA<ZorphyIntentBase>());
      expect(intent, isA<ZorphyPolymorphicBase>());
      expect(value, isA<ZorphyValueBase>());
      expect(value, isA<ZorphyPolymorphicBase>());
    });

    test('no archetype carries a codegen toggle flag', () {
      final archetypes = <String, Object>{
        'ZorphyEntity': const ZorphyEntity(),
        'ZorphyState': const ZorphyState(),
        'ZorphyUnion': const ZorphyUnion(),
        'ZorphyIntent': const ZorphyIntent(replaySafe: true),
        'ZorphyValue': const ZorphyValue(),
        'ZorphyMock': const ZorphyMock(),
      };
      for (final name in archetypes.keys) {
        expect(
          archetypes[name].toString(),
          isNot(contains('generate')),
          reason: '$name must not carry a codegen toggle',
        );
      }
    });
  });
}
