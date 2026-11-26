/// The unified polymorphic IR for Zorphy v3.0.0 (ISSUE-002, #177).
///
/// Every parsed declaration — annotated with `@ZorphyEntity`,
/// `@ZorphyState`, `@ZorphyUnion`, `@ZorphyIntent` or `@ZorphyValue` — lowers
/// to exactly one [ZorphyNodeIr]. A polymorphic hierarchy is the tree of those
/// nodes: one [PolymorphicIr] per library set, with one or more sealed roots.
///
/// `@ZorphyUnion` does NOT get a representation of its own: its factory
/// variants lower into the same [ZorphyNodeIr] shape as an `implements
/// $Parent` hierarchy, so every downstream emitter reads one structure. The
/// issue's acceptance criterion — "both forms produce identical
/// `PolymorphicIr` structures" — is a property of this file.
///
/// Nothing here emits code or mutates elements: the IR is pure data, built by
/// `HierarchyResolver`. Emission lives in the `code_builder` layer.
library;

/// Sentinel for `copyWith`'s nullable parameters: lets `null` mean "clear to
/// null" rather than "keep the current value".
const Object _unset = Object();

/// The archetype a node was declared with.
enum ArchetypeKind {
  /// `@ZorphyEntity` — an aggregate/event root with its own identity.
  entity,

  /// `@ZorphyState` — a mutable/composed state node.
  state,

  /// `@ZorphyIntent` — a replay-safe command/intent envelope.
  intent,

  /// `@ZorphyValue` — an immutable value object with no identity.
  ///
  /// `@ZorphyUnion` lowers to this archetype: a union is a closed set of
  /// value variants, and it carries no principal key.
  value,
}

/// The compile-time diagnostics the parser reports (issue #177 §2).
///
/// Each code is a named, stable contract: the emitter layer maps it to an
/// `InvalidGenerationSourceError` and its message is built by
/// [ZorphyDiagnostic.render].
enum ZorphyDiagnosticCode {
  /// `ZORPHY_E001` — root `@ZorphyEntity` missing `principalKey`, or the named
  /// field is missing / nullable / not a `String` or `int`.
  e001MissingPrincipalKey,

  /// `ZORPHY_E002` — a subtype mixes incompatible archetypes (e.g. a
  /// `@ZorphyEntity` implementing a `@ZorphyValue`).
  e002MixedArchetypes,

  /// `ZORPHY_E003` — two nodes in one hierarchy share a `discriminatorValue`.
  e003DuplicateDiscriminator,

  /// `ZORPHY_E004` — an `@ZorphyIntent` field's type has no canonical JSON
  /// form, so a generated `toWire`/`intentDigest` could only throw at call
  /// time. Reported at generation instead.
  e004FieldNotEncodable,

  /// `ZORPHY_E005` — an `@ZorphyIntent` payload field is named after the
  /// hierarchy's `discriminatorKey`, so the wire tag and the field would
  /// collide and the intent name would be lost from `toWire()`.
  e005DiscriminatorCollision,

  /// `ZORPHY_LINT_NO_BOOL_FLAGS` — a behavioral or lifecycle `bool` on a
  /// `@ZorphyState` / `@ZorphyIntent` / polymorphic variant (ISSUE-005, #180).
  ///
  /// A LINT code rather than an `E00N`: the namespace is the rule's, so a
  /// consumer matching on it is not tied to this generator's numbering.
  lintNoBoolFlags,
}

/// One diagnostic raised while resolving a hierarchy.
final class ZorphyDiagnostic {
  /// The stable code (`ZORPHY_E001`..`ZORPHY_E003`).
  final ZorphyDiagnosticCode code;

  /// The `$`-prefixed class name the diagnostic is about.
  final String nodeName;

  /// Human-readable detail, with no trailing period.
  final String message;

  const ZorphyDiagnostic({
    required this.code,
    required this.nodeName,
    required this.message,
  });

  /// The wire code (`ZORPHY_E001`, ...), stable across releases.
  String get codeName => switch (code) {
    ZorphyDiagnosticCode.e001MissingPrincipalKey => 'ZORPHY_E001',
    ZorphyDiagnosticCode.e002MixedArchetypes => 'ZORPHY_E002',
    ZorphyDiagnosticCode.e003DuplicateDiscriminator => 'ZORPHY_E003',
    ZorphyDiagnosticCode.e004FieldNotEncodable => 'ZORPHY_E004',
    ZorphyDiagnosticCode.e005DiscriminatorCollision => 'ZORPHY_E005',
    ZorphyDiagnosticCode.lintNoBoolFlags => 'ZORPHY_LINT_NO_BOOL_FLAGS',
  };

