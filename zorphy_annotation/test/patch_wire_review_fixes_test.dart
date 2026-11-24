// Direct tests for the #215 review findings on the wire primitives.
//
// The end-to-end round trips live in `zorphy/test/runtime`; these pin the
// helper contracts in isolation so a regression names the primitive that
// broke rather than a generated class.

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

void main() {
  group('ZorphyPatchWire — review findings #215', () {
    test('a valid ISO string and a DateTime both decode', () {
      final violations = <FieldViolation>[];
      expect(
        ZorphyPatchWire.asDateTime(
          '2026-11-22T10:00:00.000Z',
          '/readAt',
          violations,
        ),
        isA<DateTime>(),
      );
      final parsed = ZorphyPatchWire.asDateTime(
        DateTime(2020, 1, 2),
        '/readAt',
        violations,
      );
      expect(parsed, DateTime(2020, 1, 2));
      expect(violations, isEmpty);
    });

    test('an out-of-range calendar component is a violation', () {
      for (final corrupt in const [
        '2020-01-42',
        '2020-13-01',
        '2020-02-30T10:00:00Z',
        '2020-01-01T25:00:00Z',
        '2020-01-01T10:60:00Z',
        '2020-01-01T10:00:60Z',
        '2020-00-10',
        '2020-01-00',
      ]) {
        final violations = <FieldViolation>[];
        expect(
          ZorphyPatchWire.asDateTime(corrupt, '/readAt', violations),
          isNull,
          reason: '$corrupt must not be normalized into a different date',
        );
        expect(violations.map((v) => v.path), contains('/readAt'));
      }
    });

    test('asNum keeps a large int while asDouble converts', () {
      const value = 9007199254740993;
      final violations = <FieldViolation>[];
      expect(ZorphyPatchWire.asNum(value, '/n', violations), value);
      expect(ZorphyPatchWire.asDouble(value, '/d', violations), isA<double>());
      expect(violations, isEmpty);
    });

    test('pointerToken escapes ~ and / per RFC 6901', () {
      expect(ZorphyPatchWire.pointerToken('a/b'), 'a~1b');
      expect(ZorphyPatchWire.pointerToken('a~b'), 'a~0b');
      expect(ZorphyPatchWire.pointerToken('~1'), '~01');
    });

    test('a successful null element is preserved in a raw list', () {
      final violations = <FieldViolation>[];
      bool decode(Object? value, String path, List<FieldViolation> v) {
        if (value == null) return true;
        if (value is String) return true;
        v.add(
          FieldViolation(path: path, expected: 'String?', actual: '$value'),
        );
        return false;
      }

      final delta = ZorphyPatchWire.listDelta<String?>(
        const ['a', null],
        '/tags',
        violations,
        (value, path, v) {
          final ok = decode(value, path, v);
          return ok ? value as String? : null;
        },
      );

      expect(violations, isEmpty);
      expect(delta, isNotNull);
      expect(delta!.apply(const <String?>[]), <String?>['a', null]);
    });

    test('a null map value in a put survives the decode', () {
      final violations = <FieldViolation>[];
      final delta = ZorphyPatchWire.mapDelta<String, String?>(
        const [
          {'op': 'put', 'key': 'k', 'value': null},
        ],
        '/scores',
        violations,
        decodeKey: ZorphyPatchWire.stringKey,
        decodeValue: (value, path, v) {
          if (value == null) return null;
          return ZorphyPatchWire.as<String>(value, path, v);
        },
      );

      expect(violations, isEmpty);
      expect(delta, isNotNull);
      expect(delta!.apply(const {}), {'k': null});
    });

    test('a missing required member is a named violation', () {
      final violations = <FieldViolation>[];
      expect(
        ZorphyPatchWire.requireMember(
          const {'op': 'set'},
          'value',
          '/note',
          violations,
        ),
        isFalse,
      );
      expect(violations.single.path, '/note/value');
    });

    test('PatchWireSet unwraps a deliberate clear without a violation', () {
      final violations = <FieldViolation>[];
      expect(
        ZorphyPatchWire.fieldValue(
          const PatchWireSet(null),
          '/note',
          violations,
        ),
        isNull,
      );
      expect(violations, isEmpty);
    });

    test('a literal map with an op key is never unwrapped', () {
      final violations = <FieldViolation>[];
      final value = ZorphyPatchWire.fieldValue(
        const {'op': 7},
        '/scores',
        violations,
      );
      expect(value, {'op': 7});
      expect(violations, isEmpty);
    });

    test('the envelope names are reserved for envelope use', () {
      expect(
        ZorphyPatchWire.reservedEnvelopeKeys,
        containsAll(['entityType', 'patchKind', 'ops', 'principalKey']),
      );
    });
  });
}
