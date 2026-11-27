/// Emits trust-boundary wire codecs for polymorphic hierarchies
/// (ISSUE-013, #188).
///
/// A resolved [ZorphyNodeIr] names a node of a hierarchy and the wire tag it
/// answers to; the field declarations arrive beside it as
/// `Map<String, List<BoundaryField>>` keyed by the node's `$`-prefixed class
/// name, because the IR deliberately carries no field data (a field belongs to
/// the analyzer element the resolver does not expose). Emission is
/// `package:code_builder` specs only — no `StringBuffer`, no `generate*`
/// toggle, no preset.
///
/// ## What is emitted
///
/// Every node gets two members:
///
/// ```dart
/// static ZorphyBoundaryResult<OrderNotification> fromWire(Map<String, Object?> raw);
/// Map<String, Object?> toWire();
/// ```
///
/// * A **dispatch node** (a sealed root or an abstract intermediate) resolves
///   `raw[discriminatorKey]` against the tags of the concrete leaves BELOW it
///   and delegates to the matching leaf's `fromWire`. A missing or unknown tag
///   answers a `BoundaryErr` carrying one structured violation at
///   `/<discriminatorKey>` — never a thrown `UnsupportedError`.
/// * A **leaf** decodes its own fields into the trusted constructor
///   ([trustedConstructor], `fromTrusted` by default), and its `toWire`
///   injects `discriminatorKey: discriminatorValue` automatically.
///
/// ## Why the errors are collected, not thrown
///
/// Every read is an `is` test on the `Object?` the wire handed over, so a
/// corrupt payload can never reach a `TypeError` or `CastError`: a value of
/// the wrong shape becomes a `FieldViolation` and decoding continues, which is
/// what lets one `BoundaryErr` describe every bad field at once. Nested
/// objects and list elements are decoded recursively and their violations are
/// re-pathed under the parent's pointer, so a bad contract id inside the
/// second element of `children` reports `/children[1]/contractId`.
///
/// ## What this emitter does NOT do
///
/// It emits no `fromJson`/`toJson` and no `fromTrusted` body: class shape and
/// the trusted constructor are ISSUE-003 (#178)'s `PolymorphicClassEmitter`.
/// The v3 archetype surface has exactly one wire entry point per direction, so
/// nothing legacy is emitted for it — the retirement of the v2 `@Zorphy`
/// JSON surface is the v3 migration's job (#194), not a growth here.
///
/// The generated library must import
/// `package:zorphy_annotation/zorphy_annotation.dart` (that is where
/// `ZorphyBoundaryResult`, `BoundaryOk`, `BoundaryErr` and `FieldViolation`
/// live) and [helperSpecs] must be emitted ONCE per library.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/type_ref.dart';
import '../parser/polymorphic_ir.dart';
import 'wire_kind.dart';

/// One field a codec must read off the wire and write back onto it.
///
/// [type] is the DECLARED Dart type as source spells it, `?` included, so a
/// caller can lift it off an analyzer `FieldElement` or a `ClassMetadata`
/// field without re-deriving nullability.
final class BoundaryField {
  /// The Dart field name (the getter the codec reads).
  final String name;

  /// The declared type, e.g. `String`, `DateTime?`, `List<OrderLine>`.
  final String type;

  /// Whether the declared type is an `enum` (issue #313).
  ///
  /// An enum field encodes as its `.name` and decodes by name (mirroring the
  /// patch wire path's `ZorphyPatchWire.enumByName`), instead of the plain
  /// scalar reified `is` test that records a TYPE violation for a wire string.
  final bool isEnum;

  /// The names of enum types used as elements/values of this field's
  /// collection type (`{'AccountTier'}` for `List<AccountTier>`), from the
  /// analyzer-resolved IR (issue #313 review). A collection's element is a
  /// different type from the field, so [isEnum] cannot describe it; the codec
  /// consults this set when classifying collection elements.
  final Set<String> enumElementTypes;

  const BoundaryField({
    required this.name,
    required this.type,
    this.isEnum = false,
    this.enumElementTypes = const {},
  });

  /// Whether the declaration is nullable (`String?`).
  bool get isNullable => type.trim().endsWith('?');

  /// [type] with any trailing `?` and the `$`/`$$` declaration prefixes
  /// stripped, so the value is a legal Dart type reference.
  String get baseType {
    final trimmed = type.trim();
    final withoutNull = trimmed.endsWith('?')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return withoutNull.replaceAll(r'$', '');
  }

  @override
  String toString() => '$type $name';
}

/// How a declared field type maps onto the wire.
enum _Shape {
  /// A `DateTime`, decoded from an ISO-8601 string and emitted back as one.
  dateTime,

  /// A `double`/`num`, which a JSON payload may deliver as an `int`.
  number,

  /// A `List<T>` — decoded element-wise, because a decoded `List<dynamic>` is
  /// never a `List<T>` whatever its elements are.
  list,

  /// A `Map<String, V>` — decoded entry-wise for the same reason.
  map,

  /// Another node of the hierarchy: recurse through its own
  /// `fromWire`/`toWire` and re-path its violations.
  node,

  /// A type parameter of the enclosing generic class (`T`, `List<T>`,
  /// `Map<String, T>`): routed through the codec parameter the emitter
  /// declares for it (`encodeT` / `decodeT`) instead of a reified `is` test.
  typeParam,

  /// Anything else (`String`, `int`, `bool`, enums, `Duration`, …): one
  /// reified `is` test against the declared type, which is total for every
  /// type and throws for none.
  scalar,

  /// An `enum` field (issue #313): encoded as its `.name` and decoded by name
  /// through `ZorphyPatchWire.enumByName`, mirroring the patch wire path so a
  /// wire string resolves to the enum constant (a `FieldViolation` at the
  /// field pointer when no name matches) instead of a TYPE violation.
  enumValue,
}

/// Emits `fromWire` / `toWire` members for the nodes of a polymorphic
/// hierarchy.
///
/// [trustedConstructor] names the zero-copy constructor a leaf decode calls
/// (ISSUE-003/#178 emits `fromTrusted`); a test or an alternative class shape
/// can pin its own and keep the codec unchanged.
class BoundaryCodecEmitter {
  /// The field kinds this emitter's `_Shape` classifier branches handle.
  ///
  /// Exposed so the wire-capability matrix's drift gate can derive its
  /// expected kind set from the emitters instead of a duplicate literal.
  /// Adding a classifier branch MUST add its [WireKind] here.
  static Set<WireKind> get classifiedKinds => boundaryClassifiedKinds;

