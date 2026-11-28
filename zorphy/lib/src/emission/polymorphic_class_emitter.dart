/// Emits the Dart 3 class shape of a polymorphic hierarchy (ISSUE-003, #178).
///
/// A resolved [PolymorphicIr] root names the hierarchy; the node's own fields
/// arrive beside it because the IR deliberately carries no field data (a
/// field's declaration belongs to the analyzer element the resolver does not
/// expose). Emission is [Class] specs only — `package:code_builder`, no
/// `StringBuffer` and no `generate*` toggles, per the issue's acceptance gate.
///
/// The emitted shape, straight from the issue:
///
/// ```dart
/// sealed class Notification implements $Notification, ZorphyEntityBase<String> {
///   const Notification();
///   @override
///   String get id;
///   @override
///   DateTime get createdAt;
///   @override
///   String get principalKey => id;
/// }
///
/// final class OrderNotification extends Notification implements $OrderNotification {
///   @override
///   final String id;
///   @override
///   final DateTime createdAt;
///   @override
///   final String orderId;
///
///   const OrderNotification.fromTrusted({
///     required this.id,
///     required this.createdAt,
///     required this.orderId,
///   });
///   // copyWith(), ==, hashCode, toString
/// }
/// ```
///
/// Three rules the emitted code depends on:
///
/// 1. A leaf EXTENDS the nearest sealed ancestor, never the root when an
///    intermediate sits between them — Dart requires the superclass to be the
///    immediate polymorphic neighbour.
/// 2. A leaf IMPLEMENTS every transitive `$Parent` interface, so a consumer
///    holding `EmailNotification` also satisfies `Notification`'s contract.
/// 3. `copyWith` clears a nullable field through the [_sentinel] object:
///    `null` as the argument would be indistinguishable from "keep the
///    current value", which is the bug the sentinel exists to prevent.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/type_ref.dart';
import '../parser/polymorphic_ir.dart';
import 'emitter.dart';

/// One declared field of a node: the name, its source type, nullability.
///
/// [type] is the field's type as written in the annotation's class — the
/// `$`-prefixed names are lowered by the emitter the same way every other
/// generator lowers them. [isNullable] is kept separate from [type] so a
/// caller may write `String` + `isNullable: true` without the `?` and still
/// get a nullable parameter in `copyWith`.
final class PolymorphicField {
  /// The field name.
  final String name;

  /// The declared type, `$`-prefixed class names included.
  final String type;

  /// Whether the field may be null.
  ///
  /// Faithful to the source `?`: drives `fromTrusted` requiredness and
  /// `copyWith`'s clear-to-null sentinel (see [_fromTrustedConstructor] and
  /// [_copyWith]). A nullable-bounded type parameter field stays nullable
  /// here even though its redundant `?` is suppressed in the emitted TYPE
  /// TEXT by [suppressQuestionMark].
  final bool isNullable;

  /// Whether hand-built IR explicitly suppresses the source `?`.
  ///
  /// Resolved fields leave this false so nullable generic constructor
  /// parameters remain type-safe (#351).
  final bool suppressQuestionMark;

  /// The source field-formal default (`0`, `'unknown'`), or `null`.
  ///
  /// Carried from [ZorphyFieldIr.constructorDefault] so an emitted call that
  /// omits this field can supply the author's own default (#291).
  final String? constructorDefault;

  const PolymorphicField({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.suppressQuestionMark = false,
    this.constructorDefault,
  });

  /// The type as emitted: the source `?` suffix applied exactly once.
  String get emittedType {
    if (!isNullable || suppressQuestionMark || type.endsWith('?')) return type;
    return '$type?';
  }
}

/// Emits the sealed roots and concrete leaves of one polymorphic hierarchy.
final class PolymorphicClassEmitter {
  /// The marker interface for `@ZorphyEntity` hierarchies, parameterized with
  /// the principal-key type.
  static const String entityBase = 'ZorphyEntityBase';

  /// The marker interface for `@ZorphyState` hierarchies.
  static const String stateBase = 'ZorphyStateBase';

  /// The marker interface for `@ZorphyIntent` hierarchies.
  static const String intentBase = 'ZorphyIntentBase';

  /// The marker interface for `@ZorphyValue` hierarchies.
  static const String valueBase = 'ZorphyValueBase';

  /// The marker interface for `@ZorphyUnion` hierarchies.
  ///
  /// A union lowers to [ArchetypeKind.value], so the archetype alone cannot
  /// tell a union from a plain value; [ZorphyNodeIr.isUnion] is what separates
  /// them. A consumer bounding `T extends ZorphyUnionBase` must accept a union
  /// variant, so the union root and its members carry this marker instead of
  /// [valueBase] (#284).
  static const String unionBase = 'ZorphyUnionBase';

  /// The `copyWith` sentinel: an object no caller can pass, so `null` means
  /// "clear the field".
  static const String sentinel = '_sentinel';

  /// The distinct private type the sentinel is an instance of. A plain
  /// `const Object()` sentinel is canonical-identical to any `const Object()`
  /// a caller passes, so `copyWith(field: const Object())` would be read as
  /// "keep" instead of "set"; a private class no caller can construct makes
  /// the `identical(...)` test reliable.
  static const String sentinelType = '_ZorphyCopyWithSentinel';

  /// The shared emission pipeline (`code_builder` -> `dart_style`).
  ///
  /// One instance per call is what a fresh [ZorphyEmitter] would already cost;
  /// being a field keeps the emitter itself `const` while still reusing the
  /// pipeline's single formatting path.
  static final ZorphyEmitter _emitter = ZorphyEmitter();

  /// Creates an emitter with the default page width.
  const PolymorphicClassEmitter();

  /// Whether [child] can be emitted as a class directly under [parent]
  /// (issue #231).
  ///
  /// A generic parent needs the child to bind ALL of the parent's type
  /// parameters in its `extends` clause, and the IR carries no interface type
  /// arguments — only each node's own declared parameters. The child binds
  /// them with its OWN type parameters positionally, so the arities must
  /// match: `class SliceData<T> extends AsyncSlice<T>` is emittable, while a
  /// non-generic leaf under a generic parent (it would need a concrete
  /// binding the IR never saw) is not and stays pruned. A non-generic parent
  /// takes no arguments, so any child is emittable under it.
  static bool isEmittableChild(ZorphyNodeIr child, ZorphyNodeIr parent) =>
      parent.typeParameters.isEmpty ||
      child.typeParameters.length == parent.typeParameters.length;

  /// The bare names of [typeParameters] (`T extends num` -> `T`), in order.
  static List<String> bareParameterNames(List<String> typeParameters) => [
    for (final parameter in typeParameters) _bareName(parameter),
  ];

  /// The type-argument list a use-site reference to [node] carries —
  /// `'<T, U>'` for a generic node (its own parameter names, bounds dropped:
  /// a bound is declared once, at the parameter) or `''` for a non-generic
  /// one.
  static String typeArgumentList(ZorphyNodeIr node) =>
      node.typeParameters.isEmpty
      ? ''
      : '<${bareParameterNames(node.typeParameters).join(', ')}>';

  /// The [TypeReference] declaring one type parameter: the name plus its
  /// bound when the declaration carries one (`T extends num`).
  static TypeReference genericParameterSpec(String parameter) {
    final separator = parameter.indexOf(' extends ');
    if (separator == -1) {
      return TypeReference((t) => t.symbol = parameter);
    }
    final name = parameter.substring(0, separator).trim();
    final bound = parameter.substring(separator + ' extends '.length).trim();
    return TypeReference((t) {
      t.symbol = name;
      t.bound = referType(bound);
    });
  }

