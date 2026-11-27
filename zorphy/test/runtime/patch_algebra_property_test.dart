// Runtime property tests for ISSUE-007 (zorphy#182) — the patch algebra.
//
// These exercise PatchProbePatch from the v3-generated fixture
// `test/runtime/fixtures/patch_contract.dart` across deterministic randomized
// transitions, including scalars, atomic collections, and nested values.
//
// Laws under test:
//   * identity      — an empty patch is the neutral element of compose()
//   * zero-copy     — apply() on an empty patch returns the target itself
//   * diff          — identical values produce the canonical empty patch
//   * diff/apply    — applying a diff carries every changed field
//   * composition   — (a.compose(b)).apply(x) == b.apply(a.apply(x))
//   * associativity — (a.compose(b)).compose(c) behaves like a.compose(b.compose(c))
//   * invertibility — p.invert(x).apply(p.apply(x)) == x
//   * burst coalescing — a chain of edits collapses to one patch whose apply
//     matches applying the edits in order

import 'dart:math';

import 'package:test/test.dart';

import 'fixtures/patch_contract.dart';

const _ids = ['id-1', 'id-2', 'id-3', 'id-4', 'id-5', 'id-6'];
const _titles = ['ada', 'grace', 'alan', 'edsger', 'barbara', 'donald'];
const _tags = ['a', 'b', 'c', 'd', 'e'];
const _addresses = [
  ProbeAddress(street: 'Main', city: 'Springfield'),
  ProbeAddress(street: 'Elm', city: 'Shelbyville'),
  ProbeAddress(street: 'Oak', city: 'Ogdenville'),
  ProbeAddress(street: 'Pine', city: 'North Haverbrook'),
];

/// One randomized edit: a field name plus the whole value to set it to.
class _Edit {
  _Edit(this.field, this.value);

  final String field;
  final Object? value;

  PatchProbePatch toPatch() {
    final patch = PatchProbePatch();
    switch (field) {
      case 'id':
        return patch.withId(value as String);
      case 'title':
        return patch.withTitle(value as String);
      case 'tags':
        return patch.withTags(value as List<String>);
      case 'scores':
        return patch.withScores(value as Map<String, int>);
      case 'counts':
        return patch.withCounts(value as Map<int, int>);
      case 'status':
        return patch.withStatus(value as PatchProbeStatus);
      case 'address':
        return patch.withAddress(value as ProbeAddress);
      case 'previousAddress':
        return patch.withPreviousAddress(value as ProbeAddress?);
      default:
        throw StateError('unmodelled field $field');
    }
  }
}

/// Picks a value that differs from the field's current value on [entity].
_Edit _randomEdit(Random rng, PatchProbe entity) {
  const fields = [
    'id',
    'title',
    'tags',
    'scores',
    'counts',
    'status',
    'address',
    'previousAddress',
  ];
  final field = fields[rng.nextInt(fields.length)];
  switch (field) {
    case 'id':
      final candidates = _ids.where((value) => value != entity.id).toList();
      return _Edit('id', candidates[rng.nextInt(candidates.length)]);
    case 'title':
      final candidates = _titles
          .where((value) => value != entity.title)
          .toList();
      return _Edit('title', candidates[rng.nextInt(candidates.length)]);
    case 'tags':
      return _Edit('tags', <String>[
        ...entity.tags,
        _tags[rng.nextInt(_tags.length)],
      ]);
    case 'scores':
      return _Edit('scores', <String, int>{
        ...entity.scores,
        'edit': (entity.scores['edit'] ?? 0) + 1,
      });
    case 'counts':
      return _Edit('counts', <int, int>{
        ...entity.counts,
        1: (entity.counts[1] ?? 0) + 1,
      });
    case 'status':
      return _Edit(
        'status',
        entity.status == PatchProbeStatus.active
            ? PatchProbeStatus.paused
            : PatchProbeStatus.active,
      );
    case 'address':
      final candidates = _addresses
          .where((value) => value != entity.address)
          .toList();
      return _Edit('address', candidates[rng.nextInt(candidates.length)]);
    case 'previousAddress':
      final candidates = <ProbeAddress?>[
        ..._addresses,
        null,
      ].where((value) => value != entity.previousAddress).toList();
      return _Edit(
        'previousAddress',
        candidates[rng.nextInt(candidates.length)],
      );
  }
  throw StateError('unreachable');
}

PatchProbe _randomProbe(Random rng) => PatchProbe(
  id: 'id-${rng.nextInt(6) + 1}',
  title: _titles[rng.nextInt(_titles.length)],
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
  address: _addresses[rng.nextInt(_addresses.length)],
  previousAddress: rng.nextBool()
      ? _addresses[rng.nextInt(_addresses.length)]
      : null,
);

