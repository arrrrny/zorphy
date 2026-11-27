// Regression tests for issue #313: enum wire support at the entity boundary
// codec and in `MockData`.
//
// Two gaps the issue names, both generator-side:
//
//   1. `BoundaryCodecEmitter` classified an enum field as a plain scalar, so
//      decode ran a reified `is` test (a wire string recorded a TYPE violation
//      instead of resolving by name) and encode emitted the raw `Enum`
//      instance — `jsonEncode(toWire())` then threw for any enum-bearing
//      entity. The fix mirrors the patch wire path: encode `value.name`,
//      decode via `ZorphyPatchWire.enumByName`.
//
//   2. `MockFixtureEmitter` refused an enum field as unseedable, so a required
//      enum field made `MockData.single()` throw `UnsupportedError` and
//      cascaded to every fixture of the entity. The fix seeds by index
//      (`EnumType.values[seed % length]`) so `list(count:)` cycles every case.
//
// This is the golden layer: it pins the SHAPE of the emitted source. The
// behaviour is exercised in `test/runtime/enum_wire_boundary_test.dart`.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/emitters/mock_fixture_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyNodeIr _leaf({
  required String className,
  List<ZorphyFieldIr> fields = const [],
  String? principalKey,
}) => ZorphyNodeIr(
  className: className,
  cleanName: className.replaceAll(r'$', ''),
  archetype: ArchetypeKind.entity,
  isSealedRoot: true,
  isAbstractIntermediate: false,
  isConcreteLeaf: true,
  superTypes: const [],
  directSubTypes: const [],
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: className.replaceAll(r'$', ''),
  principalKey: principalKey,
  replaySafe: null,
  isSyntheticLeaf: false,
  fields: fields,
);

String _emit(List<Method> methods) => ZorphyEmitter().emitSpecs(methods);

String _compact(String source) => source.replaceAll(RegExp(r'\s+'), '');

void main() {
  group('golden: boundary codec enum field (#313)', () {
    late String source;
    late String compact;

    setUpAll(() {
      final node = _leaf(
        className: r'$Account',
        principalKey: 'id',
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
      final fields = <String, List<BoundaryField>>{
        r'$Account': const [
          BoundaryField(name: 'id', type: 'String'),
          BoundaryField(name: 'tier', type: 'AccountTier', isEnum: true),
        ],
      };
      const emitter = BoundaryCodecEmitter();
      source = _emit([
        emitter.fromWire(node, fields),
        emitter.toWire(node, fields),
      ]);
      compact = _compact(source);
    });

    test('encode writes the enum NAME, not the raw instance', () {
      // `this.tier is Enum ? this.tier.name : this.tier` — a JSON hop survives.
      expect(compact, contains('this.tierisEnum?this.tier.name:this.tier'));
    });

    test('decode resolves by name through enumByName', () {
      expect(
        compact,
        contains('ZorphyPatchWire.enumByName<AccountTier>(AccountTier.values,'),
      );
    });

    test('the plain scalar reified `is` test is NOT used for the enum', () {
      // `_boundaryAs<AccountTier>` would be the old, broken classification.
      expect(compact, isNot(contains('_boundaryAs<AccountTier>')));
    });
  });

  group('golden: MockData enum seed (#313)', () {
    late String source;

    setUpAll(() {
      final node = _leaf(
        className: r'$Account',
        principalKey: 'id',
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
      source = MockFixtureEmitter().emitForNode(node);
    });

    test('seeds the enum by index, cycling every value', () {
      final compact = _compact(source);
      expect(
        compact,
        contains('AccountTier.values[seed%AccountTier.values.length]'),
      );
    });

    test('does NOT throw UnsupportedError for the required enum field', () {
      expect(source, isNot(contains('has no seedable value')));
    });
  });
}
