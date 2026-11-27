// Runtime tests for issue #313: enum wire support end-to-end.
//
// The golden layer (`test/golden/enum_wire_golden_test.dart`) pins the SHAPE of
// the emitted source. This layer compiles and EXECUTES the emitter's real
// output for an enum-bearing entity, proving the two behaviours the issue asks
// for:
//
//   * `jsonEncode(entity.toWire())` survives (the enum is written as its NAME),
//     and `fromWire` resolves that name back to the constant — the round trip
//     the scalar reified `is` test broke (Gap 1).
//   * `MockData.single()` no longer throws for the required enum field, and
//     `MockData.list(count: n)` cycles through EVERY enum case (Gap 2).
//
// Like the other runtime suites, the program is the emitter's own output spliced
// into a tiny hand-shaped hierarchy; nothing in the mock/codec section is
// hand-written.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/emitters/mock_fixture_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';
import 'package:code_builder/code_builder.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

ZorphyNodeIr _account() => ZorphyNodeIr(
  className: r'$Account',
  cleanName: 'Account',
  archetype: ArchetypeKind.entity,
  isSealedRoot: true,
  isAbstractIntermediate: false,
  isConcreteLeaf: true,
  superTypes: const [],
  directSubTypes: const [],
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: 'account',
  principalKey: 'id',
  replaySafe: null,
  isSyntheticLeaf: false,
  fields: const [
    ZorphyFieldIr(name: 'id', type: 'String'),
    ZorphyFieldIr(
      name: 'tier',
      type: 'AccountTier',
      isEnum: true,
      enumValues: ['free', 'pro', 'enterprise'],
    ),
  ],
);

const _fields = <String, List<BoundaryField>>{
  r'$Account': [
    BoundaryField(name: 'id', type: 'String'),
    BoundaryField(name: 'tier', type: 'AccountTier', isEnum: true),
  ],
};

/// The codec members indented to sit inside the `Account` class body.
String _indent(String source) =>
    source.trimRight().split('\n').map((l) => '  $l').join('\n');

String _codecSource() {
  const emitter = BoundaryCodecEmitter();
  final methods = <Method>[
    emitter.fromWire(_account(), _fields),
    emitter.toWire(_account(), _fields),
  ];
  return ZorphyEmitter().emitSpecs(methods);
}

String _mockSource() => MockFixtureEmitter().emitForNode(_account());

String _helperSource() =>
    ZorphyEmitter().emitSpecs(BoundaryCodecEmitter.helperSpecs());

const _checks = r'''
void check(bool condition, String message) {
  if (!condition) throw StateError('FAILED: ' + message);
}

void main() {
  // ── Gap 1: toWire writes the NAME and jsonEncode survives ──────────
  final account = Account.fromTrusted(id: 'a1', tier: AccountTier.pro);
  final wire = account.toWire();
  check(wire['tier'] == 'pro', 'toWire writes the enum name (got ' + wire['tier'].toString() + ')');
  final encoded = jsonEncode(wire);
  check(encoded.contains('"tier":"pro"'), 'jsonEncode survives (got ' + encoded + ')');

  // ── Gap 1: fromWire resolves the name back to the constant ────────
  final decoded = Account.fromWire(<String, Object?>{'id': 'a1', 'tier': 'pro'});
  final ok = decoded.fold(
    (value) => value,
    (error) => throw StateError('decode failed: ' + error.toString()),
  );
  check(ok.tier == AccountTier.pro, 'fromWire resolves the name to the constant');
  check(ok.id == 'a1', 'fromWire keeps the other fields');

  // An unknown name is a structured violation at the field pointer, never a
  // cast or an uncaught error.
  final bad = Account.fromWire(<String, Object?>{'id': 'a1', 'tier': 'nope'});
  bad.fold(
    (_) => throw StateError('an unknown enum name must not decode'),
    (error) => check(
      error.violations.any((v) => v.path == '/tier'),
      'the violation points at /tier',
    ),
  );

  // ── Gap 2: MockData.single() no longer throws for the enum field ──
  final a = AccountMockData.single(seed: 0);
  check(a.tier == AccountTier.free, 'seed 0 -> first enum value');
  final b = AccountMockData.single(seed: 1);
  check(b.tier == AccountTier.pro, 'seed 1 -> second enum value');
  final c = AccountMockData.single(seed: 2);
  check(c.tier == AccountTier.enterprise, 'seed 2 -> third enum value');
  final d = AccountMockData.single(seed: 3);
  check(d.tier == AccountTier.free, 'seed 3 wraps to the first value');

  // ── Gap 2: list(count:) cycles through EVERY enum case ────────────
  final all = AccountMockData.list(count: AccountTier.values.length);
  final tiers = all.map((x) => x.tier).toSet();
  check(
    tiers.length == AccountTier.values.length,
    'list(count: values.length) covers every case (got ' + tiers.toString() + ')',
  );

  print('ALL ENUM WIRE CHECKS PASSED');
}
''';