  /// Whether this diagnostic blocks generation.
  ///
  /// All codes do today; the getter exists so a future advisory code does not
  /// have to change every caller.
  bool get isError => true;

  /// `ZORPHY_E001: $Product — message`
  String render() => '$codeName: $nodeName — $message';

  @override
  String toString() => render();
}

/// One field a node declares (`String get productId;`).
///
/// [type] is the field's type as written, so the emitter can declare the
/// generated property and its constructor parameter with the same text a
/// consumer already writes in the abstract declaration.
final class ZorphyFieldIr {
  /// The field name, without any `get`/`set` keyword.
  final String name;

  /// The declared type, as source text (`String`, `List<int>`, ...).
  final String type;

  /// Whether the declared type is nullable (`String?`).
  ///
  /// This stays faithful to the SOURCE `?`: emitters use it for API shape
  /// (`fromTrusted` requiredness, `copyWith`'s clear-to-null sentinel), where a
  /// nullable-bounded type parameter must still behave as nullable — an
  /// unbounded `I` can be instantiated as `String?`. The redundant `?` in the
  /// emitted TYPE TEXT is suppressed separately by [suppressQuestionMark].
  final bool isNullable;

  /// Whether a `?` on [type] would be redundant because the field is typed by
  /// a type parameter whose bound is already nullable (ISSUE-273, ZRP-010).
  ///
  /// `class ToggleParams<I>` (implicit bound `Object?`) declares `I? get id`;
  /// emitting `I? id` is an `unnecessary_question_mark` in generated code. The
  /// bound is resolved ONCE here, at the IR level, so every type-text emitter
  /// inherits the same answer instead of re-deriving it from strings. Only
  /// type-text emission consults this flag — [isNullable] remains faithful to
  /// the source `?` so the generated API keeps its null-clearing behavior.
  final bool suppressQuestionMark;

  /// Whether the declaration carries `@ZorphyDomainBool()` — the author's
  /// explicit claim that this boolean is part of the domain rather than a
  /// behavioral mode switch (ISSUE-005, #180).
  ///
  /// `ZORPHY_LINT_NO_BOOL_FLAGS` skips an exempted field; nothing else reads
  /// the flag, so the escape hatch changes no emitted code.
  final bool isDomainBool;

  const ZorphyFieldIr({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.suppressQuestionMark = false,
    this.isDomainBool = false,
  });

  /// Whether the emitted type text carries a `?`.
  ///
  /// The source `?` is suppressed only when it is redundant (a
  /// nullable-bounded type parameter); [isNullable] itself stays faithful to
  /// the source so API-shape logic keeps treating the field as nullable.
  bool get emitsQuestionMark => isNullable && !suppressQuestionMark;

  /// Whether this field is a `bool` (and therefore a candidate flag).
  bool get isBool => type == 'bool';

  @override
  String toString() => '$type${emitsQuestionMark ? '?' : ''} $name';
}

/// One redirecting variant factory declared on a `@ZorphyUnion` root
/// (`factory $AppFailure.network({...}) = $NetworkFailure;`, issue #271).
///
/// The sealed root re-emits it as a `const factory <Union>.<name>({...}) =
/// <Variant>.fromTrusted;` so a consumer can construct a variant through the
/// root — and Dart 3 dot-shorthand (`.network(...)`) resolves — without
/// importing the variant class or hand-writing a top-level wrapper.
final class ZorphyVariantFactoryIr {
  /// The factory's name on the root (`network`), without the class prefix.
  final String name;

  /// The variant class the factory redirects to, prefixes included
  /// (`$NetworkFailure`) — the emitter lowers it the same way every other
  /// `$`-prefixed name is lowered.
  final String variantClassName;

  /// The factory's OWN declared formal parameters, in declaration order, read
  /// from the analyzer element (issue #290).
  ///
  /// The sealed root re-emits the source declaration's names, requiredness and
  /// defaults — NOT a parameter list rebuilt from the variant's fields, which
  /// silently dropped a declared default (`bool isRetryable = false` became
  /// `required bool isRetryable`) and turned an optional parameter required.
  /// Empty when the source could not be read; the emitter then falls back to
  /// the variant leaf's `fromTrusted` field list.
  final List<ZorphyUserParamIr> parameters;

