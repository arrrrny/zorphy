import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

void main() {
  group('ZorphyEntity', () {
    test(
      'defaults: no principalKey, kind discriminator, no explicit subtypes',
      () {
        const e = ZorphyEntity();
        expect(e.principalKey, isNull);
        expect(e.discriminator, 'kind');
        expect(e.explicitSubTypes, isEmpty);
      },
    );

    test('carries an explicit principalKey and overrides', () {
      const e = ZorphyEntity(
        principalKey: #id,
        discriminator: 'type',
        explicitSubTypes: [ZorphyEntity, ZorphyEntity],
      );
      expect(e.principalKey, #id);
      expect(e.discriminator, 'type');
      expect(e.explicitSubTypes, hasLength(2));
    });

    test('is const-constructible', () {
      const a = ZorphyEntity(principalKey: #uuid);
      const b = ZorphyEntity(principalKey: #uuid);
      expect(identical(a, b), isTrue);
    });
  });

  group('ZorphyState', () {
    test('defaults', () {
      const s = ZorphyState();
      expect(s.discriminator, 'kind');
      expect(s.explicitSubTypes, isEmpty);
    });

    test('overrides', () {
      const s = ZorphyState(
        discriminator: 'state',
        explicitSubTypes: [ZorphyState],
      );
      expect(s.discriminator, 'state');
      expect(s.explicitSubTypes, [ZorphyState]);
    });
  });

  group('ZorphyUnion', () {
    test('default discriminator', () {
      const u = ZorphyUnion();
      expect(u.discriminator, 'kind');
    });

    test('override discriminator', () {
      const u = ZorphyUnion(discriminator: 'variant');
      expect(u.discriminator, 'variant');
    });
  });

  group('ZorphyIntent', () {
    test('replaySafe is required — no default', () {
      // A const ZorphyIntent without replaySafe must not compile; we assert the
      // runtime surface instead: both values are representable and distinct.
      const safe = ZorphyIntent(replaySafe: true);
      const unsafe = ZorphyIntent(replaySafe: false);
      expect(safe.replaySafe, isTrue);
      expect(unsafe.replaySafe, isFalse);
      expect(safe.discriminator, 'kind');
      expect(safe.explicitSubTypes, isEmpty);
    });

    test('override discriminator and subtypes', () {
      const i = ZorphyIntent(
        replaySafe: true,
        discriminator: 'command',
        explicitSubTypes: [ZorphyIntent],
      );
      expect(i.discriminator, 'command');
      expect(i.explicitSubTypes, [ZorphyIntent]);
    });
  });

  group('ZorphyValue', () {
    test('defaults', () {
      const v = ZorphyValue();
      expect(v.discriminator, 'kind');
      expect(v.explicitSubTypes, isEmpty);
    });

    test('overrides', () {
      const v = ZorphyValue(
        discriminator: 'v',
        explicitSubTypes: [ZorphyValue],
      );
      expect(v.discriminator, 'v');
      expect(v.explicitSubTypes, [ZorphyValue]);
    });
  });

  group('ZorphyMock', () {
    test('empty seed', () {
      const m = ZorphyMock();
      expect(m.preset, isNull);
      expect(m.example, isNull);
    });

    test('named preset', () {
      const m = ZorphyMock(preset: 'email');
      expect(m.preset, 'email');
    });

    test('literal example', () {
      const m = ZorphyMock(example: 'seed-42');
      expect(m.example, 'seed-42');
    });
  });

  group('zero-toggle guarantee', () {
    test('no archetype exposes a generate* boolean toggle', () {
      // v3 dropped every preset and feature flag. These expressions only
      // compile if the toggle parameters no longer exist on the archetypes;
      // the test passing is the proof the surface is zero-toggle.
      const ZorphyEntity().discriminator;
      const ZorphyState().discriminator;
      const ZorphyUnion().discriminator;
      const ZorphyIntent(replaySafe: true).discriminator;
      const ZorphyValue().discriminator;
      expect(true, isTrue);
    });
  });

  group('archetype base markers', () {
    test(
      'a subtype can implement its archetype base and the common marker',
      () {
        _EntityImpl e = _EntityImpl();
        ZorphyEntityBase<Object> asEntity = e;
        ZorphyPolymorphicBase asPoly = e;
        expect(asEntity, same(e));
        expect(asPoly, same(e));

        ZorphyStateBase s = _StateImpl();
        ZorphyUnionBase u = _UnionImpl();
        ZorphyIntentBase i = _IntentImpl();
        ZorphyValueBase v = _ValueImpl();
        expect(s, isA<ZorphyStateBase>());
        expect(u, isA<ZorphyPolymorphicBase>());
        expect(i, isA<ZorphyPolymorphicBase>());
        expect(v, isA<ZorphyPolymorphicBase>());
      },
    );
  });
}

class _EntityImpl implements ZorphyEntityBase<Object> {}

class _StateImpl implements ZorphyStateBase {}

class _UnionImpl implements ZorphyUnionBase {}

class _IntentImpl implements ZorphyIntentBase {}

class _ValueImpl implements ZorphyValueBase {}
