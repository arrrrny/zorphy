// Golden tests for ISSUE-013 (arrrrny/zorphy#188): `BoundaryCodecEmitter`.
//
// The emitter turns a resolved `ZorphyNodeIr` tree plus each node's declared
// fields into `fromWire` / `toWire` members — `package:code_builder` specs
// only, no string-buffer assembly, no `generate*` toggle.
//
// Two layers, because the issue's acceptance criteria split between the SHAPE
// of the emitted code and its BEHAVIOUR on corrupt input:
//
//   1. golden (this file) — the emitted source carries the discriminator
//      dispatch, the boundary result types, and the JSON pointers the issue
//      names;
//   2. runtime (`test/runtime/hierarchical_from_wire_test.dart`) — the
//      emitted source is compiled and EXECUTED against arbitrary corrupt
//      maps, proving a `BoundaryErr` with accumulated violations and never an
//      uncaught `TypeError`.
//
// The emitter's output is a member list, and a bare member list is not a
// library, so assertions run against whitespace-stripped raw output — the
// technique `issue_148_list_map_cast_test.dart` already uses for long
// generated expressions.

import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyNodeIr _node({
  required String className,
  ArchetypeKind archetype = ArchetypeKind.entity,
  bool isSealedRoot = false,
  List<ZorphyNodeIr> children = const [],
  List<ZorphyNodeIr> superTypes = const [],
  String? principalKey,
  String discriminatorKey = 'kind',
  String? discriminatorValue,
  ZorphyNodeIr? root,
}) {
  return ZorphyNodeIr(
    className: className,
    cleanName: className.replaceAll(r'$', ''),
    archetype: archetype,
    isSealedRoot: isSealedRoot,
    isAbstractIntermediate: superTypes.isNotEmpty && children.isNotEmpty,
    isConcreteLeaf: children.isEmpty,
    superTypes: superTypes,
    directSubTypes: children,
    allConcreteLeaves: const [],
    discriminatorKey: discriminatorKey,
    discriminatorValue: discriminatorValue ?? className.replaceAll(r'$', ''),
    principalKey: principalKey,
    replaySafe: null,
    isSyntheticLeaf: false,
    root: root,
  );
}

/// `$Notification` -> `$OrderNotification` | `$PriceDropNotification`.
///
/// The leaves are built first (a `ZorphyNodeIr` is immutable, so a child
/// cannot point back at a root that names it); the codec only needs
/// `superTypes` on a leaf to decide it stamps a discriminator, and
/// `directSubTypes` on the root to enumerate the tags.
({
  ZorphyNodeIr root,
  ZorphyNodeIr order,
  ZorphyNodeIr priceDrop,
  Map<String, List<BoundaryField>> fields,
})
_notification() {
  final rootStub = _node(className: r'$Notification', isSealedRoot: true);
  final wiredOrder = _node(
    className: r'$OrderNotification',
    discriminatorValue: 'order',
    principalKey: 'id',
    superTypes: [rootStub],
  );
  final wiredPriceDrop = _node(
    className: r'$PriceDropNotification',
    discriminatorValue: 'price_drop',
    principalKey: 'id',
    superTypes: [rootStub],
  );
  final root = _node(
    className: r'$Notification',
    isSealedRoot: true,
    principalKey: 'id',
    children: [wiredOrder, wiredPriceDrop],
  );
  return (
    root: root,
    order: wiredOrder,
    priceDrop: wiredPriceDrop,
    fields: {
      r'$Notification': const [
        BoundaryField(name: 'id', type: 'String'),
        BoundaryField(name: 'createdAt', type: 'DateTime'),
      ],
      r'$OrderNotification': const [
        BoundaryField(name: 'id', type: 'String'),
        BoundaryField(name: 'createdAt', type: 'DateTime'),
        BoundaryField(name: 'orderId', type: 'String'),
        BoundaryField(name: 'note', type: 'String?'),
      ],
      r'$PriceDropNotification': const [
        BoundaryField(name: 'id', type: 'String'),
        BoundaryField(name: 'createdAt', type: 'DateTime'),
        BoundaryField(name: 'oldPrice', type: 'double'),
        BoundaryField(name: 'newPrice', type: 'double'),
      ],
    },
  );
}

