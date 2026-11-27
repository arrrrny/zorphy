import 'dart:convert';

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';

import '../runtime/fixtures/patch_contract.dart';

PatchProbe _base() => const PatchProbe(
  id: 'p1',
  title: 'ada',
  tags: ['a', 'b'],
  scores: const {'a': 1},
  counts: const {1: 1},
  status: PatchProbeStatus.active,
  address: ProbeAddress(street: 'Main', city: 'Springfield'),
);

void main() {
  group('changedPaths', () {
    test('names every changed field as a JSON pointer', () {
      final patch = PatchProbePatch.diff(
        _base(),
        _base().copyWith(title: 'grace', id: 'p2'),
      );
      expect(patch.changedPaths, {'/id', '/title'});
    });

    test('an empty patch changes no path', () {
      expect(PatchProbePatch.diff(_base(), _base()).changedPaths, isEmpty);
    });

    test('a nested change is an atomic whole-value pointer', () {
      final patch = PatchProbePatch.diff(
        _base(),
        _base().copyWith(
          address: const ProbeAddress(street: 'Elm', city: 'Springfield'),
        ),
      );
      expect(patch.changedPaths, {'/address'});
    });

    test('an enum field reports its wire name', () {
      final patch = PatchProbePatch.diff(
        _base(),
        _base().copyWith(status: PatchProbeStatus.paused),
      );
      expect(patch.changedPaths, {'/status'});
      expect(patch.toWire(), containsPair('status', 'paused'));
    });
  });

  group('conflictingPaths', () {
    test('disjoint scalar edits do not conflict', () {
      final a = PatchProbePatch.diff(_base(), _base().copyWith(title: 'x'));
      final b = PatchProbePatch.diff(_base(), _base().copyWith(id: 'p9'));
      expect(a.conflictingPaths(b), isEmpty);
    });

    test('overlapping scalar edits report the exact pointer', () {
      final a = PatchProbePatch.diff(_base(), _base().copyWith(title: 'x'));
      final b = PatchProbePatch.diff(_base(), _base().copyWith(title: 'y'));
      expect(a.conflictingPaths(b), {'/title'});
    });

    test('nested values conflict on the whole field', () {
      final a = PatchProbePatch.diff(
        _base(),
        _base().copyWith(
          address: const ProbeAddress(street: 'Elm', city: 'Springfield'),
        ),
      );
      final b = PatchProbePatch.diff(
        _base(),
        _base().copyWith(
          address: const ProbeAddress(street: 'Main', city: 'Shelbyville'),
        ),
      );
      expect(a.conflictingPaths(b), {'/address'});
    });

    test('a concurrent list replacement conflicts on the whole field', () {
      final a = PatchProbePatch.diff(_base(), _base().copyWith(tags: ['x']));
      final b = PatchProbePatch.diff(_base(), _base().copyWith(tags: ['y']));
      expect(a.conflictingPaths(b), {'/tags'});
    });

    test('a list edit and a disjoint map edit do not conflict', () {
      final a = PatchProbePatch.diff(_base(), _base().copyWith(tags: ['x']));
      final b = PatchProbePatch.diff(
        _base(),
        _base().copyWith(scores: {'a': 2}),
      );
      expect(a.conflictingPaths(b), isEmpty);
    });

    test('nullable nested replacement conflicts with another replacement', () {
      final withAddress = _base().copyWith(
        previousAddress: const ProbeAddress(
          street: 'Main',
          city: 'Springfield',
        ),
      );
      final replacement = PatchProbePatch.diff(withAddress, _base());
      final nested = PatchProbePatch.diff(
        withAddress,
        withAddress.copyWith(
          previousAddress: const ProbeAddress(
            street: 'Elm',
            city: 'Springfield',
          ),
        ),
      );
      expect(replacement.changedPaths, {'/previousAddress'});
      expect(nested.changedPaths, {'/previousAddress'});
      expect(replacement.conflictingPaths(nested), {'/previousAddress'});
    });
  });

  group('composePatches', () {
    test('merges disjoint edits cleanly', () {
      final base = _base();
      final a = PatchProbePatch.diff(base, base.copyWith(title: 'grace'));
      final b = PatchProbePatch.diff(base, base.copyWith(id: 'p2'));

      final merged = a.composePatches(b).apply(base);
      expect(merged.title, 'grace');
      expect(merged.id, 'p2');
    });

    test('threads left to right like compose', () {
      final base = _base();
      final mid = base.copyWith(title: 'grace');
      final end = mid.copyWith(tags: ['a', 'b', 'c']);
      final a = PatchProbePatch.diff(base, mid);
      final b = PatchProbePatch.diff(mid, end);

      expect(a.composePatches(b).apply(base), b.apply(a.apply(base)));
      expect(a.composePatches(b).apply(base), end);
    });

    test('nested composition keeps the later atomic value and invert law', () {
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

      final composed = a.composePatches(b);
      expect(
        composed.apply(base).address,
        const ProbeAddress(street: 'Main', city: 'Shelbyville'),
      );
      expect(composed.invert(base).apply(composed.apply(base)), base);
    });
  });

  group('atomic collection replacement', () {
    test('a changed list is carried as the whole value, not a delta', () {
      final patch = PatchProbePatch.diff(
        _base(),
        _base().copyWith(tags: ['a', 'b', 'c']),
      );
      expect(patch.tags.valueOrNull, ['a', 'b', 'c']);
      expect(patch.apply(_base()).tags, ['a', 'b', 'c']);
    });

    test('an unchanged list carries nothing', () {
      final patch = PatchProbePatch.diff(_base(), _base());
      expect(patch.tags.isUnchanged, isTrue);
    });

    test('the list renders as a bare JSON array on the wire', () {
      final wire = PatchProbePatch.diff(
        _base(),
        _base().copyWith(tags: ['a', 'b', 'c']),
      ).toWire();
      expect(wire['tags'], ['a', 'b', 'c']);
    });

    test('list and map changes round-trip through JSON with their types', () {
      final patch = PatchProbePatch.diff(
        _base(),
        _base().copyWith(tags: ['a', 'b', 'c'], scores: {'a': 2}),
      );
      final transported =
          jsonDecode(jsonEncode(patch.toWire())) as Map<String, Object?>;
      final restored = PatchProbePatch.fromWire(transported).getOrThrow();
      expect(restored.apply(_base()).tags, ['a', 'b', 'c']);
      expect(restored.apply(_base()).scores, {'a': 2});
    });
  });
}