  const ZorphyVariantFactoryIr({
    required this.name,
    required this.variantClassName,
    this.parameters = const [],
  });

  @override
  String toString() => '$name = $variantClassName';
}

/// One user-declared member a `@ZorphyUnion` root carries onto its generated
/// sealed class (issue #271): a `static` method or a body `factory`
/// constructor.
///
/// The SIGNATURE is structured data read from the analyzer element (lossless),
/// so the emitter rebuilds it as a `code_builder` [Method]/[Constructor]. The
/// BODY cannot be rebuilt from the AST without loss, so its ORIGINAL source
/// text is carried in [bodySource] and spliced through a `code_builder` `Code`
/// after the emitter rewrites `$Variant` identifiers to `Variant`.
final class ZorphyUserMemberIr {
  /// The member's name (`from`, `describe`); `''` for an unnamed factory.
  final String name;

  /// Whether this is a body `factory` constructor (true) or a `static` method
  /// (false).
  final bool isFactory;

  /// The method's return type as source text (`String`), or `null` for a
  /// factory.
  final String? returnType;

  /// The method's type parameters as source text (`T extends num`), empty for
  /// a non-generic member.
  final List<String> typeParameters;

  /// The member's formal parameters, in declaration order.
  final List<ZorphyUserParamIr> parameters;

  /// The member's ORIGINAL body source text, `$Variant` references included —
  /// a block body WITHOUT its outer braces, or an expression body WITHOUT the
  /// leading `=>` / trailing `;`.
  final String bodySource;

  /// Whether the body was an expression body (`=> expr`) rather than a block
  /// (`{ ... }`).
  final bool bodyIsLambda;

  const ZorphyUserMemberIr({
    required this.name,
    required this.isFactory,
    required this.returnType,
    required this.typeParameters,
    required this.parameters,
    required this.bodySource,
    required this.bodyIsLambda,
  });

  @override
  String toString() => name;
}

/// One formal parameter of a [ZorphyUserMemberIr].
final class ZorphyUserParamIr {
  /// The parameter name.
  final String name;

  /// The declared type as source text (`String`, `StackTrace?`), or `null`
  /// when the parameter has no explicit type.
  final String? type;

  /// Whether the parameter is named (`{ ... }`).
  final bool isNamed;

  /// Whether a named parameter is required.
  final bool isRequired;

  /// Whether the parameter is an optional positional (`[ ... ]`).
  final bool isOptionalPositional;

  /// The default-value source text (`3`), or `null` when there is none.
  final String? defaultValue;

  const ZorphyUserParamIr({
    required this.name,
    required this.type,
    required this.isNamed,
    required this.isRequired,
    required this.isOptionalPositional,
    required this.defaultValue,
  });
}

/// One node of a polymorphic hierarchy.
///
/// A node keeps BOTH names: [className] is the declared identifier
/// (`$UiNode`, `$$UiNode`), and [cleanName] is the generated class name
/// (`UiNode`) — the same split `ClassMetadata` uses, so emitters read the
/// field they need without re-deriving it.
final class ZorphyNodeIr {
  /// The declared class name, `$`/`$$` prefixes included.
  final String className;

  /// The node's identity across libraries: `libraryUri#ClassName`.
  ///
  /// [className] alone is NOT unique — two libraries may declare the same
  /// `$UiState`, which is exactly why [PolymorphicIr.nodes] is keyed this
  /// way. A rule that dedupes a graph walk must dedupe on this, or the first
  /// same-named node silently hides every other one.
  final String qualifiedName;

  /// The generated class name, prefixes stripped.
  final String cleanName;

  /// Which archetype the declaration carried.
  final ArchetypeKind archetype;

  /// Whether this node is the root of its hierarchy.
  final bool isSealedRoot;

  /// Whether this node sits between a root and a leaf.
  final bool isAbstractIntermediate;

  /// Whether this node can be instantiated (no subtype below it).
  final bool isConcreteLeaf;

  /// The transitive `$Parent` interfaces, nearest first.
  final List<ZorphyNodeIr> superTypes;

  /// The nodes that name this one in their `implements` clause.
  final List<ZorphyNodeIr> directSubTypes;

