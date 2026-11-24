// Runtime tests for ISSUE-015 (arrrrny/zorphy#190): `<Name>MockData` seeds.
//
// The golden layer (`test/golden/mock_data_golden_test.dart`) pins the SHAPE of
// the emitted classes. This layer proves the BEHAVIOUR the issue's acceptance
// gate actually asks for:
//
//   > `NotificationMockData.list(count: 10)` produces a heterogeneous mix of
//   > all registered subtypes with unique `principalKey`s.
//
// That cannot be proven from inside the zorphy test package: the emitted
// builders need a class hierarchy to construct AND `package:zorphy_annotation`
// in scope. So this test composes a complete tiny program — minimal hand-shaped
// classes with the EMITTER'S REAL output spliced into it, nothing hand-written
// into the mock data — and runs it. A non-zero exit fails the test.
//
// The fixture mirrors the hierarchy the earlier v3 emitters use:
//
//   $Notification -> $OrderNotification | $PriceDropNotification
//
// plus a standalone `$Product` for the concrete-entity path.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emitters/mock_fixture_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

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

/// The notification hierarchy, with the inherited fields declared on each leaf
/// so `single()` can hand `fromTrusted` a complete argument list.
ZorphyNodeIr _notificationsRoot() {
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
  return _node(
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
}

/// A standalone entity, seeded partly through `@ZorphyMock` hints.
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
    ZorphyFieldIr(name: 'tags', type: 'List<String>'),
  ],
);

const _productSeeds = <String, ZorphyMock>{
  'name': ZorphyMock(preset: ZorphyMockPresets.email),
  'price': ZorphyMock(preset: ZorphyMockPresets.price),
  'tags': ZorphyMock(example: <String>['seed-a']),
};

/// The hand-shaped classes the emitted mock data constructs.
///
/// Nothing here is mock data: every `MockData` member in the program below is
/// the emitter's own output. The `fromTrusted` constructors and the patch's
/// fluent `with*` builders are the shapes ISSUE-003 and ISSUE-007 emit, pinned
/// by their own suites.
const _fixtures = r'''
sealed class Notification {
  const Notification();
  String get id;
  DateTime get createdAt;

  Map<String, Object?> toWire();
}

final class OrderNotification extends Notification {
  const OrderNotification.fromTrusted({
    required this.id,
    required this.createdAt,
    required this.orderId,
    this.note,
  });

  @override
  final String id;
  @override
  final DateTime createdAt;
  final String orderId;
  final String? note;

  @override
  Map<String, Object?> toWire() => <String, Object?>{
    'kind': 'order_notification',
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'orderId': orderId,
    if (note != null) 'note': note,
  };
}

final class PriceDropNotification extends Notification {
  const PriceDropNotification.fromTrusted({
    required this.id,
    required this.createdAt,
    required this.oldPrice,
    required this.newPrice,
  });

  @override
  final String id;
  @override
  final DateTime createdAt;
  final double oldPrice;
  final double newPrice;

  @override
  Map<String, Object?> toWire() => <String, Object?>{
    'kind': 'price_drop_notification',
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'oldPrice': oldPrice,
    'newPrice': newPrice,
  };
}

final class Product {
  const Product.fromTrusted({
    required this.id,
    required this.name,
    required this.price,
    required this.inStock,
    required this.tags,
  });

  final String id;
  final String name;
  final double price;
  final bool inStock;
  final List<String> tags;

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'price': price,
    'inStock': inStock,
    'tags': tags,
  };
}

class ProductPatch {
  final Map<String, Object?> changes = <String, Object?>{};
  ProductPatch withId(String value) {
    changes['id'] = value;
    return this;
  }

  ProductPatch withName(String value) {
    changes['name'] = value;
    return this;
  }

  ProductPatch withPrice(double value) {
    changes['price'] = value;
    return this;
  }

  ProductPatch withInStock(bool value) {
    changes['inStock'] = value;
    return this;
  }

  ProductPatch withTags(List<String> value) {
    changes['tags'] = value;
    return this;
  }
}

class NotificationPatch {
  final Map<String, Object?> changes = <String, Object?>{};
  NotificationPatch withId(String value) {
    changes['id'] = value;
    return this;
  }

  NotificationPatch withCreatedAt(DateTime value) {
    changes['createdAt'] = value;
    return this;
  }
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

  OrderNotificationPatch withOrderId(String value) {
    changes['orderId'] = value;
    return this;
  }

  OrderNotificationPatch withNote(String value) {
    changes['note'] = value;
    return this;
  }
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

  PriceDropNotificationPatch withOldPrice(double value) {
    changes['oldPrice'] = value;
    return this;
  }

  PriceDropNotificationPatch withNewPrice(double value) {
    changes['newPrice'] = value;
    return this;
  }
}
''';

