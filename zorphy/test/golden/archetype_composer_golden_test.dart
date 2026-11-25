// Regression tests for the review findings on arrrrny/zorphy#226 that live in
// `ArchetypeComposer` — the production wiring that composes the v3 emitters.
//
// The IR is built directly (the emitters' own golden tests do the same): the
// findings are about how the composer CLASSIFIES and FILTERS nodes before it
// hands them to an emitter, not about analyzer resolution.

import 'package:test/test.dart';
import 'package:zorphy/src/emission/archetype_composer.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyNodeIr _node({
  required String name,
  ArchetypeKind archetype = ArchetypeKind.entity,
  bool isRoot = false,
  List<ZorphyFieldIr> fields = const [],
  List<ZorphyNodeIr> superTypes = const [],
  List<ZorphyNodeIr> directSubTypes = const [],
  List<String> typeParameters = const [],
}) {
  return ZorphyNodeIr(
    className: '\$$name',
    cleanName: name,
    archetype: archetype,
    isSealedRoot: isRoot,
    isAbstractIntermediate: superTypes.isNotEmpty && directSubTypes.isNotEmpty,
    isConcreteLeaf: directSubTypes.isEmpty,
    superTypes: superTypes,
    directSubTypes: directSubTypes,
    allConcreteLeaves: const [],
    discriminatorKey: 'kind',
    discriminatorValue: name.toLowerCase(),
    fields: fields,
    typeParameters: typeParameters,
  );
}

