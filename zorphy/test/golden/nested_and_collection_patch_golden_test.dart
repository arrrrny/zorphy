// Golden tests for ISSUE-008 (zorphy#183) — nested sub-patches and collection
// deltas in the emitted `<Name>Patch`.
//
// `PatchEmitter` must emit, per field shape:
//   * a nested Zorphy field      -> `PatchNested<Sub, SubPatch>` carried in the
//                                   patch map, so the entity's own `patchWith`
//                                   delegates to `SubPatch.apply`
//   * a `List<E>` field          -> `ListPatchDelta<E>` carried in the patch map
//   * a `Map<K, V>` field        -> `MapPatchDelta<K, V>` carried in the patch map
//   * a scalar field             -> the value itself (unchanged)
//
// The emitted class must then still be a `Patch`, because that is the arm the
// generated `patchWith` resolves a carried field through. The runtime fixture
// (`test/runtime/fixtures/profile.dart`) carries this emitter's output for the
// `Profile` entity, so `test/runtime/nested_and_collection_patch_test.dart`
// exercises the REAL emitted patch rather than a hand-written lookalike.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/patch_emitter.dart';

const _fixturePath = 'test/runtime/fixtures/profile.dart';

const _startMarker = '// GOLDEN-PROFILE-PATCH-START';
const _endMarker = '// GOLDEN-PROFILE-PATCH-END';

/// The `Profile` entity's fields, in declaration order.
///
/// `address` is a nested Zorphy type, `tags` a `List<String>`, `scores` a
/// `Map<String, int>` and the rest scalars — one field per shape the issue
/// names. `scores` has an `int` value type so the emitted cast site is a plain
/// generic and not a nested-map conversion.
List<NameTypeClassComment> profileFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('displayName', 'String', ''),
  NameTypeClassComment('address', 'Address', ''),
  NameTypeClassComment('tags', 'List<String>', ''),
  NameTypeClassComment('scores', 'Map<String, int>', ''),
  NameTypeClassComment('previousAddress', 'Address?', ''),
];

/// The `Address` entity's fields, in declaration order.
///
/// `postalCode` is nullable, so the emitted patch exercises a nullable scalar
/// beside the nullable nested `previousAddress` above.
List<NameTypeClassComment> addressFields() => [
  NameTypeClassComment('street', 'String', ''),
  NameTypeClassComment('city', 'String', ''),
  NameTypeClassComment('postalCode', 'String?', ''),
];

/// The patch region of the fixture, markers excluded.
String _fixturePatchRegion() => _fixtureRegionOf(_startMarker, _endMarker);

/// Any marked region of the fixture, markers excluded.
String _fixtureRegionOf(String startMarker, String endMarker) {
  final source = File(_fixturePath).readAsStringSync();
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker);
  expect(start, isNot(-1), reason: 'fixture must carry $startMarker');
  expect(end, isNot(-1), reason: 'fixture must carry $endMarker');
  return source.substring(start + startMarker.length, end).trim();
}

void main() {
  group('ISSUE-008 PatchEmitter golden', () {
    late String emitted;

    setUp(() {
      emitted = PatchEmitter().emit(
        className: 'Profile',
        fields: profileFields(),
        knownClasses: const ['Address'],
      );
    });

    test('emitted patch matches the runtime fixture byte for byte', () {
      expect(
        emitted.trim(),
        _fixturePatchRegion(),
        reason:
            'the runtime suite must exercise the real emitted patch — '
            'regenerate $_fixturePath if the emission changed on purpose',
      );
    });

    test('the Address emission matches the runtime fixture byte for byte', () {
      // The Address patch is what `ProfilePatch`'s nested field decodes
      // through, so a drift here breaks the profile suite rather than this
      // one — which is exactly why it needs its own assertion.
      expect(
        PatchEmitter()
            .emit(className: 'Address', fields: addressFields())
            .trim(),
        _fixtureRegionOf(
          '// GOLDEN-ADDRESS-PATCH-START',
          '// GOLDEN-ADDRESS-PATCH-END',
        ),
        reason:
            'the runtime suite must exercise the real emitted Address patch — '
            'regenerate $_fixturePath if the emission changed on purpose',
      );
    });

    test('a nested Zorphy field is carried as a PatchNested', () {
      expect(emitted, contains('PatchNested<Address, AddressPatch>'));
      // The diff delegates to the nested patch instead of copying the
      // sub-entity wholesale.
      expect(emitted, contains('AddressPatch.diff('));
      // A nullable nested field only diffs when both sides carry a value.
      expect(emitted, contains('previousAddress != null'));
    });

    test('a List field is carried as an atomic whole-value replacement', () {
      // zorphy#248: a list field is replaced atomically, never edited by
      // positional index ops, so a concurrent list edit is an exact conflict.
      expect(emitted, contains('ListEquality<Object?>().equals('));
      expect(
        emitted,
        contains('changes.patchMap[Profile\$.tags] = next.tags;'),
      );
      expect(emitted, isNot(contains('ListPatchDelta<String>')));
      expect(emitted, isNot(contains('ListPatchDelta.diff<String>(')));
    });

    test('a Map field is carried as a MapPatchDelta', () {
      expect(emitted, contains('MapPatchDelta<String, int>'));
      expect(emitted, contains('MapPatchDelta.diff<String, int>('));
    });

    test('a scalar field still carries its value directly', () {
      expect(emitted, contains('changes.patchMap[Profile\$.id] = next.id;'));
      expect(emitted, contains('changes.patchMap[Profile\$.displayName]'));
    });

    test('the emitted patch is a Patch, the arm patchWith resolves', () {
      // PatchBase implements Patch<TEntity>, which is the arm a generated
      // patchWith applies a carried field through; a nested field carries a
      // PatchNested, which implements Patch<Sub> for the same reason.
      expect(
        emitted,
        contains(r'class ProfilePatch extends PatchBase<Profile, Profile$>'),
      );
      expect(emitted, contains('PatchNested<Address, AddressPatch>'));
    });

    test('a nullable list keeps the whole-value transition', () {
      // A list field is replaced atomically (zorphy#248): one content-equality
      // check covers both the both-present and the null-transition cases, so a
      // nullable `List<T>?` needs no two-phase diff. A MAP field stays a delta,
      // so its nullable whole-value transition is unchanged.
      final nullable = PatchEmitter().emit(
        className: 'Task',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('history', 'List<String>?', ''),
          NameTypeClassComment('index', 'Map<String, int>?', ''),
        ],
      );
      expect(
        nullable,
        contains(
          'ListEquality<Object?>().equals(previous.history, next.history)',
        ),
      );
      expect(
        nullable,
        contains('changes.patchMap[Task\$.history] = next.history;'),
      );
      expect(nullable, contains('previous.index != null &&'));
      expect(nullable, contains('before.index != null'));
    });

    test('invert restores the prior list and map state', () {
      expect(emitted, contains('undo.patchMap[Profile\$.tags] = before.tags;'));
      expect(emitted, contains('before.scores'));
    });
  });
}
