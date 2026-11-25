/// Composes the v3 archetype emitters into one library fragment (ISSUE-0223,
/// arrrrny/zorphy#223).
///
/// The closed v3 parser/emitter PRs (#177, #178, #188, #189, #190) each shipped
/// a tested `PolymorphicIr` consumer, but no production caller composed them:
/// `ZorphyGenerator` registered only the legacy `@Zorphy`/`@Zorphy2` checkers,
/// so a real consumer's archetype-annotated class generated nothing. This
/// composer is the missing production wiring — the generator resolves the
/// library's [PolymorphicIr] and hands it here, and the returned fragment is
/// appended to the library's shared part.
///
/// The composition is archetype-aware, because the emitters own disjoint
/// class surfaces:
///
/// - **entity / state / value / union** — [PolymorphicClassEmitter] emits the
///   sealed/final class shape, [BoundaryCodecEmitter] contributes the
///   `fromWire`/`toWire` members (spliced INTO those classes through the class
///   emitter's `extraMethods` hook), and [MockFixtureEmitter] emits the
///   `<Name>MockData` seed builders. [BoundaryCodecEmitter.helperSpecs] are
///   emitted once per library, after the hierarchies that call them.
/// - **entity patches** — [PolymorphicPatchEmitter] emits the `<Root>Patch` /
///   `<Leaf>Patch` surface every `@ZorphyEntity` mock's `samplePatch()`
///   builds through: the sealed root patch plus one concrete patch per leaf
///   for a hierarchy, a single `ZorphyPatch<T>`-implementing class for a
///   standalone entity, and a `typedef <Intermediate>Patch = <Root>Patch`
///   alias for an abstract intermediate (its mock delegates to a leaf patch,
///   which IS a root patch — a first-class intermediate patch is follow-up
///   work). State/value/union hierarchies get no patch: nothing in the
///   composed surface references one.
/// - **intent** — [IntentEmitter] alone: it emits its own class declarations
///   (a second class emitter would duplicate every intent class), and its
///   `toWire` would collide with the codec's.
///
/// The output is a PART-FILE BODY: directive-free source the owning library
/// composes into its shared part. The fragment names `ZorphyEntityBase`,
/// `ZorphyBoundaryResult`, `ZorphyIntentDigest`, ... — all from
/// `package:zorphy_annotation/zorphy_annotation.dart`, which the owning
/// library already imports for the archetype annotations themselves.
library;

import 'package:code_builder/code_builder.dart';

import '../common/NameType.dart';
import '../emitters/intent_emitter.dart';
import '../emitters/mock_fixture_emitter.dart';
import '../parser/polymorphic_ir.dart';
import 'boundary_codec_emitter.dart';
import 'emitter.dart';
import 'polymorphic_class_emitter.dart';
import 'polymorphic_patch_emitter.dart';

/// Composes a resolved [PolymorphicIr] into the v3 source fragment of one
/// library.
final class ArchetypeComposer {
  /// Creates a composer with the default emission pipeline.
  const ArchetypeComposer();

