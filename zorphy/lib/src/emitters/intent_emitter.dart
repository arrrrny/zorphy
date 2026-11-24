/// Emits the `@ZorphyIntent` surface of a [PolymorphicIr] (ISSUE-014, #189).
///
/// An intent hierarchy is the one archetype family whose payload is replayed
/// across a trust boundary, so its generated surface carries three things the
/// other archetypes do not: an explicit `replaySafe` decision, a wire name
/// (`intentName`), and a canonical `intentDigest()` that a receiver can verify
/// a replay against. This emitter produces all of it — for a standalone intent
/// and for a sealed root with abstract intermediate leaves — through
/// `package:code_builder` only: every declaration is a [Spec].
///
/// The output is a PART-FILE BODY: a sequence of class declarations with no
/// `import`/`part` directives of its own. zorphy 3.0.0's output model is shared
/// parts (`shared_part_builder.dart`, `adds_to_library: true`), and a Dart part
/// may carry no directive other than `part of`. The Owning library is therefore
/// responsible for importing the symbols the fragment names — at minimum
/// [annotationImportUrl] — exactly the way `orchestrator.dart` folds
/// `pluginImports` into the library it generates. Because the fragment is
/// directive-free it composes into that library (and its `part` wrapper) as-is.
///
/// Field types are emitted verbatim from the IR (`ZorphyFieldIr.type`), so a
/// non-`dart:core` field type resolves against the Owning library's existing
/// imports — the same imports that resolve the type in the hand-written
/// `$`-prefixed declaration this class was generated from. A field type with no
/// canonical JSON form, or one named after the discriminator, is rejected at
/// GENERATION by the resolver (ZORPHY_E004/E005) rather than emitting a method
/// that compiles and then throws at replay time.
///
/// Nothing here reads or writes a `.zorphy.dart` file: the emitter is a pure
/// `PolymorphicIr -> String` function the generator composes into a part file.
library;

import 'dart:collection';

import 'package:code_builder/code_builder.dart';

import '../emission/emitter.dart';
import '../parser/polymorphic_ir.dart';

/// The annotation package's import URI.
///
/// The emitted fragment carries no directives (it is a part-file body), so the
/// Owning library must import this for the symbols the fragment names —
/// `ZorphyIntentBase`, `ZorphyIntentDigest` — to resolve.
const String annotationImportUrl =
    'package:zorphy_annotation/zorphy_annotation.dart';

/// Emits the intent surface of one resolved hierarchy.
final class IntentEmitter {
  /// The shared spec-emission pipeline, so page width and the formatter are
  /// owned in ONE place (`ZorphyEmitter`) rather than re-created per call.
  final ZorphyEmitter _emitter;

  /// Creates an emitter that formats through [ZorphyEmitter] at [pageWidth]
  /// (the shared `defaultPageWidth` by default).
  IntentEmitter({int pageWidth = ZorphyEmitter.defaultPageWidth})
    : _emitter = ZorphyEmitter.withPageWidth(pageWidth);

  /// Emits every `@ZorphyIntent` node in [ir] as one formatted source block.
  ///
  /// Returns an empty string when [ir] carries no intent hierarchy, so a
  /// caller can compose this unconditionally into a part file. The result has
  /// no directives: the Owning library supplies [annotationImportUrl] and the
  /// `part of` wrapper.
  String emitIntents(PolymorphicIr ir) {
    final specs = <Spec>[
      for (final root in ir.roots)
        if (root.archetype == ArchetypeKind.intent) ..._hierarchySpecs(root),
    ];
    if (specs.isEmpty) return '';

    final library = Library((b) => b.body.addAll(specs));
    return _emitter.emit(library);
  }

