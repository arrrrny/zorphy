// Runtime property tests for ISSUE-007 (zorphy#182) — the patch algebra.
//
// These exercise the patch shape the emitter produces (`AccountPatch` in
// `test/runtime/fixtures/account.dart`, byte-locked to `PatchEmitter`'s output
// by `test/golden/patch_golden_test.dart`) across randomized entity
// transitions.
//
// Laws under test:
//   * identity      — an empty patch is the neutral element of compose()
//   * zero-copy     — apply() on an empty patch returns the target itself
//   * O(1) diff     — diff(x, x) is the canonical empty patch
//   * composition   — (a.compose(b)).apply(x) == b.apply(a.apply(x))
//   * associativity — (a.compose(b)).compose(c) behaves like a.compose(b.compose(c))
//   * invertibility — p.invert(x).apply(p.apply(x)) == x
//   * burst coalescing — a chain of edits collapses to one patch whose apply
//     matches applying the edits in order

import 'dart:math';

import 'package:test/test.dart';

import 'fixtures/account.dart';

const _names = ['ada', 'grace', 'alan', 'edsger', 'barbara', 'donald'];
const _notes = [null, '', 'draft', 'review', 'shipped', 'a longer note value'];
const _tiers = AccountTier.values;

/// One randomized edit: a field name plus the value to set it to.
class _Edit {
  _Edit(this.field, this.value);

  final String field;
  final Object? value;

  AccountPatch toPatch() {
    final patch = AccountPatch();
    switch (field) {
      case 'name':
        patch.withName(value as String?);
      case 'score':
        patch.withScore(value as int?);
      case 'note':
        patch.withNote(value as String?);
      case 'tier':
        patch.withTier(value as AccountTier?);
      default:
        throw StateError('unmodelled field $field');
    }
    return patch;
  }
}

/// Picks a value that differs from the field's current value on [entity].
_Edit _randomEdit(Random rng, Account entity) {
  final fields = <String>['name', 'score', 'note', 'tier'];
  final field = fields[rng.nextInt(fields.length)];
  switch (field) {
    case 'name':
      return _Edit('name', _names[rng.nextInt(_names.length)]);
    case 'score':
      final delta = rng.nextInt(10) + 1;
      return _Edit('score', entity.score + (rng.nextBool() ? delta : -delta));
    case 'note':
      final candidates = _notes.where((n) => n != entity.note).toList();
      return _Edit('note', candidates[rng.nextInt(candidates.length)]);
    case 'tier':
      final candidates = _tiers.where((t) => t != entity.tier).toList();
      return _Edit('tier', candidates[rng.nextInt(candidates.length)]);
  }
  throw StateError('unreachable');
}

Account _randomAccount(Random rng) => Account(
  id: 'id-${rng.nextInt(1 << 20)}',
  name: _names[rng.nextInt(_names.length)],
  score: rng.nextInt(200) - 50,
  note: _notes[rng.nextInt(_notes.length)],
  tier: _tiers[rng.nextInt(_tiers.length)],
);

