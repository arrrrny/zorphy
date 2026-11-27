// Regression tests for issue #284 — five generated-code defects found during
// the zuraffa v3 migration review. Each test drives the owning emitter directly
// and asserts on the emitted source, the same technique the other golden tests
// use. They are RED on the unfixed generator and GREEN once the generator is
// fixed; the generated `.part.dart` files are never hand-edited.

import 'package:test/test.dart';
import 'package:zorphy/src/common/name_type.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/emission/polymorphic_class_emitter.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';
import 'package:zorphy/src/emitters/mock_fixture_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

ZorphyNodeIr _node({
  required String className,
  ArchetypeKind archetype = ArchetypeKind.entity,
  bool isSealedRoot = false,
  bool isUnion = false,
  List<ZorphyNodeIr> children = const [],
  List<ZorphyNodeIr> superTypes = const [],
  String? principalKey,
  ZorphyNodeIr? root,
  List<ZorphyFieldIr> fields = const [],
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
    discriminatorKey: 'kind',
    discriminatorValue: className.replaceAll(r'$', ''),
    principalKey: principalKey,
    isUnion: isUnion,
    root: root,
    fields: fields,
  );
}

PolymorphicField _field(String name, String type, {bool nullable = false}) =>
    PolymorphicField(name: name, type: type, isNullable: nullable);

String _compact(String source) => source.replaceAll(RegExp(r'\s+'), '');