void main() {
  group('ArchetypeComposer — review findings on #226', () {
    test('an intent-typed field is not classified as a codec node', () {
      final intent = _node(
        name: 'InspectIntent',
        archetype: ArchetypeKind.intent,
        isRoot: true,
        fields: const [ZorphyFieldIr(name: 'target', type: 'String')],
      );
      final order = _node(
        name: 'Order',
        isRoot: true,
        fields: const [
          ZorphyFieldIr(name: 'id', type: 'String'),
          ZorphyFieldIr(name: 'intent', type: 'InspectIntent'),
        ],
      );
      final ir = PolymorphicIr(
        nodes: {'\$Order': order, '\$InspectIntent': intent},
        roots: [order, intent],
        diagnostics: const [],
      );

      final emitted = const ArchetypeComposer().compose(ir);

      // IntentEmitter emits toWire/intentDigest but NO fromWire, so treating
      // an intent as a known node would make the codec call a decoder that
      // does not exist in the generated library.
      expect(
        emitted,
        isNot(contains('InspectIntent.fromWire(')),
        reason: 'the codec must not call a decoder the intent does not emit',
      );
    });

    test('a generic standalone entity emits no unbound patch', () {
      final box = _node(
        name: 'Box',
        isRoot: true,
        typeParameters: const ['T'],
        fields: const [
          ZorphyFieldIr(name: 'id', type: 'String'),
          ZorphyFieldIr(name: 'value', type: 'T'),
        ],
      );
      final ir = PolymorphicIr(
        nodes: {'\$Box': box},
        roots: [box],
        diagnostics: const [],
      );

      final emitted = const ArchetypeComposer().compose(ir);

      // MockFixtureEmitter fails closed on generic nodes (no samplePatch is
      // emitted), so no patch may be emitted either — `BoxPatch` would name
      // `T` and `ZorphyPatch<Box>` without a type argument.
      expect(
        emitted,
        isNot(contains('BoxPatch')),
        reason: 'a generic entity has no compilable patch surface',
      );
    });

    test('a generic root emits no codec or class surface', () {
      final box = _node(
        name: 'Box',
        isRoot: true,
        typeParameters: const ['T'],
        fields: const [
          ZorphyFieldIr(name: 'id', type: 'String'),
          ZorphyFieldIr(name: 'value', type: 'T'),
        ],
      );
      final ir = PolymorphicIr(
        nodes: {'\$Box': box},
        roots: [box],
        diagnostics: const [],
      );

      final emitted = const ArchetypeComposer().compose(ir);

      // Neither the class emitter nor the codec declares type parameters, so
      // emitting this root would leave `T` unbound in the generated library.
      // Fail closed — the same rule the patch and mock surfaces apply.
      expect(
        emitted,
        isEmpty,
        reason: 'a generic root must not reach class or codec emission',
      );
    });

    test('helper selection ignores an intent field that no codec reads', () {
      final intent = _node(
        name: 'StampIntent',
        archetype: ArchetypeKind.intent,
        isRoot: true,
        fields: const [ZorphyFieldIr(name: 'at', type: 'DateTime')],
      );
      final order = _node(
        name: 'Order',
        isRoot: true,
        fields: const [ZorphyFieldIr(name: 'id', type: 'String')],
      );
      final ir = PolymorphicIr(
        nodes: {'\$Order': order, '\$StampIntent': intent},
        roots: [order, intent],
        diagnostics: const [],
      );

      final emitted = const ArchetypeComposer().compose(ir);

      expect(
        emitted,
        isNot(contains('_boundaryDateTime')),
        reason: 'helper set must come only from nodes that receive codecs',
      );
    });

    test(
      'the shared apply narrows an inherited field the leaf did not redeclare',
      () {
        final root = _node(
          name: 'Node',
          isRoot: true,
          fields: const [ZorphyFieldIr(name: 'payload', type: 'Object')],
        );
        final mid = _node(
          name: 'Mid',
          fields: const [ZorphyFieldIr(name: 'payload', type: 'String')],
          superTypes: [root],
        );
        final leaf = _node(name: 'Leaf', superTypes: [mid]);
        final wiredMid = mid.copyWith(
          directSubTypes: [leaf],
          isConcreteLeaf: false,
        );
        final wiredRoot = root.copyWith(
          directSubTypes: [wiredMid],
          isConcreteLeaf: false,
        );
        final ir = PolymorphicIr(
          nodes: {'\$Node': wiredRoot, '\$Mid': wiredMid, '\$Leaf': leaf},
          roots: [wiredRoot],
          diagnostics: const [],
        );

        final emitted = const ArchetypeComposer().compose(ir);

        // `payload` is declared on the intermediate, not on the leaf. Building
        // the subtype type map from `leaf.fields` alone drops it, and the
        // shared apply writes an `Object?` into `copyWith(payload: String?)`.
        expect(
          emitted,
          contains('payload.valueOrNull as String'),
          reason: 'the nearest inherited declaration must win in the apply arm',
        );
      },
    );

    test(
      'a generic leaf under a live root is pruned from class and dispatch',
      () {
        final root = _node(
          name: 'Node',
          isRoot: true,
          fields: const [ZorphyFieldIr(name: 'id', type: 'String')],
        );
        final leaf = _node(name: 'Leaf', superTypes: [root]);
        final generic = _node(
          name: 'Box',
          typeParameters: const ['T'],
          fields: const [ZorphyFieldIr(name: 'value', type: 'T')],
          superTypes: [root],
        );
        final wiredRoot = root.copyWith(
          directSubTypes: [leaf, generic],
          isConcreteLeaf: false,
        );
        final ir = PolymorphicIr(
          nodes: {'\$Node': wiredRoot, '\$Leaf': leaf, '\$Box': generic},
          roots: [wiredRoot],
          diagnostics: const [],
        );

        final emitted = const ArchetypeComposer().compose(ir);

        // The composer's own walks prune the generic subtree (no codec, no
        // class spec), so neither the class-emission walk nor the codec's leaf
        // enumeration may reach it: an emitted `$Box` would leave `T` unbound,
        // and a `box` dispatch arm would reference a `fromWire` the library
        // never declares.
        expect(
          emitted,
          contains('Leaf'),
          reason: 'the non-generic leaf still composes',
        );
        // The class emitter names emitted classes by their clean name, so
        // the pruned leaf would appear as `class Box` — assert that spelling.
        expect(emitted, isNot(contains('class Box')));
        expect(emitted, isNot(contains("'box'")));
      },
    );

    test('a field naming a pruned generic node fails generation loudly', () {
      final root = _node(
        name: 'Shelf',
        isRoot: true,
        fields: const [ZorphyFieldIr(name: 'boxes', type: 'List<Box>')],
      );
      final generic = _node(
        name: 'Box',
        isRoot: true,
        typeParameters: const ['T'],
        fields: const [ZorphyFieldIr(name: 'value', type: 'T')],
      );
      final ir = PolymorphicIr(
        nodes: {'\$Shelf': root, '\$Box': generic},
        roots: [root, generic],
        diagnostics: const [],
      );

      // With the pruned name absent from the codec's known-node set the
      // field would classify as a scalar and the raw object would reach the
      // wire silently; the composer must refuse the generation instead.
      expect(() => const ArchetypeComposer().compose(ir), throwsArgumentError);
    });

    test('a non-generic descendant of a generic node is not a codec node', () {
      final root = _node(
        name: 'Node',
        isRoot: true,
        fields: const [
          ZorphyFieldIr(name: 'id', type: 'String'),
          ZorphyFieldIr(name: 'leaf', type: 'Leaf'),
        ],
      );
      final generic = _node(
        name: 'Box',
        typeParameters: const ['T'],
        fields: const [ZorphyFieldIr(name: 'value', type: 'T')],
        superTypes: [root],
      );
      final leaf = _node(
        name: 'Leaf',
        superTypes: [generic],
        fields: const [ZorphyFieldIr(name: 'tag', type: 'String')],
      );
      final wiredRoot = root.copyWith(
        directSubTypes: [generic],
        isConcreteLeaf: false,
      );
      final ir = PolymorphicIr(
        nodes: {'\$Node': wiredRoot, '\$Box': generic, '\$Leaf': leaf},
        roots: [wiredRoot],
        diagnostics: const [],
      );

      // `Leaf` carries no type parameters of its own but hangs under the
      // generic `Box`, so no codec is emitted for it: classifying a field
      // named `Leaf` as a nested node would emit a `fromWire` that does not
      // exist. The field must refuse the generation (see the guard above).
      expect(() => const ArchetypeComposer().compose(ir), throwsArgumentError);
    });
  });
}
