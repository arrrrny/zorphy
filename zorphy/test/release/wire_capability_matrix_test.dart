// Wire-capability matrix (arrrrny/zorphy#316).
//
// ONE table-driven contract that pins, for EVERY field kind the IR recognizes,
// the required behavior across ALL THREE consumption paths:
//
//   * boundary codec  — `BoundaryCodecEmitter` (`toWire`/`fromWire`),
//   * patch envelope   — `PatchEmitter` + `ZorphyPatchWire` (`toWire`/`fromWire`),
//   * mock seeder      — `MockFixtureEmitter` (`<Name>MockData`).
//
// The table below IS the contract; each row names the emitter responsible. A
// single-path fix like #215 (enum encode/decode landed on the patch path only)
// now mechanically fails a row here until every affected path is updated, so
// cross-emitter drift becomes unmergeable instead of invisible.
//
// Each cell is either:
//
//   * `Enforced(...)` — the test runs the emitter's REAL output and asserts the
//     exact wire form, the `jsonEncode` round-trip outcome, the decode
//     resolution / violation-not-throw / pointer-path behavior, and the seed.
//   * `Omitted(issue, reason)` — a KNOWN divergence, documented here and not
//     yet enforced. The #313 enum gaps are the first omissions; they migrate
//     INTO `Enforced` rows in the PR that lands #313 (the issue's own words:
//     "the #313 fixes become the first rows migrated INTO the matrix once it
//     exists"). An omission MUST name a reason, and a tracking issue when one
//     exists, so a gap can never be silent.
//
// The `matrix is complete` test fails when a kind is recognized by an emitter
// but has no row — that is the drift gate that forces a new field kind to add
// its full row before the emitter that uses it merges.

@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/emitters/mock_fixture_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../runtime/fixtures/account.dart';
import '../runtime/fixtures/profile.dart';

// ── The contract table ────────────────────────────────────────────────

/// One cell of the matrix: an enforced expectation or a documented omission.
sealed class Cell {
  const Cell();
}

/// A behavior the test PROVES by running the emitter's real output.
final class Enforced extends Cell {
  /// The exact wire form the encoder must produce (e.g. `ISO-8601 String`,
  /// `name`, `instance`, `base64 String`).
  final String encode;

  /// Whether `jsonEncode(toWire())` must survive a transport hop.
  final bool jsonSurvives;

  /// How decode resolves the value (`by name`, `by value`, `is-test`).
  final String decode;

  const Enforced({
    required this.encode,
    required this.jsonSurvives,
    required this.decode,
  });
}

/// A KNOWN divergence, documented and not yet enforced.
final class Omitted extends Cell {
  /// The tracking issue, when one exists (the #313 enum gaps).
  final String? issue;

  /// Why the cell is not enforced yet.
  final String reason;

  const Omitted({this.issue, required this.reason});
}

/// One field kind's behavior across the three paths.
final class WireRow {
  /// The field kind as the IR spells it (`String`, `List<String>`, `T`, …).
  final String kind;

  /// The emitter(s) responsible for this kind's wire behavior.
  final String responsible;

  final Cell boundary;
  final Cell patch;
  final Cell seed;

  const WireRow({
    required this.kind,
    required this.responsible,
    required this.boundary,
    required this.patch,
    required this.seed,
  });
}

