import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/common/name_type.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

const _fixturePath = 'test/runtime/fixtures/patch_contract.dart';
const _startMarker = '// GOLDEN-PATCH-CONTRACT-START';
const _endMarker = '// GOLDEN-PATCH-CONTRACT-END';

List<NameTypeClassComment> _patchProbeFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('title', 'String', ''),
  NameTypeClassComment('tags', 'List<String>', ''),
  NameTypeClassComment('scores', 'Map<String, int>', ''),
  NameTypeClassComment('counts', 'Map<int, int>', ''),
  NameTypeClassComment('status', 'PatchProbeStatus', '', isEnum: true),
  NameTypeClassComment('address', 'ProbeAddress', ''),
  NameTypeClassComment('previousAddress', 'ProbeAddress?', ''),
];

String _fixturePatchRegion() {
  final source = File(_fixturePath).readAsStringSync();
  final start = source.indexOf(_startMarker);
  final end = source.indexOf(_endMarker);
  expect(
    start,
    greaterThanOrEqualTo(0),
    reason: 'fixture must carry $_startMarker',
  );
  expect(
    end,
    greaterThanOrEqualTo(0),
    reason: 'fixture must carry $_endMarker',
  );
  return source.substring(start + _startMarker.length, end).trim();
}

void main() {
  group('v3 standalone patch golden', () {
    test('emitted patch matches the runtime fixture byte for byte', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'PatchProbe',
        fields: _patchProbeFields(),
      );
      expect(emitted.trim(), _fixturePatchRegion());
    });

    test('emits the v3 algebra and atomic collection surface', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'PatchProbe',
        fields: _patchProbeFields(),
      );

      expect(emitted, contains('static PatchProbePatch diff('));
      expect(emitted, contains('if (identical(previous, next))'));
      expect(
        emitted,
        contains('PatchProbe apply(covariant PatchProbe target)'),
      );
      expect(emitted, contains('if (isEmpty) return target;'));
      expect(emitted, contains('PatchProbePatch compose('));
      expect(emitted, contains('PatchProbePatch invert(PatchProbe before)'));
      expect(emitted, contains('Map<String, Object?> toWire()'));
      expect(emitted, contains('PatchProbePatch withTags(List<String> value)'));
      expect(emitted, isNot(contains('PatchBase')));
      expect(emitted, isNot(contains('PatchNested')));
      expect(emitted, isNot(contains('MapPatchDelta')));
      expect(emitted, isNot(contains('StringBuffer')));
      expect(emitted, isNot(contains('generatePatch')));
    });

    test('a fieldless entity still emits a usable v3 patch', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Marker',
        fields: const [],
      );
      expect(
        emitted,
        contains('final class MarkerPatch implements ZorphyPatch<Marker>'),
      );
      expect(emitted, contains('Marker apply(covariant Marker target)'));
    });
  });
}