  /// The trusted constructor each leaf's `fromWire` calls, `fromTrusted` by
  /// default (ISSUE-003/#178 emits it).
  ///
  /// `null` names NO constructor: the leaf decode then constructs through the
  /// class's plain (unnamed) generative constructor — the shape the intent
  /// surface emits (`IntentEmitter`), which carries no `fromTrusted` (#232).
  final String? trustedConstructor;

  /// Whether a `num` field widens to `double` on decode.
  ///
  /// The entity/value codec widens: a JSON hop spells `1.0` as `1`, so encode
  /// and decode must agree on `double` or the round trip truncates. An intent
  /// codec must NOT: `ZorphyIntentDigest` keeps the int `2` and the double
  /// `2.0` distinct by contract, so widening an int into a double would change
  /// the digest across `fromWire(intent.toWire())` — and #232's acceptance
  /// gate pins digest stability across exactly that round trip. A `double`
  /// field still widens (only a JSON hop delivers an `int` where a `double`
  /// was written, and widening restores the written value).
  final bool widenNumbers;

  const BoundaryCodecEmitter({
    this.trustedConstructor = 'fromTrusted',
    this.widenNumbers = true,
  });

  // ── Public API ────────────────────────────────────────────────────

  /// The wire-decoding member for [node].
  ///
  /// [additionalNodes] names further classes in the same library that a field
  /// may reference as a nested hierarchy node — a leaf cannot reach its
  /// siblings through `directSubTypes`, so a `List<Sibling>` field only
  /// resolves once the sibling's name is known here.
  Method fromWire(
    ZorphyNodeIr node,
    Map<String, List<BoundaryField>> fields, {
    Set<String> additionalNodes = const {},
  }) {
    // A generic node emits a codec-parameterized `fromWire` ONLY when it is a
    // concrete leaf (ZRP-009, #272). A generic DISPATCH node still has no wire
    // surface: its `fromWire` would have to forward the decoders to a leaf's
    // own re-declared static, which the IR cannot express — so it stays
    // fail-closed, exactly as before #272.
    final generic = node.typeParameters.isNotEmpty && node.isConcreteLeaf;
    final typeParams = generic ? _bareNames(node.typeParameters) : <String>[];
    return Method((m) {
      m
        ..name = 'fromWire'
        ..static = true
        ..returns = referType(
          'ZorphyBoundaryResult<${_resultType(node, typeParams)}>',
        );
      // A static member cannot reference the class type parameters, so a
      // generic `fromWire` RE-DECLARES them on the method itself — WITH their
      // bounds (`T extends num`), or the re-declared `T` would not satisfy the
      // class's own bound and the return type would not type-check.
      for (final parameter in node.typeParameters) {
        if (generic) m.types.add(_genericParameterSpec(parameter));
      }
      m.requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'raw'
            ..type = referType('Map<String, Object?>');
        }),
      );
      // One decoder per type parameter, in declaration order. Each consumes
      // the field's raw map (so `Product.fromWire` can be passed directly) and
      // its violations merge with the wrapper field violations.
      for (final parameter in typeParams) {
        m.requiredParameters.add(
          Parameter((p) {
            p
              ..name = _decoderName(parameter)
              // A function type is stored verbatim in the symbol (the same
              // escape-free trick `referType` uses for nullable types):
              // code_builder's `FunctionType` carries no parameter names, and
              // the issue's signature spells the raw-map parameter `raw`.
              ..type = TypeReference(
                (t) => t
                  ..symbol =
                      'ZorphyBoundaryResult<$parameter> '
                      'Function(Map<String, Object?> raw)',
              );
          }),
        );
      }
      m.body = Block.of(
        node.isConcreteLeaf
            ? _leafFromWireBody(
                node,
                fields,
                _known(node, additionalNodes),
                typeParams,
              )
            : _dispatchFromWireBody(node),
      );
    });
  }

  /// The wire-encoding member for [node].
  ///
  /// A dispatch node delegates to the matching leaf; a leaf writes its own
  /// fields and its discriminator. A generic node takes one encoder per type
  /// parameter, in declaration order; a field that mentions a parameter routes
  /// through that parameter's encoder.
  Method toWire(
    ZorphyNodeIr node,
    Map<String, List<BoundaryField>> fields, {
    Set<String> additionalNodes = const {},
  }) {
    // Mirror `fromWire`: only a generic concrete LEAF gets the codec-
    // parameterized surface; a generic dispatch node stays fail-closed.
    final generic = node.typeParameters.isNotEmpty && node.isConcreteLeaf;
    final typeParams = generic ? _bareNames(node.typeParameters) : <String>[];
    return Method((m) {
      m
        ..name = 'toWire'
        ..returns = referType('Map<String, Object?>');
      // One encoder per type parameter, in declaration order.
      for (final parameter in typeParams) {
        m.requiredParameters.add(
          Parameter((p) {
            p
              ..name = _encoderName(parameter)
              // Stored verbatim in the symbol for the same reason as the
              // decoder: a function type carries its parameter name `value`.
              ..type = TypeReference(
                (t) => t
                  ..symbol = 'Map<String, Object?> Function($parameter value)',
              );
          }),
        );
      }
      m.body = Block.of(
        node.isConcreteLeaf
            ? _leafToWireBody(
                node,
                fields,
                _known(node, additionalNodes),
                typeParams,
              )
            : _dispatchToWireBody(node),
      );
    });
  }

  /// Both members for [node], in injection order (`fromWire`, `toWire`).
  List<Method> emitCodec(
    ZorphyNodeIr node,
    Map<String, List<BoundaryField>> fields, {
    Set<String> additionalNodes = const {},
  }) => [
    fromWire(node, fields, additionalNodes: additionalNodes),
    toWire(node, fields, additionalNodes: additionalNodes),
  ];

  /// The `dart:convert` / ecosystem-compat `toJson` alias over [toWire] (#310).
  ///
  /// Emitted ONLY where a zero-arg `toJson() => toWire()` typechecks: a
  /// non-generic node, whose [toWire] takes no codec parameter. A generic node's
  /// [toWire] is codec-parameterized (ZRP-009, #272), so a zero-arg `toJson`
  /// would not compile — there the alias is skipped and this returns `null`.
  ///
  /// The alias is pure compat sugar: it projects the boundary codec, it does
  /// not move serialization policy onto the entity.
  Method? toJson(
    ZorphyNodeIr node,
    Map<String, List<BoundaryField>> fields, {
    Set<String> additionalNodes = const {},
  }) {
    if (node.typeParameters.isNotEmpty) return null;
    return Method((m) {
      m
        ..name = 'toJson'
        ..returns = referType('Map<String, dynamic>')
        ..body = const Code('return toWire();');
    });
  }

  /// The `dart:convert` / ecosystem-compat `fromJson` alias over [fromWire]
  /// (#310).
  ///
  /// Emitted ONLY where the zero-arg shape typechecks (a non-generic node); a
  /// generic node's [fromWire] re-declares its type parameters and takes a
  /// decoder per parameter, so the alias is skipped and this returns `null`.
  ///
  /// It aliases the STRICT validating [fromWire], never `fromTrusted`: the
  /// trust boundary is unchanged, this is only the ecosystem-compat name.
  Method? fromJson(
    ZorphyNodeIr node,
    Map<String, List<BoundaryField>> fields, {
    Set<String> additionalNodes = const {},
  }) {
    if (node.typeParameters.isNotEmpty) return null;
    return Method((m) {
      m
        ..name = 'fromJson'
        ..static = true
        ..returns = referType(
          'ZorphyBoundaryResult<${_resultType(node, const [])}>',
        )
        ..requiredParameters.add(
          Parameter((p) {
            p
              ..name = 'json'
              ..type = referType('Map<String, dynamic>');
          }),
        )
        ..body = Code('return ${node.cleanName}.fromWire(json);');
    });
  }

  /// The codec members for [node] WITH the #310 compat aliases appended when
  /// they typecheck: `fromWire`, `toWire`, then `fromJson`, `toJson` for a
  /// non-generic node, or just `fromWire`, `toWire` for a generic one.
  List<Method> emitJsonAliases(
    ZorphyNodeIr node,
    Map<String, List<BoundaryField>> fields, {
    Set<String> additionalNodes = const {},
  }) => [
    ...emitCodec(node, fields, additionalNodes: additionalNodes),
    if (fromJson(node, fields, additionalNodes: additionalNodes) case final f?)
      f,
    if (toJson(node, fields, additionalNodes: additionalNodes) case final t?) t,
  ];

  /// The library-level helpers every emitted codec calls.
  ///
  /// Emit these ONCE per library — they are shared by every hierarchy in it
  /// and a second copy is a duplicate-definition error. Each is total: a value
  /// of the wrong shape yields a `FieldViolation` (or `null`), never a thrown
  /// cast, which is what keeps `fromWire`'s "zero uncaught TypeError" promise.
  static List<Method> helperSpecs() => [
    _describeHelper(),
    _prefixHelper(),
    _asHelper(),
    _objectHelper(),
    _listHelper(),
    _doubleHelper(),
    _dateTimeHelper(),
  ];

  /// The subset of [helperSpecs] the codecs of [nodes] actually call.
  ///
  /// An unreferenced helper is an `unused_element` warning in the consuming
  /// library's analysis, so the composition (#223) emits exactly the used
  /// set — computed with the same classification the codecs were built with,
  /// so the two can never drift apart. [helperSpecs] stays the full set for a
  /// caller that composes its own library by hand.
  static List<Method> usedHelperSpecs(
    Iterable<ZorphyNodeIr> nodes,
    Map<String, List<BoundaryField>> fields, {
    Set<String> additionalNodes = const {},

    /// Class names whose decoder disables numeric widening (intents, #232).
    ///
    /// An intent's `num` decodes value-exact via `_boundaryAs<num>` while an
    /// entity/value `num` widens via `_boundaryDouble`; helper selection must
    /// use the SAME configuration as the decoder that calls it, or a
    /// standalone numeric intent references a `_boundaryAs` that was never
    /// emitted (#242 review).
    Set<String> noWidenClassNames = const {},
  }) {
    const emitter = BoundaryCodecEmitter();
    const noWidenEmitter = BoundaryCodecEmitter(widenNumbers: false);
    final shapes = <_Shape>{};
    final elementShapes = <_Shape>{};
    var hasDispatch = false;
    for (final node in nodes) {
      final activeEmitter = noWidenClassNames.contains(node.className)
          ? noWidenEmitter
          : emitter;
      if (!node.isConcreteLeaf) hasDispatch = true;
      final known = activeEmitter._known(node, additionalNodes);
      final typeParams = _bareNames(node.typeParameters).toSet();
      for (final field in fields[node.className] ?? const <BoundaryField>[]) {
        final type = activeEmitter._classify(field, known, typeParams);
        shapes.add(type.shape);
        // `elementShape` defaults to scalar for a non-collection field, so it
        // only names a real decode path for a list/map.
        if (type.shape == _Shape.list || type.shape == _Shape.map) {
          elementShapes.add(type.elementShape);
        }
      }
    }

    bool uses(_Shape shape) =>
        shapes.contains(shape) || elementShapes.contains(shape);

    // A type-parameter field decodes through `_boundaryObject` + the
    // parameter's decoder, re-pathing with `_boundaryPrefix` — the same helper
    // set a nested node field selects.
    final usesTypeParam = uses(_Shape.typeParam);

    return [
      // Every typed helper reports a mismatch through `_boundaryDescribe`,
      // and a dispatch node's unknown-tag error does too.
      if (shapes.isNotEmpty || hasDispatch) _describeHelper(),
      if (uses(_Shape.node) || usesTypeParam) _prefixHelper(),
      // A nested collection element decodes through the reified `is` test,
      // exactly like a scalar field.
      if (uses(_Shape.scalar) ||
          elementShapes.contains(_Shape.list) ||
          elementShapes.contains(_Shape.map))
        _asHelper(),
      if (shapes.contains(_Shape.map) || uses(_Shape.node) || usesTypeParam)
        _objectHelper(),
      if (shapes.contains(_Shape.list)) _listHelper(),
      if (uses(_Shape.number)) _doubleHelper(),
      if (uses(_Shape.dateTime)) _dateTimeHelper(),
    ];
  }

  /// Every emittable concrete leaf at or below [node], depth-first.
  ///
  /// A generic node (and everything below it) is pruned from the DISPATCH
  /// enumeration: a dispatch `fromWire` would have to forward the type
  /// parameters' decoders to the leaf's own re-declared static, which the IR
  /// cannot express. A generic CONCRETE LEAF still carries its own codec
  /// (ZRP-009, #272) — it is only the dispatch arm that is withheld. The same
  /// fail-closed rule the class-emission walk applies.
  static List<ZorphyNodeIr> leavesOf(ZorphyNodeIr node) {
    final out = <ZorphyNodeIr>[];
    void walk(ZorphyNodeIr current) {
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

  // ── Dispatch nodes ────────────────────────────────────────────────

  List<Code> _dispatchFromWireBody(ZorphyNodeIr node) {
    // ASSUMPTION (explicit, by design): the dispatch switches over
    // `leavesOf(node)` — the CONCRETE leaves only. An abstract intermediate
    // node between [node] and a leaf carries no discriminator of its own in
    // the current IR, so it is never a `case`; a wire tag that would match an
    // intermediate's value falls through to the `BoundaryErr` below. This is
    // correct for the v3 IR shape (only leaves are tagged). If a future IR
    // gives intermediates their own tags, this dispatch must recurse into the
    // intermediate's own dispatch rather than enumerating only leaves.
    final key = node.discriminatorKey;
    final leaves = leavesOf(node);
    final tags = leaves.map((leaf) => leaf.discriminatorValue).join(', ');
    final clean = node.cleanName;
    final body = <Code>[
      Code('final Object? tag = raw[${_literal(key)}];'),
      Code('if (tag is String) {'),
      Code('  switch (tag) {'),
    ];
    for (final leaf in leaves) {
      body.add(Code('    case ${_literal(leaf.discriminatorValue)}:'));
      // The leaf's own result is re-typed onto the ROOT's contract: a
      // caller holding `BoundaryOk<Notification>` must be able to own an
      // `OrderNotification` without knowing which leaf answered.
      body
        ..add(
          Code(
            '      return ${leaf.cleanName}.fromWire(raw).fold'
            '<ZorphyBoundaryResult<$clean>>(',
          ),
        )
        ..add(Code('        (value) => BoundaryOk<$clean>(value),'))
        ..add(
          Code(
            '        (error) => BoundaryErr<$clean>('
            'targetType: error.targetType, violations: error.violations),',
          ),
        )
        ..add(const Code('      );'));
    }
    // A missing tag and an unknown tag share one path so a caller reads the
    // same pointer either way; the expectation names the tags that WOULD
    // have been accepted.
    body
      ..add(const Code('  }'))
      ..add(const Code('}'))
      ..add(
        Code(
          'return BoundaryErr<$clean>('
          'targetType: ${_literal(clean)},'
          ' violations: <FieldViolation>[FieldViolation('
          'path: ${_literal('/$key')},'
          ' expected: ${_literal('String (one of: $tags)')},'
          ' actual: _boundaryDescribe(tag))]);',
        ),
      );
    return body;
  }

  List<Code> _dispatchToWireBody(ZorphyNodeIr node) {
    final leaves = leavesOf(node);
    final key = node.discriminatorKey;
    final body = <Code>[const Code('final value = this;')];
    // `is` promotion, not an `as` cast: the dispatch is total and the
    // promotion is what hands the leaf's own `toWire` the call.
    for (final leaf in leaves) {
      body.add(Code('if (value is ${leaf.cleanName}) return value.toWire();'));
    }
    // The boundary is symmetric with `fromWire`: an unknown subtype (e.g. a
    // plugin extending a sealed hierarchy at runtime) is ENCODED, never thrown
    // — `toWire` keeps the same "never a thrown UnsupportedError" promise
    // `fromWire` makes. The runtime type under the discriminator key is the
    // most informative map a codec can produce for a value it cannot dispatch,
    // and `_boundaryDescribe`-style diagnostics stay on the decode side.
    body.add(
      Code("return <String, Object?>{${_literal(key)}: '\$runtimeType'};"),
    );
    return body;
  }

  // ── Leaves ────────────────────────────────────────────────────────

  List<Code> _leafFromWireBody(
    ZorphyNodeIr node,
    Map<String, List<BoundaryField>> fields,
    Set<String> known,
    List<String> typeParams,
  ) {
    final own = fields[node.className] ?? const <BoundaryField>[];
    final clean = node.cleanName;
    // A generic class's boundary result is parameterized by its type
    // parameters (`BoundaryOk<CreateParams<T>>`), so the success/error types
    // and the `fromWire` return type agree.
    final resultType = _resultType(node, typeParams);
    final paramSet = typeParams.toSet();
    final body = <Code>[const Code('final violations = <FieldViolation>[];')];

    for (final field in own) {
      body.addAll(_readField(field, known, paramSet));
    }

    // Bail BEFORE construction: every local below is nullable, and the `!`
    // at the argument site is unreachable while a violation was recorded —
    // a null check, never a cast.
    body.add(
      Code(
        'if (violations.isNotEmpty) {'
        ' return BoundaryErr<$resultType>('
        'targetType: ${_literal(clean)}, violations: violations); }',
      ),
    );
    final arguments = own
        .map((field) {
          final local = _local(field);
          return '${field.name}: ${field.isNullable ? local : '$local!'}';
        })
        .join(', ');
    body.add(
      Code(
        'return BoundaryOk<$resultType>('
        '${_constructorCall(clean, arguments)});',
      ),
    );
    return body;
  }

  /// The constructor call a leaf decode builds its value with: through
  /// [trustedConstructor] when one is named, otherwise the plain generative
  /// constructor (`IntentEmitter`'s intent classes, #232).
  String _constructorCall(String clean, String arguments) =>
      trustedConstructor == null
      ? '$clean($arguments)'
      : '$clean.$trustedConstructor($arguments)';

  /// The statements that read one field off `raw`, bind it to a local, and
  /// record a violation instead of throwing when the shape is wrong.
  List<Code> _readField(
    BoundaryField field,
    Set<String> known,
    Set<String> typeParams,
  ) {
    final rawVar = 'raw_${field.name}';
    final local = _local(field);
    final path = _literal('/${field.name}');
    final out = <Code>[
      Code('final Object? $rawVar = raw[${_literal(field.name)}];'),
      Code('${field.baseType}? $local;'),
    ];
    final decode = _decode(field, known, typeParams, rawVar, local, path);
    if (field.isNullable) {
      // An ABSENT nullable field is legal: decode only when the key is there,
      // so a null never manufactures a violation.
      out
        ..add(Code('if ($rawVar != null) {'))
        ..addAll(decode)
        ..add(const Code('}'));
    } else {
      out.addAll(decode);
    }
    return out;
  }

  /// The assignment statements that decode [rawVar] into [local].
  List<Code> _decode(
    BoundaryField field,
    Set<String> known,
    Set<String> typeParams,
    String rawVar,
    String local,
    String path,
  ) {
    final base = field.baseType;
    final type = _classify(field, known, typeParams);

    switch (type.shape) {
      case _Shape.dateTime:
        return [
          Code('$local = _boundaryDateTime($rawVar, $path, violations);'),
        ];
      case _Shape.number:
        return [Code('$local = _boundaryDouble($rawVar, $path, violations);')];
      case _Shape.scalar:
        return [
          Code('$local = _boundaryAs<$base>($rawVar, $path, violations);'),
        ];

      case _Shape.enumValue:
        // Decode by NAME (mirrors the patch wire path), recording a
        // `FieldViolation` at the field pointer when no constant matches.
        return [
          Code(
            '$local = ZorphyPatchWire.enumByName<$base>('
            '$base.values, $rawVar, $path, violations);',
          ),
        ];

      case _Shape.typeParam:
        // A field that mentions a type parameter decodes through that
        // parameter's decoder, which consumes the field's raw map and whose
        // violations merge under the field pointer.
        final decoder = _decoderName(type.inner);
        return [
          Code(
            'final map_${field.name} = '
            '_boundaryObject($rawVar, $path, violations);',
          ),
          Code('if (map_${field.name} != null) {'),
          Code(
            '  $decoder(map_${field.name}).fold('
            '(value) { $local = value; }, '
            '(error) => violations.addAll('
            '_boundaryPrefix(error.violations, $path)));',
          ),
          const Code('}'),
        ];

      case _Shape.node:
        return [
          Code(
            'final map_${field.name} = '
            '_boundaryObject($rawVar, $path, violations);',
          ),
          Code('if (map_${field.name} != null) {'),
          Code(
            '  $base.fromWire(map_${field.name}).fold('
            '(value) { $local = value; }, '
            '(error) => violations.addAll('
            '_boundaryPrefix(error.violations, $path)));',
          ),
          const Code('}'),
        ];

      case _Shape.list:
        return _decodeList(field, type, rawVar, local, path, known, typeParams);

      case _Shape.map:
        return _decodeMap(field, type, rawVar, local, path, known, typeParams);
    }
  }

  List<Code> _decodeList(
    BoundaryField field,
    _FieldType type,
    String rawVar,
    String local,
    String path,
    Set<String> known,
    Set<String> typeParams,
  ) {
    final elementType = type.inner;
    final suffix = field.name;
    final body = <Code>[
      Code('final list_$suffix = _boundaryList($rawVar, $path, violations);'),
      Code('if (list_$suffix != null) {'),
      Code('  final decoded_$suffix = <$elementType>[];'),
      Code('  for (var i = 0; i < list_$suffix.length; i++) {'),
      // The pointer the issue's acceptance example pins: `/children[1]/…`.
      Code("    final path_$suffix = $path + '[\$i]';"),
    ];
    body.addAll(
      _elementDecode(
        elementType: elementType,
        elementShape: type.elementShape,
        element: 'list_$suffix[i]',
        target: 'decoded_$suffix',
        suffix: suffix,
        pathVar: 'path_$suffix',
        assign: 'decoded_$suffix.add(element_$suffix);',
        typeParams: typeParams,
      ),
    );
    body
      ..add(const Code('  }'))
      ..add(Code('  $local = decoded_$suffix;'))
      ..add(const Code('}'));
    return body;
  }

  List<Code> _decodeMap(
    BoundaryField field,
    _FieldType type,
    String rawVar,
    String local,
    String path,
    Set<String> known,
    Set<String> typeParams,
  ) {
    final valueType = type.inner;
    final suffix = field.name;
    final body = <Code>[
      Code('final map_$suffix = _boundaryObject($rawVar, $path, violations);'),
      Code('if (map_$suffix != null) {'),
      Code('  final decoded_$suffix = <String, $valueType>{};'),
      Code('  for (final entry in map_$suffix.entries) {'),
      Code("    final path_$suffix = $path + '/' + entry.key;"),
    ];
    body.addAll(
      _elementDecode(
        elementType: valueType,
        elementShape: type.elementShape,
        element: 'map_$suffix[entry.key]',
        target: 'decoded_$suffix',
        suffix: suffix,
        pathVar: 'path_$suffix',
        assign: 'decoded_$suffix[entry.key] = element_$suffix;',
        typeParams: typeParams,
      ),
    );
    body
      ..add(const Code('  }'))
      ..add(Code('  $local = decoded_$suffix;'))
      ..add(const Code('}'));
    return body;
  }

  /// The per-element decode statements shared by the list and map loops.
  ///
  /// [elementShape] is resolved by [_classify] with the hierarchy's known node
  /// names in hand, so a `List<Sibling>` recurses through the sibling's own
  /// `fromWire` rather than falling back to a plain `is` test.
  List<Code> _elementDecode({
    required String elementType,
    required _Shape elementShape,
    required String element,
    required String target,
    required String suffix,
    required String pathVar,
    required String assign,
    required Set<String> typeParams,
  }) {
    final variable = 'element_$suffix';
    final List<Code> body;
    switch (elementShape) {
      case _Shape.typeParam:
        // A collection element that is a type parameter decodes through that
        // parameter's decoder, re-pathing its violations under the element
        // pointer — the same shape as a nested node element, but through the
        // codec parameter rather than a static `fromWire`.
        final paramAssign = assign
            .replaceAll(variable, 'value')
            .replaceFirst(RegExp(r';\s*$'), '');
        final decoder = _decoderName(elementType.trim());
        body = [
          Code(
            '    final $variable = '
            '_boundaryObject($element, $pathVar, violations);',
          ),
          Code('    if ($variable != null) {'),
          Code(
            '      $decoder($variable).fold'
            '((value) => $paramAssign, '
            '(error) => violations.addAll('
            '_boundaryPrefix(error.violations, $pathVar)));',
          ),
          const Code('    }'),
        ];
      case _Shape.node:
        // The decoded node is the fold's success value, NOT the raw
        // `element_$suffix` map: substitute it into the assignment and drop
        // the trailing `;` (the assign is spliced into an arrow closure, not
        // a block). Without this the list/map element decode added the raw
        // JSON map and emitted `(value) => decoded.add(element);`, which does
        // not parse.
        final nodeAssign = assign
            .replaceAll(variable, 'value')
            .replaceFirst(RegExp(r';\s*$'), '');
        body = [
          Code(
            '    final $variable = '
            '_boundaryObject($element, $pathVar, violations);',
          ),
          Code('    if ($variable != null) {'),
          Code(
            '      $elementType.fromWire($variable).fold'
            '((value) => $nodeAssign, '
            '(error) => violations.addAll('
            '_boundaryPrefix(error.violations, $pathVar)));',
          ),
          const Code('    }'),
        ];
      case _Shape.dateTime:
        body = [
          Code(
            '    final $variable = '
            '_boundaryDateTime($element, $pathVar, violations);',
          ),
          Code('    if ($variable != null) { $assign }'),
        ];
      case _Shape.number:
        body = [
          Code(
            '    final $variable = '
            '_boundaryDouble($element, $pathVar, violations);',
          ),
          Code('    if ($variable != null) { $assign }'),
        ];
      case _Shape.list:
      case _Shape.map:
      case _Shape.scalar:
        // A nested collection or a plain scalar: the reified `is` test keeps
        // the read total (a mismatch is a violation, never a cast).
        body = [
          Code(
            '    final $variable = '
            '_boundaryAs<$elementType>($element, $pathVar, violations);',
          ),
          Code('    if ($variable != null) { $assign }'),
        ];
      case _Shape.enumValue:
        // A collection element that is an enum decodes by name, mirroring the
        // scalar enum field (issue #313).
        body = [
          Code(
            '    final $variable = '
            'ZorphyPatchWire.enumByName<$elementType>('
            '$elementType.values, $element, $pathVar, violations);',
          ),
          Code('    if ($variable != null) { $assign }'),
        ];
    }

    // A nullable element/value type accepts a wire `null` as a genuine
    // `null`, so the entry must be KEPT, not skipped by the decode guard
    // below (#242 review — `['a', null]` used to decode to `['a']`, changing
    // an intent's digest across `fromWire(intent.toWire())`). Short-circuit
    // BEFORE calling any helper so a legitimate null records no violation;
    // a wrong-typed NON-null value still takes the decode path and reports
    // one. Non-nullable element types keep the current violation for null.
    //
    // `dynamic` is treated the same way (#284): a `Map<String, dynamic>`
    // accepts every value INCLUDING null, so `{'clear': null}` must survive a
    // wire round trip instead of being dropped by the `!= null` guard.
    final bareElementType = elementType.trim();
    final keepsNull =
        bareElementType.endsWith('?') || bareElementType == 'dynamic';
    if (!keepsNull) return body;
    return [
      Code(
        '    if ($element == null) { ${assign.replaceAll(variable, 'null')} } else {',
      ),
      ...body,
      const Code('    }'),
    ];
  }

  List<Code> _leafToWireBody(
    ZorphyNodeIr node,
    Map<String, List<BoundaryField>> fields,
    Set<String> known,
    List<String> typeParams,
  ) {
    final own = fields[node.className] ?? const <BoundaryField>[];
    final paramSet = typeParams.toSet();
    final body = <Code>[];

    // A leaf that sits in a hierarchy ALWAYS stamps its own tag, so a
    // round-trip through `toWire` dispatches back to this same leaf.
    if (node.superTypes.isNotEmpty) {
      body.add(
        Code(
          'final map = <String, Object?>{'
          '${_literal(node.discriminatorKey)}: '
          '${_literal(node.discriminatorValue)}};',
        ),
      );
    } else {
      body.add(const Code('final map = <String, Object?>{};'));
    }

    for (final field in own) {
      final type = _classify(field, known, paramSet);
      if (field.isNullable) {
        // Dart does not promote a public field after a null check, so an
        // encoding that calls a member on it (`toWire`, `toIso8601String`,
        // `toDouble`) would stay a call on the nullable type and fail to
        // compile. Bind it to a local, guard the local, encode the local.
        final local = _local(field);
        final value = _wireExpression(field, type, source: local);
        // Read through `this`: a field named `map` would otherwise bind the
        // output `map` local declared above, feeding the map into itself and
        // losing the field's value.
        body
          ..add(Code('final $local = this.${field.name};'))
          ..add(
            Code(
              'if ($local != null) { '
              'map[${_literal(field.name)}] = $value; }',
            ),
          );
      } else {
        final value = _wireExpression(field, type);
        body.add(Code('map[${_literal(field.name)}] = $value;'));
      }
    }

    body.add(const Code('return map;'));
    return body;
  }

  /// The wire expression for [field] read from `this.<field>` — the shared
  /// encode seam for emitters that build their own `toWire` map (the intent
  /// surface), so an enum writes its NAME there exactly as it does in the
  /// generated entity codec (issue #313 review: an intent with an enum field
  /// otherwise emitted the raw `Enum` and `jsonEncode` threw).
  String wireExpression(BoundaryField field) {
    final type = _classify(field, const {}, const {});
    if (!field.isNullable) return _wireExpression(field, type);
    // A nullable field cannot have a member called on it without a guard, and
    // its `null` is a canonical wire value that must survive unchanged. A bare
    // `this.field == null ? … : this.field.map(…)` does NOT compile: a public
    // field is not promoted across the second read. Bind a local in an IIFE
    // (the same local promotion `_leafToWireBody` uses for entities) and render
    // the expression against it through `source`.
    final local = '_${field.name}';
    final expression = _wireExpression(field, type, source: local);
    return '(() { final $local = this.${field.name}; '
        'return $local == null ? null : $expression; })()';
  }

  /// [source] is the expression to encode — the field itself, or a local a
  /// nullable field was promoted into by [_leafToWireBody].
  String _wireExpression(
    BoundaryField field,
    _FieldType type, {
    String? source,
  }) {
    // An unqualified field name can be shadowed by the output `map` local in
    // `toWire` (e.g. a non-nullable field named `map`). Nullable fields arrive
    // with an explicit [source] local, so only the direct read is qualified.
    final name = source ?? 'this.${field.name}';
    switch (type.shape) {
      case _Shape.typeParam:
        return '${_encoderName(type.inner)}($name)';
      case _Shape.node:
        return '$name.toWire()';
      case _Shape.list:
        // `elementShape` is resolved by `_classify` with the hierarchy's
        // known node names; re-classifying `type.inner` here would lose that
        // context and turn a `List<Child>` into a scalar list whose elements
        // are never converted through `toWire()`.
        return switch (type.elementShape) {
          _Shape.typeParam => '$name.map(${_encoderName(type.inner)}).toList()',
          _Shape.node => '$name.map((e) => e.toWire()).toList()',
          _Shape.dateTime => '$name.map((e) => e.toIso8601String()).toList()',
          _Shape.enumValue =>
            '$name.map((e) => e is Enum ? e.name : e).toList()',
          _ => name,
        };
      case _Shape.map:
        return switch (type.elementShape) {
          _Shape.typeParam =>
            '$name.map((key, e) => MapEntry(key, ${_encoderName(type.inner)}(e)))',
          _Shape.node => '$name.map((key, e) => MapEntry(key, e.toWire()))',
          _Shape.dateTime =>
            '$name.map((key, e) => MapEntry(key, e.toIso8601String()))',
          _Shape.enumValue =>
            '$name.map((key, e) => MapEntry(key, e is Enum ? e.name : e))',
          _ => name,
        };
      case _Shape.dateTime:
        return '$name.toIso8601String()';
      case _Shape.number:
        // A `double` field already carries a double, so identity is correct.
        // A `num` field may hold an `int` that the decode side ALWAYS widens to
        // a `double` (`_boundaryDouble`); emitting it raw would silently
        // truncate on the round-trip, so encode it symmetrically with `.toDouble()`.
        return _strip(type.inner) == 'num' ? '$name.toDouble()' : name;
      case _Shape.scalar:
        return name;
      case _Shape.enumValue:
        // An `Enum` instance is not JSON-encodable: write its NAME so
        // `jsonEncode(toWire())` survives a transport hop (#215's fix, here for
        // the entity boundary codec). A same-process value already decoded in
        // flight is still an `Enum`, so the `is Enum` guard is total.
        return '$name is Enum ? $name.name : $name';
    }
  }

  // ── Type classification ──────────────────────────────────────────

  /// The clean class names a field of [node] may reference as a nested node.
  Set<String> _known(ZorphyNodeIr node, Set<String> additional) {
    final names = <String>{...additional};
    void walk(ZorphyNodeIr current) {
      // A generic node's name must not classify a field as a nested node: a
      // dispatch cannot reach a generic leaf's codec (it cannot forward the
      // decoders), so a field naming one would emit a `fromWire` call the
      // dispatch never declares. A generic CONCRETE LEAF still carries its own
      // codec (ZRP-009, #272); it is only the nested-node classification that
      // stays fail-closed here.
      if (current.typeParameters.isNotEmpty) return;
      names.add(current.cleanName);
      for (final child in current.directSubTypes) {
        walk(child);
      }
    }

    // A leaf cannot see its siblings through `directSubTypes`; walking from
    // the hierarchy root is what makes a `List<Sibling>` field resolve. When
    // [node] IS the root (`node.root == null`, or a self-referential root),
    // the two walks would traverse the same subtree and double every name in
    // the set, so the second walk is guarded away.
    final root = node.root;
    if (root != null && root != node) walk(root);
    walk(node);
    return names;
  }

  _FieldType _classify(
    BoundaryField field,
    Set<String> known,
    Set<String> typeParams,
  ) {
    final base = field.baseType;
    if (base.startsWith('List<') && base.endsWith('>')) {
      final element = _strip(base.substring(5, base.length - 1));
      return _FieldType(
        _Shape.list,
        inner: element,
        elementShape: _shapeOfType(
          element,
          known: known,
          typeParams: typeParams,
          enumTypes: field.enumElementTypes,
        ),
      );
    }
    if (base.startsWith('Map<') && base.endsWith('>')) {
      final arguments = _splitArguments(base.substring(4, base.length - 1));
      final value = arguments.length == 2 ? _strip(arguments[1]) : 'Object?';
      return _FieldType(
        _Shape.map,
        inner: value,
        elementShape: _shapeOfType(
          value,
          known: known,
          typeParams: typeParams,
          enumTypes: field.enumElementTypes,
        ),
      );
    }
    // A top-level enum field (issue #313) is its own shape: the wire carries
    // the constant's NAME, so encode writes `.name` and decode resolves by name
    // through `ZorphyPatchWire.enumByName`. `field.isEnum` is set from the IR's
    // analyzer `EnumElement` detection, so a non-enum class is never matched.
    if (field.isEnum) {
      return _FieldType(_Shape.enumValue, inner: base);
    }
    return _FieldType(
      _shapeOfType(base, known: known, typeParams: typeParams),
      inner: base,
    );
  }

  _Shape _shapeOfType(
    String type, {
    Set<String>? known,
    Set<String> typeParams = const {},
    Set<String> enumTypes = const {},
  }) {
    final base = _strip(type);
    // A type parameter is checked FIRST: a bare `T`, a nullable `T?` FIELD
    // (`baseType` has already lifted its trailing `?`), and a `T` element of a
    // `List<T>` / `Map<String, T>` all route through the parameter's codec,
    // never a reified `is` test (which could not name the parameter's bound).
    // Nullable ELEMENTS (`List<T?>`, `Map<String, T?>`) are deliberately
    // outside ZRP-009's listed shapes: `_strip` keeps their trailing `?`, so
    // they fall through to `scalar` and decode via `_boundaryAs` instead of
    // the parameter's decoder. A bare `T?` field is unaffected — its `?` is
    // stripped by `baseType` before classification.
    if (typeParams.contains(base)) return _Shape.typeParam;
    // An enum ELEMENT is a distinct type from its collection field, so it is
    // named by the IR's `enumElementTypes` rather than `field.isEnum`. Without
    // this check `List<Enum>`/`Map<String, Enum>` classify as scalars and the
    // element-level `enumValue` branches below are dead code (issue #313).
    if (enumTypes.contains(base)) return _Shape.enumValue;
    if (base == 'DateTime') return _Shape.dateTime;
    if (base == 'double' || (widenNumbers && base == 'num')) {
      return _Shape.number;
    }
    if (base.startsWith('List<')) return _Shape.list;
    if (base.startsWith('Map<')) return _Shape.map;
    if (known != null && known.contains(base)) return _Shape.node;
    return _Shape.scalar;
  }

  // ── Formatting helpers ───────────────────────────────────────────

  /// A single-quoted Dart string literal for [value].
  static String _literal(String value) =>
      "'${value.replaceAll('\\', '\\\\').replaceAll("'", "\\'")}'";

  static String _local(BoundaryField field) => '_${field.name}';

  /// The bare names of [typeParameters] (`T extends num` -> `T`), in order.
  static List<String> _bareNames(List<String> typeParameters) => [
    for (final parameter in typeParameters)
      parameter.split(' extends ').first.trim(),
  ];

  /// The [TypeReference] re-declaring one type parameter on a static method,
  /// carrying its bound (`T extends num`) so the re-declaration satisfies the
  /// class's own bound.
  static TypeReference _genericParameterSpec(String parameter) {
    final separator = parameter.indexOf(' extends ');
    if (separator == -1) {
      return TypeReference((t) => t..symbol = parameter.trim());
    }
    final name = parameter.substring(0, separator).trim();
    final bound = parameter.substring(separator + ' extends '.length).trim();
    return TypeReference((t) {
      t.symbol = name;
      t.bound = referType(bound);
    });
  }

  /// The parameterized type a generic node's boundary result carries
  /// (`CreateParams<T, U>`), or the bare [node] name for a non-generic one.
  static String _resultType(ZorphyNodeIr node, Iterable<String> typeParams) =>
      typeParams.isEmpty
      ? node.cleanName
      : '${node.cleanName}<${typeParams.join(', ')}>';

  /// The `toWire` encoder parameter name for type parameter [parameter].
  static String _encoderName(String parameter) => 'encode$parameter';

  /// The `fromWire` decoder parameter name for type parameter [parameter].
  static String _decoderName(String parameter) => 'decode$parameter';

  /// `$`/`$$` are generator declaration prefixes, never Dart identifiers.
  static String _strip(String type) => type.trim().replaceAll(r'$', '');

  /// Splits `A, B<C, D>` into `['A', 'B<C, D>']` on top-level commas.
  static List<String> _splitArguments(String input) {
    final out = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '<' || char == '(' || char == '[') depth++;
      if (char == '>' || char == ')' || char == ']') depth--;
      if (char == ',' && depth == 0) {
        out.add(input.substring(start, i));
        start = i + 1;
      }
    }
    if (start < input.length) out.add(input.substring(start));
    return out;
  }

  // ── Helper specs ─────────────────────────────────────────────────

  static Method _describeHelper() => Method((m) {
    m
      ..name = '_boundaryDescribe'
      ..returns = refer('String')
      ..requiredParameters.add(_param('value', 'Object?'))
      ..body = Code('''
if (value == null) return 'null';
final text = value.toString();
final clipped = text.length > 60 ? '\${text.substring(0, 60)}…' : text;
return '\${value.runtimeType} ("\$clipped")';''');
  });

  static Method _prefixHelper() => Method((m) {
    m
      ..name = '_boundaryPrefix'
      ..returns = refer('List<FieldViolation>')
      ..requiredParameters.add(_param('violations', 'List<FieldViolation>'))
      ..requiredParameters.add(_param('path', 'String'))
      ..body = Code('''
return violations
    .map(
      (violation) => FieldViolation(
        path: path + violation.path,
        expected: violation.expected,
        actual: violation.actual,
      ),
    )
    .toList();''');
  });

  static Method _asHelper() => Method((m) {
    m
      ..name = '_boundaryAs'
      ..types.add(refer('T'))
      ..returns = refer('T?')
      ..requiredParameters.add(_param('value', 'Object?'))
      ..requiredParameters.add(_param('path', 'String'))
      ..requiredParameters.add(_param('violations', 'List<FieldViolation>'))
      ..body = Code('''
if (value is T) return value;
violations.add(
  FieldViolation(
    path: path,
    expected: '\$T',
    actual: _boundaryDescribe(value),
  ),
);
return null;''');
  });

  static Method _objectHelper() => Method((m) {
    m
      ..name = '_boundaryObject'
      ..returns = refer('Map<String, Object?>?')
      ..requiredParameters.add(_param('value', 'Object?'))
      ..requiredParameters.add(_param('path', 'String'))
      ..requiredParameters.add(_param('violations', 'List<FieldViolation>'))
      // Only a genuine `Map<String, Object?>` is accepted. A map with non-String
      // keys (`{1: 'a'}`) is NOT coerced via `'$key'` — that silently invents
      // string keys and hides corruption — it becomes a `FieldViolation`, the
      // same way `_boundaryAs` reports a scalar type mismatch.
      ..body = Code('''
if (value is Map<String, Object?>) return value;
violations.add(
  FieldViolation(
    path: path,
    expected: 'Map<String, Object?>',
    actual: _boundaryDescribe(value),
  ),
);
return null;''');
  });

  static Method _listHelper() => Method((m) {
    m
      ..name = '_boundaryList'
      ..returns = refer('List<Object?>?')
      ..requiredParameters.add(_param('value', 'Object?'))
      ..requiredParameters.add(_param('path', 'String'))
      ..requiredParameters.add(_param('violations', 'List<FieldViolation>'))
      ..body = Code('''
if (value is List<Object?>) return value;
if (value is List) return List<Object?>.of(value);
violations.add(
  FieldViolation(
    path: path,
    expected: 'List<Object?>',
    actual: _boundaryDescribe(value),
  ),
);
return null;''');
  });

  static Method _doubleHelper() => Method((m) {
    m
      ..name = '_boundaryDouble'
      ..returns = refer('double?')
      ..requiredParameters.add(_param('value', 'Object?'))
      ..requiredParameters.add(_param('path', 'String'))
      ..requiredParameters.add(_param('violations', 'List<FieldViolation>'))
      // A JSON payload spells 1.0 as `1`, so an `int` IS a legal double.
      ..body = Code('''
if (value is double) return value;
if (value is num) return value.toDouble();
violations.add(
  FieldViolation(
    path: path,
    expected: 'double',
    actual: _boundaryDescribe(value),
  ),
);
return null;''');
  });

  static Method _dateTimeHelper() => Method((m) {
    m
      ..name = '_boundaryDateTime'
      ..returns = refer('DateTime?')
      ..requiredParameters.add(_param('value', 'Object?'))
      ..requiredParameters.add(_param('path', 'String'))
      ..requiredParameters.add(_param('violations', 'List<FieldViolation>'))
      ..body = Code('''
if (value is DateTime) return value;
if (value is String) {
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;
}
violations.add(
  FieldViolation(
    path: path,
    expected: 'DateTime (ISO-8601 String)',
    actual: _boundaryDescribe(value),
  ),
);
return null;''');
  });

  static Parameter _param(String name, String type) => Parameter((p) {
    p
      ..name = name
      ..type = referType(type);
  });
}

/// The classification of one declared field type.
final class _FieldType {
  final _Shape shape;

  /// The element value type for `list`/`map`, the base type otherwise.
  final String inner;

  /// For `list`/`map`: the shape of the element, resolved against the
  /// hierarchy's known node names so a `List<Sibling>` recurses.
  final _Shape elementShape;

  const _FieldType(
    this.shape, {
    this.inner = '',
    this.elementShape = _Shape.scalar,
  });
}