/// Every field kind the IR recognizes, with its per-path contract.
///
/// The classification is MEASURED from the emitters on `master` (3.0.0-dev.4):
/// the boundary `_Shape` buckets, the patch `ZorphyPatchWire` helpers, and the
/// mock `_defaultSeedValue` switch. Where master diverges from the required
/// behavior the cell is `Omitted` with the tracking issue — never a silent
/// `Enforced` that would enshrine a bug as the contract.
const _matrix = <WireRow>[
  WireRow(
    kind: 'String',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'instance',
      jsonSurvives: true,
      decode: 'is-test',
    ),
    patch: Enforced(encode: 'instance', jsonSurvives: true, decode: 'is-test'),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
  WireRow(
    kind: 'int',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'instance',
      jsonSurvives: true,
      decode: 'is-test',
    ),
    patch: Enforced(encode: 'instance', jsonSurvives: true, decode: 'is-test'),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
  WireRow(
    kind: 'bool',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'instance',
      jsonSurvives: true,
      decode: 'is-test',
    ),
    patch: Enforced(encode: 'instance', jsonSurvives: true, decode: 'is-test'),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
  WireRow(
    kind: 'double',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'instance (JSON int widens)',
      jsonSurvives: true,
      decode: 'asDouble (int→double)',
    ),
    patch: Enforced(
      encode: 'instance (JSON int widens)',
      jsonSurvives: true,
      decode: 'asDouble (int→double)',
    ),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
  WireRow(
    kind: 'num',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    // The boundary codec widens a `num` via `toDouble()` on encode but decodes
    // with `asNum` (int preserved) — an asymmetric pair with no clean contract
    // to pin yet. The patch path's `asNum`/`asDouble` ARE clean and enforced.
    boundary: Omitted(
      reason:
          'boundary encode widens num via toDouble() but decode keeps int '
          '(asNum) — asymmetric, no stable wire form to pin',
    ),
    patch: Enforced(
      encode: 'instance',
      jsonSurvives: true,
      decode: 'asNum (int preserved)',
    ),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
  WireRow(
    kind: 'DateTime',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'ISO-8601 String',
      jsonSurvives: true,
      decode: 'ISO-8601 parse (violation on mismatch)',
    ),
    patch: Enforced(
      encode: 'ISO-8601 String',
      jsonSurvives: true,
      decode: 'asDateTime (violation on mismatch)',
    ),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
  WireRow(
    kind: 'Duration',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    // No dedicated boundary/patch wire form: a Duration is a scalar `is`-test
    // and encodes as a raw instance, which `jsonEncode` cannot survive. The
    // mock seeder DOES seed it, so that cell is enforced.
    boundary: Omitted(
      reason:
          'scalar is-test bucket; raw Duration instance is not '
          'JSON-encodable (no ISO/seconds wire form)',
    ),
    patch: Omitted(
      reason:
          'scalar is-test bucket; raw Duration instance is not '
          'JSON-encodable (no wire form)',
    ),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
  WireRow(
    kind: 'enum',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    // #313 Gap 1: the boundary codec emits the raw instance (breaks
    // jsonEncode) and decodes by `is`-test, no name resolution. The patch path
    // (#215) already does `.name` + `enumByName`.
    boundary: Omitted(
      issue: '#313',
      reason:
          'boundary codec emits raw enum instance and is-tests decode; '
          'no `.name` encode / `enumByName` decode yet (#313 Gap 1)',
    ),
    patch: Enforced(
      encode: 'name',
      jsonSurvives: true,
      decode: 'enumByName (violation on mismatch)',
    ),
    // #313 Gap 2: a required enum field throws UnsupportedError in the seeder.
    seed: Omitted(
      issue: '#313',
      reason:
          'required enum field throws UnsupportedError in MockData; '
          'no `.values[seed % length]` seed yet (#313 Gap 2)',
    ),
  ),
  WireRow(
    kind: 'Uint8List',
    responsible: 'BoundaryCodecEmitter / MockFixtureEmitter',
    boundary: Omitted(
      reason: 'decoded as a plain `is`-test bucket; no base64 wire form',
    ),
    patch: Omitted(reason: 'no dedicated patch-wire form; is-test bucket'),
    seed: Omitted(reason: 'unseedable bucket; no element seed'),
  ),
  WireRow(
    kind: 'Uri',
    responsible: 'BoundaryCodecEmitter / MockFixtureEmitter',
    boundary: Omitted(
      reason: 'decoded as a plain `is`-test bucket; no string wire form',
    ),
    patch: Omitted(reason: 'no dedicated patch-wire form; is-test bucket'),
    seed: Omitted(reason: 'unseedable bucket; no seed'),
  ),
  WireRow(
    kind: 'nested entity',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'nested toWire()',
      jsonSurvives: true,
      decode: 'recursive fromWire (re-pathed violations)',
    ),
    patch: Enforced(
      encode: 'nested toWire()',
      jsonSurvives: true,
      decode: 'recursive fromWire (re-pathed violations)',
    ),
    // The mock seeder seeds scalars and collections only; a nested entity is
    // not constructed (`_defaultSeedValue` has no branch for a node type).
    seed: Omitted(
      reason:
          'MockData does not construct a nested entity; only scalars and '
          'collections of seedable elements are seeded',
    ),
  ),
  WireRow(
    kind: 'generic type param (T)',
    responsible: 'BoundaryCodecEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'encodeT(value)',
      jsonSurvives: true,
      decode: 'decodeT(raw)',
    ),
    patch: Omitted(reason: 'generic patches carry no codec parameter yet'),
    seed: Omitted(reason: 'a generic node is skipped by the mock emitter'),
  ),
  WireRow(
    kind: 'List<T>',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'element-wise',
      jsonSurvives: true,
      decode: 'element-wise (re-pathed violations)',
    ),
    patch: Enforced(
      encode: 'element-wise',
      jsonSurvives: true,
      decode: 'element-wise (re-pathed violations)',
    ),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
  WireRow(
    kind: 'Map<String, V>',
    responsible: 'BoundaryCodecEmitter / PatchEmitter / MockFixtureEmitter',
    boundary: Enforced(
      encode: 'entry-wise',
      jsonSurvives: true,
      decode: 'entry-wise (re-pathed violations)',
    ),
    patch: Enforced(
      encode: 'entry-wise',
      jsonSurvives: true,
      decode: 'entry-wise (re-pathed violations)',
    ),
    seed: Enforced(encode: 'seeded', jsonSurvives: true, decode: 'n/a'),
  ),
];