  /// Every instantiating node below this one, depth-first.
  final List<ZorphyNodeIr> allConcreteLeaves;

  /// The wire field carrying the subtype tag (`ZorphyEntity.discriminator`).
  ///
  /// Owned by the hierarchy ROOT and inherited by every node below it: a
  /// hierarchy that dispatched on two different keys could never round-trip.
  final String discriminatorKey;

  /// This node's wire value in [discriminatorKey], snake_case by default.
  final String discriminatorValue;

  /// The inherited identity field name, or `null` outside an entity
  /// hierarchy.
  final String? principalKey;

  /// The replay-safety decision for this node, `null` outside an intent
  /// hierarchy.
  final bool? replaySafe;

  /// Whether this node was lowered from a `@ZorphyUnion` factory variant.
  final bool isSyntheticLeaf;

  /// Whether this node belongs to a `@ZorphyUnion` hierarchy — the union root
  /// itself, or any of its variants (ISSUE-005, #180).
  ///
  /// `@ZorphyUnion` lowers to [ArchetypeKind.value], so without this flag the
  /// two value shapes are indistinguishable to a rule that must treat a union
  /// as the replacement for the flags its variants may not carry.
  final bool isUnion;

  /// The root of this node's hierarchy; unset on the root itself.
  final ZorphyNodeIr? root;

  /// The fields this node DECLARES itself (`String get productId;`), in
  /// declaration order.
  ///
  /// Inherited fields are NOT copied down. A consumer assembling a leaf's
  /// whole payload walks the node itself first and then its `superTypes`
  /// NEAREST-first, so the leaf's own declaration wins when a name is
  /// redeclared further up the chain (the emitter's `_payloadFields` keeps
  /// the first declaration of a name and drops the rest). Nearest-first is the
  /// intended precedence — do not "fix" an emitter that lets the leaf win to
  /// match a root-first reading of this comment.
  final List<ZorphyFieldIr> fields;

  /// The declaration's type parameters, bounds included (`T extends num`),
  /// empty for a non-generic node.
  ///
  /// The analyzer keeps these OFF [className] (`element.name` is the bare
  /// `$Box`), so an emitter that must know whether a node is generic cannot
  /// infer it from the name — it has to read this field. `PolymorphicIr`
  /// carries them per node for exactly that reason: an emitter that can only
  /// produce source for a non-generic class fails closed here instead of
  /// emitting `class Box<T>MockData`.
  final List<String> typeParameters;

  /// The redirecting variant factories the `@ZorphyUnion` source declared
  /// (`factory $AppFailure.network(...) = $NetworkFailure;`), in declaration
  /// order. Empty on every node except a union ROOT (issue #271).
  final List<ZorphyVariantFactoryIr> variantFactories;

  /// The user-declared `static` methods and body `factory` constructors the
  /// `@ZorphyUnion` source declared, in declaration order. Empty on every node
  /// except a union ROOT (issue #271).
  final List<ZorphyUserMemberIr> userMembers;

  /// The clean names of the union's variants whose SOURCE declares no
  /// `fromTrusted` constructor (issue #293). Empty on every node except a union
  /// ROOT.
  final List<String> variantsWithoutFromTrusted;

  const ZorphyNodeIr({
    required this.className,
    required this.cleanName,
    required this.archetype,
    required this.isSealedRoot,
    required this.isAbstractIntermediate,
    required this.isConcreteLeaf,
    required this.superTypes,
    required this.directSubTypes,
    required this.allConcreteLeaves,
    required this.discriminatorKey,
    required this.discriminatorValue,
    this.qualifiedName = '',
    this.principalKey,
    this.replaySafe,
    this.isSyntheticLeaf = false,
    this.isUnion = false,
    this.root,
    this.fields = const [],
    this.typeParameters = const [],
    this.variantFactories = const [],
    this.userMembers = const [],
    this.variantsWithoutFromTrusted = const [],
  });