  /// Whether the type parameter declared as [source] may be used where
  /// [target] is declared: the target's bound must be satisfied by the
  /// source's bound.
  ///
  /// Bounds are compared textually — the emission pipeline has no type system
  /// to ask — so the check is deliberately conservative: an unbounded target
  /// always accepts, a bounded target accepts only the SAME bound, and a
  /// bounded target under an unbounded source refuses. A subtype bound that
  /// would satisfy (`int` under `num`) refuses too; refusing withholds the
  /// dependent surface (a matcher, a morph method) instead of emitting an
  /// argument that violates `type_argument_not_matching_bounds`.
  static bool typeParameterSatisfies(String source, String target) {
    final targetBound = _boundOf(target);
    if (targetBound == null) return true;
    final sourceBound = _boundOf(source);
    if (sourceBound == null) return false;
    return sourceBound == targetBound;
  }

  /// [type] with every identifier in [from] replaced by the name at the same
  /// index in [to] — the positional binding a child's `extends Parent<Own…>`
  /// establishes between the parent's type parameters and its own. The
  /// replacement is one simultaneous pass, so swapped names (`<T, U>` bound
  /// as `<U, T>`) cannot cascade.
  static String substituteTypeParameters(
    String type,
    List<String> from,
    List<String> to,
  ) {
    final mapping = <String, String>{};
    for (var i = 0; i < from.length && i < to.length; i++) {
      if (from[i] != to[i]) mapping[from[i]] = to[i];
    }
    if (mapping.isEmpty) return type;
    return type.replaceAllMapped(
      RegExp('\\b(${mapping.keys.map(RegExp.escape).join('|')})\\b'),
      (match) => mapping[match.group(1)]!,
    );
  }

  /// [field] with its declared type rebound from one scope's type parameters
  /// to another's (see [substituteTypeParameters]). An unchanged type returns
  /// the same instance.
  static PolymorphicField substituteFieldScope(
    PolymorphicField field,
    List<String> from,
    List<String> to,
  ) {
    final substituted = substituteTypeParameters(field.type, from, to);
    if (substituted == field.type) return field;
    return PolymorphicField(
      name: field.name,
      type: substituted,
      isNullable: field.isNullable,
      suppressQuestionMark: field.suppressQuestionMark,
      constructorDefault: field.constructorDefault,
    );
  }

  /// The bound of one type-parameter declaration (`'T extends num'` ->
  /// `'num'`), or `null` when it is unbounded. `dynamic` is no bound at all.
  static String? _boundOf(String parameter) {
    final separator = parameter.indexOf(' extends ');
    if (separator == -1) return null;
    final bound = parameter.substring(separator + ' extends '.length).trim();
    return bound == 'dynamic' ? null : bound;
  }

  /// Every emittable concrete leaf at or below [node], depth-first in
  /// declaration order — the arm set of the matcher emitter and the
  /// source/target set of the morphing emitter.
  ///
  /// A child failing [isEmittableChild] is pruned WITH its subtree (its
  /// parent class is not emitted, so nothing below it can be named either) —
  /// the same rule the class-emission walk applies, kept here so the matcher
  /// and the class emitter can never disagree about what was emitted.
  static List<ZorphyNodeIr> emittableLeaves(ZorphyNodeIr node) {
    final leaves = <ZorphyNodeIr>[];
    void walk(ZorphyNodeIr current) {
      if (current.isConcreteLeaf) {
        leaves.add(current);
        return;
      }
      for (final child in current.directSubTypes) {
        if (!isEmittableChild(child, current)) continue;
        walk(child);
      }
    }

    walk(node);
    return leaves;
  }

  /// Emits the whole hierarchy under [root] as one formatted source string.
  ///
  /// [fields] is keyed by a node's `className` (`$UiNode`), matching
  /// [ZorphyNodeIr.className] — the declared identifier, prefixes included.
  /// A node absent from [fields] is emitted with no fields of its own; nodes
  /// with no fields at all (a marker root) are still emitted as valid sealed
  /// classes.
  ///
  /// Every node of the hierarchy is emitted in depth-first pre-order: the root
  /// first, then each subtree — the order a reader expects and the order a
  /// deterministic golden test needs.
  ///
  /// [extraMethods] is keyed by `className` too: members another emitter owns
  /// (the boundary codec's `fromWire`/`toWire`, #223) that must live INSIDE
  /// the emitted classes. They are appended after the value methods, on both
  /// the leaf and the dispatch branches.
  ///
  /// [includeSentinelDeclarations] prepends the library-private [_sentinel]
  /// declarations. They are ONE-per-library: a caller composing SEVERAL
  /// hierarchies into one part passes `true` for the first and `false` for
  /// the rest, or the duplicate declarations are a compile error (#223).
  String emit({
    required ZorphyNodeIr root,
    required Map<String, List<PolymorphicField>> fields,
    Map<String, List<Method>> extraMethods = const {},
    Map<String, List<Field>> extraFields = const {},
    bool includeSentinelDeclarations = true,
  }) {
    final specs = <Spec>[];
    // The parent comes from the TRAVERSAL, not from `node.superTypes`: the
    // hierarchy the emitter is walking is the authority on "nearest sealed
    // ancestor", and a caller's superTypes list may be a subset of it.
    //
    // The ROOT's walk is seeded with its own resolved `superTypes` (issue
    // #278): a cross-library leaf emitted as its own library's root still
    // `extends` the base generated in the other library. A normal hierarchy
    // root has empty `superTypes`, so this seed is empty there and the
    // traversal stays the sole authority for every descendant.
    void walk(ZorphyNodeIr node, List<ZorphyNodeIr> ancestors) {
      specs.add(
        _classSpec(
          node,
          fields,
          ancestors,
          extraMethods: extraMethods[node.className] ?? const [],
          extraFields: extraFields[node.className] ?? const [],
        ),
      );
      for (final child in node.directSubTypes) {
        // Issue #231: a child is pruned only when it cannot NAME its parent —
        // a generic parent needs every type parameter bound in the `extends`
        // clause, and the child binds them with its own parameters, so the
        // arities must match. A matching-arity child is emitted WITH its type
        // parameters (`class SliceData<T> extends AsyncSlice<T>`); a
        // non-matching one (and its subtree) stays pruned, because the parent
        // class it would extend does not exist in the generated library.
        if (!isEmittableChild(child, node)) continue;
        walk(child, [node, ...ancestors]);
      }
    }

    walk(root, root.superTypes);
    return _emitter.emitSpecs([
      if (includeSentinelDeclarations) ..._sentinelDeclarations(),
      ...specs,
    ]);
  }

  /// Emits a single node, without its subtree or its ancestors.
  ///
  /// Useful for a caller that owns the traversal (a generator visiting one
  /// class element at a time) and for a test that pins one class's shape.
  /// Because no ancestors are supplied, the emitted class has no `extends`
  /// and no inherited fields: use [emit] whenever the hierarchy matters.
  ///
  /// The returned source is self-contained: it declares the [_sentinel]
  /// constant and its [_sentinelType] class so a node with a nullable field
  /// compiles on its own. Both are library-private, so a caller that combines
  /// SEVERAL [emitNode] fragments into ONE library must emit those two
  /// declarations once, not once per fragment — emit them from a single node
  /// (or call [emit]) and concatenate only the class specs of the rest.
  String emitNode({
    required ZorphyNodeIr node,
    required List<PolymorphicField> fields,
  }) {
    return _emitter.emitSpecs([
      ..._sentinelDeclarations(),
      _classSpec(node, {node.className: fields}, const []),
    ]);
  }
  // ── Class shape ───────────────────────────────────────────────────