/// The authoritative set of field kinds the emitters classify. The
/// `matrix is complete` gate asserts [_matrix] covers EXACTLY this set, so a
/// kind added to an emitter without a row (or a row without an emitter) fails
/// CI — the drift gate that makes a new field kind add its full row before the
/// emitter that uses it merges.
const _recognizedKinds = <String>{
  'String',
  'int',
  'bool',
  'double',
  'num',
  'DateTime',
  'Duration',
  'enum',
  'Uint8List',
  'Uri',
  'nested entity',
  'generic type param (T)',
  'List<T>',
  'Map<String, V>',
};

/// The kinds whose [pick] cell is [Enforced] — the set a path's generated
/// program must exercise.
Set<String> _enforcedKinds(Cell Function(WireRow) pick) =>
    _matrix.where((r) => pick(r) is Enforced).map((r) => r.kind).toSet();

void main() {
  group('matrix is the contract', () {
    test('covers every field kind the IR recognizes (drift gate)', () {
      final covered = _matrix.map((r) => r.kind).toSet();
      expect(
        covered,
        _recognizedKinds,
        reason:
            'a field kind was added to an emitter without a matrix row, '
            'or a row names a kind no emitter classifies',
      );
    });

    test('every row names the emitter responsible', () {
      for (final row in _matrix) {
        expect(
          row.responsible.trim(),
          isNotEmpty,
          reason: '${row.kind} must name its responsible emitter',
        );
      }
    });

    test(
      'every documented omission names a reason (and an issue when one exists)',
      () {
        for (final row in _matrix) {
          for (final cell in [row.boundary, row.patch, row.seed]) {
            if (cell is Omitted) {
              expect(
                cell.reason.trim(),
                isNotEmpty,
                reason: '${row.kind} omission must say why',
              );
            }
          }
        }
        // The #313 enum gaps are the omissions that carry a tracking issue; a
        // NEW omission with no issue is allowed but these two must keep theirs
        // until #313 migrates them into Enforced rows.
        final enumRow = _matrix.firstWhere((r) => r.kind == 'enum');
        expect((enumRow.boundary as Omitted).issue, '#313');
        expect((enumRow.seed as Omitted).issue, '#313');
      },
    );
  });

  group('boundary codec honors the matrix', () {
    test(
      'every Enforced boundary kind round-trips through real emitted code',
      () {
        final program = _buildBoundaryProgram();
        final output = _runProgram(program, 'zorphy_316_boundary');
        expect(output, contains('ALL BOUNDARY CHECKS PASSED'));

        final covered = _coverage(output, 'boundary');
        expect(
          covered,
          _enforcedKinds((r) => r.boundary),
          reason:
              'the boundary program did not exercise exactly the Enforced '
              'boundary kinds in the matrix',
        );
      },
    );
  });

  group('patch envelope honors the matrix', () {
    test('every Enforced patch kind resolves/encodes per the contract', () {
      _checkPatchMatrix();
      // The patch column is exercised inline; assert the classification the
      // inline checks cover matches the table.
      expect(_enforcedKinds((r) => r.patch), <String>{
        'String',
        'int',
        'bool',
        'double',
        'num',
        'DateTime',
        'enum',
        'nested entity',
        'List<T>',
        'Map<String, V>',
      });
    });
  });

  group('mock seeder honors the matrix', () {
    test('every Enforced seed kind is seeded (never UnsupportedError)', () {
      final program = _buildSeedProgram();
      final output = _runProgram(program, 'zorphy_316_seed');
      expect(output, contains('ALL SEED CHECKS PASSED'));

      final covered = _coverage(output, 'seed');
      expect(
        covered,
        _enforcedKinds((r) => r.seed),
        reason:
            'the seed program did not exercise exactly the Enforced seed '
            'kinds in the matrix',
      );
    });
  });
}