void main() {
  const transitions = 500;

  group('ISSUE-007 patch algebra', () {
    test('identity: empty patch is the neutral element of compose', () {
      final rng = Random(7);
      final empty = AccountPatch();
      for (var i = 0; i < transitions; i++) {
        final base = _randomAccount(rng);
        final edit = _randomEdit(rng, base);
        final patch = empty.compose(edit.toPatch());
        final other = edit.toPatch().compose(empty);

        expect(patch.isEmpty, isFalse, reason: 'identity on the left');
        expect(other.isEmpty, isFalse, reason: 'identity on the right');
        expect(
          patch.apply(base),
          edit.toPatch().apply(base),
          reason: 'empty.compose(p) behaves like p',
        );
        expect(
          other.apply(base),
          edit.toPatch().apply(base),
          reason: 'p.compose(empty) behaves like p',
        );
      }
    });

    test('zero-copy: apply() on an empty patch returns the target itself', () {
      final rng = Random(11);
      final empty = AccountPatch();
      for (var i = 0; i < transitions; i++) {
        final base = _randomAccount(rng);
        final result = empty.apply(base);
        expect(
          identical(result, base),
          isTrue,
          reason: 'isEmpty ⇒ no allocation',
        );
      }
    });

    test('O(1) diff: diff(x, x) is the canonical empty patch', () {
      final rng = Random(13);
      for (var i = 0; i < transitions; i++) {
        final base = _randomAccount(rng);
        final patch = AccountPatch.diff(base, base);
        expect(patch.isEmpty, isTrue);
        expect(identical(patch.apply(base), base), isTrue);
      }
    });

    test('diff: apply(diff(previous, next)) == next', () {
      final rng = Random(17);
      for (var i = 0; i < transitions; i++) {
        final previous = _randomAccount(rng);
        final next = previous.copyWith(
          name: _randomEdit(rng, previous).field == 'name'
              ? _names[rng.nextInt(_names.length)]
              : previous.name,
          score: rng.nextInt(500) - 250,
          note: _notes[rng.nextInt(_notes.length)],
          tier: _tiers[rng.nextInt(_tiers.length)],
        );
        final patch = AccountPatch.diff(previous, next);
        expect(
          patch.apply(previous),
          next,
          reason: 'diff must carry every changed field',
        );
        expect(patch.isEmpty, isFalse, reason: 'a changed pair is not empty');
      }
    });

    test(
      'composition order: (a.compose(b)).apply(x) == b.apply(a.apply(x))',
      () {
        final rng = Random(23);
        for (var i = 0; i < transitions; i++) {
          final base = _randomAccount(rng);
          final a = _randomEdit(rng, base).toPatch();
          final middle = a.apply(base);
          final b = _randomEdit(rng, middle).toPatch();

          expect(
            a.compose(b).apply(base),
            b.apply(a.apply(base)),
            reason: 'compose threads left to right',
          );
        }
      },
    );

    test('associativity: (a∘b)∘c behaves like a∘(b∘c)', () {
      final rng = Random(29);
      for (var i = 0; i < transitions; i++) {
        final base = _randomAccount(rng);
        final a = _randomEdit(rng, base).toPatch();
        final afterA = a.apply(base);
        final b = _randomEdit(rng, afterA).toPatch();
        final afterB = b.apply(afterA);
        final c = _randomEdit(rng, afterB).toPatch();

        expect(
          a.compose(b).compose(c).apply(base),
          a.compose(b.compose(c)).apply(base),
          reason: 'compose is associative',
        );
      }
    });

    test('invertibility: p.invert(x).apply(p.apply(x)) == x', () {
      final rng = Random(31);
      for (var i = 0; i < transitions; i++) {
        final base = _randomAccount(rng);
        final patch = _randomEdit(rng, base).toPatch();
        final patched = patch.apply(base);

        expect(
          patch.invert(base).apply(patched),
          base,
          reason: 'invert restores every field the patch changed',
        );
      }
    });

    test('burst coalescing: chained edits collapse to one faithful patch', () {
      final rng = Random(37);
      for (var i = 0; i < transitions; i++) {
        final base = _randomAccount(rng);

        // A burst: load progress style, many edits on one value.
        final burst = <AccountPatch>[];
        var current = base;
        for (var step = 0; step < 5; step++) {
          final edit = _randomEdit(rng, current).toPatch();
          burst.add(edit);
          current = edit.apply(current);
        }

        var coalesced = AccountPatch();
        var applied = base;
        for (final edit in burst) {
          coalesced = coalesced.compose(edit);
          applied = edit.apply(applied);
        }

        expect(coalesced.apply(base), applied, reason: 'coalesced burst');
        expect(coalesced.apply(base), current);
      }
    });

    test('toWire: keys are field names, values are the carried changes', () {
      final patch = AccountPatch().withName('grace').withScore(9);
      expect(patch.toWire(), {'name': 'grace', 'score': 9});

      expect(AccountPatch().toWire(), isEmpty);
    });
  });
}