  /// A copy with the named fields replaced, used by the resolver while it
  /// wires a tree up. Nodes are otherwise immutable, so a resolved IR is a
  /// value a caller can cache without a later mutation changing it.
  ///
  /// [principalKey] and [replaySafe] use a sentinel so `null` can mean
  /// "clear to null" rather than "keep": a node that moves out of an
  /// entity/intent hierarchy must be able to drop its inherited key (finding:
  /// `x ?? this.x` made clearing impossible).
  ZorphyNodeIr copyWith({
    List<ZorphyNodeIr>? superTypes,
    List<ZorphyNodeIr>? directSubTypes,
    List<ZorphyNodeIr>? allConcreteLeaves,
    String? discriminatorKey,
    Object? principalKey = _unset,
    Object? replaySafe = _unset,
    ZorphyNodeIr? root,
    bool? isSealedRoot,
    bool? isAbstractIntermediate,
    bool? isConcreteLeaf,
    bool? isSyntheticLeaf,
    bool? isUnion,
    List<ZorphyFieldIr>? fields,
    List<String>? typeParameters,
    List<ZorphyVariantFactoryIr>? variantFactories,
    List<ZorphyUserMemberIr>? userMembers,
    List<String>? variantsWithoutFromTrusted,
  }) {
    return ZorphyNodeIr(
      className: className,
      cleanName: cleanName,
      archetype: archetype,
      qualifiedName: qualifiedName,
      isSealedRoot: isSealedRoot ?? this.isSealedRoot,
      isAbstractIntermediate:
          isAbstractIntermediate ?? this.isAbstractIntermediate,
      isConcreteLeaf: isConcreteLeaf ?? this.isConcreteLeaf,
      superTypes: superTypes ?? this.superTypes,
      directSubTypes: directSubTypes ?? this.directSubTypes,
      allConcreteLeaves: allConcreteLeaves ?? this.allConcreteLeaves,
      discriminatorKey: discriminatorKey ?? this.discriminatorKey,
      discriminatorValue: discriminatorValue,
      principalKey: identical(principalKey, _unset)
          ? this.principalKey
          : principalKey as String?,
      replaySafe: identical(replaySafe, _unset)
          ? this.replaySafe
          : replaySafe as bool?,
      isSyntheticLeaf: isSyntheticLeaf ?? this.isSyntheticLeaf,
      isUnion: isUnion ?? this.isUnion,
      root: root ?? this.root,
      fields: fields ?? this.fields,
      typeParameters: typeParameters ?? this.typeParameters,
      variantFactories: variantFactories ?? this.variantFactories,
      userMembers: userMembers ?? this.userMembers,
      variantsWithoutFromTrusted:
          variantsWithoutFromTrusted ?? this.variantsWithoutFromTrusted,
    );
  }

  @override
  String toString() =>
      '${archetype.name}:$cleanName($discriminatorKey=$discriminatorValue)';
}

/// The parsed polymorphic graph of one library (or library set).
final class PolymorphicIr {
  /// Every node in the graph, keyed by qualified name
  /// (`libraryUri#ClassName`) so two libraries may declare same-named
  /// classes without one silently winning. A caller that knows the class
  /// name can still reach a node through [nodeFor].
  final Map<String, ZorphyNodeIr> nodes;

  /// The hierarchy roots, in declaration order.
  final List<ZorphyNodeIr> roots;

  /// Every diagnostic found while resolving, in discovery order.
  final List<ZorphyDiagnostic> diagnostics;

  const PolymorphicIr({
    required this.nodes,
    required this.roots,
    required this.diagnostics,
  });

  /// An empty graph — a library with no archetype annotations.
  static const PolymorphicIr empty = PolymorphicIr(
    nodes: {},
    roots: [],
    diagnostics: [],
  );

  /// Whether any diagnostic would block generation.
  bool get hasErrors => diagnostics.any((d) => d.isError);

  /// The ROOT node whose clean name is [cleanName], or `null`.
  ///
  /// Matching on the clean name is what the issue's fixtures describe
  /// (`rootFor('UiNode')`), and it is unambiguous inside one hierarchy.
  ZorphyNodeIr? rootFor(String cleanName) {
    for (final root in roots) {
      if (root.cleanName == cleanName) return root;
    }
    return null;
  }

  /// The node declared as [className] (prefixes included), or `null`.
  ///
  /// The map is keyed by qualified name, so a bare class name is resolved by
  /// a scan — unique in a single-library graph, and the first match in a
  /// multi-library one. Callers that need a specific library's node should
  /// key by `libraryUri#ClassName` directly.
  ZorphyNodeIr? nodeFor(String className) {
    final direct = nodes[className];
    if (direct != null) return direct;
    for (final node in nodes.values) {
      if (node.className == className) return node;
    }
    return null;
  }
}