  /// Emits every hierarchy in [ir] as one formatted source fragment, or an
  /// empty string when the library carries no archetype annotations — so the
  /// generator can append the result unconditionally.
  String compose(PolymorphicIr ir) {
    if (ir.roots.isEmpty) return '';

    final fragments = <String>[];

    final codecRoots = <ZorphyNodeIr>[
      for (final root in ir.roots)
        if (root.archetype != ArchetypeKind.intent &&
            root.typeParameters.isEmpty)
          root,
    ];
    if (codecRoots.isNotEmpty) {
      final ownFields = _ownFields(ir);
      final payloads = _payloads(ir);
      // Intent names are deliberately NOT known nodes for the codec: intents
      // are emitted by [IntentEmitter], which provides `toWire`/`intentDigest`
      // but no `fromWire`. Classifying an intent-typed field as a nested node
      // would make the codec emit `<Intent>.fromWire(...)`, which does not
      // exist in the generated library. An intent value therefore travels as
      // a plain field on the wire, as it does in `IntentEmitter.toWire`.
      // Generic nodes are excluded for the same fail-closed reason as the
      // patch and mock surfaces: `PolymorphicClassEmitter` declares no type
      // parameters and the codec would emit `_boundaryAs<T>` with an
      // unbound `T`. A generic root (and its subtree) is not composed at all,
      // so a field naming it must not be classified as a nested node either.
      final knownNodes = <String>{
        for (final node in ir.nodes.values)
          if (node.archetype != ArchetypeKind.intent &&
              node.typeParameters.isEmpty)
            node.cleanName,
      };
      const codec = BoundaryCodecEmitter();
      var firstRoot = true;
      for (final root in codecRoots) {
        final extraMethods = <String, List<Method>>{
          for (final node in _walk(root))
            node.className: codec.emitCodec(
              node,
              payloads,
              additionalNodes: knownNodes,
            ),
        };
        fragments.add(
          const PolymorphicClassEmitter().emit(
            root: root,
            fields: ownFields,
            extraMethods: extraMethods,
            // The `_sentinel` declarations are one-per-library: only the first
            // hierarchy carries them, or the duplicates are a compile error.
            includeSentinelDeclarations: firstRoot,
          ),
        );
        firstRoot = false;
        if (root.archetype == ArchetypeKind.entity) {
          fragments.add(_emitEntityPatches(root));
        }
        fragments.add(MockFixtureEmitter().emit(root));
      }
      // The codec's shared helpers are emitted ONCE per library — a second
      // copy is a duplicate-definition error — and only the helpers this
      // library's field shapes actually call, or the unreferenced ones are
      // `unused_element` warnings in the consumer's analysis.
      fragments.add(
        ZorphyEmitter().emitSpecs(
          // Select helpers only from the nodes that actually receive codecs.
          // Passing every IR node lets an intent's (or a skipped generic
          // node's) `DateTime` field select `_boundaryDateTime` even though
          // no emitted codec calls it — an `unused_element` warning in the
          // consumer, exactly what the guard above exists to prevent.
          BoundaryCodecEmitter.usedHelperSpecs(
            codecRoots.expand(_walk),
            payloads,
            additionalNodes: knownNodes,
          ),
        ),
      );
    }

    // Intent hierarchies emit their own class surface (see the library doc).
    final intents = IntentEmitter().emitIntents(ir);
    if (intents.isNotEmpty) fragments.add(intents);

    return fragments.where((fragment) => fragment.isNotEmpty).join('\n\n');
  }

  /// The patch surface of one `@ZorphyEntity` hierarchy (ISSUE-0223).
  ///
  /// `MockFixtureEmitter.samplePatch()` builds through `<Name>Patch` fluent
  /// builders, so the composed library must carry them:
  ///
  /// - a hierarchy emits the sealed `<Root>Patch` + `<Root>SharedPatch` and
  ///   one concrete `<Leaf>Patch` per concrete leaf (each extends the root
  ///   patch, so the root mock's delegation to a leaf patch type-checks);
  /// - a standalone entity (no subtypes) emits a single concrete
  ///   `<Name>Patch` implementing `ZorphyPatch<<Name>>` — there is no root
  ///   patch to extend;
  /// - an abstract intermediate emits no patch of its own: its mock's
  ///   `samplePatch()` delegates to a leaf patch typed `<Intermediate>Patch`,
  ///   so the intermediate gets a `typedef` alias to the root patch — which
  ///   every leaf patch already is. A first-class intermediate patch (its own
  ///   fields patchable through it) is follow-up work.
  String _emitEntityPatches(ZorphyNodeIr root) {
    const emitter = PolymorphicPatchEmitter();
    // A generic entity has no compilable patch surface: `T` would be an
    // unbound type parameter in `BoxPatch` and in `ZorphyPatch<Box>`. Fail
    // closed the same way `MockFixtureEmitter` does for generic nodes — that
    // emitter skips the node entirely, so no `samplePatch()` will reference a
    // patch we did not emit.
    if (root.typeParameters.isNotEmpty) return '';
    // A childless root is its own concrete leaf (the resolver's rule), so
    // "standalone" is read off the ROOT, not off a leaf walk — a walk would
    // answer `[root]` and emit a hierarchy whose one subtype patch extends
    // itself.
    if (root.isConcreteLeaf) {
      return emitter.emitStandalone(
        name: root.cleanName,
        fields: _patchFields(root.fields),
      );
    }
    final leaves = _concreteLeaves(root);
    if (leaves.isEmpty) return '';

    final fragments = <String>[
      emitter.emitRoot(
        rootName: root.cleanName,
        fields: _patchFields(root.fields),
        subtypeNames: [for (final leaf in leaves) leaf.cleanName],
        subtypeFieldTypes: {
          for (final leaf in leaves)
            leaf.cleanName: {
              // The full inherited payload, not just the leaf's own fields:
              // the shared `apply` arm writes every field it maps, including
              // ones a leaf inherits without redeclaring. `_payloadFields`
              // keeps the nearest declaration of a name, so a narrowed
              // inherited type wins and `apply` type-checks against the
              // leaf's `copyWith`.
              for (final field in _payloadFields(leaf))
                field.name: field.isNullable ? '${field.type}?' : field.type,
            },
        },
      ),
    ];

    final rootFieldNames = [for (final field in root.fields) field.name];
    void walk(ZorphyNodeIr node) {
      for (final child in node.directSubTypes) {
        // A generic subtree is pruned from the patch surface for the same
        // reason the root is: no patch can name its type parameter, and
        // `MockFixtureEmitter` skips it too.
        if (child.typeParameters.isNotEmpty) continue;
        if (child.isConcreteLeaf) {
          fragments.add(
            emitter.emitSubtypePatch(
              subtypeName: child.cleanName,
              rootName: root.cleanName,
              fields: _patchFields(_payloadFields(child)),
              sharedFields: rootFieldNames,
            ),
          );
        } else {
          // An abstract intermediate: its mock delegates to a leaf patch, so
          // the name only has to RESOLVE to a supertype of every leaf patch.
          fragments.add(
            'typedef ${child.cleanName}Patch = ${root.cleanName}Patch;',
          );
          walk(child);
        }
      }
    }

    walk(root);
    return fragments.join('\n\n');
  }