  Class _classSpec(
    ZorphyNodeIr node,
    Map<String, List<PolymorphicField>> fields,
    List<ZorphyNodeIr> ancestors, {
    List<Method> extraMethods = const [],
    List<Field> extraFields = const [],
  }) {
    final ownFields = fields[node.className] ?? const <PolymorphicField>[];
    // A leaf redeclares its inherited fields (`@override final String id;`),
    // so its field list is the union of its own and every ancestor's, nearest
    // last. The root has no ancestors and keeps just its own.
    final allFields = node.isConcreteLeaf
        ? _withInheritedFields(node, ownFields, fields)
        : ownFields;
    final isEntity = node.archetype == ArchetypeKind.entity;

    return Class((c) {
      c.name = node.cleanName;

      // Issue #231: the node's declared type parameters (bounds included)
      // reach the generated class, so a generic root and its leaves compile:
      // `sealed class AsyncSlice<T>` and `final class SliceData<T>`.
      for (final parameter in node.typeParameters) {
        c.types.add(genericParameterSpec(parameter));
      }

      if (node.isConcreteLeaf) {
        c.modifier = ClassModifier.final$;
        // The nearest ancestor is the superclass; `ancestors` is nearest-first.
        if (ancestors.isNotEmpty) {
          c.extend = referType(_superTypeName(ancestors.first, node));
        }
        // The archetype base is the v3 marker: `ZorphyEntityBase<Id>` for an
        // entity hierarchy, `ZorphyValueBase` for a value one. It is what a
        // consumer bounds a type parameter by; the `$Name` interfaces the v2
        // generator emitted are gone in v3.
        c.implements.add(_archetypeBase(node, fields));
      } else {
        // Roots and intermediates are `sealed`: Dart 3 forbids a subtype
        // outside the library, which is exactly the closed hierarchy the
        // archetypes describe.
        c.sealed = true;
        // An intermediate extends its nearest sealed ancestor for the same
        // reason a leaf does — without the edge it is not a subtype of the
        // root, and a leaf's `extends Intermediate` would not make it one
        // either. Only the ROOT has no ancestor and therefore no superclass.
        if (ancestors.isNotEmpty) {
          c.extend = referType(_superTypeName(ancestors.first, node));
        }
        c.implements.add(_archetypeBase(node, fields));
      }

      if (node.isConcreteLeaf) {
        // A field redeclared from an ancestor overrides that ancestor's
        // abstract getter; a field the leaf introduces does not, and marking
        // it `@override` is an analyzer error.
        final inheritedNames = {
          for (final ancestor in ancestors)
            for (final field
                in fields[ancestor.className] ?? const <PolymorphicField>[])
              field.name,
        };
        for (final field in allFields) {
          c.fields.add(
            Field((f) {
              f.name = field.name;
              // `emittedType`, not `type`: a field declared
              // `PolymorphicField(type: 'String', isNullable: true)` is a
              // `String?`, and emitting `String` makes its own `copyWith`
              // cast invalid.
              f.type = referType(_lowerType(field.emittedType));
              f.modifier = FieldModifier.final$;
              if (inheritedNames.contains(field.name)) {
                f.annotations.add(refer('override'));
              }
            }),
          );
        }
        c.constructors.add(_fromTrustedConstructor(node, allFields));
        // A no-arg constructor can only exist when every final field has an
        // initializer, i.e. when the leaf declares none.
        if (allFields.isEmpty) c.constructors.add(_constConstructor());
        c.methods.addAll(_valueMethods(node, allFields, isEntity));
      } else {
        // A sealed root/intermediate declares the contract as abstract
        // getters and supplies the `const` primary constructor subclasses
        // chain to.
        c.constructors.add(_constConstructor());
        final ancestorNames = {
          for (final ancestor in ancestors)
            for (final field
                in fields[ancestor.className] ?? const <PolymorphicField>[])
              field.name,
        };
        for (final field in ownFields) {
          c.methods.add(
            Method((m) {
              m.type = MethodType.getter;
              m.name = field.name;
              m.returns = referType(_lowerType(field.emittedType));
              if (ancestorNames.contains(field.name)) {
                m.annotations.add(refer('override'));
              }
            }),
          );
        }
        // Issue #271: a union ROOT re-emits its redirecting variant factories
        // and forwards the user statics / body factories the source declared.
        // A name that collides with a member the root already has (a user
        // member, fromWire/toWire, descriptor, lenses) is skipped and named in
        // the log — the same convention the descriptor emitter uses.
        if (node.isUnion && node.isSealedRoot) {
          _emitVariantFactories(c, node, fields);
          _emitUserMembers(c, node, fields);
        }
      }

      // The principal key is DEFINED on the root and inherited by every
      // subtype, so the getter is emitted once, where the identifier is
      // declared. It runs for EVERY sealed entity root — including a
      // standalone root that is also a concrete leaf (which takes the leaf
      // branch above) — and the `isSealedRoot` guard keeps descendant leaves
      // from redeclaring it.
      final principalKey = node.principalKey;
      if (isEntity && node.isSealedRoot && principalKey != null) {
        c.methods.add(
          Method((m) {
            m.type = MethodType.getter;
            m.name = 'principalKey';
            m.returns = referType(_principalKeyType(node, fields));
            // NOT `@override`: `ZorphyEntityBase<Id>` is a pure marker that
            // declares no members, so there is nothing to override. The
            // getter is the archetype's documented contract, not an
            // inherited member.
            m.lambda = true;
            m.body = Code(principalKey);
          }),
        );
      }

      // Members owned by another emitter (the boundary codec's
      // `fromWire`/`toWire`, #223; the lens registry's static `lenses`, #230)
      // land inside this class, after the value methods — a dispatch node and a
      // leaf both carry them.
      c.methods.addAll(extraMethods);
      c.fields.addAll(extraFields);
    });
  }

  /// The fields a leaf redeclares: every ancestor's, then its own, deduped by
  /// name with the leaf's declaration winning.
  ///
  /// An ancestor's field is declared in the ANCESTOR's type-parameter scope:
  /// `Root<T>` with `T get value` under `Child<U> implements Root<U>` must
  /// redeclare `final U value`, or the emitted field names a parameter that
  /// is not in scope in the child. Each ancestor's parameters are therefore
  /// substituted positionally into the leaf's own (the same binding
  /// [_superTypeName] establishes in the `extends` clause).
  List<PolymorphicField> _withInheritedFields(
    ZorphyNodeIr node,
    List<PolymorphicField> ownFields,
    Map<String, List<PolymorphicField>> fields,
  ) {
    final byName = <String, PolymorphicField>{};
    final leafParameters = bareParameterNames(node.typeParameters);
    // Ancestors farthest-first, so a nearer declaration overwrites a farther
    // one and the leaf's own list overwrites everything above it.
    for (final ancestor in node.superTypes.reversed) {
      final ancestorParameters = bareParameterNames(ancestor.typeParameters);
      for (final field
          in fields[ancestor.className] ?? const <PolymorphicField>[]) {
        byName[field.name] = substituteFieldScope(
          field,
          ancestorParameters,
          leafParameters,
        );
      }
    }
    for (final field in ownFields) {
      byName[field.name] = field;
    }
    return byName.values.toList();
  }