String _emit(List<Method> methods) => ZorphyEmitter().emitSpecs(methods);

String _compact(String source) => source.replaceAll(RegExp(r'\s+'), '');

/// The emitter's source with comment lines removed, so the acceptance gate
/// reads CODE and not the prose that names the forbidden construct.
String _emitterCode() => File('lib/src/emission/boundary_codec_emitter.dart')
    .readAsLinesSync()
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  group('golden: dispatch node', () {
    late String source;
    late String compact;

    setUpAll(() {
      final fixture = _notification();
      const emitter = BoundaryCodecEmitter();
      source = _emit([
        emitter.fromWire(fixture.root, fixture.fields),
        emitter.toWire(fixture.root, fixture.fields),
      ]);
      compact = _compact(source);
    });

    test('fromWire is static and returns the boundary result', () {
      expect(
        compact,
        contains('staticZorphyBoundaryResult<Notification>fromWire('),
      );
      expect(compact, contains('Map<String,Object?>raw'));
    });

    test('dispatches on the discriminator and delegates to each leaf', () {
      expect(source, contains("raw['kind']"));
      expect(source, contains("case 'order':"));
      expect(source, contains("case 'price_drop':"));
      expect(compact, contains('OrderNotification.fromWire(raw)'));
      expect(compact, contains('PriceDropNotification.fromWire(raw)'));
    });

    test('a missing or unknown tag answers a structured violation', () {
      // The pointer is `/` + the hierarchy's discriminator key.
      expect(compact, contains("FieldViolation(path:'/kind',"));
      expect(compact, contains('BoundaryErr<Notification>'));
      expect(compact, contains('_boundaryDescribe(tag)'));
      // Neither direction throws: `fromWire` answers a `BoundaryErr` for a bad
      // tag, and `toWire` ENCODES an unhandled subtype (it no longer throws an
      // `UnsupportedError`), so the "never a thrown UnsupportedError" promise
      // holds for the whole codec, not just the decode side.
      expect(compact, contains('targetType:'));
      expect(source, isNot(contains('UnsupportedError')));
      expect(
        _compact(
          _emit([
            const BoundaryCodecEmitter().fromWire(
              _notification().root,
              _notification().fields,
            ),
          ]),
        ),
        isNot(contains('UnsupportedError')),
      );
    });

    test('the re-typed leaf result keeps the root contract', () {
      expect(compact, contains('fold<ZorphyBoundaryResult<Notification>>'));
      expect(compact, contains('BoundaryOk<Notification>(value)'));
    });

    test('toWire dispatches to the matching leaf without a cast', () {
      expect(compact, contains('if(valueisOrderNotification)'));
      expect(compact, contains('returnvalue.toWire();'));
      expect(source, isNot(contains(' as OrderNotification')));
    });

    test('toWire encodes an unhandled subtype instead of throwing', () {
      // The dispatch's fallback is a returned map keyed by the discriminator,
      // never a `throw` — the boundary promise is symmetric with fromWire.
      expect(compact, isNot(contains('throw')));
      expect(compact, contains("return<String,Object?>{'kind':'\$runtimeType'};"));
    });
  });

  group('golden: num field encode', () {
    test('a num field round-trips through toDouble, a double stays identity', () {
      const numFields = <String, List<BoundaryField>>{
        r'$OrderNotification': [
          BoundaryField(name: 'ratio', type: 'num'),
          BoundaryField(name: 'price', type: 'double'),
        ],
      };
      final fixture = _notification();
      final toWire = _compact(
        _emit([
          const BoundaryCodecEmitter().toWire(fixture.order, numFields),
        ]),
      );
      // A `num` may carry an int the decode side widens to double, so encode
      // widens too; a `double` is already a double and is emitted as-is.
      expect(toWire, contains("map['ratio']=ratio.toDouble();"));
      expect(toWire, contains("map['price']=price;"));
    });
  });

  group('golden: leaf node', () {
    late String fromWireSource;
    late String compact;

    setUpAll(() {
      final fixture = _notification();
      const emitter = BoundaryCodecEmitter();
      fromWireSource = _emit([
        emitter.fromWire(
          fixture.order,
          fixture.fields,
          additionalNodes: const {'Notification', 'PriceDropNotification'},
        ),
      ]);
      compact = _compact(fromWireSource);
    });

    test('decodes through the trusted constructor', () {
      expect(compact, contains('OrderNotification.fromTrusted('));
      expect(compact, contains('BoundaryOk<OrderNotification>'));
    });

    test('accumulates violations instead of returning early', () {
      expect(compact, contains('<FieldViolation>[]'));
      expect(compact, contains('if(violations.isNotEmpty)'));
    });

    test('every read is a total helper, never an as-cast', () {
      expect(compact, contains('_boundaryAs<String>'));
      expect(compact, contains('_boundaryDateTime'));
      expect(fromWireSource, isNot(contains(' as String')));
      expect(fromWireSource, isNot(contains(' as DateTime')));
    });

    test('toWire stamps the discriminator automatically', () {
      final fixture = _notification();
      final toWire = _compact(
        _emit([
          const BoundaryCodecEmitter().toWire(fixture.order, fixture.fields),
        ]),
      );
      expect(toWire, contains("<String,Object?>{'kind':'order'}"));
      expect(toWire, contains("map['orderId']=orderId;"));
      expect(toWire, contains("map['createdAt']=createdAt.toIso8601String();"));
      expect(toWire, contains('if(note!=null)'));
    });
  });

  group('golden: multi-level hierarchy', () {
    // $Contract -> $FrameContract -> $KitchenFrameContract
    late ZorphyNodeIr root;
    late ZorphyNodeIr frame;
    late ZorphyNodeIr kitchen;

    setUp(() {
      kitchen = _node(
        className: r'$KitchenFrameContract',
        archetype: ArchetypeKind.value,
        discriminatorValue: 'kitchen_frame',
      );
      final rootStub = _node(
        className: r'$Contract',
        archetype: ArchetypeKind.value,
        isSealedRoot: true,
      );
      frame = _node(
        className: r'$FrameContract',
        archetype: ArchetypeKind.value,
        discriminatorValue: 'frame',
        children: [kitchen],
        superTypes: [rootStub],
      );
      root = _node(
        className: r'$Contract',
        archetype: ArchetypeKind.value,
        isSealedRoot: true,
        children: [frame],
      );
    });

    test(
      'a mid-level node dispatches to its own leaves, not its parent\'s',
      () {
        final compact = _compact(
          _emit([const BoundaryCodecEmitter().fromWire(frame, const {})]),
        );
        expect(compact, contains('ZorphyBoundaryResult<FrameContract>'));
        expect(compact, contains("case'kitchen_frame':"));
        // The root's own tag is not this node's business.
        expect(compact, isNot(contains("case'frame':")));
      },
    );

    test('leavesOf walks only the subtree below a node', () {
      expect(
        BoundaryCodecEmitter.leavesOf(root).map((leaf) => leaf.cleanName),
        ['KitchenFrameContract'],
      );
      expect(
        BoundaryCodecEmitter.leavesOf(frame).map((leaf) => leaf.cleanName),
        ['KitchenFrameContract'],
      );
      expect(
        BoundaryCodecEmitter.leavesOf(kitchen).map((leaf) => leaf.cleanName),
        ['KitchenFrameContract'],
      );
    });
  });

  group('golden: collections', () {
    final fixture = _notification();
    const emitter = BoundaryCodecEmitter();

    test('a List<Node> field recurses and re-paths the violations', () {
      const fields = <String, List<BoundaryField>>{
        r'$OrderNotification': [
          BoundaryField(name: 'lines', type: 'List<OrderLine>'),
        ],
      };
      final compact = _compact(
        _emit([
          emitter.fromWire(
            fixture.order,
            fields,
            additionalNodes: const {'OrderLine'},
          ),
        ]),
      );
      expect(compact, contains('OrderLine.fromWire(element_lines)'));
      expect(compact, contains('_boundaryPrefix(error.violations,path_lines)'));
      expect(compact, contains("path_lines='/lines'+'[\$i]'"));
      expect(compact, contains('decoded_lines=<OrderLine>[]'));
      expect(compact, isNot(contains('asList<OrderLine>')));
    });

    test('a List<double> decodes element-wise, never a hard list cast', () {
      const fields = <String, List<BoundaryField>>{
        r'$OrderNotification': [
          BoundaryField(name: 'prices', type: 'List<double>'),
        ],
      };
      final source = _emit([emitter.fromWire(fixture.order, fields)]);
      expect(_compact(source), contains('decoded_prices=<double>[]'));
      expect(source, contains('_boundaryDouble('));
      expect(source, isNot(contains(' as List<double>')));
    });

    test('a List<DateTime> round-trips through ISO-8601', () {
      const fields = <String, List<BoundaryField>>{
        r'$OrderNotification': [
          BoundaryField(name: 'seenAt', type: 'List<DateTime>'),
        ],
      };
      final compact = _compact(
        [
          _emit([emitter.fromWire(fixture.order, fields)]),
          _emit([emitter.toWire(fixture.order, fields)]),
        ].join('\n'),
      );
      expect(compact, contains('_boundaryDateTime(list_seenAt[i]'));
      expect(
        compact,
        contains('seenAt.map((e)=>e.toIso8601String()).toList()'),
      );
    });

    test('a Map<String, Node> field decodes entry-wise', () {
      const fields = <String, List<BoundaryField>>{
        r'$OrderNotification': [
          BoundaryField(name: 'byId', type: 'Map<String, OrderLine>'),
        ],
      };
      final compact = _compact(
        _emit([
          emitter.fromWire(
            fixture.order,
            fields,
            additionalNodes: const {'OrderLine'},
          ),
        ]),
      );
      expect(compact, contains('decoded_byId[entry.key]=element_byId;'));
      expect(compact, contains('OrderLine.fromWire(element_byId)'));
      expect(compact, contains("path_byId='/byId'+'/'+entry.key"));
    });

    test('a nested node field recurses through its own fromWire', () {
      const fields = <String, List<BoundaryField>>{
        r'$OrderNotification': [
          BoundaryField(name: 'line', type: 'OrderLine'),
          BoundaryField(name: 'lastLine', type: 'OrderLine?'),
        ],
      };
      final compact = _compact(
        _emit([
          emitter.fromWire(
            fixture.order,
            fields,
            additionalNodes: const {'OrderLine'},
          ),
        ]),
      );
      expect(compact, contains('OrderLine.fromWire(map_line)'));
      // A nullable node field is only decoded when the key is present.
      expect(compact, contains('if(raw_lastLine!=null)'));
    });
  });

  group('acceptance: zero toggles, code_builder only', () {
    late String code;

    setUpAll(() => code = _emitterCode());

    test('no preset and no generate* toggle', () {
      expect(code, isNot(contains('ZorphyPreset')));
      expect(RegExp(r'bool\s+generate[A-Z]').hasMatch(code), isFalse);
    });

    test('every spec comes from package:code_builder', () {
      expect(code, contains('package:code_builder/code_builder.dart'));
      expect(code, isNot(contains('StringBuffer')));
    });

    test('the emitter exposes no boolean feature switches', () {
      // The only public knobs are a constructor name; a `bool` parameter on
      // a public member would be a toggle by another spelling.
      expect(RegExp(r'\bbool\s+\w+\s*[,)=]').hasMatch(code), isFalse);
    });
  });
}
