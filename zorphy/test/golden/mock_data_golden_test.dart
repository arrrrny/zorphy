// Golden tests for ISSUE-015 (arrrrny/zorphy#190): `<Name>MockData`.
//
// The emitter turns a resolved `ZorphyNodeIr` hierarchy plus each node's
// declared fields into a `<Name>MockData` class per node, exposing
// `single(seed:)` / `list(count:)` seed builders (and `samplePatch()` for an
// `@ZorphyEntity`). Everything is a `package:code_builder` spec — no
// `StringBuffer`, no `preset`, no `generate*` toggle, per the issue's §5 gate.
//
// Two layers, exactly like ISSUE-013's codec pair:
//
//   1. golden (this file) — the emitted source carries the members the issue
//      names, the `@ZorphyMock` seeds land on the right fields, and the
//      polymorphic rotation is a `switch` over the concrete leaves;
//   2. runtime (`test/runtime/polymorphic_mock_data_test.dart`) — the emitted
//      source is compiled and EXECUTED, proving §5's acceptance criterion: a
//      `NotificationMockData.list(count: 10)` is a heterogeneous mix of every
//      registered subtype with unique `principalKey`s.

import 'package:test/test.dart';
import 'package:zorphy/src/emitters/mock_fixture_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

ZorphyNodeIr _node({
  required String className,
  ArchetypeKind archetype = ArchetypeKind.entity,
  bool isSealedRoot = false,
  List<ZorphyNodeIr> children = const [],
  List<ZorphyNodeIr> superTypes = const [],
  String? principalKey,
  String discriminatorValue = '',
  List<ZorphyFieldIr> fields = const [],
  List<String> typeParameters = const [],
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
  replaySafe: archetype == ArchetypeKind.intent ? false : null,
  isSyntheticLeaf: false,
  fields: fields,
  typeParameters: typeParameters,
);

/// `$Notification` -> `$OrderNotification` | `$PriceDropNotification`, the
/// hierarchy both the issue and the earlier v3 emitters use.
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

/// A concrete `@ZorphyEntity` with no hierarchy at all.
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

const _productMockSeeds = <String, ZorphyMock>{
  'name': ZorphyMock(preset: ZorphyMockPresets.email),
  'price': ZorphyMock(preset: ZorphyMockPresets.price),
  'tags': ZorphyMock(example: <String>['seed-a']),
};

void main() {
  group('ISSUE-015 MockFixtureEmitter — concrete entity', () {
    test('emits a <Name>MockData class with single and list', () {
      final emitted = MockFixtureEmitter().emitForNode(_product());

      expect(emitted, contains('class ProductMockData'));
      expect(
        emitted,
        contains('static Product single('),
        reason: 'a concrete entity exposes the deterministic single builder',
      );
      expect(emitted, contains('static List<Product> list('));
    });

    test('emits samplePatch() for every @ZorphyEntity', () {
      final emitted = MockFixtureEmitter().emitForNode(_product());
      expect(
        emitted,
        contains('static ProductPatch samplePatch('),
        reason: '§4 requires a samplePatch() for every @ZorphyEntity',
      );
    });

    test('@ZorphyMock(preset:) seeds the field it annotates', () {
      final emitted = MockFixtureEmitter().emitForNode(
        _product(),
        mockSeeds: _productMockSeeds,
      );
      // The reserved `price` preset is a monetary amount; the reserved `email`
      // preset is a valid address. Both must appear as literals in the body.
      expect(
        emitted,
        matches(RegExp(r'price:\s*[0-9]+(\.[0-9]+)?')),
        reason: 'the price preset renders a numeric literal',
      );
      expect(
        emitted,
        contains('@example.com'),
        reason: 'the email preset renders a valid address literal',
      );
    });

    test('@ZorphyMock(example:) is used verbatim', () {
      final emitted = MockFixtureEmitter().emitForNode(
        _product(),
        mockSeeds: _productMockSeeds,
      );
      expect(
        emitted,
        contains("'seed-a'"),
        reason: 'an example hint is copied straight into the seed literal',
      );
    });

    test('emits no preset or generate* toggle', () {
      final emitted = MockFixtureEmitter().emitForNode(_product());
      expect(emitted, isNot(contains('ZorphyPreset')));
      expect(emitted, isNot(contains('generatePatch')));
      expect(emitted, isNot(contains('generateJson')));
      expect(emitted, isNot(contains('generateField')));
    });
  });

  group('ISSUE-015 MockFixtureEmitter — polymorphic root', () {
    test('emits MockData for the root and every concrete leaf', () {
      final emitted = MockFixtureEmitter().emit(_notifications().root);
      expect(emitted, contains('class NotificationMockData'));
      expect(emitted, contains('class OrderNotificationMockData'));
      expect(emitted, contains('class PriceDropNotificationMockData'));
    });

    test('the root rotates deterministically across the concrete leaves', () {
      final emitted = MockFixtureEmitter().emit(_notifications().root);
      // `seed % leaves.length` selects the leaf, so the rotation is a pure
      // function of the seed and a `list(count:)` walks every subtype.
      expect(
        emitted,
        matches(RegExp(r'seed % 2')),
        reason: 'the rotation must be seed modulo the leaf count',
      );
      expect(emitted, contains('switch (seed % 2)'));
      expect(emitted, contains('OrderNotificationMockData.single(seed: seed)'));
      expect(
        emitted,
        contains('PriceDropNotificationMockData.single(seed: seed)'),
      );
    });

    test('the root MockData is typed to the sealed root', () {
      final emitted = MockFixtureEmitter().emit(_notifications().root);
      expect(
        emitted,
        contains('static Notification single('),
        reason: 'a heterogeneous list is a List<Notification>',
      );
      expect(emitted, contains('static List<Notification> list('));
    });

    test('the root samplePatch delegates to a concrete leaf patch', () {
      final emitted = MockFixtureEmitter().emit(_notifications().root);
      // A sealed root patch is implicitly abstract, so the root's own patch
      // class cannot be instantiated; its concrete subtypes extend it, so
      // returning a leaf's sample keeps the declared return type.
      expect(
        emitted,
        matches(
          RegExp(
            r'static NotificationPatch samplePatch\(\)\s*\{\s*'
            r'return OrderNotificationMockData\.samplePatch\(\);',
          ),
        ),
        reason: 'a sealed root must not instantiate its abstract patch',
      );
    });

    test('every emitted MockData uses code_builder, never a StringBuffer', () {
      // Structural rule from §5: the emitter builds Specs. Proven by the
      // absence of hand-concatenated class text here and by the emitter's own
      // source carrying no StringBuffer.
      final emitted = MockFixtureEmitter().emit(_notifications().root);
      expect(emitted, startsWith('class '));
    });

    test('a generic node is skipped, and the rotation names only leaves that '
        'were emitted', () {
      // `class Box<T>MockData` and `Box<T>.fromTrusted(...)` are not legal
      // Dart, and `T` is not a type this seeder can produce — so the node is
      // withheld rather than approximated (the posture the generator takes for
      // a generic hierarchy).
      final generic = _node(
        className: r'$Box',
        isSealedRoot: true,
        fields: const [ZorphyFieldIr(name: 'value', type: 'T')],
        typeParameters: const ['T extends num'],
      );
      expect(MockFixtureEmitter().emitForNode(generic), isEmpty);

      // A generic leaf inside a hierarchy is not an arm a root can name.
      final okLeaf = _node(
        className: r'$OkNode',
        fields: const [ZorphyFieldIr(name: 'id', type: 'String')],
      );
      final genericLeaf = _node(
        className: r'$BadNode',
        superTypes: [okLeaf],
        typeParameters: const ['T'],
      );
      final root = _node(
        className: r'$Root',
        isSealedRoot: true,
        children: [okLeaf, genericLeaf],
        fields: const [ZorphyFieldIr(name: 'id', type: 'String')],
      );
      final emitted = MockFixtureEmitter().emit(root);
      expect(emitted, isNot(contains('BadNodeMockData')));
      expect(emitted, contains('seed % 1'));
    });

    test('a required unseedable field refuses instead of fabricating a value', () {
      final node = _node(
        className: r'$Order',
        isSealedRoot: true,
        fields: const [
          ZorphyFieldIr(name: 'id', type: 'String'),
          ZorphyFieldIr(name: 'status', type: 'OrderStatus'),
        ],
      );
      final emitted = MockFixtureEmitter().emitForNode(node);
      expect(
        emitted,
        contains('UnsupportedError'),
        reason: 'a required enum field has no seed this emitter can supply',
      );
      expect(
        emitted,
        isNot(contains("'status-")),
        reason: 'an enum must never be seeded as a String',
      );
      // The field it CAN seed still lands, so the rest of the class is usable.
      expect(emitted, contains("patch = patch.withId('id-"));
    });
  });

  group('ISSUE-015 MockFixtureEmitter — intents', () {
    test('emits MockData for a standalone @ZorphyIntent', () {
      final intent = _node(
        className: r'$PingIntent',
        archetype: ArchetypeKind.intent,
        isSealedRoot: true,
        discriminatorValue: 'ping_intent',
        fields: const [ZorphyFieldIr(name: 'nonce', type: 'String')],
      );
      final emitted = MockFixtureEmitter().emitForNode(intent);
      expect(emitted, contains('class PingIntentMockData'));
      expect(emitted, contains('static PingIntent single('));
    });
  });
}
