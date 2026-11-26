// Unit tests for the `<Entity>Fields` emitter (issue #247).
//
// `EntityFieldsGenerator` reads a hand-built [PolymorphicIr] — the same pure
// data shape `HierarchyResolver` produces — and emits, for every concrete
// non-generic `@ZorphyEntity` / `@ZorphyValue` node, an
// `abstract final class <Name>Fields` carrying one `ZorphyField<T, V>` per
// payload field (own + inherited, first declaration winning), the private
// tear-off helpers its constants reference, and the `static final all`
// registry list.

import 'package:test/test.dart';
import 'package:zorphy/src/emission/emission_name_helpers.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/emission/entity_fields_generator.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyFieldIr _field(String name, String type, {bool nullable = false}) =>
    ZorphyFieldIr(name: name, type: type, isNullable: nullable);

ZorphyNodeIr _node(
  String className, {
  required ArchetypeKind archetype,
  bool sealedRoot = false,
  bool concreteLeaf = true,
  List<ZorphyFieldIr> fields = const [],
  List<ZorphyNodeIr> superTypes = const [],
  List<ZorphyNodeIr> subTypes = const [],
  List<String> typeParameters = const [],
}) {
  return ZorphyNodeIr(
    className: className,
    qualifiedName: 'test.dart#$className',
    cleanName: concreteTypeName(className),
    archetype: archetype,
    isSealedRoot: sealedRoot,
    isAbstractIntermediate: !sealedRoot && !concreteLeaf,
    isConcreteLeaf: concreteLeaf,
    superTypes: superTypes,
    directSubTypes: subTypes,
    allConcreteLeaves: const [],
    discriminatorKey: 'discriminator',
    discriminatorValue: concreteTypeName(className).toLowerCase(),
    fields: fields,
    typeParameters: typeParameters,
  );
}

/// A standalone `@ZorphyEntity` with two fields — the issue's `Product`.
final product = _node(
  r'$Product',
  archetype: ArchetypeKind.entity,
  fields: [_field('id', 'String'), _field('price', 'double')],
);

/// A standalone `@ZorphyValue` — Fields must be emitted for it too.
final greeting = _node(
  r'$Greeting',
  archetype: ArchetypeKind.value,
  fields: [_field('message', 'String')],
);

/// A sealed entity root; its leaf below inherits a field from it.
final eventRoot = _node(
  r'$Event',
  archetype: ArchetypeKind.entity,
  sealedRoot: true,
  concreteLeaf: false,
  fields: [_field('eventId', 'String')],
);

/// An abstract intermediate carrying its own field.
final deployIntermediate = _node(
  r'$DeployEvent',
  archetype: ArchetypeKind.entity,
  concreteLeaf: false,
  superTypes: [eventRoot],
  fields: [_field('environment', 'String')],
);

/// A concrete leaf: its Fields class must carry its own field AND the
/// inherited ones from [deployIntermediate] and [eventRoot].
final rollbackLeaf = _node(
  r'$RollbackEvent',
  archetype: ArchetypeKind.entity,
  superTypes: [deployIntermediate, eventRoot],
  fields: [_field('fromVersion', 'String')],
);

/// A `@ZorphyState` — Fields are NOT emitted for it (issue #247 names
/// `@ZorphyEntity` and `@ZorphyValue` only).
final readyState = _node(
  r'$ReadyState',
  archetype: ArchetypeKind.state,
  fields: [_field('label', 'String')],
);

/// A generic entity — no Fields class (a static cannot bind `T`).
final box = _node(
  r'$Box',
  archetype: ArchetypeKind.entity,
  typeParameters: ['T'],
  fields: [_field('value', 'T')],
);

PolymorphicIr _ir() {
  final nodes = [
    product,
    greeting,
    eventRoot,
    deployIntermediate,
    rollbackLeaf,
    readyState,
    box,
  ];
  return PolymorphicIr(
    nodes: {for (final n in nodes) n.qualifiedName: n},
    roots: [product, greeting, eventRoot, readyState, box],
    diagnostics: const [],
  );
}

String _emit() => ZorphyEmitter().emitSpecs(
  const EntityFieldsGenerator().fieldsClasses(_ir()),
);

