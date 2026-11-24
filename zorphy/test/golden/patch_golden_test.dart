// Golden tests for ISSUE-007 (zorphy#182) — the generated `<Name>Patch`.
//
// `PatchEmitter` is the single source of truth for the patch class body: the
// generator delegates to it, and `test/runtime/fixtures/account.dart` carries
// its output for the `Account` entity between GOLDEN-PATCH markers (so the
// runtime property suite exercises the REAL emitted code, not a hand-written
// lookalike).
//
// A change that alters the emitted patch fails here; regenerate the fixture
// deliberately when the emission is meant to change.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/patch_emitter.dart';

const _fixturePath = 'test/runtime/fixtures/account.dart';

const _startMarker = '// GOLDEN-PATCH-START';
const _endMarker = '// GOLDEN-PATCH-END';

/// The `Account` entity's fields, in declaration order.
List<NameTypeClassComment> _accountFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('name', 'String', ''),
  NameTypeClassComment('score', 'int', ''),
  NameTypeClassComment('note', 'String?', ''),
  NameTypeClassComment('tier', 'AccountTier', '', isEnum: true),
];

/// The patch region of the fixture, markers included cues trimmed.
String _fixturePatchRegion() {
  final source = File(_fixturePath).readAsStringSync();
  final start = source.indexOf(_startMarker);
  final end = source.indexOf(_endMarker);
  expect(start, isNot(-1), reason: 'fixture must carry $_startMarker');
  expect(end, isNot(-1), reason: 'fixture must carry $_endMarker');
  return source.substring(start + _startMarker.length, end).trim();
}

void main() {
  group('ISSUE-007 PatchEmitter golden', () {
    test('emitted patch matches the runtime fixture byte for byte', () {
      final emitted = PatchEmitter().emit(
        className: 'Account',
        fields: _accountFields(),
      );
      expect(
        emitted.trim(),
        _fixturePatchRegion(),
        reason:
            'the runtime property suite must exercise the real emitted patch — '
            'regenerate $_fixturePath if the emission changed on purpose',
      );
    });

    test('emits the algebra surface the issue names', () {
      final emitted = PatchEmitter().emit(
        className: 'Account',
        fields: _accountFields(),
      );

      // Static O(1) diff with the identical() fast path.
      expect(emitted, contains('static AccountPatch diff('));
      expect(emitted, contains('if (identical(previous, next))'));
      expect(emitted, contains('return const AccountPatch.empty();'));

      // Zero-copy apply.
      expect(emitted, contains('Account apply(Account target)'));
      expect(emitted, contains('if (isEmpty) return target;'));

      // Algebra members.
      expect(emitted, contains('bool get isEmpty'));
      expect(emitted, contains('AccountPatch compose('));
      expect(emitted, contains('AccountPatch invert(Account before)'));
      expect(emitted, contains('Map<String, Object?> toWire()'));

      // Legacy fluent surface stays (source compatibility).
      expect(emitted, contains('AccountPatch withName(String? value)'));

      // The issue's hard rules: no presets/toggles, no StringBuffer here.
      expect(emitted, isNot(contains('generatePatch')));
    });

    test('a fieldless entity still emits a usable patch', () {
      final emitted = PatchEmitter().emit(
        className: 'Marker',
        fields: const [],
      );
      expect(
        emitted,
        contains(r'class MarkerPatch extends PatchBase<Marker, Marker$>'),
      );
      expect(emitted, contains('Marker apply(Marker target)'));
      expect(emitted, contains('MarkerPatch() : super();'));
    });
  });
}