void main() {
  group('#284.1 — union root carries the union marker', () {
    test(
      'a @ZorphyUnion root implements ZorphyUnionBase, not ZorphyValueBase',
      () {
        final leaf = _node(
          className: r'$BoundaryViolation',
          archetype: ArchetypeKind.value,
          isUnion: true,
        );
        final root = _node(
          className: r'$AppFailure',
          archetype: ArchetypeKind.value,
          isSealedRoot: true,
          isUnion: true,
          children: [leaf],
        );

        final source = const PolymorphicClassEmitter().emit(
          root: root,
          fields: {
            r'$AppFailure': const [],
            r'$BoundaryViolation': [_field('violations', 'List<String>')],
          },
        );

        expect(
          source,
          contains('sealed class AppFailure implements ZorphyUnionBase'),
        );
        expect(
          source,
          isNot(contains('class AppFailure implements ZorphyValueBase')),
        );
        // The variant member carries the marker too.
        expect(source, contains('implements ZorphyUnionBase'));
      },
    );

    test('a plain @ZorphyValue hierarchy still implements ZorphyValueBase', () {
      final leaf = _node(className: r'$Circle', archetype: ArchetypeKind.value);
      final root = _node(
        className: r'$Shape',
        archetype: ArchetypeKind.value,
        isSealedRoot: true,
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Shape': [_field('area', 'double')],
          r'$Circle': [_field('area', 'double')],
        },
      );

      expect(source, contains('sealed class Shape implements ZorphyValueBase'));
      expect(source, isNot(contains('ZorphyUnionBase')));
    });
  });

  group('#284.2 — unseedable collection variant stays in rotation', () {
    test('a List of an unseedable element seeds an empty list, not a throw', () {
      final leaf = _node(
        className: r'$BoundaryViolation',
        archetype: ArchetypeKind.value,
        isUnion: true,
        fields: const [
          ZorphyFieldIr(name: 'violations', type: r'List<$FieldViolation>'),
        ],
      );
      final root = _node(
        className: r'$AppFailure',
        archetype: ArchetypeKind.value,
        isSealedRoot: true,
        isUnion: true,
        children: [leaf],
      );

      final source = MockFixtureEmitter().emit(root);

      // The single() builder must construct the variant with an empty (valid)
      // list rather than throw UnsupportedError, so every variant stays in the
      // rotation that list() walks.
      expect(source, isNot(contains('UnsupportedError')));
      expect(_compact(source), contains('violations:[]'));
    });
  });

  group('#284.3 — collection fields are snapshotted at construction', () {
    test('fromTrusted copies a List field and is no longer const', () {
      final leaf = _node(
        className: r'$OrderCart',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Cart',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Cart': [_field('id', 'String')],
          r'$OrderCart': [
            _field('id', 'String'),
            _field('items', 'List<String>'),
            _field('scores', 'Map<String, int>'),
          ],
        },
      );

      // A collection field is defensively copied so a later mutation of the
      // caller's list/map cannot change an already-built value.
      expect(source, contains('List<String>.of(items)'));
      expect(source, contains('Map<String, int>.of(scores)'));
      // A constructor that copies cannot be const.
      expect(source, isNot(contains('const OrderCart.fromTrusted')));
    });

    test('a scalar-only class keeps its const fromTrusted', () {
      final leaf = _node(
        className: r'$OrderNotification',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Notification',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Notification': [_field('id', 'String')],
          r'$OrderNotification': [
            _field('id', 'String'),
            _field('orderId', 'String'),
          ],
        },
      );

      expect(source, contains('const OrderNotification.fromTrusted({'));
    });
  });

  group('#284.4 — explicit null in a dynamic map survives a round trip', () {
    test('a Map<String, dynamic> value keeps a null element', () {
      final leaf = _node(
        className: r'$Params',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );

      final source = ZorphyEmitter().emitSpecs([
        BoundaryCodecEmitter().fromWire(leaf, {
          r'$Params': const [
            BoundaryField(name: 'id', type: 'String'),
            BoundaryField(name: 'params', type: 'Map<String, dynamic>'),
          ],
        }),
      ]);
      final compact = _compact(source);

      // The decode of a dynamic-valued map must short-circuit a null element
      // into the map (keep it) instead of dropping it through the
      // `if (x != null)` guard.
      expect(
        compact,
        contains(
          'if(map_params[entry.key]==null){decoded_params[entry.key]=null;}',
        ),
      );
    });
  });

  group('#284.5 — patch decoder reports envelope errors at /ops/<field>', () {
    test('a concrete patch fromWire prefixes field paths with opsPathOf', () {
      final source = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('itemCount', 'int', ''),
        ],
        sharedFields: const ['id'],
      );

      // The field read path is built from ZorphyPatchWire.opsPathOf(raw), so an
      // envelope decode points at /ops/id while a bare patch keeps /id.
      expect(source, contains('ZorphyPatchWire.opsPathOf(raw)'));
      expect(_compact(source), contains("fieldValue(ops['id'],'\$prefix/id'"));
    });
  });

  // Follow-ups from the #285 review: the snapshot fix exposed several ways the
  // emitted type/equality/hint paths disagreed with the declared field.
  group('#285 review — collection snapshot correctness follow-ups', () {
    test('fromTrusted lowers \$ in a collection element type', () {
      final leaf = _node(
        className: r'$OrderCart',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Cart',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );
      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Cart': [_field('id', 'String')],
          r'$OrderCart': [
            _field('id', 'String'),
            _field('addresses', r'List<$Address>'),
          ],
        },
      );
      final compact = _compact(source);

      // The parameter, the storage field and the `.of` copy must all agree on
      // the lowered type; the generator's `$` declaration prefix never reaches
      // emitted source.
      expect(compact, contains('requiredList<Address>addresses'));
      expect(compact, contains('List<Address>.of(addresses)'));
      expect(compact, isNot(contains(r'List<$Address>')));
    });

    test(
      'the snapshot strips only the outer ? and keeps element nullability',
      () {
        final leaf = _node(
          className: r'$OrderCart',
          archetype: ArchetypeKind.entity,
          principalKey: 'id',
        );
        final root = _node(
          className: r'$Cart',
          archetype: ArchetypeKind.entity,
          isSealedRoot: true,
          principalKey: 'id',
          children: [leaf],
        );
        final source = const PolymorphicClassEmitter().emit(
          root: root,
          fields: {
            r'$Cart': [_field('id', 'String')],
            r'$OrderCart': [
              _field('id', 'String'),
              _field('items', 'List<String?>'),
              _field('scores', 'Map<String, int?>'),
              _field('maybe', 'List<String>', nullable: true),
            ],
          },
        );
        final compact = _compact(source);

        expect(compact, contains('List<String?>.of(items)'));
        expect(compact, contains('Map<String,int?>.of(scores)'));
        expect(
          compact,
          contains('maybe=maybe==null?null:List<String>.of(maybe)'),
        );
        expect(compact, isNot(contains('List<String>.of(items)')));
      },
    );

    test('collection fields use content-based == and hashCode', () {
      final leaf = _node(
        className: r'$OrderCart',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Cart',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );
      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Cart': [_field('id', 'String')],
          r'$OrderCart': [
            _field('id', 'String'),
            _field('items', 'List<String>'),
          ],
        },
      );
      final compact = _compact(source);

      // A defensive copy gives each value a different list instance, so the
      // generated operators must compare/hash CONTENTS to keep
      // `value == value.copyWith()` true.
      expect(
        compact,
        contains('zorphyCollectionEquals(this.items,other.items)'),
      );
      expect(compact, contains('zorphyCollectionHash(items)'));
      expect(compact, isNot(contains('_zorphyCollectionEquals')));
      expect(compact, isNot(contains('_zorphyCollectionHash')));
    });

    test('example hints render nested collections recursively', () {
      final leaf = _node(
        className: r'$Fixture',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
        fields: const [
          ZorphyFieldIr(name: 'nested', type: 'List<List<Status>>?'),
        ],
      );
      final emitted = MockFixtureEmitter().emitForNode(
        leaf,
        mockSeeds: const {
          'nested': ZorphyMock(example: <Object>[<Object>[]]),
        },
      );
      final compact = _compact(emitted);

      expect(compact, contains('nested:[[]]'));
      expect(compact, isNot(contains("'[]'")));
    });

    test('example hints respect collection kind and element nullability', () {
      final leaf = _node(
        className: r'$Fixture',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
        fields: const [
          ZorphyFieldIr(name: 'setField', type: 'Set<Status>?'),
          ZorphyFieldIr(name: 'mapField', type: 'Map<String, Status>'),
          ZorphyFieldIr(name: 'nullableMap', type: 'Map<String, Status?>'),
        ],
      );
      final emitted = MockFixtureEmitter().emitForNode(
        leaf,
        mockSeeds: const {
          // A List hint cannot seed a Set field.
          'setField': ZorphyMock(example: <Object>[]),
          // A null hint cannot seed a non-nullable Status value.
          'mapField': ZorphyMock(example: <String, Object?>{'first': null}),
          // ...but a nullable Status? value still accepts it.
          'nullableMap': ZorphyMock(example: <String, Object?>{'first': null}),
        },
      );
      final compact = _compact(emitted);

      expect(compact, contains('setField:{}'));
      expect(compact, contains('mapField:{}'));
      expect(compact, contains("nullableMap:{'first':null}"));
    });

    test('a compatible Set hint is still accepted', () {
      final leaf = _node(
        className: r'$Fixture',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
        fields: const [ZorphyFieldIr(name: 'setField', type: 'Set<String>')],
      );
      final emitted = MockFixtureEmitter().emitForNode(
        leaf,
        mockSeeds: const {
          'setField': ZorphyMock(example: <String>{'seed'}),
        },
      );

      expect(_compact(emitted), contains("setField:{'seed'}"));
    });
  });
}
