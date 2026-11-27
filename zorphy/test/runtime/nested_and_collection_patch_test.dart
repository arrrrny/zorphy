// Runtime tests for ISSUE-008 (zorphy#183) — v3 nested and collection patches.
//
// PatchProbePatch comes from the v3-generated fixture
// `test/runtime/fixtures/patch_contract.dart`. Nested objects, lists, and maps
// are carried as atomic whole-value replacements; there are no nested
// sub-patches, positional list ops, or granular map ops.
//
// Laws under test:
//   * nested diff/apply — a changed object is replaced as a whole value
//   * nullable nested — null and non-null transitions are whole-value sets
//   * collections — list and map changes replace the complete collection
//   * round-trip — diff -> apply -> invert restores the previous entity
//   * composition — later whole-value replacements win, left to right

import 'dart:math';

import 'package:test/test.dart';

import 'fixtures/patch_contract.dart';

const _streets = ['Main', 'Elm', 'Oak', 'Pine', 'Cedar'];
const _cities = [
  'Springfield',
  'Shelbyville',
  'Ogdenville',
  'North Haverbrook',
];
const _tags = ['a', 'b', 'c', 'd', 'e'];

ProbeAddress _address(Random rng) => ProbeAddress(
  street: _streets[rng.nextInt(_streets.length)],
  city: _cities[rng.nextInt(_cities.length)],
);

PatchProbe _base() => const PatchProbe(
  id: 'p1',
  title: 'ada',
  tags: ['a', 'b'],
  scores: {'a': 1, 'b': 2},
  counts: {1: 1},
  status: PatchProbeStatus.active,
  address: ProbeAddress(street: 'Main', city: 'Springfield'),
);

PatchProbe _probe(Random rng) => PatchProbe(
  id: 'p-${rng.nextInt(1 << 16)}',
  title: 'name-${rng.nextInt(100)}',
  address: _address(rng),
  tags: <String>[
    for (var i = 0; i < rng.nextInt(4); i++) _tags[rng.nextInt(_tags.length)],
  ],
  scores: <String, int>{
    for (var i = 0; i < rng.nextInt(3); i++)
      'k${rng.nextInt(4)}': rng.nextInt(50),
  },
  counts: <int, int>{
    for (var i = 0; i < rng.nextInt(3); i++) rng.nextInt(4): rng.nextInt(50),
  },
  status: PatchProbeStatus.values[rng.nextInt(PatchProbeStatus.values.length)],
  previousAddress: rng.nextBool() ? _address(rng) : null,
);