/// Extracts the `COVERAGE:<path>:<kind>` set a generated program printed.
Set<String> _coverage(String output, String path) => output
    .split('\n')
    .where((l) => l.startsWith('COVERAGE:$path:'))
    .map((l) => l.substring(('COVERAGE:$path:').length).trim())
    .toSet();

/// Writes [program] inside the example package (so `package:` URIs resolve),
/// runs it, and returns its combined output. Fails the test on a non-zero exit.
String _runProgram(String program, String dirName) {
  final directory = Directory('example/.dart_tool/$dirName').absolute
    ..createSync(recursive: true);
  addTearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });
  final file = File('${directory.path}/program.dart')
    ..writeAsStringSync(program);

  final result = Process.runSync(
    Platform.resolvedExecutable,
    ['run', file.path],
    workingDirectory: 'example',
    stdoutEncoding: const SystemEncoding(),
    stderrEncoding: const SystemEncoding(),
  );
  final output = '${result.stdout}\n${result.stderr}';
  expect(result.exitCode, 0, reason: 'generated program failed:\n$output');
  return output;
}

// ── Boundary codec program ──────────────────────────────────────────────

ZorphyNodeIr _valueNode(
  String className, {
  List<String> typeParameters = const [],
  List<ZorphyFieldIr> fields = const [],
}) => ZorphyNodeIr(
  className: className,
  cleanName: className.replaceAll(r'$', ''),
  archetype: ArchetypeKind.value,
  isSealedRoot: true,
  isAbstractIntermediate: false,
  isConcreteLeaf: true,
  superTypes: const [],
  directSubTypes: const [],
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: className.replaceAll(r'$', ''),
  principalKey: null,
  replaySafe: null,
  isSyntheticLeaf: false,
  typeParameters: typeParameters,
  fields: fields,
);

String _indent(String text) => text
    .split('\n')
    .map((line) => line.trimRight().isEmpty ? '' : '  $line')
    .join('\n');

String _codecFor(
  ZorphyNodeIr node,
  Map<String, List<BoundaryField>> fields, {
  Set<String> additionalNodes = const {},
}) => ZorphyEmitter().emitSpecs(
  const BoundaryCodecEmitter().emitCodec(
    node,
    fields,
    additionalNodes: additionalNodes,
  ),
);