  /// The marker interface every class of the hierarchy implements.
  ///
  /// The marker is chosen by the node's ARCHETYPE, not a binary entity/value
  /// test: the annotation surface has five families (`@ZorphyEntity`,
  /// `@ZorphyState`, `@ZorphyIntent`, `@ZorphyValue` and `@ZorphyUnion`, the
  /// last lowering to [ArchetypeKind.value]) and each declares its own base
  /// (`ZorphyEntityBase`, `ZorphyStateBase`, `ZorphyIntentBase`,
  /// `ZorphyValueBase`). A `@ZorphyState` hierarchy must implement
  /// `ZorphyStateBase`, or a consumer bounding `T extends ZorphyStateBase`
  /// would reject the very hierarchy it was written for — the same reason the
  /// entity base is parameterized.
  ///
  /// An entity base is parameterized with the INHERITED principal key's type,
  /// read from the field list — the same source the root's getter uses, so the
  /// two can never disagree. The non-entity hierarchies have no identity, so
  /// their bases take no type argument.
  Reference _archetypeBase(
    ZorphyNodeIr node,
    Map<String, List<PolymorphicField>> fields,
  ) {
    return switch (node.archetype) {
      ArchetypeKind.entity => referType(
        '$entityBase<${_principalKeyType(node, fields)}>',
      ),
      ArchetypeKind.state => referType(stateBase),
      ArchetypeKind.intent => referType(intentBase),
      // A `@ZorphyUnion` lowers to the value archetype but is its own family:
      // it carries [unionBase] so a consumer bounding `T extends
      // ZorphyUnionBase` accepts a variant. A plain `@ZorphyValue` keeps
      // [valueBase] (#284).
      ArchetypeKind.value => referType(node.isUnion ? unionBase : valueBase),
    };
  }

  /// The declared type of the principal-key field, defaulting to `String`.
  ///
  /// The key's own field is where the type comes from; when the field list is
  /// unavailable the issue's canonical identity type is the honest default.
  String _principalKeyType(
    ZorphyNodeIr node,
    Map<String, List<PolymorphicField>> fields,
  ) {
    final key = node.principalKey;
    if (key == null) return 'String';
    for (final field in fields[node.className] ?? const <PolymorphicField>[]) {
      if (field.name == key) return _lowerType(field.type);
    }
    // The key is declared on the ROOT, so a subtype resolves it from there.
    // `node.root` is only the IMMEDIATE parent (the resolver stamps each child
    // with its parent), so a leaf two levels down would never reach the root's
    // declaration and would fall through to the `String` default — emit an
    // intermediate's key type where the root declared another. Search the full
    // transitive chain nearest-first instead.
    for (final ancestor in node.superTypes) {
      for (final field
          in fields[ancestor.className] ?? const <PolymorphicField>[]) {
        if (field.name == key) return _lowerType(field.type);
      }
    }
    return 'String';
  }

  // ── Constructors ──────────────────────────────────────────────────

  /// `const Notification();` — the no-argument const constructor.
  ///
  /// A sealed root always gets one (a subtype chains to it through
  /// `extends`); a leaf gets one only when it declares no fields, since an
  /// uninitialized `final` field is a compile error.
  Constructor _constConstructor() {
    return Constructor((ctor) {
      ctor.constant = true;
    });
  }

  /// `const OrderNotification.fromTrusted({required this.id, ...});`
  ///
  /// A collection field (`List`/`Set`/`Map`) is DEFENSIVELY COPIED at
  /// construction, so a caller that keeps and later mutates the list/map it
  /// passed cannot change an already-built value (#284). The copy is what
  /// drops `const`: a constructor with an initializer list cannot be const, so
  /// a class with at least one collection field emits a non-const
  /// `fromTrusted`, while a scalar-only class keeps the const form.
  ///
  /// The parameters live in [Constructor.optionalParameters] with `named` +
  /// `required` set, because code_builder renders `{…}` only for optional
  /// parameters — `requiredParameters` always renders positionally.
  Constructor _fromTrustedConstructor(
    ZorphyNodeIr node,
    List<PolymorphicField> fields,
  ) {
    final hasCollection = fields.any(
      (field) => _collectionSnapshot(field.emittedType) != null,
    );
    return Constructor((ctor) {
      ctor.name = 'fromTrusted';
      ctor.constant = !hasCollection;
      for (final field in fields) {
        final snapshot = _collectionSnapshot(field.emittedType);
        if (snapshot == null) {
          // A field-formal parameter must NOT carry its own type:
          // `required String this.id` is not Dart, `required this.id` is.
          // A NULLABLE field is optional: `required this.note` on a
          // `String?` field would reject the null it exists to allow.
          ctor.optionalParameters.add(
            Parameter((p) {
              p.name = field.name;
              p.named = true;
              p.required = !field.isNullable;
              p.toThis = true;
            }),
          );
          continue;
        }
        // A collection is taken as a plain parameter and copied in the
        // initializer list: `items = List<String>.of(items)` (null-guarded for
        // a nullable field, where an explicit null stays null).
        ctor.optionalParameters.add(
          Parameter((p) {
            p.name = field.name;
            p.named = true;
            p.required = !field.isNullable;
            // Lower `$` here exactly as the storage field, `copyWith` and the
            // variant factories do: a `$`-prefixed element type would emit a
            // parameter the generated library cannot resolve (#285 review).
            p.type = referType(_lowerType(field.emittedType));
          }),
        );
        final name = field.name;
        ctor.initializers.add(
          Code(
            field.isNullable
                ? '$name = $name == null ? null : $snapshot($name)'
                : '$name = $snapshot($name)',
          ),
        );
      }
    });
  }

  /// The `Type.of` constructor expression that snapshots a collection field
  /// of [emittedType] (`List<String>.of`, `Set<int>.of`, `Map<String,
  /// int>.of`), or `null` when the type is not a `List`/`Set`/`Map`.
  ///
  /// The element/value arguments are kept verbatim (`Map<String, int>.of`), so
  /// the copy types against the declared field. Two normalizations matter:
  /// * `$`-prefixed generator declarations are lowered, exactly like the
  ///   storage field, `copyWith` and the `fromTrusted` parameter — otherwise
  ///   `List<$Address>.of` emits a type that does not exist (#285 review).
  /// * only the OUTER nullable suffix is removed. Inner `?` markers belong to
  ///   the element type (`List<String?>`, `Map<String, int?>`) and must survive,
  ///   or the `.of` copy cannot accept its own declared parameter (#285 review).
  /// Whether [field]'s declared type is one of [node]'s own type parameters
  /// (`P data`, `T value`), optionally nullable.
  ///
  /// A type parameter is opaque to the emitter, so such a field MAY hold a
  /// `List`/`Set`/`Map` at runtime — and a snapshotted or caller-built
  /// collection is a different instance on every value. Comparing it with
  /// `==` then compares identities and `value == value.copyWith()` fails for
  /// a `Map` payload (#294) — the same defect #285 fixed for DECLARED
  /// collections, resurfacing through a generic. Those fields route through
  /// the shared `zorphyCollectionEquals` runtime helper, which falls back to
  /// for a non-collection.
  static bool _isTypeParameterField(ZorphyNodeIr node, PolymorphicField field) {
    var bare = _lowerType(field.emittedType).trim();
    if (bare.endsWith('?')) bare = bare.substring(0, bare.length - 1).trim();
    if (bare.isEmpty) return false;
    return node.typeParameters.any((parameter) {
      final name = parameter
          .split(RegExp(r'\s+(extends|super|in)\b'))
          .first
          .trim();
      return name == bare;
    });
  }

  /// Whether [field]'s `==`/`hashCode` must go through the dynamic collection
  /// helpers: a declared collection, or a type-parameter-typed field.
  static bool _comparesByContent(ZorphyNodeIr node, PolymorphicField field) =>
      _collectionSnapshot(field.emittedType) != null ||
      _isTypeParameterField(node, field);

  static String? _collectionSnapshot(String emittedType) {
    var bare = _lowerType(emittedType).trim();
    if (bare.endsWith('?')) {
      bare = bare.substring(0, bare.length - 1).trim();
    }
    if (bare.startsWith('List<') && bare.endsWith('>')) return '$bare.of';
    if (bare.startsWith('Set<') && bare.endsWith('>')) return '$bare.of';
    if (bare.startsWith('Map<') && bare.endsWith('>')) return '$bare.of';
    return null;
  }

