// Golden tests for ZRP-009 (arrrrny/zorphy#272): codec-parameterized
// `toWire` / `fromWire` on generic `@ZorphyValue` / `@ZorphyEntity` /
// `@ZorphyUnion` classes.
//
// A generic class `Foo<T, ...>` gets one codec parameter per type parameter,
// in declaration order:
//
//   * `toWire` takes an encoder per type parameter and routes every field
//     that mentions the parameter through it (a nullable `T?` passes `null`
//     through and never calls the encoder);
//   * `fromWire` is static, takes a decoder per type parameter (each decoder
//     consumes the field's raw map), and merges the decoder's violations with
//     the wrapper field violations into one `ZorphyBoundaryResult`.
//
// These assertions run against whitespace-stripped raw output — the technique
// `boundary_codec_golden_test.dart` uses, because a bare member list is not a
// library.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyNodeIr _node({
  required String className,
  List<String> typeParameters = const [],
  List<ZorphyNodeIr> superTypes = const [],
  String? principalKey,
}) {
  return ZorphyNodeIr(
    className: className,
    cleanName: className.replaceAll(r'$', ''),
    archetype: ArchetypeKind.value,
    isSealedRoot: superTypes.isEmpty,
    isAbstractIntermediate: false,
    isConcreteLeaf: true,
    superTypes: superTypes,
    directSubTypes: const [],
    allConcreteLeaves: const [],
    discriminatorKey: 'kind',
    discriminatorValue: className.replaceAll(r'$', ''),
    principalKey: principalKey,
    replaySafe: null,
    isSyntheticLeaf: false,
    typeParameters: typeParameters,
  );
}

String _emit(List<Method> methods) => ZorphyEmitter().emitSpecs(methods);

String _compact(String source) => source.replaceAll(RegExp(r'\s+'), '');

void main() {
  group('golden: generic value — single type parameter', () {
    // `CreateParams<T>` with a `T data` field and a nullable `String? key`.
    late ZorphyNodeIr node;
    late Map<String, List<BoundaryField>> fields;

    setUp(() {
      node = _node(className: r'$CreateParams', typeParameters: ['T']);
      fields = {
        r'$CreateParams': const [
          BoundaryField(name: 'data', type: 'T'),
          BoundaryField(name: 'idempotencyKey', type: 'String?'),
        ],
      };
    });

    test('toWire takes one encoder per type parameter', () {
      final compact = _compact(
        _emit([const BoundaryCodecEmitter().toWire(node, fields)]),
      );
      expect(compact, contains('Map<String,Object?>toWire('));
      expect(compact, contains('Map<String,Object?>Function(Tvalue)encodeT'));
      // The `T` field routes through the encoder; the scalar is unchanged.
      expect(compact, contains("map['data']=encodeT(this.data);"));
      expect(compact, contains("map['idempotencyKey']=_idempotencyKey;"));
    });

    test(
      'fromWire is static, re-declares the type parameter, takes a decoder',
      () {
        final compact = _compact(
          _emit([const BoundaryCodecEmitter().fromWire(node, fields)]),
        );
        expect(
          compact,
          contains('staticZorphyBoundaryResult<CreateParams<T>>fromWire<T>('),
        );
        expect(
          compact,
          contains(
            'ZorphyBoundaryResult<T>Function(Map<String,Object?>raw)decodeT',
          ),
        );
        // The decoder consumes the field's raw map and its violations merge.
        expect(compact, contains('decodeT(map_data)'));
        expect(compact, contains("_boundaryPrefix(error.violations,'/data')"));
        expect(compact, contains('CreateParams.fromTrusted('));
      },
    );
  });

  group('golden: generic value — nullable T? passes null through', () {
    test('toWire guards the encoder behind a null check', () {
      final node = _node(className: r'$Maybe', typeParameters: ['T']);
      const fields = {
        r'$Maybe': [BoundaryField(name: 'value', type: 'T?')],
      };
      final compact = _compact(
        _emit([const BoundaryCodecEmitter().toWire(node, fields)]),
      );
      expect(compact, contains('final_value=this.value;'));
      expect(
        compact,
        contains('if(_value!=null){map[\'value\']=encodeT(_value);}'),
      );
    });

    test('fromWire decodes a present nullable T and keeps null absent', () {
      final node = _node(className: r'$Maybe', typeParameters: ['T']);
      const fields = {
        r'$Maybe': [BoundaryField(name: 'value', type: 'T?')],
      };
      final compact = _compact(
        _emit([const BoundaryCodecEmitter().fromWire(node, fields)]),
      );
      // An absent nullable key is legal: decode only when present.
      expect(compact, contains('if(raw_value!=null){'));
      expect(compact, contains('decodeT(map_value)'));
    });
  });

  group('golden: generic value — two type parameters', () {
    test('Pair<A, B> threads both codecs in declaration order', () {
      final node = _node(className: r'$Pair', typeParameters: ['A', 'B']);
      const fields = {
        r'$Pair': [
          BoundaryField(name: 'first', type: 'A'),
          BoundaryField(name: 'second', type: 'B'),
        ],
      };
      final toWire = _compact(
        _emit([const BoundaryCodecEmitter().toWire(node, fields)]),
      );
      expect(
        toWire,
        contains(
          'Map<String,Object?>Function(Avalue)encodeA,'
          'Map<String,Object?>Function(Bvalue)encodeB',
        ),
      );
      expect(toWire, contains("map['first']=encodeA(this.first);"));
      expect(toWire, contains("map['second']=encodeB(this.second);"));

      final fromWire = _compact(
        _emit([const BoundaryCodecEmitter().fromWire(node, fields)]),
      );
      expect(fromWire, contains('fromWire<A,B>('));
      expect(fromWire, contains('decodeA(map_first)'));
      expect(fromWire, contains('decodeB(map_second)'));
    });
  });

  group('golden: generic value — List<T> routes element-wise', () {
    test('a List<T> field maps the encoder over its elements', () {
      final node = _node(className: r'$Slice', typeParameters: ['T']);
      const fields = {
        r'$Slice': [BoundaryField(name: 'items', type: 'List<T>')],
      };
      final toWire = _compact(
        _emit([const BoundaryCodecEmitter().toWire(node, fields)]),
      );
      expect(
        toWire,
        contains("map['items']=this.items.map(encodeT).toList();"),
      );

      final fromWire = _compact(
        _emit([const BoundaryCodecEmitter().fromWire(node, fields)]),
      );
      // Each element decodes through the parameter decoder and re-paths under
      // the element pointer.
      expect(fromWire, contains('decodeT(element_items)'));
      expect(fromWire, contains("path_items='/items'+'[\$i]'"));
    });
  });

  group(
    'golden: generic value — unbounded codec is required, not optional',
    () {
      test('an unbounded T encoder/decoder parameter is required', () {
        final node = _node(className: r'$Box', typeParameters: ['T']);
        const fields = {
          r'$Box': [BoundaryField(name: 'value', type: 'T')],
        };
        final toWire = _compact(
          _emit([const BoundaryCodecEmitter().toWire(node, fields)]),
        );
        // No `?` after the function type: the parameter is required.
        expect(toWire, contains('Function(Tvalue)encodeT)'));
        expect(toWire, isNot(contains('Function(Tvalue)encodeT?')));
      });
    },
  );
}