  /// Every concrete leaf BELOW [node], depth-first. Only meaningful for a
  /// hierarchy — a standalone root is its own leaf and never reaches this.
  List<ZorphyNodeIr> _concreteLeaves(ZorphyNodeIr node) {
    final out = <ZorphyNodeIr>[];
    void walk(ZorphyNodeIr current) {
      // Generic nodes (and everything below them) are not emittable: a
      // patch cannot declare their type parameter, and the mock emitter
      // skips the same subtree.
      if (current.typeParameters.isNotEmpty) return;
      if (current.isConcreteLeaf) {
        out.add(current);
        return;
      }
      for (final child in current.directSubTypes) {
        walk(child);
      }
    }

    walk(node);
    return out;
  }

  /// The whole payload of [node] — own fields first, then each ancestor's,
  /// the first declaration of a name winning (a covariant redeclaration keeps
  /// the leaf's narrowed type).
  List<ZorphyFieldIr> _payloadFields(ZorphyNodeIr node) {
    final seen = <String>{};
    final payload = <ZorphyFieldIr>[];
    for (final owner in <ZorphyNodeIr>[node, ...node.superTypes]) {
      for (final field in owner.fields) {
        if (seen.add(field.name)) payload.add(field);
      }
    }
    return payload;
  }

  /// IR fields as the `NameTypeClassComment` shape the patch emitter takes,
  /// nullability folded into the type spelling.
  List<NameTypeClassComment> _patchFields(List<ZorphyFieldIr> fields) => [
    for (final field in fields)
      NameTypeClassComment(
        field.name,
        field.isNullable ? '${field.type}?' : field.type,
        '',
      ),
  ];

  /// Every emittable node of [root]'s hierarchy, depth-first pre-order.
  ///
  /// A generic node (and everything below it) is pruned: neither the class
  /// emitter nor the codec declares type parameters, so emitting it would
  /// leave `T` unbound in the generated library. This is the same fail-closed
  /// rule the patch and mock surfaces apply.
  Iterable<ZorphyNodeIr> _walk(ZorphyNodeIr root) sync* {
    if (root.typeParameters.isNotEmpty) return;
    yield root;
    for (final child in root.directSubTypes) {
      yield* _walk(child);
    }
  }

  /// Each node's OWN declared fields, keyed by `className` — the shape
  /// [PolymorphicClassEmitter] expects (it unions the ancestors itself).
  Map<String, List<PolymorphicField>> _ownFields(PolymorphicIr ir) => {
    for (final node in ir.nodes.values)
      node.className: <PolymorphicField>[
        for (final field in node.fields)
          PolymorphicField(
            name: field.name,
            type: field.type,
            isNullable: field.isNullable,
          ),
      ],
  };

  /// Each node's FULL payload (own + inherited, nearest-first, first
  /// declaration of a name winning), keyed by `className` — the shape
  /// [BoundaryCodecEmitter] expects: a leaf decodes every field its
  /// `fromTrusted` constructor takes, inherited ones included.
  Map<String, List<BoundaryField>> _payloads(PolymorphicIr ir) {
    final result = <String, List<BoundaryField>>{};
    for (final node in ir.nodes.values) {
      final seen = <String>{};
      final payload = <BoundaryField>[];
      for (final owner in <ZorphyNodeIr>[node, ...node.superTypes]) {
        for (final field in owner.fields) {
          if (seen.add(field.name)) {
            payload.add(
              BoundaryField(
                name: field.name,
                type: field.isNullable ? '${field.type}?' : field.type,
              ),
            );
          }
        }
      }
      result[node.className] = payload;
    }
    return result;
  }
}