  /// One root and its whole subtree, roots first so a leaf's `implements`
  /// clause names an already-emitted type.
  ///
  /// A [ListQueue] with a `seen` set drains in O(n) and emits each node once,
  /// so a node reachable from two roots is declared once (not twice).
  Iterable<Spec> _hierarchySpecs(ZorphyNodeIr root) sync* {
    final seen = <String>{};
    final queue = ListQueue<ZorphyNodeIr>.from([root]);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      if (!seen.add(node.cleanName)) continue;
      yield _classSpec(node);
      queue.addAll(node.directSubTypes);
    }
  }

  /// One generated intent class: concrete for a leaf, abstract otherwise.
  ///
  /// Instantiable-ness comes from the SUBTREE, not from the declaration's
  /// `abstract` keyword: zorphy's `$`-prefix convention means `abstract class
  /// $InspectProductIntent` is the hand-written DECLARATION, and the generated
  /// class it names (`InspectProductIntent`) is concrete unless something
  /// further implements it. A node with subtypes is therefore abstract — and a
  /// sealed root is `sealed`, so `switch (intent)` over it is exhaustive.
  Class _classSpec(ZorphyNodeIr node) {
    final payload = _payloadFields(node);
    final hasSubtypes = node.directSubTypes.isNotEmpty;
    final parents = <Reference>[
      refer('ZorphyIntentBase'),
      for (final superType in node.superTypes) refer(superType.cleanName),
    ];

    return Class((c) {
      c.name = node.cleanName;
      c.implements.addAll(parents);
      if (node.isSealedRoot && hasSubtypes) {
        c.sealed = true;
      } else if (hasSubtypes) {
        c.abstract = true;
      }

      for (final field in payload) {
        c.fields.add(
          Field((f) {
            f
              ..name = field.name
              ..modifier = FieldModifier.final$
              ..type = refer(_dartType(field));
          }),
        );
      }

      c.constructors.add(_constructor(payload));

      c.methods.addAll([
        _intentNameGetter(node),
        _replaySafeGetter(node),
        _toWireMethod(node, payload),
        _intentDigestMethod(node, payload),
      ]);
    });
  }

  /// `InspectProductIntent({required this.productId, this.note});`
  ///
  /// A non-nullable field is `required`: an intent missing a non-null field
  /// would hash a fabricated `null` into a valid-looking digest. A NULLABLE
  /// field stays optional — `null` is itself a canonical form that
  /// `ZorphyIntentDigest` hashes as `"note":null`, so forcing `note: null` at
  /// every call site would only be noise.
  Constructor _constructor(List<ZorphyFieldIr> payload) {
    return Constructor((k) {
      for (final field in payload) {
        // A named parameter is an OPTIONAL parameter carrying `required`:
        // code_builder emits `requiredParameters` positionally whatever
        // `named` says, so a required named field lives in the optional list.
        k.optionalParameters.add(
          Parameter((p) {
            p
              ..name = field.name
              ..named = true
              ..required = !field.isNullable
              ..toThis = true;
          }),
        );
      }
    });
  }

  /// `String get intentName => 'inspect_product';`
  Method _intentNameGetter(ZorphyNodeIr node) {
    return Method((m) {
      m
        ..name = 'intentName'
        ..type = MethodType.getter
        ..returns = refer('String')
        ..body = literalString(node.discriminatorValue).code;
    });
  }

  /// `bool get replaySafe => true;` — the node's OWN resolved decision, so a
  /// leaf that overrides the sealed root's baseline says so in its own class.
  Method _replaySafeGetter(ZorphyNodeIr node) {
    return Method((m) {
      m
        ..name = 'replaySafe'
        ..type = MethodType.getter
        ..returns = refer('bool')
        ..body = literalBool(node.replaySafe ?? false).code;
    });
  }

  /// `Map<String, Object?> toWire() => {...};`
  ///
  /// The leaf's whole payload plus the wire name, because a receiver that only
  /// got the fields could not tell an `inspect_product` from a
  /// `delete_product` carrying the same `productId`. The discriminator is
  /// guaranteed not to collide with a payload field name by the resolver
  /// (ZORPHY_E005).
  Method _toWireMethod(ZorphyNodeIr node, List<ZorphyFieldIr> payload) {
    return Method((m) {
      m
        ..name = 'toWire'
        ..returns = refer('Map<String, Object?>')
        ..body = literalMap({
          node.discriminatorKey: refer('intentName'),
          for (final field in payload)
            field.name: refer('this').property(field.name),
        }).code;
    });
  }

  /// `String intentDigest() => ZorphyIntentDigest.compute(intentName, {...});`
  ///
  /// The field map matches [toWireMethod] minus the wire name: the digest is
  /// taken over the intent's MEANING (`ZorphyIntentDigest` folds `intentName`
  /// in itself), so the discriminator key cannot change a digest by being
  /// renamed.
  Method _intentDigestMethod(ZorphyNodeIr node, List<ZorphyFieldIr> payload) {
    return Method((m) {
      m
        ..name = 'intentDigest'
        ..returns = refer('String')
        ..body = refer('ZorphyIntentDigest').property('compute').call([
          refer('intentName'),
          literalMap({
            for (final field in payload)
              field.name: refer('this').property(field.name),
          }),
        ]).code;
    });
  }

  /// The whole payload of [node], nearest declaration first: the node's own
  /// fields, then each ancestor's, with the first declaration of a name
  /// winning so a redeclared field appears once.
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

  /// [field]'s type as source text, with nullability where it belongs.
  String _dartType(ZorphyFieldIr field) =>
      field.isNullable ? '${field.type}?' : field.type;
}
