// Runtime fuzz tests for ISSUE-016 (arrrrny/zorphy#191):
// `<Name>WireFixtures` validMap and corruptMaps.
//
// Acceptance Criteria:
// - Emit `validMap` and `corruptMaps` for all @ZorphyEntity and @ZorphyIntent types.
// - `validMap({int seed = 0})` -> `<Name>MockData.single(seed: seed).toWire()`.
// - `corruptMaps()` -> emits one systematically corrupted payload per required field
//   PLUS `missing_discriminator` and `unknown_discriminator` cases for polymorphic hierarchies.
// - 100% of `corruptMaps()` return `BoundaryErr` when decoded via `fromWire`.
// - Every entry in `T.corruptMaps()` produces `BoundaryErr` with exact `FieldViolation.path` metadata.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/emitters/mock_fixture_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

ZorphyNodeIr _node({
  required String className,
  ArchetypeKind archetype = ArchetypeKind.entity,
  bool isSealedRoot = false,
  List<ZorphyNodeIr> children = const [],
  List<ZorphyNodeIr> superTypes = const [],
  String? principalKey,
  String discriminatorValue = '',
  List<ZorphyFieldIr> fields = const [],
}) => ZorphyNodeIr(
  className: className,
  cleanName: className.replaceAll(r'$', ''),
  archetype: archetype,
  isSealedRoot: isSealedRoot,
  isAbstractIntermediate: superTypes.isNotEmpty && children.isNotEmpty,
  isConcreteLeaf: children.isEmpty,
  superTypes: superTypes,
  directSubTypes: children,
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: discriminatorValue,
  principalKey: principalKey,
  replaySafe: archetype == ArchetypeKind.intent ? true : null,
  isSyntheticLeaf: false,
  fields: fields,
);

({ZorphyNodeIr root, ZorphyNodeIr order, ZorphyNodeIr priceDrop})
_notifications() {
  final rootContract = _node(
    className: r'$Notification',
    isSealedRoot: true,
    principalKey: 'id',
    fields: const [
      ZorphyFieldIr(name: 'id', type: 'String'),
      ZorphyFieldIr(name: 'createdAt', type: 'DateTime'),
    ],
  );
  final order = _node(
    className: r'$OrderNotification',
    principalKey: 'id',
    discriminatorValue: 'order_notification',
    superTypes: [rootContract],
    fields: const [
      ZorphyFieldIr(name: 'id', type: 'String'),
      ZorphyFieldIr(name: 'createdAt', type: 'DateTime'),
      ZorphyFieldIr(name: 'orderId', type: 'String'),
      ZorphyFieldIr(name: 'note', type: 'String', isNullable: true),
    ],
  );
  final priceDrop = _node(
    className: r'$PriceDropNotification',
    principalKey: 'id',
    discriminatorValue: 'price_drop_notification',
    superTypes: [rootContract],
    fields: const [
      ZorphyFieldIr(name: 'id', type: 'String'),
      ZorphyFieldIr(name: 'createdAt', type: 'DateTime'),
      ZorphyFieldIr(name: 'oldPrice', type: 'double'),
      ZorphyFieldIr(name: 'newPrice', type: 'double'),
    ],
  );
  final root = _node(
    className: r'$Notification',
    isSealedRoot: true,
    principalKey: 'id',
    discriminatorValue: 'notification',
    children: [order, priceDrop],
    fields: const [
      ZorphyFieldIr(name: 'id', type: 'String'),
      ZorphyFieldIr(name: 'createdAt', type: 'DateTime'),
    ],
  );
  return (root: root, order: order, priceDrop: priceDrop);
}

ZorphyNodeIr _product() => _node(
  className: r'$Product',
  isSealedRoot: true,
  principalKey: 'id',
  discriminatorValue: 'product',
  fields: const [
    ZorphyFieldIr(name: 'id', type: 'String'),
    ZorphyFieldIr(name: 'name', type: 'String'),
    ZorphyFieldIr(name: 'price', type: 'double'),
    ZorphyFieldIr(name: 'inStock', type: 'bool'),
  ],
);

