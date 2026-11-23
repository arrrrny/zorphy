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
List<NameTypeClassComment> _profileFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('displayName', 'String', ''),
  NameTypeClassComment('address', 'Address', ''),
  NameTypeClassComment('tags', 'List<String>', ''),
  NameTypeClassComment('scores', 'Map<String, int>', ''),
  NameTypeClassComment('previousAddress', 'Address?', ''),
];

/// The patch region of the fixture, markers excluded.
String _fixturePatchRegion() {
  final source = File(_fixturePath).readAsStringSync();
  final start = source.indexOf(_startMarker);
  final end = source.indexOf(_endMarker);
  expect(start, isNot(-1), reason: 'fixture must carry $_startMarker');
  expect(end, isNot(-1), reason: 'fixture must carry $_endMarker');
  return source.substring(start + _startMarker.length, end).trim();
}

void main() {
  group('ISSUE-008 PatchEmitter golden', () {
    late String emitted;

    setUp(() {
      emitted = PatchEmitter().emit(
        className: 'Profile',
        fields: _profileFields(),
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

    test('a nested Zorphy field is carried as a PatchNested', () {
      expect(emitted, contains('PatchNested<Address, AddressPatch>'));
      // The diff delegates to the nested patch instead of copying the
      // sub-entity wholesale.
      expect(emitted, contains('AddressPatch.diff('));
      // A nullable nested field only diffs when both sides carry a value.
      expect(emitted, contains('previousAddress != null'));
    });

    test('a List field is carried as a ListPatchDelta', () {
      expect(emitted, contains('ListPatchDelta<String>'));
      expect(emitted, contains('ListPatchDelta.diff<String>('));
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

    test('invert captures the prior collection state', () {
      expect(emitted, contains('ListPatchDelta.diff<String>('));
      expect(emitted, contains('before.tags'));
      expect(emitted, contains('before.scores'));
    });
  });
}