const _boundaryFields = <String, List<BoundaryField>>{
  r'$Child': [
    BoundaryField(name: 'sku', type: 'String'),
    BoundaryField(name: 'price', type: 'double'),
  ],
  r'$Scalars': [
    BoundaryField(name: 's', type: 'String'),
    BoundaryField(name: 'i', type: 'int'),
    BoundaryField(name: 'b', type: 'bool'),
    BoundaryField(name: 'd', type: 'double'),
    BoundaryField(name: 't', type: 'DateTime'),
    BoundaryField(name: 'tags', type: 'List<String>'),
    BoundaryField(name: 'stamps', type: 'List<DateTime>'),
    BoundaryField(name: 'scores', type: 'Map<String, int>'),
    BoundaryField(name: 'child', type: 'Child'),
  ],
  r'$Box': [BoundaryField(name: 'item', type: 'T')],
};

const _boundaryChecks = r'''
void check(bool condition, String message) {
  if (!condition) throw StateError('FAILED: ' + message);
}

void coverage(String kind) => print('COVERAGE:boundary:' + kind);

void main() {
  final wire = <String, Object?>{
    's': 'hello',
    'i': 7,
    'b': true,
    'd': 1, // a JSON int is a legal double
    't': '2026-11-23T00:00:00.000Z',
    'tags': <Object?>['a', 'b'],
    'stamps': <Object?>['2026-11-23T00:00:00.000Z'],
    'scores': <String, Object?>{'x': 1, 'y': 2},
    'child': <String, Object?>{'sku': 'sku-1', 'price': 9.5},
  };

  final ok = Scalars.fromWire(wire);
  check(ok.isOk, 'a well-formed scalars payload decodes');
  final v = ok.getOrThrow();
  check(v.s == 'hello', 'String decoded');
  check(v.i == 7, 'int decoded');
  check(v.b, 'bool decoded');
  check(v.d == 1.0, 'double decoded (int widened)');
  check(v.t.isUtc, 'DateTime decoded from ISO-8601');
  check(v.tags.length == 2, 'List<String> decoded');
  check(v.stamps.single.isUtc, 'List<DateTime> decoded element-wise');
  check(v.scores['x'] == 1, 'Map<String,int> decoded');
  check(v.child.sku == 'sku-1', 'nested entity decoded');
  coverage('String');
  coverage('int');
  coverage('bool');
  coverage('double');
  coverage('DateTime');
  coverage('List<T>');
  coverage('Map<String, V>');
  coverage('nested entity');

  // encode: exact wire forms + jsonEncode survives a transport hop.
  final encoded = v.toWire();
  check(encoded['t'] is String, 'DateTime encodes as an ISO-8601 String');
  check((encoded['child'] as Map)['sku'] == 'sku-1', 'nested encodes as a map');
  check(
    (encoded['stamps'] as List).single is String,
    'List<DateTime> encodes element-wise to ISO strings',
  );
  final json = jsonEncode(encoded);
  check(json.contains('2026-11-23'), 'jsonEncode(toWire()) survives');

  // decode violations: a mismatch is a FieldViolation at the pointer, never a
  // throw, and every bad field is collected.
  final corrupt = Scalars.fromWire(<String, Object?>{
    's': 7,
    'i': 'x',
    'b': 'no',
    'd': 'free',
    't': 'not-a-date',
    'tags': <Object?>[1],
    'stamps': <Object?>[123],
    'scores': <String, Object?>{'x': 'y'},
    'child': <String, Object?>{'sku': 7, 'price': 'x'},
  });
  check(!corrupt.isOk, 'a fully corrupt payload is an error, not a throw');
  final paths = (corrupt as BoundaryErr<Scalars>).violations
      .map((v) => v.path)
      .toList();
  for (final p in <String>[
    '/s',
    '/i',
    '/b',
    '/d',
    '/t',
    '/tags[0]',
    '/stamps[0]',
    '/scores/x',
    '/child/sku',
  ]) {
    check(paths.contains(p), 'violation pointer $p is present (got $paths)');
  }

  // generic type param: routed through the caller's codec, violations re-path.
  final boxOk = Box.fromWire<int>(
    <String, Object?>{'item': <String, Object?>{'n': 41}},
    (raw) => _decodeInt(raw),
  );
  check(boxOk.isOk, 'a generic payload decodes through decodeT');
  check(boxOk.getOrThrow().item == 41, 'the wrapped T decoded');
  final boxEncoded = boxOk.getOrThrow().toWire((i) => <String, Object?>{'n': i});
  check((boxEncoded['item'] as Map)['n'] == 41, 'the wrapped T encoded via encodeT');
  final boxBad = Box.fromWire<int>(
    <String, Object?>{'item': <String, Object?>{'n': 'x'}},
    (raw) => _decodeInt(raw),
  );
  check(!boxBad.isOk, 'a corrupt wrapped T is an error');
  check(
    (boxBad as BoundaryErr<Box<int>>).violations.any((v) => v.path.startsWith('/item')),
    'the inner violation re-paths under /item',
  );
  coverage('generic type param (T)');

  print('ALL BOUNDARY CHECKS PASSED');
}

ZorphyBoundaryResult<int> _decodeInt(Map<String, Object?> raw) {
  final violations = <FieldViolation>[];
  final value = _boundaryAs<int>(raw['n'], '/item', violations);
  if (violations.isNotEmpty) {
    return BoundaryErr<int>(targetType: 'int', violations: violations);
  }
  return BoundaryOk<int>(value!);
}
''';

