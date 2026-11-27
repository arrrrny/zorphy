import 'package:code_builder/code_builder.dart';
import 'package:zorphy_annotation/zorphy.dart' show ZorphyPatchWire;

import '../ast/ast.dart';
import '../common/NameType.dart';
import '../emission/emitter.dart';
import '../emission/wire_kind.dart';
import '../helpers.dart' as helpers;

/// Emits the concrete `<Name>Patch` class for one entity (ISSUE-007).
///
/// The patch is a value, not a mutable form: it implements the v3 patch
/// algebra (`isEmpty` / `apply` / `compose` / `invert` / `toWire`) on top of
/// the same field-keyed map the fluent `with*` builders write, so both
/// surfaces describe one patch.
///
/// Guarantees this emitter owns, per the issue:
/// - `diff(previous, next)` is O(1) and allocation-free when the two entities
///   are `identical` — it returns the canonical constant [emptyPatchFieldName]
///   patch before touching any field.
/// - `apply(target)` returns `target` itself when the patch is empty.
/// - `compose(next)` folds two patches left to right, so
///   `(a.compose(b)).apply(x) == b.apply(a.apply(x))`.
/// - `invert(before)` captures the prior values, so
///   `p.invert(x).apply(p.apply(x)) == x`.
///
/// Everything is emitted as [Spec] objects and formatted by
/// [ZorphyEmitter]: this class assembles no source text of its own, and it
/// introduces no preset or generation toggle.
class PatchEmitter {
  /// The field kinds this emitter / `ZorphyPatchWire`'s helpers handle.
  ///
  /// Exposed so the wire-capability matrix's drift gate can derive its
  /// expected kind set from the emitters instead of a duplicate literal.
  static Set<WireKind> get classifiedKinds => patchClassifiedKinds;

  /// Creates an emitter. Stateless: one instance serves every entity.
  const PatchEmitter();

  /// Name of the canonical constant empty patch (a static field).
  ///
  /// `emptyPatch` rather than `empty`: Dart forbids a static member and a named
  /// constructor sharing one name, and the const constructor is
  /// [emptyConstructorName].
  static const String emptyPatchFieldName = 'emptyPatch';

  /// Name of the const constructor that builds the empty patch.
  static const String emptyConstructorName = 'empty';

  /// The field-keyed change map inherited from `PatchBase`.
  static const String patchMapName = 'patchMap';

  /// Emits the patch class for [className] carrying [fields], as formatted
  /// Dart source.
  ///
  /// [fields] are the entity's fields in declaration order. Names starting
  /// with `_` are emitted without the underscore, matching the fluent builders.
  /// Fieldless entities still get a patch: the empty patch is what makes one
  /// usable.
  String emit({
    required String className,
    required List<NameTypeClassComment> fields,
    List<String> knownClasses = const [],
    List<String> genericTypeNames = const [],
    List<String> genericDeclarations = const [],
  }) {
    final classSpec = buildClass(
      className: className,
      fields: fields,
      knownClasses: knownClasses,
      genericTypeNames: genericTypeNames,
      genericDeclarations: genericDeclarations,
    );
    return ZorphyEmitter().emitSpecs([classSpec]).trim();
  }

  /// Builds the patch [Class] spec.
  ///
  /// Exposed separately from [emit] so a caller can fold the spec into a
  /// larger library and so tests can assert on the spec itself.
  Class buildClass({
    required String className,
    required List<NameTypeClassComment> fields,
    List<String> knownClasses = const [],
    List<String> genericTypeNames = const [],
    List<String> genericDeclarations = const [],
  }) {
    // Envelope keys and field names share one namespace in a bare `toWire()`
    // map. Refuse the collision at GENERATION time rather than shipping a
    // decoder that misreads a legitimate field as envelope metadata (#215).
    for (final field in fields) {
      final member = _memberName(field.name);
      if (ZorphyPatchWire.reservedEnvelopeKeys.contains(member)) {
        throw ArgumentError.value(
          member,
          'fields',
          'is a reserved patch envelope key '
              '(${ZorphyPatchWire.reservedEnvelopeKeys.join(', ')}) '
              'and cannot be a patch field',
        );
      }
    }
    final name = _clean(className);
    final enumName = '${name}\$';
    final patchName = '${name}Patch';
    final typeArgs = genericTypeNames.isEmpty
        ? ''
        : '<${genericTypeNames.join(', ')}>';

    return Class((c) {
      c.name = patchName;
      c.extend = referType('PatchBase<$name$typeArgs, $enumName>');
      // A DECLARATION site: the type parameters must carry their bounds, or
      // every use of `T` inside the class violates `<T extends num>`
      // (`type_argument_not_matching_bounds`). Falls back to the bare names
      // when no declaration list was supplied, which is the unbounded case
      // the emitters take by default.
      c.types.addAll(
        (genericDeclarations.isEmpty ? genericTypeNames : genericDeclarations)
            .map(referType),
      );

      // The canonical empty patch: const, so diff()'s identical() fast path
      // allocates nothing and compose() has a real neutral element. It is a
      // FIELD, not a method, but it is named `emptyPatch` because Dart forbids
      // a static member and a named constructor sharing the name `empty`.
      //
      // A static member cannot reference the class's type variables, so a
      // GENERIC patch declares no `emptyPatch` field; its callers reach the
      // const empty through the constructor instead (see [_diffMethod]).
      if (genericTypeNames.isEmpty) {
        c.fields.add(
          Field((f) {
            f
              ..name = emptyPatchFieldName
              ..static = true
              ..modifier = FieldModifier.constant
              ..type = referType(patchName)
              ..assignment = Code('$patchName.$emptyConstructorName()');
            f.docs.add(
              '/// The canonical empty patch: no change, allocations.',
            );
          }),
        );
      }

      // The const empty constructor the static field instantiates. Const
      // rather than a const default constructor because the default one must
      // hand out a MUTABLE map for the fluent builders.
      c.constructors.add(
        Constructor((con) {
          con
            ..name = emptyConstructorName
            ..constant = true
            ..initializers.add(const Code('super.empty()'));
        }),
      );
      c.constructors.add(
        Constructor((con) {
          con.initializers.add(const Code('super()'));
        }),
      );

      // A generic patch must reference the PARAMETERIZED forms in every
      // member signature, or the override no longer matches Patch<T>/the
      // entity's own type (issue #182 generic-entity case).
      final entityRef = '$name$typeArgs';
      final patchRef = '$patchName$typeArgs';

      c.methods.add(_isEmptyGetter());
      c.methods.add(_applyMethod(entityRef, patchRef));
      c.methods.add(_applyToMethod(entityRef, patchRef));
      c.methods.add(
        _composeMethod(
          patchRef,
          enumName,
          fields,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
        ),
      );
      c.methods.add(_wireNameForMethod(enumName, fields));
      c.methods.add(
        _invertMethod(
          patchRef,
          entityRef,
          fields,
          enumName,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
        ),
      );
      c.methods.add(
        _diffMethod(
          patchRef,
          entityRef,
          fields,
          enumName,
          genericTypeNames: genericTypeNames,
          genericDeclarations: genericDeclarations,
          knownClasses: knownClasses,
        ),
      );
      c.methods.add(
        _toWireMethod(
          enumName,
          fields,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
        ),
      );
      c.methods.add(
        _fromWireMethod(
          patchRef,
          name,
          fields,
          enumName,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
          genericDeclarations: genericDeclarations,
        ),
      );
      c.methods.add(_toEnvelopeMethod(name, fields, isShared: false));
      for (final field in fields) {
        c.methods.addAll(
          _fluentBuilders(
            patchName: patchName,
            field: field,
            enumName: enumName,
            knownClasses: knownClasses,
            genericTypeNames: genericTypeNames,
          ),
        );
      }
    });
  }