  // ── Union root: variant factories & user members (#271) ───────────

  /// The names a union root already declares, so a forwarded member never
  /// collides with an existing one (issue #271 §3.4): the abstract getters and
  /// the members another emitter splices in (`fromWire`, `toWire`,
  /// `descriptor`, `lenses`, `resolvePath`). The user members and variant
  /// factories being emitted are NOT in this set — each emitter adds the names
  /// it has already emitted so a later one skips a collision.
  Set<String> _rootBaseNames(
    ZorphyNodeIr node,
    List<PolymorphicField> ownFields,
  ) {
    return <String>{
      for (final field in ownFields) field.name,
      'fromWire',
      'toWire',
      'descriptor',
      'lenses',
      'resolvePath',
    };
  }

  /// Emits one variant factory per variant onto the sealed root
  /// (issue #271 §3.1):
  /// `const factory AppFailure.network({...}) = NetworkFailure.fromTrusted;`.
  ///
  /// The parameter list is the SOURCE factory's own declaration (#290) —
  /// names, requiredness and defaults exactly as written — so the author's
  /// `bool isRetryable = false` stays optional instead of being re-derived
  /// from the variant's fields, where every non-nullable field would turn
  /// `required`. Only an IR built without the analyzer element (empty
  /// [ZorphyVariantFactoryIr.parameters]) falls back to the field-derived list.
  ///
  /// Dart constrains a REDIRECTING factory to the target's exact signature and
  /// forbids defaults on it (`default_value_in_redirecting_factory_constructor`,
  /// `redirect_to_invalid_function_type`), and a `const` redirect must target
  /// a `const` constructor. So the emitted shape is decided per variant:
  ///
  /// - **redirect** when the declaration is already the target's signature —
  ///   every parameter named, no defaults — AND the target's `fromTrusted` is
  ///   const; this keeps `const AppFailure.timeout(...)` and Dart 3
  ///   dot-shorthand (`.timeout(...)`) working;
  /// - **body factory** otherwise — `factory AppFailure.network({...}) =>
  ///   NetworkFailure.fromTrusted(...)` forwarding every declared parameter to
  ///   the field of the same name. A declared default, a positional
  ///   declaration, or a collection field (which makes `fromTrusted`
  ///   non-const, #284) each take this path.
  ///
  /// A factory whose name collides with a member the root already has (an
  /// abstract getter, a codec/lens/descriptor member, or a user member) is
  /// skipped and named in the log.
  void _emitVariantFactories(
    ClassBuilder c,
    ZorphyNodeIr node,
    Map<String, List<PolymorphicField>> fields,
  ) {
    final taken = _rootBaseNames(node, fields[node.className] ?? const []);
    // A variant factory may not shadow a user member the root also forwards.
    for (final member in node.userMembers) {
      if (member.name.isNotEmpty) taken.add(member.name);
    }
    for (final factory in node.variantFactories) {
      if (factory.name.isEmpty) continue;
      if (!taken.add(factory.name)) {
        _logSkipped(node, factory.name);
        continue;
      }
      final variant = _variantNode(node, factory.variantClassName);
      final variantFields = variant == null
          ? const <PolymorphicField>[]
          : _withInheritedFields(
              variant,
              fields[variant.className] ?? const [],
              fields,
            );
      // `fromTrusted` is const unless a collection field is snapshotted in
      // its initializer list — the same predicate _fromTrustedConstructor uses.
      final targetIsConst = !variantFields.any(
        (field) => _collectionSnapshot(field.emittedType) != null,
      );
      final targetSymbol =
          '${_lowerType(factory.variantClassName)}.fromTrusted';
      c.constructors.add(
        Constructor((ctor) {
          ctor.factory = true;
          ctor.name = factory.name;
          if (!factory.hasDeclaredParameters) {
            // No analyzer element behind the IR: the field-derived list is the
            // only shape available, and it is redirect-compatible by design.
            ctor.constant = targetIsConst;
            for (final field in variantFields) {
              ctor.optionalParameters.add(
                Parameter((p) {
                  p.name = field.name;
                  p.named = true;
                  p.required = !field.isNullable;
                  p.type = referType(_lowerType(field.emittedType));
                }),
              );
            }
            ctor.redirect = refer(targetSymbol);
            return;
          }
          final (required, optional) = _splitParams(factory.parameters);
          ctor.requiredParameters.addAll(required);
          ctor.optionalParameters.addAll(optional);
          // A redirecting factory must ACCEPT EVERY required parameter of its
          // target. `fromTrusted` declares one named parameter per leaf field,
          // so a declaration that omits a (defaulted) field — e.g.
          // `network({required String message}) = $NetworkFailure` where the
          // variant also has `this.code = 'unknown'` — would emit
          // `redirect_to_invalid_function_type`. Compare the declaration with
          // the COMPLETE target signature, not just its own shape (#291).
          final targetFieldNames = {
            for (final field in variantFields) field.name,
          };
          final targetRequiredNames = {
            for (final field in variantFields)
              if (!field.isNullable) field.name,
          };
          final declaredNames = {for (final p in factory.parameters) p.name};
          final redirectCompatible =
              targetIsConst &&
              !factory.parameters.any(
                (p) => p.defaultValue != null || !p.isNamed,
              ) &&
              targetRequiredNames.every(declaredNames.contains) &&
              declaredNames.every(targetFieldNames.contains);
          if (redirectCompatible) {
            ctor.constant = true;
            ctor.redirect = refer(targetSymbol);
            return;
          }

          // Body factory: forward each declared parameter to the TARGET FIELD
          // it binds, not to a same-named parameter. A positional declaration
          // binds by position (`ready(String input) = $Ready` against
          // `const $Ready(this.value)` becomes `value: input`), while a named
          // declaration binds by its own name (#291).
          final forwarded = <String>[];
          final supplied = <String>{};
          var positionalIndex = 0;
          for (final p in factory.parameters) {
            final targetName = p.isNamed
                ? p.name
                : positionalIndex < variantFields.length
                ? variantFields[positionalIndex].name
                : p.name;
            if (!p.isNamed) positionalIndex++;
            forwarded.add('$targetName: ${p.name}');
            supplied.add(targetName);
          }
          // Required target fields the source declaration omitted still need a
          // value — the author's own field-formal default is the right one.
          // `idle()` against `const $Idle({this.count = 0})` becomes
          // `Idle.fromTrusted(count: 0)` instead of a field-derived
          // `idle({required int count})` (#291).
          for (final field in variantFields) {
            if (field.isNullable ||
                field.constructorDefault == null ||
                supplied.contains(field.name)) {
              continue;
            }
            forwarded.add('${field.name}: ${field.constructorDefault}');
          }
          ctor.lambda = true;
          ctor.body = Code('$targetSymbol(${forwarded.join(', ')})');
        }),
      );
    }
  }