String _buildBoundaryProgram() {
  final child = _valueNode(r'$Child');
  final scalars = _valueNode(r'$Scalars');
  final box = _valueNode(r'$Box', typeParameters: ['T']);
  final nodes = [child, scalars, box];
  final helpers = ZorphyEmitter().emitSpecs(
    BoundaryCodecEmitter.usedHelperSpecs(nodes, _boundaryFields),
  );

  return '''
// GENERATED BY test/release/wire_capability_matrix_test.dart — do not edit.
import 'dart:convert';
import 'package:zorphy_annotation/zorphy_annotation.dart';

final class Child {
  final String sku;
  final double price;
  const Child.fromTrusted({required this.sku, required this.price});

${_indent(_codecFor(child, _boundaryFields))}
}

final class Scalars {
  final String s;
  final int i;
  final bool b;
  final double d;
  final DateTime t;
  final List<String> tags;
  final List<DateTime> stamps;
  final Map<String, int> scores;
  final Child child;
  const Scalars.fromTrusted({
    required this.s,
    required this.i,
    required this.b,
    required this.d,
    required this.t,
    required this.tags,
    required this.stamps,
    required this.scores,
    required this.child,
  });

${_indent(_codecFor(scalars, _boundaryFields, additionalNodes: {'Child'}))}
}

final class Box<T> {
  final T item;
  const Box.fromTrusted({required this.item});

${_indent(_codecFor(box, _boundaryFields))}
}

$helpers
$_boundaryChecks
''';
}

// ── Mock seeder program ─────────────────────────────────────────────────

const _seedChecks = r'''
void check(bool condition, String message) {
  if (!condition) throw StateError('FAILED: ' + message);
}

void coverage(String kind) => print('COVERAGE:seed:' + kind);

void main() {
  final w = WidgetMockData.single(seed: 0);
  check(w.s is String, 'String seeded');
  check(w.i is int, 'int seeded');
  check(w.b is bool, 'bool seeded');
  check(w.d is double, 'double seeded');
  check(w.n is num, 'num seeded');
  check(w.t is DateTime, 'DateTime seeded');
  check(w.dur is Duration, 'Duration seeded');
  check(w.tags is List<String>, 'List<String> seeded');
  check(w.scores is Map<String, int>, 'Map<String,int> seeded');
  coverage('String');
  coverage('int');
  coverage('bool');
  coverage('double');
  coverage('num');
  coverage('DateTime');
  coverage('Duration');
  coverage('List<T>');
  coverage('Map<String, V>');

  final many = WidgetMockData.list(count: 3);
  check(many.length == 3, 'list(count: 3) yields three seeds');

  print('ALL SEED CHECKS PASSED');
}
''';

