// Runtime tests for ISSUE-008 (zorphy#183) — nested sub-patches and collection
// deltas in the REAL emitted patch.
//
// `ProfilePatch` / `AddressPatch` in `test/runtime/fixtures/profile.dart` are
// byte-locked to `PatchEmitter`'s output by
// `test/golden/nested_and_collection_patch_golden_test.dart`, so the invariants
// below are stated against generated code rather than a hand-written
// lookalike.
//
// Laws under test:
//   * nested diff/apply — a changed sub-entity travels as a `PatchNested`
//     carrying `SubPatch.diff`, and applying it delegates to the sub-entity's
//     own patch
//   * nullable nested — a null on either side is a whole-value transition, not
//     a sub-patch
//   * collection deltas — `List`/`Map` changes travel as granular ops and
//     apply to the target collection
//   * round-trip — `diff -> apply -> invert` restores the previous entity
//   * composition — `(a.compose(b)).apply(x) == b.apply(a.apply(x))`

import 'dart:math';

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';

import 'fixtures/profile.dart';

const _streets = ['Main', 'Elm', 'Oak', 'Pine', 'Cedar'];
const _cities = [
  'Springfield',
  'Shelbyville',
  'Ogdenville',
  'North Haverbrook',
];
const _tags = ['a', 'b', 'c', 'd', 'e'];

Address _address(Random rng) => Address(
  street: _streets[rng.nextInt(_streets.length)],
  city: _cities[rng.nextInt(_cities.length)],
  postalCode: rng.nextBool() ? null : '${10000 + rng.nextInt(89999)}',
);

Profile _profile(Random rng) => Profile(
  id: 'p-${rng.nextInt(1 << 16)}',
  displayName: 'name-${rng.nextInt(100)}',
  address: _address(rng),
  tags: <String>[
    for (var i = 0; i < rng.nextInt(4); i++) _tags[rng.nextInt(_tags.length)],
  ],
  scores: <String, int>{
    for (var i = 0; i < rng.nextInt(3); i++)
      'k${rng.nextInt(4)}': rng.nextInt(50),
  },
  previousAddress: rng.nextBool() ? _address(rng) : null,
);