void main() {
  const transitions = 500;

  group('ISSUE-007 patch algebra', () {
    test('identity: empty patch is the neutral element of compose', () {
      final rng = Random(7);
      final empty = PatchProbePatch();
      for (var i = 0; i < transitions; i++) {
        final base = _randomProbe(rng);
        final edit = _randomEdit(rng, base).toPatch();
        final left = empty.compose(edit);
        final right = edit.compose(empty);

        expect(left.isEmpty, isFalse, reason: 'identity on the left');
        expect(right.isEmpty, isFalse, reason: 'identity on the right');
        expect(left.apply(base), edit.apply(base));
        expect(right.apply(base), edit.apply(base));
      }
    });

    test('zero-copy: apply() on an empty patch returns the target itself', () {
      final rng = Random(11);
      final empty = PatchProbePatch();
      for (var i = 0; i < transitions; i++) {
        final base = _randomProbe(rng);
        expect(identical(empty.apply(base), base), isTrue);
      }
    });

    test(
      'diff: identical and content-equal values are canonical empty patches',
      () {
        final rng = Random(13);
        for (var i = 0; i < transitions; i++) {
          final base = _randomProbe(rng);
          for (final next in [base, base.copyWith()]) {
            final patch = PatchProbePatch.diff(base, next);
            expect(patch.isEmpty, isTrue);
            expect(identical(patch.apply(base), base), isTrue);
          }
        }
      },
    );

    test('diff: apply(diff(previous, next)) == next', () {
      final rng = Random(17);
      for (var i = 0; i < transitions; i++) {
        final previous = _randomProbe(rng);
        final next = _randomEdit(rng, previous).toPatch().apply(previous);
        final patch = PatchProbePatch.diff(previous, next);

        expect(patch.apply(previous), next);
        expect(patch.isEmpty, isFalse);
      }
    });

    test('diff: every field changed at once is carried and inverted', () {
      const previous = PatchProbe(
        id: 'id-before',
        title: 'ada',
        tags: ['a'],
        scores: {'a': 1},
        counts: {1: 1},
        status: PatchProbeStatus.active,
        address: ProbeAddress(street: 'Main', city: 'Springfield'),
        previousAddress: ProbeAddress(street: 'Oak', city: 'Ogdenville'),
      );
      const next = PatchProbe(
        id: 'id-after',
        title: 'grace',
        tags: ['b', 'c'],
        scores: {'a': 2, 'b': 3},
        counts: {1: 2, 2: 3},
        status: PatchProbeStatus.paused,
        address: ProbeAddress(street: 'Elm', city: 'Shelbyville'),
        previousAddress: ProbeAddress(street: 'Pine', city: 'North Haverbrook'),
      );

      final patch = PatchProbePatch.diff(previous, next);

      expect(patch.apply(previous), next);
      expect(
        patch.toWire().keys,
        unorderedEquals([
          'id',
          'title',
          'tags',
          'scores',
          'counts',
          'status',
          'address',
          'previousAddress',
        ]),
      );
      expect(patch.invert(previous).apply(next), previous);
    });

    test(
      'composition order: (a.compose(b)).apply(x) == b.apply(a.apply(x))',
      () {
        final rng = Random(23);
        for (var i = 0; i < transitions; i++) {
          final base = _randomProbe(rng);
          final a = _randomEdit(rng, base).toPatch();
          final middle = a.apply(base);
          final b = _randomEdit(rng, middle).toPatch();

          expect(a.compose(b).apply(base), b.apply(a.apply(base)));
        }
      },
    );

    test('associativity: (a∘b)∘c behaves like a∘(b∘c)', () {
      final rng = Random(29);
      for (var i = 0; i < transitions; i++) {
        final base = _randomProbe(rng);
        final a = _randomEdit(rng, base).toPatch();
        final afterA = a.apply(base);
        final b = _randomEdit(rng, afterA).toPatch();
        final afterB = b.apply(afterA);
        final c = _randomEdit(rng, afterB).toPatch();

        expect(
          a.compose(b).compose(c).apply(base),
          a.compose(b.compose(c)).apply(base),
        );
      }
    });

    test('invertibility: p.invert(x).apply(p.apply(x)) == x', () {
      final rng = Random(31);
      for (var i = 0; i < transitions; i++) {
        final base = _randomProbe(rng);
        final patch = _randomEdit(rng, base).toPatch();
        final patched = patch.apply(base);

        expect(patch.invert(base).apply(patched), base);
      }
    });

    test('burst coalescing: chained edits collapse to one faithful patch', () {
      final rng = Random(37);
      for (var i = 0; i < transitions; i++) {
        final base = _randomProbe(rng);
        final burst = <PatchProbePatch>[];
        var current = base;
        for (var step = 0; step < 5; step++) {
          final edit = _randomEdit(rng, current).toPatch();
          burst.add(edit);
          current = edit.apply(current);
        }

        var coalesced = PatchProbePatch();
        var applied = base;
        for (final edit in burst) {
          coalesced = coalesced.compose(edit);
          applied = edit.apply(applied);
        }

        expect(coalesced.apply(base), applied);
        expect(coalesced.apply(base), current);
      }
    });

    test('toWire: keys are field names, values are the carried changes', () {
      final patch = PatchProbePatch().withId('p2').withTitle('grace');
      expect(patch.toWire(), {'id': 'p2', 'title': 'grace'});
      expect(PatchProbePatch().toWire(), isEmpty);
    });
  });
}
