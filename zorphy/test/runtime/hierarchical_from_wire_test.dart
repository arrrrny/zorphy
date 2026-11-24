// Runtime tests for ISSUE-013 (arrrrny/zorphy#188):
// hierarchical `fromWire` / `toWire` on corrupt input.
//
// The golden layer (`test/golden/boundary_codec_golden_test.dart`) pins the
// SHAPE of the emitted code. This layer proves its BEHAVIOUR, which is what
// the issue's acceptance gate actually asks for:
//
//   > Zero uncaught `TypeError` or `CastError` on arbitrary corrupt
//   > `Map<String, Object?>` inputs across polymorphic hierarchies.
//
// That cannot be proven from inside the zorphy test package: the emitted
// members need a class hierarchy to live in AND `package:zorphy_annotation` in
// scope. So this test composes a complete tiny program — minimal hand-shaped
// classes with the EMITTER'S REAL output spliced into their bodies, nothing
// hand-written into the codec — and runs it. A non-zero exit, or a thrown
// `TypeError`/`CastError` inside the program, fails the test.
//
// The fixture mirrors the issue's own example hierarchy:
//
//   $Notification -> $OrderNotification | $PriceDropNotification
//
// The `$`-prefixed names are the DECLARED names zorphy uses; generated classes
// drop the prefix, which is exactly the split `ZorphyNodeIr.cleanName`
// encodes.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyNodeIr _node({
  required String className,
  bool isSealedRoot = false,
  List<ZorphyNodeIr> children = const [],
  List<ZorphyNodeIr> superTypes = const [],
  String discriminatorValue = '',
  String? principalKey,
}) => ZorphyNodeIr(
  className: className,
  cleanName: className.replaceAll(r'$', ''),
  archetype: ArchetypeKind.entity,
  isSealedRoot: isSealedRoot,
  isAbstractIntermediate: superTypes.isNotEmpty && children.isNotEmpty,
  isConcreteLeaf: children.isEmpty,
  superTypes: superTypes,
  directSubTypes: children,
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: discriminatorValue,
  principalKey: principalKey,
  replaySafe: null,
  isSyntheticLeaf: false,
);

const _known = {'Notification', 'OrderNotification', 'PriceDropNotification'};

const _fields = <String, List<BoundaryField>>{
  r'$Notification': [
    BoundaryField(name: 'id', type: 'String'),
    BoundaryField(name: 'createdAt', type: 'DateTime'),
  ],
  r'$OrderNotification': [
    BoundaryField(name: 'id', type: 'String'),
    BoundaryField(name: 'createdAt', type: 'DateTime'),
    BoundaryField(name: 'orderId', type: 'String'),
    BoundaryField(name: 'note', type: 'String?'),
  ],
  r'$PriceDropNotification': [
    BoundaryField(name: 'id', type: 'String'),
    BoundaryField(name: 'createdAt', type: 'DateTime'),
    BoundaryField(name: 'oldPrice', type: 'double'),
    BoundaryField(name: 'newPrice', type: 'double'),
  ],
};

/// The notification hierarchy from the issue's §2 example.
({ZorphyNodeIr root, ZorphyNodeIr order, ZorphyNodeIr priceDrop})
_notifications() {
  final rootContract = _node(
    className: r'$Notification',
    isSealedRoot: true,
    principalKey: 'id',
  );
  final order = _node(
    className: r'$OrderNotification',
    discriminatorValue: 'order',
    principalKey: 'id',
    superTypes: [rootContract],
  );
  final priceDrop = _node(
    className: r'$PriceDropNotification',
    discriminatorValue: 'price_drop',
    principalKey: 'id',
    superTypes: [rootContract],
  );
  final root = _node(
    className: r'$Notification',
    isSealedRoot: true,
    principalKey: 'id',
    children: [order, priceDrop],
  );
  return (root: root, order: order, priceDrop: priceDrop);
}