  /// Forwards the user-declared static methods and body factory constructors
  /// onto the sealed root (issue #271 §3.2), with every `$Variant` identifier
  /// rewritten to `Variant`. The signature is rebuilt from structured IR; the
  /// body is spliced through a `code_builder` `Code` (never a `StringBuffer`).
  void _emitUserMembers(
    ClassBuilder c,
    ZorphyNodeIr node,
    Map<String, List<PolymorphicField>> fields,
  ) {
    final taken = _rootBaseNames(node, fields[node.className] ?? const []);
    // The generated leaf's `fromTrusted` is the retargeting destination for
    // `$Variant(...)` calls in forwarded bodies (#293). Keep its field order
    // and source defaults so positional args and omitted fields can be bound
    // correctly (#291).
    final variantShapes = <String, List<PolymorphicField>>{
      for (final name in node.variantsWithoutFromTrusted)
        name: _variantFieldsFor(node, name, fields),
    };
    // A user member is the author's OWN declaration and always survives (issue
    // #271 §3.4 makes the GENERATED factory yield to it, never the reverse); it
    // only yields to a member the root already carries from another emitter.
    for (final member in node.userMembers) {
      if (member.name.isNotEmpty && !taken.add(member.name)) {
        _logSkipped(node, member.name);
        continue;
      }
      final body = _rewriteVariants(
        member.bodySource,
        variantShapes: variantShapes,
      );
      final (required, optional) = _splitParams(member.parameters);
      if (member.isFactory) {
        c.constructors.add(
          Constructor((ctor) {
            ctor.factory = true;
            if (member.name.isNotEmpty) ctor.name = member.name;
            ctor.requiredParameters.addAll(required);
            ctor.optionalParameters.addAll(optional);
            ctor.lambda = member.bodyIsLambda;
            ctor.body = Code(body);
          }),
        );
      } else {
        c.methods.add(
          Method((m) {
            m.static = true;
            m.name = member.name;
            if (member.returnType != null) {
              m.returns = referType(_lowerType(member.returnType!));
            }
            for (final parameter in member.typeParameters) {
              m.types.add(genericParameterSpec(parameter));
            }
            m.requiredParameters.addAll(required);
            m.optionalParameters.addAll(optional);
            m.lambda = member.bodyIsLambda;
            m.body = Code(body);
          }),
        );
      }
    }
  }

  /// Splits [parameters] into the positional [required] and the [optional]
  /// lists code_builder renders as `(a, b)` and `{...}` / `[...]`. Shared by
  /// the forwarded user members and the variant factories, so a declared
  /// default value (`bool isRetryable = false`) survives both paths.
  (List<Parameter>, List<Parameter>) _splitParams(
    List<ZorphyUserParamIr> parameters,
  ) {
    final required = <Parameter>[];
    final optional = <Parameter>[];
    for (final p in parameters) {
      final parameter = Parameter((spec) {
        spec.name = p.name;
        if (p.type != null) spec.type = referType(_lowerType(p.type!));
        if (p.isNamed) {
          spec.named = true;
          spec.required = p.isRequired;
        }
        if (p.defaultValue != null) spec.defaultTo = Code(p.defaultValue!);
      });
      (p.isOptionalPositional || p.isNamed ? optional : required).add(
        parameter,
      );
    }
    return (required, optional);
  }

  /// The variant leaf named [variantClassName] (`$NetworkFailure`) at or below
  /// [node], or `null` when the IR does not carry it (a cross-library target
  /// the resolver pruned) — the factory is then emitted with no parameters,
  /// which is still a legal redirect to a no-arg `fromTrusted`.
  ZorphyNodeIr? _variantNode(ZorphyNodeIr node, String variantClassName) {
    // `allConcreteLeaves` is itself derived from `directSubTypes`, so one
    // recursive walk visits every candidate exactly once (review nit #281).
    for (final child in node.directSubTypes) {
      if (child.className == variantClassName) return child;
      final nested = _variantNode(child, variantClassName);
      if (nested != null) return nested;
    }
    return null;
  }

  /// The fields a variant's generated `fromTrusted` accepts, in declaration
  /// order with inherited fields included — the shape a `$Variant(...)` call
  /// in a forwarded body is retargeted to (#291).
  List<PolymorphicField> _variantFieldsFor(
    ZorphyNodeIr node,
    String cleanName,
    Map<String, List<PolymorphicField>> fields,
  ) {
    ZorphyNodeIr? find(ZorphyNodeIr current) {
      if (current.cleanName == cleanName) return current;
      for (final child in current.directSubTypes) {
        final hit = find(child);
        if (hit != null) return hit;
      }
      return null;
    }

    final variant = find(node);
    if (variant != null) {
      return _withInheritedFields(
        variant,
        fields[variant.className] ?? const [],
        fields,
      );
    }
    // A cross-library variant may be absent from this hierarchy's walk; fall
    // back to the fields map keyed by its declared (prefixed) name.
    for (final entry in fields.entries) {
      if (entry.key.replaceAll(r'$', '') == cleanName) return entry.value;
    }
    return const <PolymorphicField>[];
  }

  /// Rewrites every `$Variant` identifier in [source] to `Variant` — the same
  /// `$`-lowering every other generator applies, so a forwarded member body
  /// that names `$NetworkFailure` or `$AppFailure` compiles against the
  /// generated classes.
  ///
  /// The rewrite is TOKEN-AWARE: only real identifier tokens lose their `$`.
  /// `$` characters inside string literals (interpolation, raw strings,
  /// escapes) and comments are copied verbatim. A raw `replaceAll(r'$', '')`
  /// silently corrupted `'cost: $amount'` and `r'$raw'` (issue #281 review).
  ///
  /// [variantShapes] holds the fields (in declaration order, with the source
  /// field-formal defaults) of the union's variants whose SOURCE has no
  /// `fromTrusted` (issue #293). A `$Variant(...)` CONSTRUCTOR invocation of
  /// one of those is retargeted to the generated leaf's trusted constructor:
  /// positional arguments are bound to the target field names, omitted fields
  /// that had a source default are supplied, and type arguments are placed
  /// before `.fromTrusted` (#291). A `$Variant.x` member access, a `$Variant`
  /// type position, a switch OBJECT PATTERN, or a variant that declares
  /// `fromTrusted` keeps the plain lowering — only the call shape is rewritten.
  static String _rewriteVariants(
    String source, {
    Map<String, List<PolymorphicField>> variantShapes = const {},
  }) {
    final result = <String>[];
    var i = 0;
    while (i < source.length) {
      final code = source.codeUnitAt(i);

      // Comments are prose: a `$` in them is never an identifier.
      if (code == 0x2f /* / */ && i + 1 < source.length) {
        final next = source.codeUnitAt(i + 1);
        if (next == 0x2f) {
          final end = _endOfLineComment(source, i + 2);
          result.add(source.substring(i, end));
          i = end;
          continue;
        }
        if (next == 0x2a) {
          final end = _endOfBlockComment(source, i + 2);
          result.add(source.substring(i, end));
          i = end;
          continue;
        }
      }

      // Skip the WHOLE string literal, interpolation and escapes included.
      final stringEnd = _stringLiteralEnd(source, i);
      if (stringEnd != null) {
        result.add(source.substring(i, stringEnd));
        i = stringEnd;
        continue;
      }

      if (code == 0x24 /* $ */ ) {
        var end = i + 1;
        while (end < source.length &&
            _isIdentifierPart(source.codeUnitAt(end))) {
          end++;
        }
        if (end > i + 1) {
          final name = source.substring(i + 1, end);
          // `<...>` type arguments may sit between the name and the call's
          // `(`; whitespace may not. They are captured so a retargeted call
          // emits `Ready<T>.fromTrusted()` instead of `Ready.fromTrusted<T>()`.
          var cursor = end;
          var typeArgs = '';
          if (cursor < source.length && source.codeUnitAt(cursor) == 0x3c) {
            final typeArgsStart = cursor;
            var depth = 0;
            while (cursor < source.length) {
              final c = source.codeUnitAt(cursor);
              if (c == 0x3c) depth++;
              if (c == 0x3e && --depth == 0) {
                cursor++;
                break;
              }
              cursor++;
            }
            typeArgs = source.substring(typeArgsStart, cursor);
          }
          final isCall =
              cursor < source.length && source.codeUnitAt(cursor) == 0x28;
          final fields = variantShapes[name];
          if (isCall && fields != null) {
            final close = _matchingParen(source, cursor);
            if (close != null) {
              // [close] is one past the closing paren, so the argument text
              // excludes it.
              final args = source.substring(cursor + 1, close - 1);
              // An object pattern (`case $Variant(message: final message)`)
              // is a TYPE match, not a construction — retargeting it to
              // `Variant.fromTrusted(...)` produces unanalyzable code (#291).
              if (!_isObjectPattern(args)) {
                result.add(_retargetVariantCall(name, typeArgs, args, fields));
                i = close;
                continue;
              }
            }
          }
          result.add(name);
          i = end;
          continue;
        }
      }

      result.add(source[i]);
      i++;
    }
    return result.join();
  }