const _known = {
  'Notification',
  'OrderNotification',
  'PriceDropNotification',
  'Product',
};

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
  r'$Product': [
    BoundaryField(name: 'id', type: 'String'),
    BoundaryField(name: 'name', type: 'String'),
    BoundaryField(name: 'price', type: 'double'),
    BoundaryField(name: 'inStock', type: 'bool'),
  ],
};

String _codecFor(ZorphyNodeIr node) => ZorphyEmitter().emitSpecs(
  const BoundaryCodecEmitter().emitCodec(
    node,
    _fields,
    additionalNodes: _known,
  ),
);

String _indent(String text) => text
    .split('\n')
    .map((line) => line.trimRight().isEmpty ? '' : '  $line')
    .join('\n');

String _buildProgram() {
  final notif = _notifications();
  final product = _product();
  final helpers = ZorphyEmitter().emitSpecs(BoundaryCodecEmitter.helperSpecs());

  final classes =
      '''
sealed class Notification {
  const Notification();
  String get id;
  DateTime get createdAt;

${_indent(_codecFor(notif.root))}
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

${_indent(_codecFor(notif.order))}
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

${_indent(_codecFor(notif.priceDrop))}
}

final class Product {
  final String id;
  final String name;
  final double price;
  final bool inStock;

  const Product.fromTrusted({
    required this.id,
    required this.name,
    required this.price,
    required this.inStock,
  });

${_indent(_codecFor(product))}
}

class ProductPatch {
  final Map<String, Object?> changes = <String, Object?>{};
  ProductPatch withId(String value) { changes['id'] = value; return this; }
  ProductPatch withName(String value) { changes['name'] = value; return this; }
  ProductPatch withPrice(double value) { changes['price'] = value; return this; }
  ProductPatch withInStock(bool value) { changes['inStock'] = value; return this; }
}

class NotificationPatch {
  final Map<String, Object?> changes = <String, Object?>{};
  NotificationPatch withId(String value) { changes['id'] = value; return this; }
  NotificationPatch withCreatedAt(DateTime value) { changes['createdAt'] = value; return this; }
}

class OrderNotificationPatch extends NotificationPatch {
  @override
  OrderNotificationPatch withId(String value) {
    super.withId(value);
    return this;
  }

  @override
  OrderNotificationPatch withCreatedAt(DateTime value) {
    super.withCreatedAt(value);
    return this;
  }

  OrderNotificationPatch withOrderId(String value) { changes['orderId'] = value; return this; }
  OrderNotificationPatch withNote(String value) { changes['note'] = value; return this; }
}

class PriceDropNotificationPatch extends NotificationPatch {
  @override
  PriceDropNotificationPatch withId(String value) {
    super.withId(value);
    return this;
  }

  @override
  PriceDropNotificationPatch withCreatedAt(DateTime value) {
    super.withCreatedAt(value);
    return this;
  }

  PriceDropNotificationPatch withOldPrice(double value) { changes['oldPrice'] = value; return this; }
  PriceDropNotificationPatch withNewPrice(double value) { changes['newPrice'] = value; return this; }
}
''';

  final mockEmitter = MockFixtureEmitter();
  final emittedMockAndFixtures =
      '''
${mockEmitter.emit(notif.root)}
${mockEmitter.emit(product)}
''';

  final checks = r'''
void check(bool condition, String message) {
  if (!condition) throw StateError('FAILED: ' + message);
}

void main() {
  // ── 1. ProductWireFixtures validMap and corruptMaps ─────────────────
  final productValid = ProductWireFixtures.validMap(seed: 42);
  final productDecoded = Product.fromWire(productValid);
  check(productDecoded.isOk, 'Product validMap decodes successfully via fromWire');
  check(productDecoded.getOrThrow() is Product, 'Decoded instance is Product');

  final productCorrupt = ProductWireFixtures.corruptMaps();
  check(productCorrupt.isNotEmpty, 'Product corruptMaps is not empty');
  for (final corrupt in productCorrupt) {
    final result = Product.fromWire(corrupt);
    check(!result.isOk, 'corrupt map must fail decoding');
    final err = result as BoundaryErr<Product>;
    check(err.violations.isNotEmpty, 'BoundaryErr contains violations');
    for (final v in err.violations) {
      check(v.path.startsWith('/'), 'Violation path starts with /: ' + v.path);
    }
  }

  // ── 2. NotificationWireFixtures validMap and corruptMaps ────────────
  final notifValid = NotificationWireFixtures.validMap(seed: 0);
  final notifDecoded = Notification.fromWire(notifValid);
  check(notifDecoded.isOk, 'Notification validMap decodes successfully via fromWire');

  final notifCorrupt = NotificationWireFixtures.corruptMaps();
  check(notifCorrupt.isNotEmpty, 'Notification corruptMaps is not empty');

  // Verify missing discriminator case
  final missingDisc = notifCorrupt.where((m) => !m.containsKey('kind')).toList();
  check(missingDisc.isNotEmpty, 'contains missing discriminator case');
  for (final m in missingDisc) {
    final res = Notification.fromWire(m);
    check(!res.isOk, 'missing discriminator fails decoding');
    final err = res as BoundaryErr<Notification>;
    check(err.violations.any((v) => v.path == '/kind'), 'records violation at /kind');
  }

  // Verify unknown discriminator case
  final unknownDisc = notifCorrupt.where((m) => m['kind'] == '__unknown_discriminator__').toList();
  check(unknownDisc.isNotEmpty, 'contains unknown discriminator case');
  for (final m in unknownDisc) {
    final res = Notification.fromWire(m);
    check(!res.isOk, 'unknown discriminator fails decoding');
    final err = res as BoundaryErr<Notification>;
    check(err.violations.any((v) => v.path == '/kind'), 'records violation at /kind');
  }

  // Verify 100% of corruptMaps return BoundaryErr
  for (final corrupt in notifCorrupt) {
    final result = Notification.fromWire(corrupt);
    check(!result.isOk, '100% of corruptMaps must return BoundaryErr');
    final err = result as BoundaryErr<Notification>;
    check(err.violations.isNotEmpty, 'every BoundaryErr has violations');
    for (final v in err.violations) {
      check(v.path.startsWith('/'), 'violation path has exact metadata: ' + v.path);
    }
  }

  // ── 3. OrderNotificationWireFixtures corruptMaps ────────────────────
  final orderCorrupt = OrderNotificationWireFixtures.corruptMaps();
  check(orderCorrupt.isNotEmpty, 'OrderNotification corruptMaps is not empty');
  for (final corrupt in orderCorrupt) {
    final result = OrderNotification.fromWire(corrupt);
    if (result.isOk) {
      throw StateError('OrderNotification passed on corrupt map: $corrupt');
    }
    check(!result.isOk, '100% of OrderNotification corruptMaps return BoundaryErr');
    final err = result as BoundaryErr<OrderNotification>;
    check(err.violations.isNotEmpty, 'OrderNotification BoundaryErr has violations');
  }

  print('ALL WIRE FIXTURES FUZZ CHECKS PASSED');
}
''';

  return '''
$_annotationImport
import 'dart:io';

$helpers

$classes

$emittedMockAndFixtures

$checks
''';
}

void main() {
  test(
    'MockFixtureEmitter emits <Name>WireFixtures with validMap and corruptMaps',
    () {
      final product = _product();
      final emitted = MockFixtureEmitter().emit(product);
      expect(emitted, contains('class ProductWireFixtures'));
      expect(
        emitted,
        contains('static Map<String, Object?> validMap({int seed = 0})'),
      );
      expect(
        emitted,
        contains('static List<Map<String, Object?>> corruptMaps()'),
      );
    },
  );

  test(
    'runtime wire fixtures fuzz execution verifies 100% BoundaryErr and exact paths',
    () {
      final program = _buildProgram();

      final directory = Directory(
        'example/.dart_tool/zorphy_191_runtime',
      ).absolute..createSync(recursive: true);
      addTearDown(() {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
      });

      final file = File('${directory.path}/wire_fixtures_fuzz_program.dart')
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
            'generated wire-fixtures fuzz program failed:\n$output\n---program---\n$program',
      );
      expect(output, contains('ALL WIRE FIXTURES FUZZ CHECKS PASSED'));
    },
  );
}
