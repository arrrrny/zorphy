import 'dart:io';

import 'package:zorphy/src/common/name_type.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

void main() {
  final emitted = PolymorphicPatchEmitter().emitStandalone(
    name: 'PatchProbe',
    fields: [
      NameTypeClassComment('id', 'String', ''),
      NameTypeClassComment('title', 'String', ''),
      NameTypeClassComment('tags', 'List<String>', ''),
      NameTypeClassComment('scores', 'Map<String, int>', ''),
      NameTypeClassComment('counts', 'Map<int, int>', ''),
      NameTypeClassComment('status', 'PatchProbeStatus', '', isEnum: true),
      NameTypeClassComment('address', 'ProbeAddress', ''),
      NameTypeClassComment('previousAddress', 'ProbeAddress?', ''),
    ],
  );
  final fixture = File('test/runtime/fixtures/patch_contract.dart');
  final source = fixture.readAsStringSync();
  const startMarker = '// GOLDEN-PATCH-CONTRACT-START';
  const endMarker = '// GOLDEN-PATCH-CONTRACT-END';
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker);
  if (start < 0 || end < 0) {
    throw StateError('patch contract fixture markers are missing');
  }
  fixture.writeAsStringSync(
    '${source.substring(0, start)}$startMarker\n'
    '${emitted.trim()}\n'
    '${source.substring(end)}',
  );
}