  /// Index just past the `)` matching the `(` at [open], or `null` when the
  /// call is unterminated. Strings and comments are skipped so their parens
  /// never change the nesting depth.
  static int? _matchingParen(String s, int open) {
    var depth = 0;
    var i = open;
    while (i < s.length) {
      final stringEnd = _stringLiteralEnd(s, i);
      if (stringEnd != null) {
        i = stringEnd;
        continue;
      }
      if (s.codeUnitAt(i) == 0x2f /* / */ && i + 1 < s.length) {
        final next = s.codeUnitAt(i + 1);
        if (next == 0x2f) {
          i = _endOfLineComment(s, i + 2);
          continue;
        }
        if (next == 0x2a) {
          i = _endOfBlockComment(s, i + 2);
          continue;
        }
      }
      final c = s.codeUnitAt(i);
      if (c == 0x28 /* ( */ ) depth++;
      if (c == 0x29 /* ) */ && --depth == 0) return i + 1;
      i++;
    }
    return null;
  }

  /// Whether an argument list is an object PATTERN rather than a constructor
  /// invocation. Object patterns bind with `final`/`var` (or `_`) inside their
  /// fields; a real expression argument never contains those tokens. Keeping
  /// the check to this narrow, positive signal avoids rewriting ordinary calls
  /// while leaving the plain `$Variant` -> `Variant` type lowering intact.
  static bool _isObjectPattern(String args) =>
      RegExp(r'(^|[,{(\s])(final|var)\s').hasMatch(args);

  /// Builds a `Variant.fromTrusted(...)` call from a source `$Variant(...)`.
  /// Named arguments are kept verbatim; positional ones bind to the target
  /// field of the same position; required fields the source omitted are
  /// supplied from their own field-formal defaults (#291).
  static String _retargetVariantCall(
    String name,
    String typeArgs,
    String args,
    List<PolymorphicField> fields,
  ) {
    final pieces = _splitArgs(args);
    final forwarded = <String>[];
    final supplied = <String>{};
    var positionalIndex = 0;
    for (final piece in pieces) {
      final named = _namedArgTarget(piece);
      if (named != null) {
        forwarded.add(piece);
        supplied.add(named);
        continue;
      }
      final targetName = positionalIndex < fields.length
          ? fields[positionalIndex].name
          : piece.trim();
      if (positionalIndex < fields.length) positionalIndex++;
      forwarded.add('$targetName: ${piece.trim()}');
      supplied.add(targetName);
    }
    for (final field in fields) {
      if (field.isNullable ||
          field.constructorDefault == null ||
          supplied.contains(field.name)) {
        continue;
      }
      forwarded.add('${field.name}: ${field.constructorDefault}');
    }
    return '$name$typeArgs.fromTrusted(${forwarded.join(', ')})';
  }

  /// Splits an argument list at top-level commas. Nested `(`, `[` and `{`
  /// groups (and string literals/comments) are copied without splitting.
  static List<String> _splitArgs(String args) {
    final pieces = <String>[];
    var start = 0;
    var depth = 0;
    var i = 0;
    while (i < args.length) {
      final stringEnd = _stringLiteralEnd(args, i);
      if (stringEnd != null) {
        i = stringEnd;
        continue;
      }
      final c = args.codeUnitAt(i);
      if (c == 0x28 /* ( */ || c == 0x5b /* [ */ || c == 0x7b /* { */ ) {
        depth++;
      } else if (c == 0x29 /* ) */ || c == 0x5d /* ] */ || c == 0x7d /* } */ ) {
        depth--;
      } else if (c == 0x2c /* , */ && depth == 0) {
        pieces.add(args.substring(start, i));
        start = i + 1;
      }
      i++;
    }
    final tail = args.substring(start);
    if (tail.trim().isNotEmpty || pieces.isNotEmpty) pieces.add(tail);
    return pieces;
  }

  /// The field name of a named argument (`message: expr` -> `message`), or
  /// `null` for a positional expression. A ternary's `:` is not a named
  /// argument because the text before it is not a bare identifier.
  static String? _namedArgTarget(String piece) {
    final colon = piece.indexOf(':');
    if (colon < 1) return null;
    final lhs = piece.substring(0, colon).trim();
    if (lhs.isEmpty) return null;
    for (final unit in lhs.codeUnits) {
      if (!_isIdentifierPart(unit)) return null;
    }
    return lhs;
  }

  static int _endOfLineComment(String s, int i) {
    while (i < s.length && s.codeUnitAt(i) != 0x0a) i++;
    return i;
  }

  static int _endOfBlockComment(String s, int i) {
    while (i + 1 < s.length) {
      if (s.codeUnitAt(i) == 0x2a && s.codeUnitAt(i + 1) == 0x2f) return i + 2;
      i++;
    }
    return s.length;
  }

  /// Index just past the string literal beginning at [i], or `null` when [i]
  /// does not start one. Handles raw (`r`/`R`) prefixes, single/double quotes,
  /// triple quotes and backslash escapes. An unterminated literal is copied to
  /// the end verbatim — fail closed, never a half-rewritten body.
  static int? _stringLiteralEnd(String s, int i) {
    var start = i;
    var raw = false;
    final first = s.codeUnitAt(i);
    if ((first == 0x72 /* r */ || first == 0x52 /* R */ ) &&
        i + 1 < s.length &&
        (i == 0 || !_isIdentifierPart(s.codeUnitAt(i - 1)))) {
      final next = s.codeUnitAt(i + 1);
      if (next == 0x27 || next == 0x22) {
        raw = true;
        start = i + 1;
      }
    }
    final quote = s.codeUnitAt(start);
    if (quote != 0x27 && quote != 0x22) return null;
    if (!raw && start > 0 && _isIdentifierPart(s.codeUnitAt(start - 1))) {
      return null;
    }

    final triple =
        start + 2 < s.length &&
        s.codeUnitAt(start + 1) == quote &&
        s.codeUnitAt(start + 2) == quote;
    var j = start + (triple ? 3 : 1);
    while (j < s.length) {
      final c = s.codeUnitAt(j);
      if (!raw && c == 0x5c /* \ */ ) {
        j += 2;
        continue;
      }
      if (c == quote) {
        if (!triple) return j + 1;
        if (j + 2 < s.length &&
            s.codeUnitAt(j + 1) == quote &&
            s.codeUnitAt(j + 2) == quote) {
          return j + 3;
        }
      }
      j++;
    }
    return s.length;
  }

  static bool _isIdentifierPart(int code) =>
      (code >= 0x41 && code <= 0x5a) || // A-Z
      (code >= 0x61 && code <= 0x7a) || // a-z
      (code >= 0x30 && code <= 0x39) || // 0-9
      code == 0x5f || // _
      code == 0x24; // $

  /// Names a skipped forwarded member in the build log (issue #271 §3.4).
  void _logSkipped(ZorphyNodeIr node, String name) {
    // ignore: avoid_print
    print(
      'zorphy: union ${node.cleanName} — skipped member "$name": the sealed '
      'root already declares a member with that name',
    );
  }