void main() {
  group('nested sub-patches', () {
    test('a changed sub-entity travels as a PatchNested', () {
      const before = Address(street: 'Main', city: 'Springfield');
      final previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: before,
        tags: const ['x'],
        scores: const {'a': 1},
      );
      final next = previous.copyWith(
        address: const Address(street: 'Elm', city: 'Springfield'),
      );

      final patch = ProfilePatch.diff(previous, next);
      final carried = patch.patchMap[Profile$.address];
      expect(carried, isA<PatchNested<Address, AddressPatch>>());
      expect(
        patch.apply(previous).address,
        const Address(street: 'Elm', city: 'Springfield'),
        reason: 'apply delegates to the sub-entity patch',
      );
    });

    test('an unchanged sub-entity carries nothing', () {
      final rng = Random(3);
      for (var i = 0; i < 50; i++) {
        final profile = _profile(rng);
        final patch = ProfilePatch.diff(profile, profile.copyWith());
        expect(
          patch.patchMap.containsKey(Profile$.address),
          isFalse,
          reason: 'a content-equal nested value is no change',
        );
      }
    });

    test('a nullable sub-entity going null is a whole-value transition', () {
      final previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: const Address(street: 'Main', city: 'Springfield'),
        tags: const [],
        scores: const {},
        previousAddress: const Address(street: 'Oak', city: 'Ogdenville'),
      );
      final next = Profile(
        id: previous.id,
        displayName: previous.displayName,
        address: previous.address,
        tags: previous.tags,
        scores: previous.scores,
      );

      final patch = ProfilePatch.diff(previous, next);
      expect(
        patch.patchMap[Profile$.previousAddress],
        isNull,
        reason: 'null is carried verbatim, never as a sub-patch',
      );
      expect(patch.apply(previous).previousAddress, isNull);
    });

    test('a nullable sub-entity appearing from null is a whole value', () {
      final previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: const Address(street: 'Main', city: 'Springfield'),
        tags: const [],
        scores: const {},
      );
      final next = previous.copyWith(
        previousAddress: const Address(street: 'Oak', city: 'Ogdenville'),
      );

      final patch = ProfilePatch.diff(previous, next);
      expect(patch.apply(previous).previousAddress, next.previousAddress);
    });

    test('invert restores a fluent-built non-nullable nested value', () {
      const originalAddress = Address(street: 'Main', city: 'Springfield');
      final before = Profile(
        id: 'p1',
        displayName: 'ada',
        address: originalAddress,
        tags: const [],
        scores: const {},
      );
      // The always-emitted `withAddress` builder carries a RAW value, not a
      // PatchNested — inverting must still restore the prior value (the
      // non-nullable nested arm needs the same `is! PatchNested` fallback the
      // list / map arms have).
      final patch = ProfilePatch().withAddress(
        const Address(street: 'Elm', city: 'Ogdenville'),
      );
      final patched = patch.apply(before);
      expect(patched.address, const Address(street: 'Elm', city: 'Ogdenville'));
      expect(
        patch.invert(before).apply(patched).address,
        originalAddress,
        reason: 'invert restores the original nested value',
      );
    });

    test('invert restores a fluent-built sub-patch nested value', () {
      const originalAddress = Address(street: 'Main', city: 'Springfield');
      final before = Profile(
        id: 'p1',
        displayName: 'ada',
        address: originalAddress,
        tags: const [],
        scores: const {},
      );
      // `withAddressPatch` carries an AddressPatch (a Patch, but not a
      // PatchNested); the fallback must still restore the prior value.
      final patch = ProfilePatch().withAddressPatch(
        AddressPatch()..withStreet('Elm'),
      );
      final patched = patch.apply(before);
      expect(patched.address.street, 'Elm');
      expect(
        patch.invert(before).apply(patched).address,
        originalAddress,
        reason: 'invert restores the original nested value',
      );
    });
  });

  group('collection deltas', () {
    test('an appended tag travels as one append op', () {
      final previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: const Address(street: 'Main', city: 'Springfield'),
        tags: const ['x', 'y'],
        scores: const {},
      );
      final patch = ProfilePatch.diff(
        previous,
        previous.copyWith(tags: const ['x', 'y', 'z']),
      );

      final carried = patch.patchMap[Profile$.tags];
      expect(carried, isA<ListPatchDelta<String>>());
      expect(
        carried,
        ListPatchDelta<String>(<ListPatchOp<String>>[
          const ListPatchOp<String>.append('z'),
        ]),
      );
      expect(patch.apply(previous).tags, ['x', 'y', 'z']);
    });

    test('a changed score travels as one put', () {
      final previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: const Address(street: 'Main', city: 'Springfield'),
        tags: const [],
        scores: const {'a': 1, 'b': 2},
      );
      final patch = ProfilePatch.diff(
        previous,
        previous.copyWith(scores: const {'a': 1, 'b': 9}),
      );

      expect(
        patch.patchMap[Profile$.scores],
        isA<MapPatchDelta<String, int>>(),
      );
      expect(patch.apply(previous).scores, {'a': 1, 'b': 9});
    });

    test('an unchanged collection carries no op', () {
      final rng = Random(5);
      for (var i = 0; i < 50; i++) {
        final profile = _profile(rng);
        final patch = ProfilePatch.diff(
          profile,
          profile.copyWith(
            tags: List<String>.of(profile.tags),
            scores: Map<String, int>.of(profile.scores),
          ),
        );
        expect(patch.patchMap.containsKey(Profile$.tags), isFalse);
        expect(patch.patchMap.containsKey(Profile$.scores), isFalse);
      }
    });

    test('the delta renders its ops on the wire, not an opaque object', () {
      final previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: const Address(street: 'Main', city: 'Springfield'),
        tags: const ['x'],
        scores: const {},
      );
      final wire = ProfilePatch.diff(
        previous,
        previous.copyWith(tags: const ['x', 'y']),
      ).toWire();

      expect(wire['tags'], <String, Object?>{
        'ops': <Object?>[
          <String, Object?>{'op': 'append', 'item': 'y'},
        ],
      });
    });

    test(
      'a nested change renders the sub-patch on the wire, not an object',
      () {
        final previous = Profile(
          id: 'p1',
          displayName: 'ada',
          address: const Address(street: 'Main', city: 'Springfield'),
          tags: const [],
          scores: const {},
        );
        final wire = ProfilePatch.diff(
          previous,
          previous.copyWith(
            address: const Address(street: 'Elm', city: 'Springfield'),
          ),
        ).toWire();

        // A nested field unwraps to its inner toWire map — plain JSON, never a
        // live PatchNested object.
        expect(wire['address'], <String, Object?>{'street': 'Elm'});
      },
    );
  });

  group('round-trip and composition', () {
    test('diff -> apply -> invert restores the previous entity', () {
      final rng = Random(11);
      for (var i = 0; i < 200; i++) {
        final previous = _profile(rng);
        final next = Profile(
          id: previous.id,
          displayName: 'name-${rng.nextInt(100)}',
          address: _address(rng),
          tags: <String>[
            for (var t = 0; t < rng.nextInt(4); t++)
              _tags[rng.nextInt(_tags.length)],
          ],
          scores: <String, int>{
            for (var k = 0; k < rng.nextInt(3); k++)
              'k${rng.nextInt(4)}': rng.nextInt(50),
          },
          previousAddress: rng.nextBool() ? _address(rng) : null,
        );

        final patch = ProfilePatch.diff(previous, next);
        final patched = patch.apply(previous);
        expect(patched, next, reason: 'diff must carry every changed field');
        expect(
          patch.invert(previous).apply(patched),
          previous,
          reason: 'invert restores the previous entity',
        );
      }
    });

    test('composition threads left to right', () {
      final rng = Random(13);
      for (var i = 0; i < 200; i++) {
        final base = _profile(rng);
        final middle = base.copyWith(
          displayName: 'name-${rng.nextInt(100)}',
          tags: <String>[for (var t = 0; t < rng.nextInt(3); t++) 't$t'],
        );
        final end = middle.copyWith(
          address: _address(rng),
          scores: <String, int>{'z': rng.nextInt(50)},
        );

        final a = ProfilePatch.diff(base, middle);
        final b = ProfilePatch.diff(middle, end);

        expect(
          a.compose(b).apply(base),
          b.apply(a.apply(base)),
          reason: 'compose is apply-then-apply',
        );
        expect(a.compose(b).apply(base), end);
      }
    });

    test('an identical pair is the canonical empty patch', () {
      final rng = Random(17);
      for (var i = 0; i < 20; i++) {
        final profile = _profile(rng);
        final patch = ProfilePatch.diff(profile, profile);
        expect(patch.isEmpty, isTrue);
        expect(identical(patch.apply(profile), profile), isTrue);
      }
    });
  });
}
