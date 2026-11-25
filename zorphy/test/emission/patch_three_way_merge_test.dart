// Three-way offline-sync primitives on the REAL emitted patch (zorphy#248).
//
// `ProfilePatch` / `AddressPatch` in `test/runtime/fixtures/profile.dart` are
// byte-locked to `PatchEmitter`'s output by
// `test/golden/nested_and_collection_patch_golden_test.dart`, so the invariants
// below are stated against generated code rather than a hand-written lookalike.
//
// Laws under test (issue #248):
//   * `changedPaths` — the JSON pointers a patch touches, e.g. {'/displayName'}
//   * `conflictingPaths` — the exact intersection of two patches' changed paths
//   * `composePatches` — applies `next` over this patch (the three-way name for
//     `compose`); disjoint edits merge cleanly
//   * atomic list replacement — a changed `List<E>` field is carried as the
//     whole list value, never as positional index ops, so a concurrent list
//     edit is an exact `/tags` conflict rather than silent index corruption

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';

import '../runtime/fixtures/profile.dart';

Profile _base() => const Profile(
  id: 'p1',
  displayName: 'ada',
  address: Address(street: 'Main', city: 'Springfield'),
  tags: ['a', 'b'],
  scores: {'a': 1},
);

void main() {
  group('changedPaths', () {
    test('names every changed field as a JSON pointer', () {
      final patch = ProfilePatch.diff(
        _base(),
        _base().copyWith(displayName: 'grace', id: 'p2'),
      );
      expect(patch.changedPaths, {'/id', '/displayName'});
    });

    test('an empty patch changes no path', () {
      expect(ProfilePatch.diff(_base(), _base()).changedPaths, isEmpty);
    });

    test('a nested change expands to the leaf pointer', () {
      final patch = ProfilePatch.diff(
        _base(),
        _base().copyWith(
          address: const Address(street: 'Elm', city: 'Springfield'),
        ),
      );
      expect(patch.changedPaths, {'/address/street'});
    });
  });

  group('conflictingPaths', () {
    test('disjoint scalar edits do not conflict', () {
      final a = ProfilePatch.diff(_base(), _base().copyWith(displayName: 'x'));
      final b = ProfilePatch.diff(_base(), _base().copyWith(id: 'p9'));
      expect(a.conflictingPaths(b), isEmpty);
    });

    test('overlapping scalar edits report the exact pointer', () {
      final a = ProfilePatch.diff(_base(), _base().copyWith(displayName: 'x'));
      final b = ProfilePatch.diff(_base(), _base().copyWith(displayName: 'y'));
      expect(a.conflictingPaths(b), {'/displayName'});
    });

    test('disjoint nested edits under one object do not conflict', () {
      final a = ProfilePatch.diff(
        _base(),
        _base().copyWith(
          address: const Address(street: 'Elm', city: 'Springfield'),
        ),
      );
      final b = ProfilePatch.diff(
        _base(),
        _base().copyWith(
          address: const Address(street: 'Main', city: 'Shelbyville'),
        ),
      );
      expect(a.conflictingPaths(b), isEmpty);
    });

    test('the same nested leaf conflicts exactly', () {
      final a = ProfilePatch.diff(
        _base(),
        _base().copyWith(
          address: const Address(street: 'Elm', city: 'Springfield'),
        ),
      );
      final b = ProfilePatch.diff(
        _base(),
        _base().copyWith(
          address: const Address(street: 'Oak', city: 'Springfield'),
        ),
      );
      expect(a.conflictingPaths(b), {'/address/street'});
    });

    test('a concurrent list replacement conflicts on the whole field', () {
      final a = ProfilePatch.diff(_base(), _base().copyWith(tags: const ['x']));
      final b = ProfilePatch.diff(_base(), _base().copyWith(tags: const ['y']));
      expect(a.conflictingPaths(b), {'/tags'});
    });

    test('a list edit and a disjoint field edit do not conflict', () {
      final a = ProfilePatch.diff(_base(), _base().copyWith(tags: const ['x']));
      final b = ProfilePatch.diff(
        _base(),
        _base().copyWith(scores: const {'a': 2}),
      );
      expect(a.conflictingPaths(b), isEmpty);
    });
  });

  group('composePatches', () {
    test('merges disjoint edits cleanly', () {
      final base = _base();
      final a = ProfilePatch.diff(base, base.copyWith(displayName: 'grace'));
      final b = ProfilePatch.diff(base, base.copyWith(id: 'p2'));

      final merged = a.composePatches(b).apply(base);
      expect(merged.displayName, 'grace');
      expect(merged.id, 'p2');
    });

    test('threads left to right like compose', () {
      final base = _base();
      final mid = base.copyWith(displayName: 'grace');
      final end = mid.copyWith(tags: const ['a', 'b', 'c']);
      final a = ProfilePatch.diff(base, mid);
      final b = ProfilePatch.diff(mid, end);

      expect(a.composePatches(b).apply(base), b.apply(a.apply(base)));
      expect(a.composePatches(b).apply(base), end);
    });
  });

  group('atomic list replacement', () {
    test('a changed list is carried as the whole value, not a delta', () {
      final patch = ProfilePatch.diff(
        _base(),
        _base().copyWith(tags: const ['a', 'b', 'c']),
      );
      expect(patch.patchMap[Profile$.tags], isA<List<String>>());
      expect(
        patch.patchMap[Profile$.tags],
        isNot(isA<ListPatchDelta<String>>()),
      );
      expect(patch.apply(_base()).tags, ['a', 'b', 'c']);
    });

    test('an unchanged list carries nothing', () {
      final patch = ProfilePatch.diff(
        _base(),
        _base().copyWith(tags: const ['a', 'b']),
      );
      expect(patch.patchMap.containsKey(Profile$.tags), isFalse);
    });

    test('the list renders as a bare JSON array on the wire', () {
      final wire = ProfilePatch.diff(
        _base(),
        _base().copyWith(tags: const ['a', 'b', 'c']),
      ).toWire();
      expect(wire['tags'], ['a', 'b', 'c']);
    });

    test('a list change round-trips through the wire', () {
      final patch = ProfilePatch.diff(
        _base(),
        _base().copyWith(tags: const ['a', 'b', 'c']),
      );
      final decoded = ProfilePatch.fromWire(patch.toWire());
      final restored = decoded.fold((p) => p, (_) => ProfilePatch());
      expect(restored.apply(_base()).tags, ['a', 'b', 'c']);
    });
  });
}
