// Runtime patch wire codec tests on the v3-generated fixture.
//
// PatchProbePatch in `test/runtime/fixtures/patch_contract.dart` carries scalar
// changes, atomic list/map replacements, and whole nested values. Its bare ops
// map and standalone envelope decode through the same boundary result.
//
// The fixture has no polymorphic hierarchy or calendar fields, so this suite
// retains the applicable scalar/enum, malformed-input, envelope, and in-memory
// nested round-trip laws rather than v2 fixture-specific dispatch.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';

import 'fixtures/patch_contract.dart';

PatchProbe _base() => const PatchProbe(
  id: 'p1',
  title: 'ada',
  tags: ['a'],
  scores: {'a': 1},
  counts: {1: 1},
  status: PatchProbeStatus.active,
  address: ProbeAddress(street: 'Main', city: 'Springfield'),
);

void _expectViolation(
  ZorphyBoundaryResult<PatchProbePatch> result,
  String path,
) {
  expect(result.isOk, isFalse);
  final error = result as BoundaryErr<PatchProbePatch>;
  expect(error.violations.map((violation) => violation.path), contains(path));
}

void main() {
  group('v3 concrete patch fromWire', () {
    test('scalar changes survive a JSON wire round-trip', () {
      final patch = PatchProbePatch().withId('p2').withTitle('grace');
      final transported = jsonDecode(jsonEncode(patch.toWire())) as Map;
      final result = PatchProbePatch.fromWire(
        Map<String, Object?>.from(transported),
      );

      expect(result.isOk, isTrue);
      final decoded = result.getOrThrow();
      expect(decoded.toWire(), patch.toWire());
      expect(decoded.apply(_base()), patch.apply(_base()));
    });

    test('an enum survives a JSON wire round-trip by its name', () {
      final patch = PatchProbePatch().withStatus(PatchProbeStatus.paused);
      final transported = jsonDecode(jsonEncode(patch.toWire())) as Map;
      final decoded = PatchProbePatch.fromWire(
        Map<String, Object?>.from(transported),
      ).getOrThrow();

      expect(transported['status'], 'paused');
      expect(decoded.apply(_base()).status, PatchProbeStatus.paused);
    });

    test('an absent key leaves the field unchanged', () {
      final base = _base();
      final decoded = PatchProbePatch.fromWire(const {}).getOrThrow();
      expect(decoded.isEmpty, isTrue);
      expect(identical(decoded.apply(base), base), isTrue);
    });

    test('an explicit null clears a nullable nested field', () {
      final before = _base().copyWith(
        previousAddress: const ProbeAddress(street: 'Oak', city: 'Ogdenville'),
      );
      final patch = PatchProbePatch().withPreviousAddress(null);
      final decoded = PatchProbePatch.fromWire(patch.toWire()).getOrThrow();

      expect(decoded.apply(before).previousAddress, isNull);
    });

    test('an atomic list replacement round-trips in memory', () {
      final patch = PatchProbePatch.diff(
        _base(),
        _base().copyWith(tags: const ['a', 'b']),
      );
      final decoded = PatchProbePatch.fromWire(patch.toWire()).getOrThrow();

      expect(decoded.apply(_base()).tags, ['a', 'b']);
    });

    test('atomic maps and literal op keys round-trip in memory', () {
      for (final scores in const <Map<String, int>>[
        {'math': 9},
        {'op': 7},
        {'ops': 7},
      ]) {
        final patch = PatchProbePatch().withScores(scores);
        final decoded = PatchProbePatch.fromWire(patch.toWire()).getOrThrow();
        expect(decoded.apply(_base()).scores, scores);
      }
    });

    test('an atomic non-String-key map replacement round-trips in memory', () {
      final patch = PatchProbePatch().withCounts(const {1: 2, 2: 3});
      final decoded = PatchProbePatch.fromWire(patch.toWire()).getOrThrow();
      expect(decoded.apply(_base()).counts, {1: 2, 2: 3});
    });

    test('a whole nested replacement round-trips in memory', () {
      final previous = _base();
      final next = previous.copyWith(
        address: const ProbeAddress(street: 'Elm', city: 'Springfield'),
      );
      final patch = PatchProbePatch.diff(previous, next);
      final decoded = PatchProbePatch.fromWire(patch.toWire()).getOrThrow();

      expect(decoded.apply(previous), next);
    });

    test('a nested replacement from null round-trips as a whole value', () {
      final previous = _base();
      final next = previous.copyWith(
        previousAddress: const ProbeAddress(street: 'Elm', city: 'Springfield'),
      );
      final patch = PatchProbePatch.diff(previous, next);
      final decoded = PatchProbePatch.fromWire(patch.toWire()).getOrThrow();

      expect(decoded.apply(previous).previousAddress, next.previousAddress);
    });

    test('a standalone envelope retains its principal and scalar ops', () {
      final patch = PatchProbePatch().withTitle('grace');
      final envelope = patch.toEnvelope(principalKey: 'p1');
      expect(envelope['entityType'], 'PatchProbe');
      expect(envelope['patchKind'], 'PatchProbe');
      expect(envelope['principalKey'], 'p1');
      expect(envelope['ops'], {'title': 'grace'});

      final transported = jsonDecode(jsonEncode(envelope)) as Map;
      final decoded = PatchProbePatch.fromWire(
        Map<String, Object?>.from(transported),
      ).getOrThrow();
      expect(decoded.apply(_base()).title, 'grace');
    });

    test(
      'an explicit PatchWireSet can set a scalar and clear a nullable field',
      () {
        final decoded = PatchProbePatch.fromWire(const {
          'title': PatchWireSet('grace'),
          'previousAddress': PatchWireSet(null),
        }).getOrThrow();
        final applied = decoded.apply(_base());

        expect(applied.title, 'grace');
        expect(applied.previousAddress, isNull);
      },
    );
  });

  group('corrupt patch rejection', () {
    test('a wrong scalar type is a violation, never a thrown cast', () {
      _expectViolation(PatchProbePatch.fromWire(const {'title': 42}), '/title');
    });

    test('an unknown enum name is a violation', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {'status': 'telepathy'}),
        '/status',
      );
    });

    test('a wrong nullable nested type is a violation', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {'previousAddress': 'Elm St'}),
        '/previousAddress',
      );
    });

    test('a non-array list value is a violation', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {
          'tags': {'ops': <Object?>[]},
        }),
        '/tags',
      );
    });

    test('a list with a bad element is rejected whole', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {
          'tags': ['a', 123],
        }),
        '/tags/1',
      );
    });

    test('a map with a bad value is rejected whole', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {
          'scores': {'math': 'nine'},
        }),
        '/scores/math',
      );
    });

    test('a non-instance nested value is a violation', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {'address': 'Elm St'}),
        '/address',
      );
    });

    test('a descriptor with no value cannot silently clear a scalar', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {
          'title': {'op': 'set'},
        }),
        '/title',
      );
    });

    test('an envelope without ops is rejected at the envelope pointer', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {
          'entityType': 'PatchProbe',
          'patchKind': 'PatchProbe',
        }),
        '/ops',
      );
    });

    test('an envelope scalar violation is re-pathed under ops', () {
      _expectViolation(
        PatchProbePatch.fromWire(const {
          'entityType': 'PatchProbe',
          'patchKind': 'PatchProbe',
          'ops': {'title': 42},
        }),
        '/ops/title',
      );
    });
  });
}