/// Emits one node's codec members as source text.
String _codecFor(ZorphyNodeIr node) => ZorphyEmitter().emitSpecs(
  const BoundaryCodecEmitter().emitCodec(
    node,
    _fields,
    additionalNodes: _known,
  ),
);

/// Indents every non-blank line of [text] by two spaces so it lands inside a
/// class body.
String _indent(String text) => text
    .split('\n')
    .map((line) => line.trimRight().isEmpty ? '' : '  $line')
    .join('\n');

/// The verification program the emitted codecs are executed by.
const _checks = r'''
void check(bool condition, String message) {
  if (!condition) throw StateError('FAILED: $message');
}

void main() {
  final orderWire = <String, Object?>{
    'kind': 'order',
    'id': 'o-1',
    'createdAt': '2026-11-23T00:00:00.000Z',
    'orderId': 'ord-9',
    'note': 'gift',
  };
  final priceWire = <String, Object?>{
    'kind': 'price_drop',
    'id': 'p-1',
    'createdAt': '2026-11-23T00:00:00.000Z',
    'oldPrice': 20,
    'newPrice': 15.5,
  };

  // ── happy path: dispatch, decode, discriminated encode ─────────────
  final ok = Notification.fromWire(orderWire);
  check(ok.isOk, 'a well-formed order payload decodes');
  final order = ok.getOrThrow() as OrderNotification;
  check(order is OrderNotification, 'dispatch reached the order leaf');
  check(order.id == 'o-1', 'id decoded');
  check(order.note == 'gift', 'a present nullable field decodes');

  final encoded = order.toWire();
  check(encoded['kind'] == 'order', 'toWire stamps the discriminator');
  check(encoded['createdAt'] is String, 'DateTime encodes as ISO-8601');
  check(encoded['orderId'] == 'ord-9', 'a field re-encodes');

  // A JSON payload spells 1.0 as `1`; that is a legal double.
  final priceOk = Notification.fromWire(priceWire);
  check(priceOk.isOk, 'an int wire value is a legal double');
  check(
    priceOk.getOrThrow() is PriceDropNotification,
    'dispatch reached the price leaf',
  );

  // An absent nullable key is legal and decodes to null.
  final withoutNote = Map<String, Object?>.of(orderWire)..remove('note');
  check(
    Notification.fromWire(withoutNote).getOrThrow().id == 'o-1',
    'a missing nullable field is not a violation',
  );

  // ── unknown discriminator: BoundaryErr at /kind ───────────────────
  for (final badTag in <Object?>[null, 'unknown', 42]) {
    final wire = Map<String, Object?>.of(orderWire);
    if (badTag == null) {
      wire.remove('kind');
    } else {
      wire['kind'] = badTag;
    }
    final result = Notification.fromWire(wire);
    check(!result.isOk, 'an unknown discriminator is an error');
    final error = result as BoundaryErr<Notification>;
    check(error.violations.length == 1, 'exactly one tag violation');
    check(error.violations.single.path == '/kind', 'the pointer is /kind');
  }

  // ── corrupt fields: EVERY violation is collected ──────────────────
  final corrupt = Notification.fromWire(<String, Object?>{
    'kind': 'order',
    'id': 7,
    'createdAt': 'not-a-date',
    'orderId': true,
    'note': 3.5,
  });
  check(!corrupt.isOk, 'a fully corrupt payload is an error');
  final violations = (corrupt as BoundaryErr<Notification>).violations;
  check(
    violations.length == 4,
    'all four bad fields are reported (got ${violations.length})',
  );
  final paths = violations.map((v) => v.path).toList();
  for (final path in <String>['/id', '/createdAt', '/orderId', '/note']) {
    check(paths.contains(path), 'violation path $path is present');
  }

  final oneBad = Map<String, Object?>.of(orderWire)..['createdAt'] = 123;
  final single = Notification.fromWire(oneBad) as BoundaryErr<Notification>;
  check(single.violations.single.path == '/createdAt', 'names the bad field');

  // Every violation carries the expectation and the found value, so a caller
  // can log a diagnosable message without re-decoding.
  final expectedId = violations.firstWhere((v) => v.path == '/id');
  check(expectedId.expected == 'String', 'expected names the type');
  check(expectedId.actual.contains('int'), 'actual names the found type');

  // ── the fuzz gate: arbitrary junk NEVER throws ────────────────────
  final junk = <Map<String, Object?>>[
    <String, Object?>{},
    <String, Object?>{'kind': 'order'},
    <String, Object?>{'kind': 'order', 'id': null, 'createdAt': null},
    <String, Object?>{'kind': <String, Object?>{}, 'id': 'x'},
    <String, Object?>{'kind': 'price_drop', 'oldPrice': 'free'},
    <String, Object?>{'kind': 'order', 'id': [], 'createdAt': {}},
    <String, Object?>{'kind': 'order', 'id': 'o', 'createdAt': '2026-11-23'},
    <String, Object?>{'kind': 'order', 'id': 'o', 'createdAt': null, 'note': <Object?>[1]},
  ];
  for (final payload in junk) {
    final result = Notification.fromWire(payload);
    check(
      result is BoundaryOk<Notification> || result is BoundaryErr<Notification>,
      'junk decodes to a result, never a throw',
    );
    if (result.isOk) {
      final round = result.getOrThrow().toWire();
      check(round['kind'] is String, 'a decoded value re-encodes a tag');
    }
  }

  // A deep structural mismatch must still be a BoundaryErr, not a throw.
  final deep = Notification.fromWire(<String, Object?>{
    'kind': 'order',
    'id': 'o-1',
    'createdAt': '2026-11-23T00:00:00.000Z',
    'orderId': 'ord-9',
    'note': <String, Object?>{'nested': <Object?>[1, 2]},
  });
  check(!deep.isOk, 'a structurally wrong nullable field is a violation');

  print('ALL BOUNDARY CHECKS PASSED');
}
''';

