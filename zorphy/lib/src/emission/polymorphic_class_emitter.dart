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
  final bool isNullable;

  const PolymorphicField({
    required this.name,
    required this.type,
    this.isNullable = false,
  });

  /// The type as emitted: the `?` suffix applied exactly once.
  String get emittedType {
    if (!isNullable || type.endsWith('?')) return type;
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

  /// The marker interface for `@ZorphyValue` (and `@ZorphyUnion`) hierarchies.
  static const String valueBase = 'ZorphyValueBase';

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
    bool includeSentinelDeclarations = true,
  }) {
    final specs = <Spec>[];
    // The parent comes from the TRAVERSAL, not from `node.superTypes`: the
    // hierarchy the emitter is walking is the authority on "nearest sealed
    // ancestor", and a caller's superTypes list may be a subset of it.
    void walk(ZorphyNodeIr node, List<ZorphyNodeIr> ancestors) {
      specs.add(
        _classSpec(
          node,
          fields,
          ancestors,
          extraMethods: extraMethods[node.className] ?? const [],
        ),
      );
      for (final child in node.directSubTypes) {
        walk(child, [node, ...ancestors]);
      }
    }

    walk(root, const []);
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

      if (node.isConcreteLeaf) {
        c.modifier = ClassModifier.final$;
        // The nearest ancestor is the superclass; `ancestors` is nearest-first.
        if (ancestors.isNotEmpty) {
          c.extend = referType(ancestors.first.cleanName);
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
          c.extend = referType(ancestors.first.cleanName);
        }
        c.implements.add(_archetypeBase(node, fields));
      }

      if (node.isConcreteLeaf) {
        // A field redeclared from an ancestor overrides that ancestor's
        // abstract getter; a field the leaf introduces does not, and marking
        // it `@override` is an analyzer error.
        final inheritedNames = {
          for (final ancestor in ancestors)
            for (final field in fields[ancestor.className] ?? const [])
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
            for (final field in fields[ancestor.className] ?? const [])
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
      // `fromWire`/`toWire`, #223) land inside this class, after the value
      // methods — a dispatch node and a leaf both carry them.
      c.methods.addAll(extraMethods);
    });
  }

  /// The fields a leaf redeclares: every ancestor's, then its own, deduped by
  /// name with the leaf's declaration winning.
  List<PolymorphicField> _withInheritedFields(
    ZorphyNodeIr node,
    List<PolymorphicField> ownFields,
    Map<String, List<PolymorphicField>> fields,
  ) {
    final byName = <String, PolymorphicField>{};
    // Ancestors farthest-first, so a nearer declaration overwrites a farther
    // one and the leaf's own list overwrites everything above it.
    for (final ancestor in node.superTypes.reversed) {
      for (final field in fields[ancestor.className] ?? const []) {
        byName[field.name] = field;
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
      ArchetypeKind.value => referType(valueBase),
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
  /// Zero defensive cloning: a collection is assigned by REFERENCE, so the
  /// constructor never pays for a copy the caller already owns.
  ///
  /// The parameters live in [Constructor.optionalParameters] with `named` +
  /// `required` set, because code_builder renders `{…}` only for optional
  /// parameters — `requiredParameters` always renders positionally.
  Constructor _fromTrustedConstructor(
    ZorphyNodeIr node,
    List<PolymorphicField> fields,
  ) {
    return Constructor((ctor) {
      ctor.name = 'fromTrusted';
      ctor.constant = true;
      for (final field in fields) {
        ctor.optionalParameters.add(
          Parameter((p) {
            // A field-formal parameter must NOT carry its own type:
            // `required String this.id` is not Dart, `required this.id` is.
            // A NULLABLE field is optional: `required this.note` on a
            // `String?` field would reject the null it exists to allow.
            p.name = field.name;
            p.named = true;
            p.required = !field.isNullable;
            p.toThis = true;
          }),
        );
      }
    });
  }

  // ── Value methods ─────────────────────────────────────────────────

  List<Method> _valueMethods(
    ZorphyNodeIr node,
    List<PolymorphicField> fields,
    bool isEntity,
  ) {
    return [
      _copyWith(node, fields),
      _equals(node, fields),
      _hashCode(node, fields),
      _toString(node, fields),
    ];
  }

  /// `OrderNotification copyWith({String? id, ..., Object? nickname = _sentinel})`
  ///
  /// A nullable field's parameter defaults to [_sentinel] and the body tests
  /// `identical(nickname, _sentinel)` — that is what lets `copyWith(nickname:
  /// null)` CLEAR the field, which a plain `nickname ?? this.nickname` can
  /// never express.
  Method _copyWith(ZorphyNodeIr node, List<PolymorphicField> fields) {
    return Method((m) {
      m.name = 'copyWith';
      m.returns = referType(node.cleanName);
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
      m.body = Code(
        'return ${node.cleanName}.fromTrusted(${args.join(', ')});',
      );
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
        for (final field in fields) 'this.${field.name} == other.${field.name}',
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
            : 'Object.hashAll([${[for (final f in fields) f.name].join(', ')}])',
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
