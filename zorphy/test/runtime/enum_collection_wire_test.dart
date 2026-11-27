// Runtime regression for issue #313's review findings: a collection of enums
// reproduced the same Gap-1 bug the PR fixed for a top-level enum field.
//
// The element-level `enumValue` branches in `BoundaryCodecEmitter` existed but
// were unreachable because `_classify` resolved element shapes through
// `_shapeOfType`, which had no enum detection. This suite compiles and EXECUTES
// the emitter's own output for `List<Enum>` and `Map<String, Enum>` fields,
// proving both directions of the round trip.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

ZorphyNodeIr _catalog() => ZorphyNodeIr(
  className: r'$Catalog',
  cleanName: 'Catalog',
  archetype: ArchetypeKind.entity,
  isSealedRoot: true,
  isAbstractIntermediate: false,
  isConcreteLeaf: true,
  superTypes: const [],
  directSubTypes: const [],
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: 'catalog',
  principalKey: 'id',
  replaySafe: null,
  isSyntheticLeaf: false,
  fields: const [
    ZorphyFieldIr(name: 'id', type: 'String'),
    ZorphyFieldIr(
      name: 'tiers',
      type: 'List<AccountTier>',
      enumElementTypes: {'AccountTier'},
    ),
    ZorphyFieldIr(
      name: 'labels',
      type: 'Map<String, AccountTier>',
      enumElementTypes: {'AccountTier'},
    ),
  ],
);

const _fields = <String, List<BoundaryField>>{
  r'$Catalog': [
    BoundaryField(name: 'id', type: 'String'),
    BoundaryField(
      name: 'tiers',
      type: 'List<AccountTier>',
      enumElementTypes: {'AccountTier'},
    ),
    BoundaryField(
      name: 'labels',
      type: 'Map<String, AccountTier>',
      enumElementTypes: {'AccountTier'},
    ),
  ],
};

String _indent(String source) =>
    source.trimRight().split('\n').map((l) => '  $l').join('\n');

String _codecSource() {
  const emitter = BoundaryCodecEmitter();
  return ZorphyEmitter().emitSpecs([
    emitter.fromWire(_catalog(), _fields),
    emitter.toWire(_catalog(), _fields),
  ]);
}

const _checks = r'''
void check(bool condition, String message) {
  if (!condition) throw StateError('FAILED: ' + message);
}

void main() {
  final catalog = Catalog.fromTrusted(
    id: 'c-1',
    tiers: <AccountTier>[AccountTier.free, AccountTier.pro],
    labels: <String, AccountTier>{'primary': AccountTier.enterprise},
  );

  // Encode writes NAMES into both collections and survives a JSON hop.
  final wire = catalog.toWire();
  check(wire['tiers'] is List, 'tiers is a wire list');
  check((wire['tiers'] as List).first == 'free', 'list element is a name');
  check((wire['labels'] as Map)['primary'] == 'enterprise',
      'map value is a name');
  final encoded = jsonEncode(wire);
  check(encoded.contains('"tiers":["free","pro"]'),
      'jsonEncode survives for a list of enums (got ' + encoded + ')');
  check(encoded.contains('"primary":"enterprise"'),
      'jsonEncode survives for a map of enums (got ' + encoded + ')');

  // Decode resolves those names back to constants.
  final back = Catalog.fromWire(wire);
  final ok = back.fold(
    (value) => value,
    (error) => throw StateError('decode failed: ' + error.toString()),
  );
  check(ok.tiers.length == 2, 'list length preserved');
  check(ok.tiers[0] == AccountTier.free && ok.tiers[1] == AccountTier.pro,
      'list elements resolve by name');
  check(ok.labels['primary'] == AccountTier.enterprise,
      'map value resolves by name');

  // An unknown name is a structured violation at the ELEMENT pointer.
  final bad = Catalog.fromWire(<String, Object?>{
    'id': 'c-1',
    'tiers': ['free', 'nope'],
    'labels': {'primary': 'nope'},
  });
  bad.fold(
    (_) => throw StateError('unknown enum names must not decode'),
    (error) {
      check(error.violations.any((v) => v.path == '/tiers[1]'),
          'list violation points at /tiers[1]');
      check(error.violations.any((v) => v.path == '/labels/primary'),
          'map violation points at /labels/primary');
    },
  );

  print('ALL ENUM COLLECTION CHECKS PASSED');
}
''';

String _buildProgram() => '''
$_annotationImport
import 'dart:convert';

enum AccountTier { free, pro, enterprise }

final class Catalog {
  const Catalog.fromTrusted({
    required this.id,
    required this.tiers,
    required this.labels,
  });

  final String id;
  final List<AccountTier> tiers;
  final Map<String, AccountTier> labels;

${_indent(_codecSource())}
}

${ZorphyEmitter().emitSpecs(BoundaryCodecEmitter.helperSpecs())}

$_checks
''';

void main() {
  test('collection-of-enum codec round-trips and reports element paths', () {
    final program = _buildProgram();

    final directory = Directory(
      'example/.dart_tool/zorphy_enum_collection_runtime',
    ).absolute..createSync(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final file = File('${directory.path}/enum_collection_program.dart')
      ..writeAsStringSync(program);

    final result = Process.runSync(
      Platform.resolvedExecutable,
      ['run', file.path],
      workingDirectory: 'example',
      stdoutEncoding: const SystemEncoding(),
      stderrEncoding: const SystemEncoding(),
    );

    final output = '${result.stdout}\n${result.stderr}';
    expect(
      result.exitCode,
      0,
      reason:
          'generated enum-collection program failed:\n$output\n---program---\n$program',
    );
    expect(output, contains('ALL ENUM COLLECTION CHECKS PASSED'));
  });
}
