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
  bool isUnion = false,
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
    isUnion: isUnion,
  );
}

void main() {
  group('ArchetypeComposer — review findings on #226', () {
    test(
      'an intent-typed field decodes through the intent\'s own fromWire',
      () {
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

        // Since #232 the intent surface carries `fromWire` (emitted by
        // IntentEmitter through the shared codec), so the entity codec MUST
        // classify an intent-typed field as a nested node: the value decodes
        // through the intent's own boundary instead of travelling as an
        // unvalidated raw wire value.
        expect(
          emitted,
          contains('static ZorphyBoundaryResult<InspectIntent> fromWire('),
          reason: 'the intent emits the decoder the field names',
        );
        expect(
          emitted,
          contains('InspectIntent.fromWire('),
          reason: 'the entity codec decodes the intent-valued field through it',
        );
      },
    );

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

    test('a generic union DISPATCH root emits its class surface but no codec, '
        'patch or mock', () {
      final box = _node(
        name: 'Box',
        archetype: ArchetypeKind.value,
        isRoot: true,
        isUnion: true,
        typeParameters: const ['T'],
        fields: const [
          ZorphyFieldIr(name: 'id', type: 'String'),
          ZorphyFieldIr(name: 'value', type: 'T'),
        ],
      );
      final leaf = _node(
        name: 'Filled',
        archetype: ArchetypeKind.value,
        isUnion: true,
        typeParameters: const ['T'],
        superTypes: [box],
        fields: const [ZorphyFieldIr(name: 'extra', type: 'T')],
      );
      final wiredBox = box.copyWith(
        directSubTypes: [leaf],
        isConcreteLeaf: false,
      );
      final ir = PolymorphicIr(
        nodes: {'\$Box': wiredBox, '\$Filled': leaf},
        roots: [wiredBox],
        diagnostics: const [],
      );

      final emitted = const ArchetypeComposer().compose(ir);

      // Issue #231: the generic root is no longer pruned — the class
      // emitter declares the type parameter, so the surface compiles.
      expect(emitted, contains('sealed class Box<T>'));
      expect(emitted, contains('final class Filled<T> extends Box<T>'));
      // ZRP-009 (#272): a generic DISPATCH hierarchy still has no wire
      // surface — a dispatch `fromWire` would have to forward the decoders to
      // a leaf's own re-declared static, which the IR cannot express — so the
      // codec is withheld for the whole generic dispatch subtree. (A generic
      // CONCRETE LEAF root, like `CreateParams<T>`, DOES get one; see
      // `generic_boundary_codec_test.dart`.)
      expect(
        emitted,
        isNot(contains('fromWire')),
        reason: 'a generic dispatch hierarchy still has no wire surface',
      );
      // The patch and mock surfaces stay fail-closed the same way.
      expect(emitted, isNot(contains('BoxPatch')));
      expect(emitted, isNot(contains('BoxMockData')));
    });

    test('a generic CONCRETE LEAF root emits a codec-parameterized wire '
        'surface (ZRP-009, #272)', () {
      final params = _node(
        name: 'CreateParams',
        archetype: ArchetypeKind.value,
        isRoot: true,
        typeParameters: const ['T'],
        fields: const [
          ZorphyFieldIr(name: 'data', type: 'T'),
          ZorphyFieldIr(name: 'idempotencyKey', type: 'String?'),
        ],
      );
      final ir = PolymorphicIr(
        nodes: {'\$CreateParams': params},
        roots: [params],
        diagnostics: const [],
      );

      final emitted = const ArchetypeComposer().compose(ir);

      expect(emitted, contains('class CreateParams<T>'));
      // `fromWire` re-declares the type parameter and takes a decoder;
      // `toWire` takes an encoder.
      expect(emitted, contains('static ZorphyBoundaryResult<CreateParams<T>>'));
      expect(emitted, contains('fromWire<T>('));
      expect(emitted, contains('decodeT'));
      expect(emitted, contains('encodeT'));
      // The `T` field routes through the codec parameter, not a reified cast.
      expect(emitted, contains('encodeT(this.data)'));
      // The patch and mock surfaces stay fail-closed on a generic node.
      expect(emitted, isNot(contains('CreateParamsPatch')));
      expect(emitted, isNot(contains('CreateParamsMockData')));
    });

    test('helper selection covers the intent codecs', () {
      final intent = _node(
        name: 'TagIntent',
        archetype: ArchetypeKind.intent,
        isRoot: true,
        fields: const [ZorphyFieldIr(name: 'tags', type: 'List<String>')],
      );
      final order = _node(
        name: 'Order',
        isRoot: true,
        fields: const [ZorphyFieldIr(name: 'id', type: 'String')],
      );
      final ir = PolymorphicIr(
        nodes: {'\$Order': order, '\$TagIntent': intent},
        roots: [order, intent],
        diagnostics: const [],
      );

      final emitted = const ArchetypeComposer().compose(ir);

      // Since #232 the intent's `fromWire` IS an emitted codec, so the
      // helpers its field shapes call must be selected — an unreferenced
      // helper would be an `unused_element` warning, and a MISSING one would
      // not compile. The intent's `List<String>` field needs `_boundaryList`.
      expect(
        emitted,
        contains('_boundaryList'),
        reason: 'the intent codec\'s list field selects the list helper',
      );
      // A field shape NO emitted codec calls still selects nothing: the
      // entity's plain `String` field alone would not have pulled the list
      // helper in.
      expect(
        emitted,
        contains('static ZorphyBoundaryResult<TagIntent> fromWire('),
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

    test('a generic leaf under a live root emits its class + its own codec, '
        'but the dispatch keeps no arm for it (ZRP-009, #272)', () {
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

      // Issue #231: the generic leaf is no longer pruned from the CLASS
      // surface — a non-generic parent needs no type argument, so `Box<T>`
      // compiles as-is.
      expect(emitted, contains('Leaf'));
      expect(emitted, contains('class Box<T> extends Node'));
      // ZRP-009 (#272): a generic CONCRETE LEAF now carries its own
      // codec-parameterized wire surface — a re-declared static `fromWire<T>`
      // with a decoder, and a `toWire` with an encoder.
      expect(emitted, contains('static ZorphyBoundaryResult<Box<T>>'));
      expect(emitted, contains('fromWire<T>('));
      expect(emitted, contains('encodeT(this.value)'));
      // The non-generic dispatch root still has NO arm for the generic leaf:
      // `leavesOf` prunes a generic node, so the root cannot name a decoder
      // for it. No `case 'box':` and no `Box.fromWire(raw)` delegation. (The
      // string `'box'` still appears inside Box's OWN `toWire`, which stamps
      // its discriminator tag — that is the leaf's surface, not an arm.)
      expect(emitted, isNot(contains("case 'box':")));
      expect(emitted, isNot(contains('Box.fromWire(raw)')));
      // And the mock rotation names only leaves it actually emits seeds
      // for — a generic leaf stays out of it.
      expect(emitted, isNot(contains('BoxMockData')));
    });

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