  /// `bool get isEmpty` — the patch carries no change.
  Method _isEmptyGetter() => Method((m) {
    m
      ..name = 'isEmpty'
      ..type = MethodType.getter
      ..returns = referType('bool');
    m.body = Code('return $patchMapName.isEmpty;');
  });

  /// `T apply(T target)` — the target itself when empty (zero-copy).
  Method _applyMethod(String entityRef, String patchRef) => Method((m) {
    final bareEntity = _baseName(entityRef);
    m
      ..name = 'apply'
      ..returns = referType(entityRef)
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'target'
            ..type = referType(entityRef);
        }),
      );
    m.body = Block((b) {
      b.statements.add(const Code('if (isEmpty) return target;'));
      // A generic entity's patchWith returns the RAW generic type (a
      // pre-existing limitation of the entity-side generator), so the
      // parameterized patch narrows the result here.
      final isGeneric = entityRef != bareEntity;
      final call = 'target.patchWith$bareEntity(this)';
      b.statements.add(
        Code('return ${isGeneric ? '$call as $entityRef' : call};'),
      );
    });
  });

  /// `T applyTo(T entity)` — the legacy [Patch] entry point, same behaviour.
  Method _applyToMethod(String entityRef, String patchRef) => Method((m) {
    m
      ..name = 'applyTo'
      ..returns = referType(entityRef)
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'entity'
            ..type = referType(entityRef);
        }),
      );
    m.body = Code('return apply(entity);');
  });

  /// `compose(next)` — one patch that applies this and then [next].
  ///
  /// The parameter is narrowed (covariantly, as [ZorphyPatch.compose]
  /// permits) so a chain keeps its static patch type. A nested field carried
  /// by BOTH patches composes its carried sub-patch instead of letting the
  /// later `addAll` replace it — otherwise disjoint edits such as
  /// `address.street` and `address.city` lose the earlier one (zorphy#265
  /// review). Scalar and atomic-list replacements keep later-value precedence.
  Method _composeMethod(
    String patchRef,
    String enumName,
    List<NameTypeClassComment> fields, {
    List<String> knownClasses = const [],
    List<String> genericTypeNames = const [],
  }) => Method((m) {
    m
      ..name = 'compose'
      ..returns = referType(patchRef)
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'next'
            ..type = referType(patchRef)
            ..covariant = true;
        }),
      );
    m.body = Block((b) {
      b.statements.add(const Code('if (next.isEmpty) return this;'));
      b.statements.add(const Code('if (isEmpty) return next;'));
      b.statements.add(
        Code(
          'final composed = $patchRef()'
          '..$patchMapName.addAll($patchMapName)'
          '..$patchMapName.addAll(next.$patchMapName);',
        ),
      );
      for (final field in fields) {
        final shape = _fieldShape(
          field,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
        );
        if (shape.kind != _FieldShapeKind.nested) continue;
        final member = _memberName(field.name);
        final key = '$enumName.${helpers.enumMemberName(member)}';
        final carry = 'PatchNested<${shape.valueType}, ${shape.patchType}>';
        b.statements.add(Code('final ${member}Carried = $patchMapName[$key];'));
        b.statements.add(
          Code('final ${member}Next = next.$patchMapName[$key];'),
        );
        b.statements.add(
          Code(
            'if (${member}Carried is $carry && '
            '${member}Next is $carry) '
            'composed.$patchMapName[$key] = '
            '${member}Carried.composeNested(${member}Next);',
          ),
        );
      }
      b.statements.add(const Code('return composed;'));
    });
  });

  /// `wireNameFor(key)` — the ORIGINAL field name a patch key addresses.
  ///
  /// Reserved enum members are escaped (`name` becomes `name_`), but `toWire()`
  /// and JSON use the entity's field name. `PatchBase.changedPaths` calls this
  /// so a JSON pointer names the field the entity actually has (zorphy#265
  /// review).
  Method _wireNameForMethod(
    String enumName,
    List<NameTypeClassComment> fields,
  ) => Method((m) {
    m
      ..name = 'wireNameFor'
      ..returns = referType('String')
      ..annotations.add(referType('override'))
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'key'
            ..type = referType(enumName);
        }),
      );
    if (fields.isEmpty) {
      m.body = const Code('return key.name;');
    } else {
      // The generated field enum has exactly one member per field, so the
      // cases are exhaustive — a wildcard would be unreachable (and warned).
      final cases = fields
          .map((field) {
            final member = _memberName(field.name);
            return '$enumName.${helpers.enumMemberName(member)} => '
                '${_stringLiteral(member)},';
          })
          .join('\n');
      m.body = Code('return switch (key) {\n$cases\n};');
    }
  });

  /// `invert(before)` — the patch that undoes this one for [before].
  ///
  /// The inverse is built from the value this patch ACTUALLY carried, not from
  /// a fresh empty patch: a nested field carries a `PatchNested`, a map field
  /// carries a delta, and a list field carries the whole value, so each is
  /// inverted through its own carried instance. A scalar carries the value
  /// itself, so its inverse is simply the prior value.
  Method _invertMethod(
    String patchRef,
    String entityRef,
    List<NameTypeClassComment> fields,
    String enumName, {
    List<String> knownClasses = const [],
    List<String> genericTypeNames = const [],
  }) => Method((m) {
    m
      ..name = 'invert'
      ..returns = referType(patchRef)
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'before'
            ..type = referType(entityRef);
        }),
      );
    m.body = Block((b) {
      b.statements.add(Code('final undo = $patchRef();'));
      for (final field in fields) {
        final member = _memberName(field.name);
        final key = '$enumName.${helpers.enumMemberName(member)}';
        final shape = _fieldShape(
          field,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
        );
        switch (shape.kind) {
          case _FieldShapeKind.nested:
            // Only a carried PatchNested can be inverted; a nullable field
            // that transitioned to or from null carried the raw value, and
            // that is restored wholesale. The carried value is bound to a
            // LOCAL: Dart does not promote a public FIELD through an `is`
            // test, so testing `before.$member` directly cannot narrow it.
            b.statements.add(
              Code('final ${member}Carried = $patchMapName[$key];'),
            );
            if (shape.isNullable) {
              // A public FIELD is never promoted through a null test, so the
              // prior value is bound to a local as well.
              b.statements.add(Code('final ${member}Before = before.$member;'));
            }
            final priorRef = shape.isNullable
                ? '${member}Before'
                : 'before.$member';
            final carriedGuard = shape.isNullable
                ? '${member}Carried is PatchNested && $priorRef != null'
                : '${member}Carried is PatchNested';
            b.statements.add(
              Code('if ($patchMapName.containsKey($key) && $carriedGuard) {'),
            );
            b.statements.add(
              Code(
                '  undo.$patchMapName[$key] = '
                '(${member}Carried as PatchNested<'
                '${shape.valueType}, ${shape.patchType}>)'
                '.invertNested($priorRef);',
              ),
            );
            b.statements.add(const Code('}'));
            // A fluent `with*` builder writes a raw value, a sub-patch or a
            // function into the map — none of which is a `PatchNested` — so
            // the inverse restores the prior value wholesale, exactly as the
            // list / map arms below do. Without this fallback a patch built
            // from the public `withX`/`withXPatch`/`withXPatchFunc` builders
            // and then inverted silently drops the field (issue #207 review).
            b.statements.add(
              Code(
                'if ($patchMapName.containsKey($key) && '
                '${member}Carried is! PatchNested) '
                'undo.$patchMapName[$key] = before.$member;',
              ),
            );
          case _FieldShapeKind.list:
            // Atomic list replacement (zorphy#248): the patch carries the whole
            // prior list value, so the inverse restores it wholesale — the same
            // shape as a scalar. No positional history to replay.
            b.statements.add(
              Code(
                'if ($patchMapName.containsKey($key)) '
                'undo.$patchMapName[$key] = before.$member;',
              ),
            );
          case _FieldShapeKind.map:
            b.statements.add(
              Code(
                'if ($patchMapName[$key] '
                'is MapPatchDelta<${shape.valueType}>'
                '${shape.isNullable ? ' && before.$member != null' : ''}) '
                'undo.$patchMapName[$key] = '
                '($patchMapName[$key] as MapPatchDelta<${shape.valueType}>)'
                '.invert(before.$member${shape.isNullable ? '!' : ''});',
              ),
            );
            b.statements.add(
              Code(
                'if ($patchMapName.containsKey($key) && '
                '$patchMapName[$key] is! MapPatchDelta<${shape.valueType}>) '
                'undo.$patchMapName[$key] = before.$member;',
              ),
            );
          case _FieldShapeKind.scalar:
            b.statements.add(
              Code(
                'if ($patchMapName.containsKey($key)) '
                'undo.$patchMapName[$key] = before.$member;',
              ),
            );
        }
      }
      b.statements.add(const Code('return undo;'));
    });
  });

  /// `static diff(previous, next)` — O(1) when the two are identical.
  ///
  /// Per field shape (ISSUE-008):
  /// - a nested Zorphy field carries a `PatchNested<Sub, SubPatch>` built from
  ///   `SubPatch.diff(previous.x, next.x)`, so the parent patch delegates to
  ///   the sub-entity's own patch instead of copying it wholesale;
  /// - a `List<E>` field carries the whole new list (atomic replacement, never
  ///   positional index ops) so a concurrent list edit is an exact conflict;
  /// - a `Map<K, V>` field carries a `MapPatchDelta<K, V>`;
  /// - anything else carries the value itself.
  ///
  /// A guarded shape (nested nullable, collection) only records a change when
  /// its delta is non-empty, so a patch never carries a no-op step.
  Method _diffMethod(
    String patchRef,
    String entityRef,
    List<NameTypeClassComment> fields,
    String enumName, {
    List<String> genericTypeNames = const [],
    List<String> genericDeclarations = const [],
    List<String> knownClasses = const [],
  }) => Method((m) {
    final patchName = _baseName(patchRef);
    m
      ..name = 'diff'
      ..static = true
      ..returns = referType(patchRef);
    // A static member cannot see the class's type variables, so a generic
    // patch declares them on `diff` itself — the caller supplies them from
    // the two entities it passes in. A DECLARATION site, so the bounds ride
    // along: a bare `<T>` here is not well-bounded against `Box<T extends
    // num>` (type_argument_not_matching_bounds).
    for (final generic
        in genericDeclarations.isEmpty
            ? genericTypeNames
            : genericDeclarations) {
      m.types.add(referType(generic));
    }
    m.requiredParameters.addAll([
      Parameter((p) {
        p
          ..name = 'previous'
          ..type = referType(entityRef);
      }),
      Parameter((p) {
        p
          ..name = 'next'
          ..type = referType(entityRef);
      }),
    ]);
    m.body = Block((b) {
      // The O(1) fast path: identical values carry no transition at all, so
      // the canonical CONST empty patch is returned — zero allocations.
      // It is a value: [`with*` builders mutate, so build with `<X>Patch()`,
      // never by cascading off a `diff` result.]
      // Type variables are illegal in const expressions, so a generic patch
      // reaches its empty instance through the constructor instead.
      final emptyRef = genericTypeNames.isEmpty
          ? 'const $patchName.empty()'
          : '$patchName<${genericTypeNames.join(', ')}>.empty()';
      b.statements.add(
        Code('if (identical(previous, next)) return $emptyRef;'),
      );
      b.statements.add(Code('final changes = $patchRef();'));
      for (final field in fields) {
        final member = _memberName(field.name);
        final key = '$enumName.${helpers.enumMemberName(member)}';
        final shape = _fieldShape(
          field,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
        );
        switch (shape.kind) {
          case _FieldShapeKind.nested when shape.isNullable:
            // Both sides must carry a sub-entity to diff one against the
            // other; a null on either side is a whole-value transition.
            b.statements.add(
              Code('if (previous.$member != null && next.$member != null) {'),
            );
            b.statements.add(
              Code(
                '  final nested = ${shape.patchType}.diff('
                'previous.$member!, next.$member!);',
              ),
            );
            b.statements.add(
              Code(
                '  if (nested.isNotEmpty) '
                'changes.$patchMapName[$key] = '
                'PatchNested<${shape.valueType}, ${shape.patchType}>(nested);',
              ),
            );
            b.statements.add(const Code('}'));
            b.statements.add(
              Code('if (previous.$member == null || next.$member == null) {'),
            );
            b.statements.add(
              Code(
                '  if (previous.$member != next.$member) '
                'changes.$patchMapName[$key] = next.$member;',
              ),
            );
            b.statements.add(const Code('}'));
          case _FieldShapeKind.nested:
            b.statements.add(
              Code(
                'final ${member}Delta = ${shape.patchType}.diff('
                'previous.$member, next.$member);',
              ),
            );
            b.statements.add(
              Code(
                'if (${member}Delta.isNotEmpty) '
                'changes.$patchMapName[$key] = '
                'PatchNested<${shape.valueType}, ${shape.patchType}>'
                '(${member}Delta);',
              ),
            );
          case _FieldShapeKind.list:
            // Atomic list replacement (zorphy#248): a changed list is carried
            // as the whole value, never as positional index ops. ListEquality
            // accepts a nullable list on either side, so one content-equality
            // check covers both the both-present and the null-transition cases
            // — no separate `when shape.isNullable` arm is needed.
            b.statements.add(
              Code(
                'if (!const ListEquality<Object?>().equals('
                'previous.$member, next.$member)) '
                'changes.$patchMapName[$key] = next.$member;',
              ),
            );
          case _FieldShapeKind.map when shape.isNullable:
            b.statements.add(
              Code('if (previous.$member != null && next.$member != null) {'),
            );
            b.statements.add(
              Code(
                '  final ${member}Delta = MapPatchDelta.diff<${shape.valueType}>('
                'previous.$member!, next.$member!);',
              ),
            );
            b.statements.add(
              Code(
                '  if (${member}Delta.isNotEmpty) '
                'changes.$patchMapName[$key] = ${member}Delta;',
              ),
            );
            b.statements.add(const Code('}'));
            b.statements.add(
              Code('if (previous.$member == null || next.$member == null) {'),
            );
            b.statements.add(
              Code(
                '  if (previous.$member != next.$member) '
                'changes.$patchMapName[$key] = next.$member;',
              ),
            );
            b.statements.add(const Code('}'));
          case _FieldShapeKind.map:
            final args = shape.valueType;
            b.statements.add(
              Code(
                'final ${member}Delta = MapPatchDelta.diff<$args>('
                'previous.$member, next.$member);',
              ),
            );
            b.statements.add(
              Code(
                'if (${member}Delta.isNotEmpty) '
                'changes.$patchMapName[$key] = ${member}Delta;',
              ),
            );
          case _FieldShapeKind.scalar:
            b.statements.add(
              Code(
                'if (previous.$member != next.$member) '
                'changes.$patchMapName[$key] = next.$member;',
              ),
            );
        }
      }
      b.statements.add(const Code('return changes;'));
    });
  });

  /// `toWire()` — the carried changes keyed by FIELD name.
  ///
  /// The wire key is the entity's field name, not the enum member: reserved
  /// members are escaped in the enum (`name` becomes `name_`), and a wire map
  /// that leaked that escape would name a field the entity does not have.
  ///
  /// A carried delta renders as its own `toWire` step list (ISSUE-008), so a
  /// collection change reaches the wire as `{'ops': [...]}` rather than as an
  /// opaque delta object; every other shape renders verbatim.
  Method _toWireMethod(
    String enumName,
    List<NameTypeClassComment> fields, {
    List<String> knownClasses = const [],
    List<String> genericTypeNames = const [],
  }) => Method((m) {
    m
      ..name = 'toWire'
      ..returns = referType('Map<String, Object?>');
    m.body = Block((b) {
      b.statements.add(const Code('final wire = <String, Object?>{};'));
      for (final field in fields) {
        final member = _memberName(field.name);
        final key = '$enumName.${helpers.enumMemberName(member)}';
        final shape = _fieldShape(
          field,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
        );
        // A collection field carries either a delta (from `diff`) or a raw
        // collection (from the fluent `with*` builder), and a nested field
        // carries either a `PatchNested` (from `diff`) or a raw sub-value (from
        // the fluent builder), so each arm is narrowed rather than blind-cast.
        // Both unwrap to plain JSON so a wire map never carries an opaque patch
        // object.
        final wireValue = switch (shape.kind) {
          // Atomic list replacement (zorphy#248): a list field carries the raw
          // list value (a JSON array), rendered verbatim — never a delta.
          _FieldShapeKind.list => '$patchMapName[$key]',
          // A map delta carries a BARE step list: a replacement map may hold a
          // literal `ops` key, so a wrapper keyed `ops` would be ambiguous
          // (#215). The field-level `toWireSteps()` keeps that distinction.
          _FieldShapeKind.map =>
            '$patchMapName[$key] is MapPatchDelta<${shape.valueType}>'
                ' ? ($patchMapName[$key] as MapPatchDelta<${shape.valueType}>)'
                '.toWireSteps() : $patchMapName[$key]',
          // A whole-value replacement is wrapped so its decoder never treats
          // it as an edit of the old value; a PatchNested still renders as the
          // field-keyed sub-patch map (#215).
          _FieldShapeKind.nested =>
            '$patchMapName[$key] is PatchNested'
                ' ? ($patchMapName[$key] as PatchNested).toWire()'
                ' : PatchWireReplacement($patchMapName[$key])',
          _ => '$patchMapName[$key]',
        };
        // An enum instance is not JSON-encodable. Write its NAME on the wire
        // so `jsonEncode(toEnvelope())` survives a transport hop and the
        // existing name-based decoder reads it back (#215).
        if (field.isEnum) {
          b.statements.add(Code('if ($patchMapName.containsKey($key)) {'));
          b.statements.add(Code('  final value = $patchMapName[$key];'));
          b.statements.add(
            Code(
              '  wire[${_stringLiteral(member)}] = '
              'value is Enum ? value.name : value;',
            ),
          );
          b.statements.add(const Code('}'));
        } else {
          b.statements.add(
            Code(
              'if ($patchMapName.containsKey($key)) '
              'wire[${_stringLiteral(member)}] = $wireValue;',
            ),
          );
        }
      }
      b.statements.add(const Code('return wire;'));
    });
  });

  static String _stringLiteral(String value) =>
      "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";

  /// `static fromWire(raw)` — decode an untrusted wire map, never throwing.
  ///
  /// The patch is a value carried across a process boundary, so its wire form
  /// is decoded AT a trust boundary (ISSUE-017): every field is read with an
  /// `is` test and a value of the wrong shape becomes a [FieldViolation]
  /// instead of a thrown cast, so one `BoundaryErr` can describe every bad
  /// field at once.
  ///
  /// [raw] is accepted in BOTH shapes a peer may send: a bare `toWire()` map
  /// (field name -> value) and the polymorphic envelope, whose `ops` carries
  /// that same map beside `entityType` / `patchKind`. A transport that already
  /// knows the patch kind therefore needs no wrapper at all.
  Method _fromWireMethod(
    String patchRef,
    String bareName,
    List<NameTypeClassComment> fields,
    String enumName, {
    List<String> knownClasses = const [],
    List<String> genericTypeNames = const [],
    List<String> genericDeclarations = const [],
  }) => Method((m) {
    final patchName = _baseName(patchRef);
    m
      ..name = 'fromWire'
      ..static = true
      ..returns = referType('ZorphyBoundaryResult<$patchRef>');
    // A static member cannot see the class's type variables, so a generic
    // patch declares them on `fromWire` itself — a DECLARATION site, so the
    // bounds ride along (see [_diffMethod]).
    for (final generic
        in genericDeclarations.isEmpty
            ? genericTypeNames
            : genericDeclarations) {
      m.types.add(referType(generic));
    }
    m.requiredParameters.add(
      Parameter((p) {
        p
          ..name = 'raw'
          ..type = referType('Map<String, Object?>');
      }),
    );

    final patchCtor = genericTypeNames.isEmpty
        ? '$patchName()'
        : '$patchName<${genericTypeNames.join(', ')}>()';

    m.body = Block((b) {
      b.statements.add(const Code('final violations = <FieldViolation>[];'));
      // A bare `toWire()` map has neither envelope key; an envelope's `ops` is
      // the patch's own map. Both reach the same field reads, and the read
      // paths carry the envelope prefix so a violation names the pointer the
      // caller actually sent.
      b.statements.add(
        const Code('final ops = ZorphyPatchWire.opsOf(raw, \'\', violations);'),
      );
      // `prefix` only feeds the per-field read paths below; a field-less
      // patch would carry it unused (an `unused_local_variable` warning).
      if (fields.isNotEmpty) {
        b.statements.add(
          const Code('final prefix = ZorphyPatchWire.opsPathOf(raw);'),
        );
      }
      b.statements.add(const Code('if (ops != null) {'));
      b.statements.add(Code('  final patch = $patchCtor;'));
      for (final field in fields) {
        final statements = _fromWireFieldStatements(
          field,
          enumName,
          knownClasses: knownClasses,
          genericTypeNames: genericTypeNames,
        );
        for (final statement in statements) {
          b.statements.add(Code('  $statement'));
        }
      }
      b.statements.add(
        Code('  if (violations.isEmpty) return BoundaryOk<$patchRef>(patch);'),
      );
      b.statements.add(const Code('}'));
      b.statements.add(
        Code(
          'return BoundaryErr<$patchRef>('
          "targetType: '${patchName.replaceAll(r'$', '')}', "
          'violations: violations);',
        ),
      );
    });
  });

  /// The statements that read one field off `ops` and write it into `patch`.
  ///
  /// The key is the FIELD name, matching [_toWireMethod]: the wire map names
  /// entity fields, never the escaped enum member.
  List<String> _fromWireFieldStatements(
    NameTypeClassComment field,
    String enumName, {
    required List<String> knownClasses,
    required List<String> genericTypeNames,
  }) {
    final member = _memberName(field.name);
    final key = '$enumName.${helpers.enumMemberName(member)}';
    final keyLiteral = _stringLiteral(member);
    final path = "'\$prefix/$member'";
    final shape = _fieldShape(
      field,
      knownClasses: knownClasses,
      genericTypeNames: genericTypeNames,
    );
    final local = '${member}Raw';
    final body = <String>[];

    switch (shape.kind) {
      case _FieldShapeKind.list:
        // Atomic list replacement (zorphy#248): the wire form is a bare JSON
        // array decoded by `listValue`, not an ops delta.
        body
          ..add(
            'final decoded = ZorphyPatchWire.listValue<'
            '${shape.valueType}>($local, $path, violations, '
            '${_valueDecoder(shape.valueType)});',
          )
          ..add('if (decoded != null) patch.$patchMapName[$key] = decoded;');
      case _FieldShapeKind.map:
        final args = _splitTypeArguments(shape.valueType);
        final keyType = args.length == 2 ? args[0] : 'String';
        final valueType = args.length == 2 ? args[1] : 'Object?';
        body
          ..add(
            'final decoded = ZorphyPatchWire.mapDelta<$keyType, '
            '$valueType>($local, $path, violations, '
            'decodeKey: ${_keyDecoder(keyType)}, '
            'decodeValue: ${_valueDecoder(valueType)});',
          )
          ..add('if (decoded != null) patch.$patchMapName[$key] = decoded;');
      case _FieldShapeKind.nested:
        // A whole-value replacement (diff from null to a sub-entity) carries
        // the sub-entity itself, wrapped so it can never be read as an edit of
        // the OLD value; a field-keyed map is still a PatchNested (#215).
        body
          ..add('if ($local is PatchWireReplacement) {')
          ..add('  final value = $local.value;')
          ..add('  if (value is ${shape.valueType}) {')
          ..add('    patch.$patchMapName[$key] = value;')
          ..add('  } else {')
          ..add(
            "    violations.add(FieldViolation(path: $path, "
            "expected: '${shape.valueType}', "
            'actual: ZorphyPatchWire.describe(value)));',
          )
          ..add('  }')
          ..add('} else if ($local is ${shape.valueType}) {')
          ..add('  patch.$patchMapName[$key] = $local;')
          ..add('} else {')
          ..add(
            '  final nestedRaw = ZorphyPatchWire.asObject('
            '$local, $path, violations);',
          )
          ..add('  if (nestedRaw != null) {')
          ..add('    ${shape.patchType}.fromWire(nestedRaw).fold(')
          ..add(
            '      (value) => patch.$patchMapName[$key] = '
            'PatchNested<${shape.valueType}, ${shape.patchType}>(value),',
          )
          ..add(
            '      (error) => violations.addAll('
            'ZorphyPatchWire.prefix(error.violations, $path)),',
          )
          ..add('    );')
          ..add('  }')
          ..add('}');
      case _FieldShapeKind.scalar:
        final baseType = shape.valueType;
        final String decode;
        if (field.isEnum) {
          decode =
              'ZorphyPatchWire.enumByName<$baseType>('
              '$baseType.values, $local, $path, violations)';
        } else if (baseType == 'DateTime') {
          decode = 'ZorphyPatchWire.asDateTime($local, $path, violations)';
        } else if (baseType == 'double') {
          decode = 'ZorphyPatchWire.asDouble($local, $path, violations)';
        } else if (baseType == 'num') {
          // A `num` field must not round a large int through a double (#215).
          decode = 'ZorphyPatchWire.asNum($local, $path, violations)';
        } else {
          decode = 'ZorphyPatchWire.as<$baseType>($local, $path, violations)';
        }
        // A nullable field's legitimate `null` and a failed read are both
        // `null` in the value domain, so the guard is the VIOLATION COUNT.
        body
          ..add('final before = violations.length;')
          ..add('final decoded = $decode;')
          ..add('if (violations.length == before) {')
          ..add('  patch.$patchMapName[$key] = decoded;')
          ..add('}');
    }

    // An explicit null is a CLEAR before any shape-specific reader runs: the
    // nested, list, map and enum readers all reject a null they were never
    // meant to see (#215). Absent keys never reach here.
    final nullBody = shape.isNullable
        ? 'patch.$patchMapName[$key] = null;'
        : "violations.add(FieldViolation(path: $path, "
              "expected: '${shape.valueType}', "
              'actual: ZorphyPatchWire.describe(null)));';

    return <String>[
      'if (ops.containsKey($keyLiteral)) {',
      '  final Object? $local = '
          'ZorphyPatchWire.fieldValue(ops[$keyLiteral], $path, violations);',
      '  if ($local == null) {',
      '    $nullBody',
      '  } else {',
      ...body.map((line) => '  $line'),
      '  }',
      '}',
    ];
  }

  /// The element decoder an emitted `listDelta` / `mapDelta` call passes for
  /// one element type.
  ///
  /// A CLOSURE, never a generic tear-off: `ZorphyPatchWire.as<T>` takes an
  /// optional `nullable:` named parameter, so its function type is wider than
  /// the `T? Function(Object?, String, List<FieldViolation>)` a delta call
  /// wants, and a tear-off does not assign to it. The declared `?` is carried
  /// into the call (`nullable: true`), so `List<String?>` keeps its nulls; the
  /// delta decides success by the violation count (#215).
  ///
  /// LIMITATION (review of #215): a JSON-hopped `List<KnownClass>` element
  /// arrives as a field-keyed Map, which `as<KnownClass>` rejects. Turning that
  /// map back into a class instance needs the entity's OWN boundary codec
  /// (`BoundaryCodecEmitter.fromWire`) and a trusted constructor, neither of
  /// which a patch field can assume exists. In-process elements (the class
  /// instance itself) round-trip; a nested-class collection across a JSON
  /// boundary is not supported by this codec.
  String _elementDecoder(String type) {
    final trimmed = type.trim();
    final nullable = trimmed.endsWith('?');
    final declared = nullable
        ? trimmed.substring(0, trimmed.length - 1).trim()
        : trimmed;
    final base = _baseName(declared);
    const signature = '(value, path, violations)';
    if (base == 'DateTime') {
      return '$signature => ZorphyPatchWire.asDateTime(value, path, violations)';
    }
    if (base == 'double') {
      return '$signature => ZorphyPatchWire.asDouble(value, path, violations)';
    }
    if (base == 'num') {
      return '$signature => ZorphyPatchWire.asNum(value, path, violations)';
    }
    if (base == 'List') {
      // A nested collection element keeps its FULL type: `as<List>` would
      // answer an untyped list where `listDelta<List<int>>` wants a callback
      // returning `List<int>?` (#215).
      final inner = _singleTypeArgument(declared);
      if (inner != null) {
        return '(value, path, violations) {'
            ' if (value is! List) {'
            '  violations.add(FieldViolation(path: path, '
            "expected: 'List<$inner>', "
            'actual: ZorphyPatchWire.describe(value)));'
            '  return null;'
            ' }'
            ' final out = <$inner>[];'
            ' for (var i = 0; i < value.length; i++) {'
            "  final elementPath = '\$path/\$i';"
            '  final before = violations.length;'
            '  final decoded = (${_elementDecoder(inner)})('
            'value[i], elementPath, violations);'
            '  if (violations.length == before) out.add(decoded as $inner);'
            ' }'
            ' return out;'
            ' }';
      }
    }
    final target = (base == 'Object' || base == 'dynamic')
        ? 'Object?'
        : declared;
    return '$signature => ZorphyPatchWire.as<$target>('
        'value, path, violations${nullable ? ', nullable: true' : ''})';
  }

  /// The VALUE decoder a map field's `mapDelta` call passes for its `V`.
  ///
  /// A map-valued entry (`Map<String, String>`) needs a keyed decode of its
  /// own: handing it the scalar `as<Map<...>>` would answer an untyped
  /// `Map<dynamic, dynamic>` no `Map<String, String>` function may return.
  /// Type arguments are split at DEPTH ZERO, so `Map<String, Map<String, int>>`
  /// keeps its full inner type (#215). Nullability is carried through the
  /// recursive decoders as well.
  String _valueDecoder(String type) {
    final trimmed = type.trim();
    final nullable = trimmed.endsWith('?');
    final declared = nullable
        ? trimmed.substring(0, trimmed.length - 1).trim()
        : trimmed;
    final mapMatch = RegExp(r'^Map<(.+)>$').firstMatch(declared);
    if (mapMatch != null) {
      final args = _splitTypeArguments(declared);
      final innerKey = args.length == 2 ? args[0] : 'String';
      final innerValue = args.length == 2 ? args[1] : 'Object?';
      return '(value, path, violations) {'
          ' final nested = ZorphyPatchWire.asObject(value, path, violations);'
          ' if (nested == null) return null;'
          ' final out = <$innerKey, $innerValue>{};'
          ' for (final entry in nested.entries) {'
          "  final path2 = '\$path/\${ZorphyPatchWire.pointerToken(entry.key)}';"
          '  final kBefore = violations.length;'
          '  final k = (${_keyDecoder(innerKey)})'
          '(entry.key, path2, violations);'
          '  final vBefore = violations.length;'
          '  final v = (${_elementDecoder(innerValue)})'
          '(entry.value, path2, violations);'
          '  if (violations.length == kBefore &&'
          ' violations.length == vBefore) {'
          '    out[k as $innerKey] = v as $innerValue;'
          '  }'
          ' }'
          ' return out;'
          ' }';
    }
    return _elementDecoder(trimmed);
  }

  /// The key decoder a map field's `mapDelta` call passes for its `K`.
  ///
  /// JSON carries every key as a string, so a non-String key is read back by
  /// its wire spelling — the same rule a value follows.
  String _keyDecoder(String type) {
    final base = type.trim();
    if (base == 'String') {
      return '(value, path, violations) => '
          'ZorphyPatchWire.stringKey(value, path, violations)';
    }
    if (base == 'int') {
      return '(value, path, violations) { '
          'if (value is int) return value; '
          'if (value is String) { final parsed = int.tryParse(value); '
          'if (parsed != null) return parsed; } '
          "violations.add(FieldViolation(path: path, expected: 'int', "
          'actual: ZorphyPatchWire.describe(value))); return null; }';
    }
    return '(value, path, violations) => '
        'ZorphyPatchWire.as<$base>(value, path, violations)';
  }

  /// The single type argument of a `List<T>` reference, or `null`.
  static String? _singleTypeArgument(String type) {
    final match = RegExp(r'^List<(.+)>$').firstMatch(type.trim());
    return match?.group(1)?.trim();
  }

  /// Splits a `Map<K, V>` type argument list at top-level commas only.
  ///
  /// A naive `split(',')` breaks `Map<String, Map<String, int>>` into three
  /// pieces and emits a `Map<String, Object?>` the field cannot assign (#215).
  static List<String> _splitTypeArguments(String type) {
    final inner =
        RegExp(r'^Map<(.+)>$').firstMatch(type.trim())?.group(1) ?? type.trim();
    final parts = <String>[];
    var depth = 0;
    var current = '';
    for (final char in inner.split('')) {
      if (char == '<' || char == '[') depth++;
      if (char == '>' || char == ']') depth--;
      if (char == ',' && depth == 0) {
        parts.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    parts.add(current.trim());
    return parts;
  }

  /// The envelope key naming the entity the ops belong to.
  static const String _entityTypeKey = 'entityType';

  /// The envelope key naming which patch class built the ops.
  static const String _patchKindKey = 'patchKind';

  /// The envelope key carrying a patch's own `toWire()` map.
  static const String _opsKey = 'ops';

  /// The envelope key carrying the principal key of the targeted row.
  static const String _principalKeyKey = 'principalKey';

  /// `toEnvelope()` — the polymorphic wire envelope this patch travels in.
  ///
  /// `entityType` names the entity the ops belong to and `patchKind` names
  /// which patch class built them, so a receiver can select the right
  /// `fromWire` before reading a single field. `ops` is this patch's own
  /// [ZorphyPatch.toWire] map, so unchanged fields stay absent and the
  /// payload stays minimal.
  Method _toEnvelopeMethod(
    String entityName,
    List<NameTypeClassComment> fields, {
    required bool isShared,
  }) => Method((m) {
    final clean = entityName.replaceAll(r'$', '');
    final kind = isShared ? 'shared' : clean;
    m
      ..name = 'toEnvelope'
      ..returns = referType('Map<String, Object?>')
      ..optionalParameters.add(
        Parameter((p) {
          p
            ..name = 'principalKey'
            ..named = true
            ..type = referType('Object?');
        }),
      );
    // A name-only patch cannot know which row it targets. The principal key
    // is TRANSPORT metadata supplied by the caller, beside ops, and never an
    // edit inside ops (#215).
    m.body = Block((b) {
      b.statements.add(const Code('final envelope = <String, Object?>{'));
      b.statements.add(Code("  '$_entityTypeKey': '$clean',"));
      b.statements.add(Code("  '$_patchKindKey': '$kind',"));
      if (!isShared) {
        b.statements.add(Code("  '$_principalKeyKey': principalKey,"));
      }
      b.statements.add(Code("  '$_opsKey': toWire(),"));
      b.statements.add(const Code('};'));
      b.statements.add(const Code('return envelope;'));
    });
  });

  /// The fluent builders for [field]: `with<Name>` always, plus the nested
  /// patch helpers when the field references another Zorphy type.
  List<Method> _fluentBuilders({
    required String patchName,
    required NameTypeClassComment field,
    required String enumName,
    required List<String> knownClasses,
    required List<String> genericTypeNames,
  }) {
    final member = _memberName(field.name);
    final capitalized =
        member.substring(0, 1).toUpperCase() + member.substring(1);
    final type = (field.type ?? 'dynamic').replaceAll(r'$', '');
    // A generic-typed field keeps the legacy `dynamic` parameter: the emitted
    // patch is the one place the type variable may not resolve to the entity's
    // own parameter, and `PatchBase`'s map is `Map<TEnum, dynamic>` anyway, so
    // narrowing it to `T?` was a silent behaviour change for a generic entity
    // (review of #203).
    final declaredNonNullable =
        type.endsWith('?') ||
        type == 'dynamic' ||
        type.startsWith('dynamic<') ||
        type.startsWith('dynamic ');
    final parameterType = _isGenericType(type, genericTypeNames)
        ? 'dynamic'
        : declaredNonNullable
        ? type
        : '$type?';
    final key = '$enumName.${helpers.enumMemberName(member)}';

    final methods = <Method>[
      Method((m) {
        m
          ..name = 'with$capitalized'
          ..returns = referType(patchName)
          ..requiredParameters.add(
            Parameter((p) {
              p
                ..name = 'value'
                ..type = referType(parameterType);
            }),
          );
        m.body = Block((b) {
          b.statements.add(Code('$patchMapName[$key] = value;'));
          b.statements.add(const Code('return this;'));
        });
      }),
    ];

    methods.addAll(
      _nestedBuilders(
        patchName: patchName,
        field: field,
        capitalized: capitalized,
        key: key,
        knownClasses: knownClasses,
        genericTypeNames: genericTypeNames,
      ),
    );
    return methods;
  }

  /// The nested-patch helpers the previous string helper emitted for fields
  /// referencing other Zorphy types: `with<Name>Patch`,
  /// `with<Name>PatchFunc`, `update<Name>At` (lists) and `update<Name>Value`
  /// (maps).
  ///
  /// These write through the same map as the algebra, so nothing about the new
  /// surface changes their behaviour.
  List<Method> _nestedBuilders({
    required String patchName,
    required NameTypeClassComment field,
    required String capitalized,
    required String key,
    required List<String> knownClasses,
    required List<String> genericTypeNames,
  }) {
    final fieldType = field.type ?? '';
    final innerType = fieldType.replaceAll(r'$', '').replaceAll('?', '');
    if (!_isZorphyType(innerType, field, knownClasses, genericTypeNames)) {
      return const [];
    }

    // A function-typed field is not a Zorphy reference (issue #105).
    if (fieldType.contains('Function')) return const [];

    // Abstract/sealed forms (`$$Type`) have no concrete patch to instantiate.
    if (fieldType.trim().startsWith(r'$$')) return const [];

    if (innerType.startsWith('List<')) {
      final match = RegExp(r'^List<(.+)>$').firstMatch(innerType);
      if (match == null) return const [];
      final elementType = match.group(1)!.replaceAll(r'$', '');
      if (!_isZorphyType(elementType, field, knownClasses, genericTypeNames)) {
        return const [];
      }
      final elementPatch = '${elementType}Patch';
      return [
        Method((m) {
          m
            ..name = 'update${capitalized}At'
            ..returns = referType(patchName)
            ..requiredParameters.addAll([
              Parameter((p) {
                p
                  ..name = 'index'
                  ..type = referType('int');
              }),
              Parameter((p) {
                p
                  ..name = 'patch'
                  ..type = referType('$elementPatch Function($elementPatch)');
              }),
            ]);
          m.body = Block((b) {
            b.statements.add(
              Code('$patchMapName[$key] = (List<dynamic> list) {'),
            );
            b.statements.add(
              Code('  final updated = List<$elementType>.from(list);'),
            );
            b.statements.add(
              const Code('  if (index >= 0 && index < updated.length) {'),
            );
            b.statements.add(
              Code(
                '    updated[index] = '
                'patch($elementPatch()).applyTo(updated[index]);',
              ),
            );
            b.statements.add(const Code('  }'));
            b.statements.add(const Code('  return updated;'));
            b.statements.add(const Code('};'));
            b.statements.add(const Code('return this;'));
          });
        }),
      ];
    }

    if (innerType.startsWith('Map<')) {
      final match = RegExp(r'^Map<(.+), (.+)>$').firstMatch(innerType);
      if (match == null) return const [];
      final keyType = match.group(1)!.replaceAll(r'$', '');
      final valueType = match.group(2)!.replaceAll(r'$', '');
      if (!_isZorphyType(valueType, field, knownClasses, genericTypeNames)) {
        return const [];
      }
      final valuePatch = '${valueType}Patch';
      return [
        Method((m) {
          m
            ..name = 'update${capitalized}Value'
            ..returns = referType(patchName)
            ..requiredParameters.addAll([
              Parameter((p) {
                p
                  ..name = 'key'
                  ..type = referType(keyType);
              }),
              Parameter((p) {
                p
                  ..name = 'patch'
                  ..type = referType('$valuePatch Function($valuePatch)');
              }),
            ]);
          m.body = Block((b) {
            b.statements.add(
              Code('$patchMapName[$key] = (Map<dynamic, dynamic> map) {'),
            );
            b.statements.add(
              const Code('  final updated = Map<dynamic, dynamic>.from(map);'),
            );
            b.statements.add(const Code('  if (updated.containsKey(key)) {'));
            b.statements.add(
              Code(
                '    updated[key] = patch($valuePatch())'
                '.applyTo(updated[key] as $valueType);',
              ),
            );
            b.statements.add(const Code('  }'));
            b.statements.add(const Code('  return updated;'));
            b.statements.add(const Code('};'));
            b.statements.add(const Code('return this;'));
          });
        }),
      ];
    }

    final nestedPatch = '${innerType}Patch';
    return [
      Method((m) {
        m
          ..name = 'with${capitalized}Patch'
          ..returns = referType(patchName)
          ..requiredParameters.add(
            Parameter((p) {
              p
                ..name = 'patch'
                ..type = referType(nestedPatch);
            }),
          );
        m.body = Block((b) {
          b.statements.add(Code('$patchMapName[$key] = patch;'));
          b.statements.add(const Code('return this;'));
        });
      }),
      Method((m) {
        m
          ..name = 'with${capitalized}PatchFunc'
          ..returns = referType(patchName)
          ..requiredParameters.add(
            Parameter((p) {
              p
                ..name = 'patch'
                ..type = referType('$nestedPatch Function($nestedPatch)');
            }),
          );
        m.body = Block((b) {
          b.statements.add(Code('$patchMapName[$key] = (dynamic current) {'));
          b.statements.add(
            Code(
              '  return patch($nestedPatch())'
              '.applyTo(current as $innerType);',
            ),
          );
          b.statements.add(const Code('};'));
          b.statements.add(const Code('return this;'));
        });
      }),
    ];
  }

  /// Whether [type] names another Zorphy type: the `$`-prefixed abstract form,
  /// or a concrete class the caller knows about.
  bool _isZorphyType(
    String type,
    NameTypeClassComment field,
    List<String> knownClasses,
    List<String> genericTypeNames,
  ) {
    if (field.isEnum) return false;
    if (type.contains('Function')) return false;
    if (_isGenericType(type, genericTypeNames)) return false;
    if (type.startsWith(r'$')) return true;
    return knownClasses.contains(type);
  }

  /// Whether [type] IS a generic parameter — exactly (`T`), nullable (`T?`), or
  /// as a whole type argument (`List<T>`, `Map<String, T>`, `Foo<T>`).
  ///
  /// The test is per IDENTIFIER, not per substring: `Token` contains `T` as a
  /// substring but is not `T`, so a generic entity's concrete `Token` field
  /// must keep its `withTokenPatch` / `withTokenPatchFunc` builders (review of
  /// #203). Splitting a type into identifiers also reaches a parameter nested
  /// in a collection argument, which the legacy helper's `<…>` probe only
  /// approximated.
  static bool _isGenericType(String type, List<String> genericTypeNames) {
    if (genericTypeNames.isEmpty) return false;
    final identifiers = RegExp(
      r'[A-Za-z_$][A-Za-z0-9_$]*',
    ).allMatches(type).map((m) => m.group(0));
    return identifiers.any(genericTypeNames.contains);
  }

  /// The patch shape a field carries, per ISSUE-008.
  ///
  /// The shapes are mutually exclusive and derived from the declared type
  /// alone, so a field is classified the same way for `diff` and `toWire`.
  _FieldShape _fieldShape(
    NameTypeClassComment field, {
    required List<String> knownClasses,
    required List<String> genericTypeNames,
  }) {
    final declared = (field.type ?? 'dynamic').replaceAll(r'$', '');
    final isNullable = declared.endsWith('?');
    final type = isNullable
        ? declared.substring(0, declared.length - 1)
        : declared;

    final list = RegExp(r'^List<(.+)>$').firstMatch(type);
    if (list != null) {
      return _FieldShape(
        kind: _FieldShapeKind.list,
        valueType: list.group(1)!.trim(),
        patchType: '',
        isNullable: isNullable,
      );
    }

    final map = RegExp(r'^Map<(.+)>$').firstMatch(type);
    if (map != null) {
      return _FieldShape(
        kind: _FieldShapeKind.map,
        // `Map<K, V>` keeps both arguments: the delta is parameterized on the
        // pair, and dropping K would not name the field's declared type.
        valueType: map.group(1)!.trim(),
        patchType: '',
        isNullable: isNullable,
      );
    }

    // A nested Zorphy field: route the test through the single `_isZorphyType`
    // helper the fluent-builder emission already uses, so the two call sites
    // cannot drift. `type` is `$`-stripped above (as the helper's other callers
    // pass it), so a concrete class the caller knows is what matches here.
    if (_isZorphyType(type, field, knownClasses, genericTypeNames)) {
      final bare = _baseName(type);
      return _FieldShape(
        kind: _FieldShapeKind.nested,
        valueType: bare,
        patchType: '${bare}Patch',
        isNullable: isNullable,
      );
    }

    return _FieldShape(
      kind: _FieldShapeKind.scalar,
      valueType: type,
      patchType: '',
      isNullable: isNullable,
    );
  }

  static String _clean(String name) => name.replaceAll(r'$', '');

  /// The bare class name of a possibly-parameterized type reference.
  static String _baseName(String ref) {
    final lt = ref.indexOf('<');
    return lt == -1 ? ref : ref.substring(0, lt);
  }

  static String _memberName(String name) =>
      name.startsWith('_') ? name.substring(1) : name;
}

/// What a patch carries for one field (ISSUE-008).
enum _FieldShapeKind {
  /// A nested Zorphy entity: carried as a `PatchNested`.
  nested,

  /// A `List<E>`: carried as a `ListPatchDelta<E>`.
  list,

  /// A `Map<K, V>`: carried as a `MapPatchDelta<K, V>`.
  map,

  /// Anything else: carried as the value itself.
  scalar,
}

/// The classification of one field's declared type.
class _FieldShape {
  const _FieldShape({
    required this.kind,
    required this.valueType,
    required this.patchType,
    required this.isNullable,
  });

  /// Which patch shape the field carries.
  final _FieldShapeKind kind;

  /// The type arguments the carried patch is parameterized on: the nullable
  /// marker stripped, and for a map both key and value (`String, int`).
  final String valueType;

  /// The nested patch type for [_FieldShapeKind.nested]; empty otherwise.
  final String patchType;

  /// Whether the declared type carries a `?`.
  final bool isNullable;
}