String _buildProgram() =>
    '''
$_annotationImport
import 'dart:convert';

enum AccountTier { free, pro, enterprise }

final class Account {
  const Account.fromTrusted({required this.id, required this.tier});

  final String id;
  final AccountTier tier;

${_indent(_codecSource())}
}

${_helperSource()}

final class AccountPatch {
  final Map<String, Object?> changes = <String, Object?>{};
  AccountPatch withId(String value) {
    changes['id'] = value;
    return this;
  }

  AccountPatch withTier(AccountTier value) {
    changes['tier'] = value;
    return this;
  }
}

${_mockSource()}

$_checks
''';

void main() {
  test('emitted enum codec + mock data round-trip and cycle every case', () {
    final program = _buildProgram();

    final directory = Directory(
      'example/.dart_tool/zorphy_313_runtime',
    ).absolute..createSync(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final file = File('${directory.path}/enum_wire_program.dart')
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
          'generated enum-wire program failed:\n$output\n---program---\n$program',
    );
    expect(output, contains('ALL ENUM WIRE CHECKS PASSED'));
  });

  test('concrete-enum toJson/toWire analyzes clean under --fatal-infos (#335)', () {
    // The dev.5 colocated emitter wrote `tier is Enum ? tier.name : tier` for a
    // concrete-enum field — an always-true `is Enum` check plus a dead `: tier`
    // branch, two analyzer findings per field. A concrete enum's static type IS
    // the enum, so the value is always an `Enum`: the direct `.name` write must
    // produce ZERO `unnecessary_type_check` / `dead_code` under the repo's
    // fatal-infos posture.
    final program = _buildProgram();

    final directory = Directory(
      'example/.dart_tool/zorphy_335_analyze',
    ).absolute..createSync(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final file = File('${directory.path}/enum_wire_program.dart')
      ..writeAsStringSync(program);

    final analyze = Process.runSync(
      Platform.resolvedExecutable,
      ['analyze', '--fatal-infos', file.path],
      workingDirectory: 'example',
      stdoutEncoding: const SystemEncoding(),
      stderrEncoding: const SystemEncoding(),
    );
    final output = '${analyze.stdout}\n${analyze.stderr}';
    // The bug is exactly these two findings on the concrete-enum field; the
    // program's full helper set also trips unrelated `unused_element` warnings,
    // so scope the gate to the regression the issue names.
    expect(
      output,
      isNot(contains('unnecessary_type_check')),
      reason:
          'concrete-enum field emitted an always-true `is Enum` check:\n$output'
          '\n---program---\n$program',
    );
    expect(
      output,
      isNot(contains('dead_code')),
      reason:
          'concrete-enum field emitted a dead `: value` branch:\n$output'
          '\n---program---\n$program',
    );
    // And the direct write is what replaced the guard.
    expect(program, contains('this.tier.name'));
    expect(program, isNot(contains('this.tier is Enum')));
  });
}