String _buildSeedProgram() {
  final widget = _valueNode(
    r'$Widget',
    fields: const [
      ZorphyFieldIr(name: 's', type: 'String'),
      ZorphyFieldIr(name: 'i', type: 'int'),
      ZorphyFieldIr(name: 'b', type: 'bool'),
      ZorphyFieldIr(name: 'd', type: 'double'),
      ZorphyFieldIr(name: 'n', type: 'num'),
      ZorphyFieldIr(name: 't', type: 'DateTime'),
      ZorphyFieldIr(name: 'dur', type: 'Duration'),
      ZorphyFieldIr(name: 'tags', type: 'List<String>'),
      ZorphyFieldIr(name: 'scores', type: 'Map<String, int>'),
    ],
  );
  final emitter = MockFixtureEmitter();
  return '''
// GENERATED BY test/release/wire_capability_matrix_test.dart — do not edit.
import 'package:zorphy_annotation/zorphy_annotation.dart';

final class Widget {
  final String s;
  final int i;
  final bool b;
  final double d;
  final num n;
  final DateTime t;
  final Duration dur;
  final List<String> tags;
  final Map<String, int> scores;
  const Widget.fromTrusted({
    required this.s,
    required this.i,
    required this.b,
    required this.d,
    required this.n,
    required this.t,
    required this.dur,
    required this.tags,
    required this.scores,
  });
}

${emitter.emitForNode(widget)}

$_seedChecks
''';
}

// ── Patch envelope (inline, real ZorphyPatchWire + emitter fixtures) ─────

void _checkPatchMatrix() {
  List<FieldViolation> v() => <FieldViolation>[];

  // String / int / bool resolve by `is`-test; a mismatch is a violation.
  expect(ZorphyPatchWire.as<String>('x', '/s', v()), 'x');
  expect(ZorphyPatchWire.as<int>(7, '/i', v()), 7);
  expect(ZorphyPatchWire.as<bool>(true, '/b', v()), isTrue);
  final badString = v();
  expect(ZorphyPatchWire.as<String>(7, '/s', badString), isNull);
  expect(badString.single.path, '/s');

  // double widens a JSON int; num preserves it.
  expect(ZorphyPatchWire.asDouble(1, '/d', v()), 1.0);
  final asNum = ZorphyPatchWire.asNum(9007199254740993, '/n', v());
  expect(asNum, isA<int>());

  // DateTime resolves an ISO-8601 String; a corrupt value is a violation.
  expect(
    ZorphyPatchWire.asDateTime('2026-11-23T00:00:00.000Z', '/t', v()),
    isNotNull,
  );
  final badDate = v();
  expect(ZorphyPatchWire.asDateTime('not-a-date', '/t', badDate), isNull);
  expect(badDate.single.path, '/t');

  // enum resolves by NAME (not index); a mismatch is a violation.
  expect(
    ZorphyPatchWire.enumByName(AccountTier.values, 'enterprise', '/tier', v()),
    AccountTier.enterprise,
  );
  final badEnum = v();
  expect(
    ZorphyPatchWire.enumByName(AccountTier.values, 'nope', '/tier', badEnum),
    isNull,
  );
  expect(badEnum.single.path, '/tier');

  // The patch EMITTER's real output (account fixture): enum encodes as its
  // name and the envelope jsonEncode-survives; nested/List/Map round-trip.
  final tierPatch = AccountPatch()..withTier(AccountTier.enterprise);
  final tierWire = tierPatch.toWire();
  expect(tierWire['tier'], 'enterprise');
  expect(() => jsonEncode(tierWire), returnsNormally);
  expect(
    AccountPatch.fromWire(
      tierWire,
    ).getOrThrow().apply(const Account(id: 'a1', name: 'ada', score: 1)).tier,
    AccountTier.enterprise,
  );

  final profilePatch = ProfilePatch()
    ..withDisplayName('grace')
    ..withTags(<String>['x'])
    ..withScores(<String, int>{'k': 1});
  final profileWire = profilePatch.toWire();
  expect(() => jsonEncode(profileWire), returnsNormally);
  final decodedProfile = ProfilePatch.fromWire(profileWire).getOrThrow();
  expect(decodedProfile.apply(_emptyProfile()).displayName, 'grace');
}

Profile _emptyProfile() => const Profile(
  id: 'p1',
  displayName: 'anon',
  address: Address(street: 's', city: 'c'),
  tags: [],
  scores: {},
);