/// What the running program asserts — the issue's §5 acceptance criteria.
const _checks = r'''
void check(bool condition, String message) {
  if (!condition) throw StateError('FAILED: ' + message);
}

void main() {
  // ── §5: heterogeneity across the whole registered subtype set ──────
  final List<Notification> mixed = NotificationMockData.list(count: 10);
  check(mixed.length == 10, 'list(count: 10) yields ten values');

  final kinds = mixed.map((n) => n.runtimeType.toString()).toSet();
  check(
    kinds.length == 2,
    'the list mixes every subtype (got ' + kinds.toString() + ')',
  );
  check(
    kinds.contains('OrderNotification') &&
        kinds.contains('PriceDropNotification'),
    'both leaves are present',
  );

  // Every subtype appears at least once in ten draws — the rotation is
  // deterministic, so this is a property of the seed modulo the leaf count.
  final counts = <String, int>{};
  for (final n in mixed) {
    final key = n.runtimeType.toString();
    counts[key] = (counts[key] ?? 0) + 1;
  }
  check(counts['OrderNotification'] == 5, 'an even split (got ' + counts.toString() + ')');
  check(counts['PriceDropNotification'] == 5, 'an even split (got ' + counts.toString() + ')');

  // ── §5: unique principalKeys ───────────────────────────────────────
  final keys = mixed.map((n) => n.id).toList();
  check(keys.toSet().length == keys.length, 'every principalKey is unique');

  // ── determinism: the same seed yields the same value ──────────────
  final a = NotificationMockData.single(seed: 3);
  final b = NotificationMockData.single(seed: 3);
  check(a.runtimeType == b.runtimeType, 'seed 3 picks a stable subtype');
  check(a.id == b.id, 'seed 3 yields a stable principalKey');

  final c = NotificationMockData.single(seed: 4);
  check(a.runtimeType != c.runtimeType, 'seed 4 rotates to the other leaf');

  // A negative seed must still land on a registered leaf (Dart's `%` on ints
  // is Euclidean, so the index stays in range).
  final negative = NotificationMockData.single(seed: -1);
  check(
    negative is OrderNotification || negative is PriceDropNotification,
    'a negative seed still dispatches to a leaf',
  );

  // ── concrete entity: every field is seeded deterministically ──────
  final p0 = ProductMockData.single(seed: 0);
  final p1 = ProductMockData.single(seed: 1);
  check(p0.id != p1.id, 'consecutive seeds differ in the principal key');
  check(p0.name.endsWith('@example.com'), 'the email preset renders an address');
  check(p0.price == 19.99, 'the price preset renders a monetary amount');
  check(p0.tags.length == 1 && p0.tags.first == 'seed-a', 'the example hint wins');
  check(p0.inStock != p1.inStock, 'a bool field varies with the seed');
  check(p0.tags.isNotEmpty, 'a collection field carries a seeded element');

  // ── list(count:) reuses single() so keys stay unique across entries ─
  final products = ProductMockData.list(count: 5);
  check(products.length == 5, 'list(count: 5) yields five values');
  final productIds = products.map((p) => p.id).toList();
  check(productIds.toSet().length == 5, 'product ids are unique');

  // ── samplePatch() is a usable, non-empty patch ────────────────────
  final patch = ProductMockData.samplePatch();
  check(patch.changes.isNotEmpty, 'samplePatch() carries at least one change');
  check(
    patch.changes.containsKey('id'),
    'samplePatch() covers the principal key',
  );

  // A polymorphic root's patch is sealed (implicitly abstract), so its sample
  // delegates to a concrete leaf's patch — and that must be a real instance.
  final rootPatch = NotificationMockData.samplePatch();
  check(
    rootPatch.changes.isNotEmpty,
    'a root samplePatch() delegates to a concrete leaf patch',
  );
  check(
    rootPatch.changes.containsKey('id'),
    'the delegated patch covers the inherited principal key',
  );
  check(
    rootPatch is OrderNotificationPatch,
    'the delegated patch is a concrete subtype patch',
  );

  print('ALL MOCK DATA CHECKS PASSED');
}
''';

/// The verification program: fixtures, the emitter's real output, the checks.
String _buildProgram() {
  final emitter = MockFixtureEmitter();
  return '''
$_annotationImport
import 'dart:io';

$_fixtures

${emitter.emitForNode(_product(), mockSeeds: _productSeeds)}

${emitter.emit(_notificationsRoot())}

$_checks
''';
}

void main() {
  test('emitted mock data seeds a heterogeneous polymorphic list', () {
    final program = _buildProgram();

    // The program must live INSIDE the example package: `dart run` resolves
    // `package:` URIs from the nearest enclosing package config, and a file
    // under the system temp directory sits outside every package.
    final directory = Directory(
      'example/.dart_tool/zorphy_190_runtime',
    ).absolute..createSync(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final file = File('${directory.path}/mock_data_program.dart')
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
          'generated mock-data program failed:\n$output\n---program---\n$program',
    );
    expect(output, contains('ALL MOCK DATA CHECKS PASSED'));
  });
}