/// Builds the whole program: minimal classes, real emitted codecs inside
/// them, the shared helpers, and the checks.
String _buildProgram() {
  final fixture = _notifications();
  final helpers = ZorphyEmitter().emitSpecs(BoundaryCodecEmitter.helperSpecs());

  return '''
// GENERATED BY test/runtime/hierarchical_from_wire_test.dart — do not edit.
import 'package:zorphy_annotation/zorphy_annotation.dart';

sealed class Notification {
  const Notification();
  String get id;
  DateTime get createdAt;

${_indent(_codecFor(fixture.root))}
}

final class OrderNotification extends Notification {
  @override
  final String id;
  @override
  final DateTime createdAt;
  final String orderId;
  final String? note;

  const OrderNotification.fromTrusted({
    required this.id,
    required this.createdAt,
    required this.orderId,
    this.note,
  });

${_indent(_codecFor(fixture.order))}
}

final class PriceDropNotification extends Notification {
  @override
  final String id;
  @override
  final DateTime createdAt;
  final double oldPrice;
  final double newPrice;

  const PriceDropNotification.fromTrusted({
    required this.id,
    required this.createdAt,
    required this.oldPrice,
    required this.newPrice,
  });

${_indent(_codecFor(fixture.priceDrop))}
}

$helpers
$_checks
''';
}

void main() {
  test('emitted codecs decode corrupt wire maps without throwing', () {
    final program = _buildProgram();

    // The program must live INSIDE the example package: `dart run` resolves
    // `package:` URIs from the nearest enclosing package config, and a file
    // under the system temp directory sits outside every package.
    final directory = Directory(
      'example/.dart_tool/zorphy_188_runtime',
    ).absolute..createSync(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final file = File('${directory.path}/boundary_program.dart')
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
      reason: 'generated boundary program failed:\n$output',
    );
    expect(output, contains('ALL BOUNDARY CHECKS PASSED'));
  });
}
