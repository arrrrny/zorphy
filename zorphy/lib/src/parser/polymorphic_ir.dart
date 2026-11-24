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
  final bool isNullable;

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
    this.isDomainBool = false,
  });

  /// Whether this field is a `bool` (and therefore a candidate flag).
  bool get isBool => type == 'bool';

  @override
  String toString() => '$type${isNullable ? '?' : ''} $name';
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