void main() {
  group('EntityFieldsGenerator', () {
    test('emits an abstract final <Name>Fields for an entity', () {
      final code = _emit();
      expect(code, contains('abstract final class ProductFields'));
    });

    test('emits a ZorphyField constant per payload field', () {
      final code = _emit();
      expect(code, contains('static const ZorphyField<Product, String> id ='));
      expect(
        code,
        contains('static const ZorphyField<Product, double> price ='),
      );
      // name / jsonKey / pointer all derived from the field name (the v3 wire
      // key IS the field name — the boundary codec reads raw[field.name]).
      expect(code, contains("name: 'id'"));
      expect(code, contains("jsonKey: 'id'"));
      expect(code, contains("pointer: '/id'"));
      expect(code, contains("pointer: '/price'"));
    });

    test('emits nullable field types as nullable', () {
      final annotated = PolymorphicIr(
        nodes: {},
        roots: [],
        diagnostics: const [],
      );
      final nullableNode = _node(
        r'$Note',
        archetype: ArchetypeKind.value,
        fields: [_field('body', 'String', nullable: true)],
      );
      final ir = PolymorphicIr(
        nodes: {nullableNode.qualifiedName: nullableNode},
        roots: [nullableNode],
        diagnostics: annotated.diagnostics,
      );
      final code = ZorphyEmitter().emitSpecs(
        const EntityFieldsGenerator().fieldsClasses(ir),
      );
      expect(code, contains('ZorphyField<Note, String?>('));
    });

    test('emits the static final all registry of erased entries', () {
      final code = _emit();
      expect(
        code,
        contains(
          'static final List<ZorphyField<Product, Object?>> all = '
          'List.unmodifiable([',
        ),
      );
      // Each entry is the field constant with its value type erased: a typed
      // `ZorphyField<T, V>` in this `Object?` slot compiles and throws on the
      // first `.set` (zorphy#301), so the registry never holds one directly.
      // The list is unmodifiable so no caller can drop an entry and break
      // later `byPointer` lookups (review finding).
      final allLine = RegExp(
        r'static final List<ZorphyField<Product, Object\?>> all = '
        r'List\.unmodifiable\(\[[^\]]*\]\);',
      ).firstMatch(code)!.group(0)!;
      expect(allLine, contains('id.asObject'));
      expect(allLine, contains('price.asObject'));
      expect(allLine, isNot(RegExp(r'\[\s*id\s*[,\]]')));
    });

    test('emits private tear-off get/set helpers routing through copyWith', () {
      final code = _emit();
      expect(code, contains('get: _getId'));
      expect(code, contains('set: _setId'));
      expect(code, contains('static String _getId(Product root) => root.id;'));
      expect(
        code,
        contains(
          'static Product _setId(Product root, String value) => '
          'root.copyWith(id: value);',
        ),
      );
    });

    test('includes inherited fields from parent interfaces (leaf wins)', () {
      final code = _emit();
      // The leaf's Fields carries its own field...
      expect(
        code,
        contains(
          'static const ZorphyField<RollbackEvent, String> '
          'fromVersion =',
        ),
      );
      // ...and every inherited one, nearest declaration winning.
      expect(
        code,
        contains(
          'static const ZorphyField<RollbackEvent, String> '
          'environment =',
        ),
      );
      expect(
        code,
        contains('static const ZorphyField<RollbackEvent, String> eventId ='),
      );
      // The pointer of an inherited field still addresses it on the leaf.
      expect(code, contains("pointer: '/eventId'"));
    });

    test('emits Fields for a @ZorphyValue', () {
      final code = _emit();
      expect(code, contains('abstract final class GreetingFields'));
      expect(code, contains('ZorphyField<Greeting, String>('));
    });

    test('skips @ZorphyState nodes', () {
      final code = _emit();
      expect(code, isNot(contains('ReadyStateFields')));
    });

    test('skips generic nodes', () {
      final code = _emit();
      expect(code, isNot(contains('BoxFields')));
    });

    test('skips abstract intermediates and sealed roots (no copyWith)', () {
      final code = _emit();
      // Word boundaries: `RollbackEventFields` contains the substring
      // `EventFields`, so only a standalone token proves absence.
      expect(RegExp(r'\bEventFields\b').allMatches(code), isEmpty);
      expect(RegExp(r'\bDeployEventFields\b').allMatches(code), isEmpty);
    });

    test('a node with no fields gets no Fields class', () {
      final empty = _node(r'$Empty', archetype: ArchetypeKind.entity);
      final ir = PolymorphicIr(
        nodes: {empty.qualifiedName: empty},
        roots: [empty],
        diagnostics: const [],
      );
      expect(const EntityFieldsGenerator().fieldsClasses(ir), isEmpty);
    });

    test('an aggregate list name collision moves the registry aside', () {
      // A field literally named `all` would collide with the generated
      // registry list; the registry renames instead of emitting a duplicate
      // member (the same decline-by-renaming rule the lens registry applies).
      final colliding = _node(
        r'$Colliding',
        archetype: ArchetypeKind.entity,
        fields: [_field('all', 'String')],
      );
      final ir = PolymorphicIr(
        nodes: {colliding.qualifiedName: colliding},
        roots: [colliding],
        diagnostics: const [],
      );
      final code = ZorphyEmitter().emitSpecs(
        const EntityFieldsGenerator().fieldsClasses(ir),
      );
      expect(code, contains('allFields ='));
      expect(
        code,
        isNot(
          contains('static final List<ZorphyField<Colliding, Object?>> all ='),
        ),
      );
    });

    test('helper names stay unique across same-cased fields', () {
      // `title` and `Title` would both lower to `_getTitle`; the second
      // helper gets an extra underscore instead of emitting a duplicate.
      final tricky = _node(
        r'$Tricky',
        archetype: ArchetypeKind.entity,
        fields: [_field('title', 'String'), _field('Title', 'String')],
      );
      final ir = PolymorphicIr(
        nodes: {tricky.qualifiedName: tricky},
        roots: [tricky],
        diagnostics: const [],
      );
      final code = ZorphyEmitter().emitSpecs(
        const EntityFieldsGenerator().fieldsClasses(ir),
      );
      // One constant reference + one declaration each — and the `Title`
      // helpers must have been uniqued, or these counts double.
      expect(RegExp(r'\b_getTitle\b').allMatches(code).length, 2);
      expect(RegExp(r'\b_setTitle\b').allMatches(code).length, 2);
      expect(code, contains('__getTitle'));
      expect(code, contains('__setTitle'));
    });
  });
}