  // ── Value methods ─────────────────────────────────────────────────

  List<Method> _valueMethods(
    ZorphyNodeIr node,
    List<PolymorphicField> fields,
    bool isEntity,
  ) {
    final methods = <Method>[
      _copyWith(node, fields),
      _equals(node, fields),
      _hashCode(node, fields),
      _toString(node, fields),
    ];
    return methods;
  }

  /// `OrderNotification copyWith({String? id, ..., Object? nickname = _sentinel})`
  ///
  /// A nullable field's parameter defaults to [_sentinel] and the body tests
  /// `identical(nickname, _sentinel)` — that is what lets `copyWith(nickname:
  /// null)` CLEAR the field, which a plain `nickname ?? this.nickname` can
  /// never express.
  ///
  /// A generic class keeps its type arguments in both the return type and the
  /// `fromTrusted` call (`SliceLoading<T> copyWith(...)`): the bare name
  /// would re-instantiate them as `dynamic` and lose the receiver's argument.
  Method _copyWith(ZorphyNodeIr node, List<PolymorphicField> fields) {
    final selfType = '${node.cleanName}${typeArgumentList(node)}';
    return Method((m) {
      m.name = 'copyWith';
      m.returns = referType(selfType);
      for (final field in fields) {
        m.optionalParameters.add(
          Parameter((p) {
            p.name = field.name;
            p.named = true;
            // Omitted must mean "keep", so neither kind of parameter is
            // `required`:
            //  - a non-nullable field takes `${T}?` and falls back with `??`;
            //  - a nullable field takes `Object?` defaulting to the sentinel,
            //    which is what makes an EXPLICIT `null` mean "clear" while an
            //    omitted argument still means "keep".
            p.type = referType(
              field.isNullable ? 'Object?' : '${_lowerType(field.type)}?',
            );
            if (field.isNullable) p.defaultTo = Code(sentinel);
          }),
        );
      }
      final args = [
        for (final field in fields)
          if (field.isNullable)
            '${field.name}: identical(${field.name}, $sentinel) '
                '? this.${field.name} : ${field.name} as ${_lowerType(field.emittedType)}'
          else
            '${field.name}: ${field.name} ?? this.${field.name}',
      ];
      m.body = Code('return $selfType.fromTrusted(${args.join(', ')});');
    });
  }

  /// `==` — identity short-circuit, a runtime-type guard so a sibling leaf
  /// never compares equal, then every declared field.
  Method _equals(ZorphyNodeIr node, List<PolymorphicField> fields) {
    return Method((m) {
      m.name = '==';
      m.returns = referType('bool');
      m.annotations.add(refer('override'));
      m.requiredParameters.add(
        Parameter((p) {
          p.name = 'other';
          p.type = referType('Object');
        }),
      );
      final checks = [
        // The left reference is qualified with `this.`: a field literally named
        // `other` would otherwise resolve to the equality PARAMETER, making
        // `other == other.other` compare the parameter to itself.
        // A snapshotted collection is a DIFFERENT instance on every value, so
        // a plain `==` compares identities and breaks `value == value.copyWith()`;
        // those fields compare their contents instead (#285 review).
        for (final field in fields)
          _comparesByContent(node, field)
              ? 'ZorphyCollections.equals('
                    'this.${field.name}, other.${field.name})'
              : 'this.${field.name} == other.${field.name}',
      ];
      // `operator ==` is the method NAME (the repo's own convention in
      // `equals_tostring_generator.dart`); a bare `==` name emits
      // `bool ==(Object other)`, which is not Dart.
      m.name = 'operator ==';
      m.body = Code(
        checks.isEmpty
            ? 'if (identical(this, other)) return true;\n'
                  'return other is ${node.cleanName};'
            : 'if (identical(this, other)) return true;\n'
                  'return other is ${node.cleanName} && ${checks.join(' && ')};',
      );
    });
  }

  /// `hashCode` — every declared field, so equal instances hash equal.
  Method _hashCode(ZorphyNodeIr node, List<PolymorphicField> fields) {
    return Method((m) {
      m.type = MethodType.getter;
      m.name = 'hashCode';
      m.returns = referType('int');
      m.annotations.add(refer('override'));
      m.lambda = true;
      m.body = Code(
        // `Object.hash` requires 2..20 positional arguments: a one-field leaf
        // (`Object.hash(x)`) and a >20-field leaf both fail to compile.
        // `Object.hashAll` accepts any nonempty iterable, covering both ends.
        fields.isEmpty
            ? 'runtimeType.hashCode'
            : 'Object.hashAll([${[for (final f in fields) _comparesByContent(node, f) ? 'ZorphyCollections.hash(${f.name})' : f.name].join(', ')}])',
      );
    });
  }

  /// `toString` — the class name and every field, in declaration order.
  Method _toString(ZorphyNodeIr node, List<PolymorphicField> fields) {
    return Method((m) {
      m.name = 'toString';
      m.returns = referType('String');
      m.annotations.add(refer('override'));
      final rendered = fields.map((f) => '${f.name}: \$${f.name}').join(', ');
      m.lambda = true;
      m.body = Code(
        fields.isEmpty
            ? "'${node.cleanName}'"
            : "'${node.cleanName}($rendered)'",
      );
    });
  }

  /// Lowers `$`-prefixed class names the way every other generator does.
  static String _lowerType(String type) => type.replaceAll(r'$', '');

  /// The `extends`-clause spelling of [parent] as seen from [child]
  /// (issue #231): the bare name for a non-generic parent, the parent name
  /// bound with the CHILD's own type parameters for a generic one —
  /// `AsyncSlice<T>` under `class SliceData<T>`. [isEmittableChild] has
  /// already guaranteed the arities match.
  static String _superTypeName(ZorphyNodeIr parent, ZorphyNodeIr child) {
    if (parent.typeParameters.isEmpty) return parent.cleanName;
    return '${parent.cleanName}<${bareParameterNames(child.typeParameters).join(', ')}>';
  }

  /// The bare name of one type-parameter declaration:
  /// `'T extends num'` -> `'T'`.
  static String _bareName(String parameter) {
    final separator = parameter.indexOf(' extends ');
    return separator == -1
        ? parameter.trim()
        : parameter.substring(0, separator).trim();
  }

  /// The library-level `_sentinel` the emitted `copyWith` parameters default
  /// to, as the specs that declare it: a distinct private [sentinelType] class
  /// plus its canonical const [sentinel] instance.
  ///
  /// The sentinel must be a DECLARATION, not a bare identifier: `Object note =
  /// _sentinel` does not compile unless `_sentinel` exists, and a per-class
  /// private constant would be invisible to the leaf that needs it. And it must
  /// be an instance of a DEDICATED type, not a plain `Object()`: Dart
  /// canonicalizes const objects, so a `const Object()` a caller passes would be
  /// `identical` to the sentinel and the method would read an explicit value as
  /// omission. A private class no caller can construct keeps `identical(...)`
  /// meaning exactly "the argument was omitted".
  ///
  /// ONE declaration per library: a caller combining several [emitNode]
  /// fragments into one library emits these specs once, not per fragment.
  List<Spec> _sentinelDeclarations() {
    return [
      Class((c) {
        c.name = sentinelType;
        c.modifier = ClassModifier.final$;
        c.constructors.add(
          Constructor((ctor) {
            ctor.constant = true;
          }),
        );
      }),
      Field((f) {
        f.name = sentinel;
        f.modifier = FieldModifier.constant;
        f.type = referType('Object');
        f.assignment = Code('$sentinelType()');
      }),
    ];
  }
}
