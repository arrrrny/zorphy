// Golden tests for arrrrny/zorphy#310: `fromJson` / `toJson` compat aliases
// over the canonical `fromWire` / `toWire` boundary API.
//
// The aliases are emitted ONLY where they typecheck:
//
//   * a non-generic node (entity / value / concrete union root) gets BOTH
//     `Map<String, dynamic> toJson() => toWire();` and a static
//     `factory <Name>.fromJson(Map<String, dynamic> json) => <Name>.fromWire(json);`
//     — but a `factory` cannot be expressed as a bare member, so the emitter
//     emits a static `fromJson` returning the boundary result, the same shape
//     `fromWire` already has;
//   * a GENERIC node's `toWire` is codec-parameterized, so a zero-arg
//     `toJson()` does NOT typecheck — the aliases are skipped there.
//
// The trust boundary is unchanged: `fromJson` aliases the STRICT validating
// `fromWire`, never `fromTrusted`.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyNodeIr _node({
  required String className,
  List<String> typeParameters = const [],
  List<ZorphyNodeIr> superTypes = const [],
  bool isConcreteLeaf = true,
}) {
  return ZorphyNodeIr(
    className: className,
    cleanName: className.replaceAll(r'$', ''),
    archetype: ArchetypeKind.entity,
    isSealedRoot: superTypes.isEmpty,
    isAbstractIntermediate: false,
    isConcreteLeaf: isConcreteLeaf,
    superTypes: superTypes,
    directSubTypes: const [],
    allConcreteLeaves: const [],
    discriminatorKey: 'kind',
    discriminatorValue: className.replaceAll(r'$', ''),
    principalKey: null,
    replaySafe: null,
    isSyntheticLeaf: false,
    typeParameters: typeParameters,
  );
}

String _emit(List<Method> methods) => ZorphyEmitter().emitSpecs(methods);

String _compact(String source) => source.replaceAll(RegExp(r'\s+'), '');

void main() {
  group('golden: non-generic entity emits both aliases', () {
    test('toJson is a zero-arg Map<String, dynamic> delegating to toWire', () {
      final node = _node(className: r'$Order');
      const fields = {
        r'$Order': [BoundaryField(name: 'id', type: 'String')],
      };
      final compact = _compact(
        _emit([const BoundaryCodecEmitter().toJson(node, fields)!]),
      );
      expect(compact, contains('Map<String,dynamic>toJson(){returntoWire();}'));
    });

    test('fromJson is static and aliases the strict fromWire', () {
      final node = _node(className: r'$Order');
      const fields = {
        r'$Order': [BoundaryField(name: 'id', type: 'String')],
      };
      final compact = _compact(
        _emit([const BoundaryCodecEmitter().fromJson(node, fields)!]),
      );
      expect(
        compact,
        contains(
          'staticZorphyBoundaryResult<Order>fromJson(Map<String,dynamic>json)',
        ),
      );
      expect(compact, contains('returnOrder.fromWire(json);'));
    });
  });

  group('golden: emitJsonAliases bundles both for a non-generic node', () {
    test('returns fromWire, toWire, fromJson, toJson in order', () {
      final node = _node(className: r'$Order');
      const fields = {
        r'$Order': [BoundaryField(name: 'id', type: 'String')],
      };
      final methods = const BoundaryCodecEmitter().emitJsonAliases(
        node,
        fields,
      );
      expect(methods.map((m) => m.name), [
        'fromWire',
        'toWire',
        'fromJson',
        'toJson',
      ]);
    });

    test('a generic node emits NO aliases', () {
      final node = _node(className: r'$Box', typeParameters: ['T']);
      const fields = {
        r'$Box': [BoundaryField(name: 'value', type: 'T')],
      };
      final methods = const BoundaryCodecEmitter().emitJsonAliases(
        node,
        fields,
      );
      expect(methods.map((m) => m.name), ['fromWire', 'toWire']);
    });
  });

  group('golden: generic node aliases are skipped individually', () {
    test('toJson on a generic node is not emitted (empty)', () {
      final node = _node(className: r'$Box', typeParameters: ['T']);
      const fields = {
        r'$Box': [BoundaryField(name: 'value', type: 'T')],
      };
      // A generic node has no zero-arg toJson; the emitter returns no method.
      final methods = <Method>[
        if (const BoundaryCodecEmitter().toJson(node, fields) != null)
          const BoundaryCodecEmitter().toJson(node, fields)!,
      ];
      expect(methods, isEmpty);
    });
  });
}
