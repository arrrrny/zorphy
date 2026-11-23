/// Emits the `@ZorphyIntent` surface of a [PolymorphicIr] (ISSUE-014, #189).
///
/// An intent hierarchy is the one archetype family whose payload is replayed
/// across a trust boundary, so its generated surface carries three things the
/// other archetypes do not: an explicit `replaySafe` decision, a wire name
/// (`intentName`), and a canonical `intentDigest()` that a receiver can verify
/// a replay against. This emitter produces all of it — for a standalone intent
/// and for a sealed root with abstract intermediate leaves — through
/// `package:code_builder` only: every declaration is a [Spec], and the one
/// non-spec construct (a `throw` inside `fromWire`) is a [CodeExpression]
/// wrapping a [Code], which is the same seam `ClassDeclarationGenerator`
/// already uses for source-level annotations.
///
/// Nothing here reads or writes a `.zorphy.dart` file: the emitter is a pure
/// `PolymorphicIr -> String` function the generator composes into a part file.
library;

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import '../parser/polymorphic_ir.dart';

/// The intent annotation's package, for the `replaySafe` base marker and the
/// digest helper the generated code calls.
const String _annotationUrl =
    'package:zorphy_annotation/zorphy_annotation.dart';

/// Emits the intent surface of one resolved hierarchy.
final class IntentEmitter {
  /// Creates a stateless emitter.
  const IntentEmitter();

  /// Emits every `@ZorphyIntent` node in [ir] as one formatted source block.
  ///
  /// Returns an empty string when [ir] carries no intent hierarchy, so a
  /// caller can compose this unconditionally into a part file.
  String emitIntents(PolymorphicIr ir, {int pageWidth = 80}) {
    final intentRoots = [
      for (final root in ir.roots)
        if (root.archetype == ArchetypeKind.intent) root,
    ];
    if (intentRoots.isEmpty) return '';

    final specs = <Spec>[
      for (final root in intentRoots) ..._hierarchySpecs(root),
    ];
    final library = Library((b) {
      b
        ..directives.add(Directive.import(_annotationUrl))
        ..body.addAll(specs);
    });

    final raw = library.accept(DartEmitter()).toString();
    try {
      return DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
        pageWidth: pageWidth,
      ).format(raw);
    } on FormatterException {
      // A spec this emitter builds is complete Dart by construction, so a
      // format failure means the generated fragment is a partial program a
      // caller is composing further (`part of` context). Returning the raw
      // form keeps that composition working, exactly like `ZorphyEmitter`.
      return raw;
    }
  }

  /// One root and its whole subtree, roots first so a leaf's `implements`
  /// clause names an already-emitted type.
  Iterable<Spec> _hierarchySpecs(ZorphyNodeIr root) sync* {
    yield _classSpec(root);
    final queue = <ZorphyNodeIr>[...root.directSubTypes];
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
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
      refer('ZorphyIntentBase', _annotationUrl),
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

  /// `InspectProductIntent({required this.productId});`
  ///
  /// Every payload field is required: an intent with a missing field has no
  /// canonical form, so the compiler refuses it rather than the digest
  /// silently hashing a `null` into a valid-looking hash.
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
              ..required = true
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
  /// `delete_product` carrying the same `productId`.
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
        ..body = refer('ZorphyIntentDigest', _annotationUrl)
            .property('compute')
            .call([
              refer('intentName'),
              literalMap({
                for (final field in payload)
                  field.name: refer('this').property(field.name),
              }),
            ])
            .code;
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