void main() {
  group('atomic nested replacement', () {
    test('a changed object is carried as the whole replacement value', () {
      final previous = _base();
      const replacement = ProbeAddress(street: 'Elm', city: 'Springfield');
      final next = previous.copyWith(address: replacement);

      final patch = PatchProbePatch.diff(previous, next);

      expect(patch.address.isSet, isTrue);
      expect(patch.address.valueOrNull, replacement);
      expect(patch.apply(previous).address, replacement);
    });

    test('a content-equal object carries no change', () {
      final rng = Random(3);
      for (var i = 0; i < 50; i++) {
        final probe = _probe(rng);
        final equalAddress = ProbeAddress(
          street: probe.address.street,
          city: probe.address.city,
        );
        final patch = PatchProbePatch.diff(
          probe,
          probe.copyWith(address: equalAddress),
        );
        expect(patch.address.isUnchanged, isTrue);
      }
    });

    test('a nullable object going null is an explicit whole-value set', () {
      final previous = _base().copyWith(
        previousAddress: const ProbeAddress(street: 'Oak', city: 'Ogdenville'),
      );
      final patch = PatchProbePatch.diff(
        previous,
        previous.copyWith(previousAddress: null),
      );

      expect(patch.previousAddress.isSet, isTrue);
      expect(patch.previousAddress.valueOrNull, isNull);
      expect(patch.toWire(), containsPair('previousAddress', null));
      expect(patch.apply(previous).previousAddress, isNull);
    });

    test('a nullable object appearing from null is a whole-value set', () {
      final previous = _base();
      const replacement = ProbeAddress(street: 'Oak', city: 'Ogdenville');
      final patch = PatchProbePatch.diff(
        previous,
        previous.copyWith(previousAddress: replacement),
      );

      expect(patch.previousAddress.valueOrNull, replacement);
      expect(patch.apply(previous).previousAddress, replacement);
    });

    test('invert restores a fluent-built non-nullable object', () {
      final before = _base();
      const replacement = ProbeAddress(street: 'Elm', city: 'Ogdenville');
      final patch = PatchProbePatch().withAddress(replacement);
      final patched = patch.apply(before);

      expect(patched.address, replacement);
      expect(patch.invert(before).apply(patched), before);
    });

    test('composition keeps only the later whole-object replacement', () {
      final base = _base();
      final a = PatchProbePatch.diff(
        base,
        base.copyWith(
          address: const ProbeAddress(street: 'Elm', city: 'Springfield'),
        ),
      );
      final b = PatchProbePatch.diff(
        base,
        base.copyWith(
          address: const ProbeAddress(street: 'Main', city: 'Shelbyville'),
        ),
      );

      final composed = a.compose(b);
      expect(
        composed.apply(base).address,
        const ProbeAddress(street: 'Main', city: 'Shelbyville'),
      );
      expect(composed.invert(base).apply(composed.apply(base)), base);
    });
  });

  group('atomic collection replacement', () {
    test('a changed list is carried as the whole value', () {
      final previous = _base();
      const replacement = ['a', 'b', 'c'];
      final patch = PatchProbePatch.diff(
        previous,
        previous.copyWith(tags: replacement),
      );

      expect(patch.tags.isSet, isTrue);
      expect(patch.tags.valueOrNull, replacement);
      expect(patch.apply(previous).tags, replacement);
    });

    test('a changed map is carried as the whole value, including removals', () {
      final previous = _base();
      const replacement = {'a': 9};
      final patch = PatchProbePatch.diff(
        previous,
        previous.copyWith(scores: replacement),
      );

      expect(patch.scores.isSet, isTrue);
      expect(patch.scores.valueOrNull, replacement);
      expect(patch.apply(previous).scores, replacement);
    });

    test(
      'unchanged collections and content-equal nested values carry no change',
      () {
        final rng = Random(5);
        for (var i = 0; i < 50; i++) {
          final probe = _probe(rng);
          final previousAddress = probe.previousAddress;
          final patch = PatchProbePatch.diff(
            probe,
            probe.copyWith(
              tags: probe.tags,
              scores: probe.scores,
              counts: probe.counts,
              address: ProbeAddress(
                street: probe.address.street,
                city: probe.address.city,
              ),
              previousAddress: previousAddress == null
                  ? null
                  : ProbeAddress(
                      street: previousAddress.street,
                      city: previousAddress.city,
                    ),
            ),
          );
          expect(patch.isEmpty, isTrue);
          expect(identical(patch.apply(probe), probe), isTrue);
        }
      },
    );

    test('list and map wire values are bare replacement values', () {
      final patch = PatchProbePatch.diff(
        _base(),
        _base().copyWith(tags: const ['x', 'y'], scores: const {'x': 3}),
      );
      final wire = patch.toWire();

      expect(wire['tags'], ['x', 'y']);
      expect(wire['scores'], {'x': 3});
    });

    test('composition keeps only the later list and map replacements', () {
      final base = _base();
      final a = PatchProbePatch.diff(
        base,
        base.copyWith(tags: const ['x'], scores: const {'a': 2}),
      );
      final b = PatchProbePatch.diff(
        base,
        base.copyWith(tags: const ['y'], scores: const {'b': 3}),
      );

      final composed = a.compose(b);
      final applied = composed.apply(base);
      expect(applied.tags, ['y']);
      expect(applied.scores, {'b': 3});
      expect(composed.invert(base).apply(applied), base);
    });
  });

  group('round-trip and composition', () {
    test('diff -> apply -> invert restores the previous entity', () {
      final rng = Random(11);
      for (var i = 0; i < 200; i++) {
        final previous = _probe(rng);
        final next = _probe(rng);
        final patch = PatchProbePatch.diff(previous, next);
        final patched = patch.apply(previous);

        expect(patched, next);
        expect(patch.invert(previous).apply(patched), previous);
      }
    });

    test('composition threads left to right', () {
      final rng = Random(13);
      for (var i = 0; i < 200; i++) {
        final base = _probe(rng);
        final middle = base.copyWith(
          title: 'name-${rng.nextInt(100)}',
          tags: <String>[for (var t = 0; t < rng.nextInt(3); t++) 't$t'],
        );
        final end = middle.copyWith(
          address: _address(rng),
          scores: <String, int>{'z': rng.nextInt(50)},
          previousAddress: rng.nextBool() ? _address(rng) : null,
        );

        final a = PatchProbePatch.diff(base, middle);
        final b = PatchProbePatch.diff(middle, end);

        expect(a.compose(b).apply(base), b.apply(a.apply(base)));
        expect(a.compose(b).apply(base), end);
      }
    });

    test('an identical pair is the canonical empty patch', () {
      final rng = Random(17);
      for (var i = 0; i < 20; i++) {
        final probe = _probe(rng);
        final patch = PatchProbePatch.diff(probe, probe);
        expect(patch.isEmpty, isTrue);
        expect(identical(patch.apply(probe), probe), isTrue);
      }
    });
  });
}
