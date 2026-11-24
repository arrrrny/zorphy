import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import '../common/NameType.dart';
import '../emission/emitter.dart';
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
  }) {
    final classSpec = buildClass(
      className: className,
      fields: fields,
      knownClasses: knownClasses,
      genericTypeNames: genericTypeNames,
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
  }) {
    final name = _clean(className);
    final enumName = '${name}\$';
    final patchName = '${name}Patch';
    final typeArgs = genericTypeNames.isEmpty
        ? ''
        : '<${genericTypeNames.join(', ')}>';

    return Class((c) {
      c.name = patchName;
      c.extend = referType('PatchBase<$name$typeArgs, $enumName>');
      c.types.addAll(genericTypeNames.map(referType));

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
      c.methods.add(_composeMethod(patchRef));
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
  /// permits) so a chain keeps its static patch type.
  Method _composeMethod(String patchRef) => Method((m) {
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
          'return $patchRef()'
          '..$patchMapName.addAll($patchMapName)'
          '..$patchMapName.addAll(next.$patchMapName);',
        ),
      );
    });
  });

  /// `invert(before)` — the patch that undoes this one for [before].
  ///
  /// The inverse is built from the value this patch ACTUALLY carried, not from
  /// a fresh empty patch: a nested field carries a `PatchNested`, and a
  /// collection field carries a delta, so each is inverted through its own
  /// carried instance. A scalar carries the value itself, so its inverse is
  /// simply the prior value.
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
            // A nullable field's prior value may be null, and `invert` takes
            // the non-nullable collection; the else arm below restores the
            // raw prior value (including null) wholesale.
            b.statements.add(
              Code(
                'if ($patchMapName[$key] is ListPatchDelta<${shape.valueType}>'
                '${shape.isNullable ? ' && before.$member != null' : ''}) '
                'undo.$patchMapName[$key] = '
                '($patchMapName[$key] as ListPatchDelta<${shape.valueType}>)'
                '.invert(before.$member${shape.isNullable ? '!' : ''});',
              ),
            );
            b.statements.add(
              Code(
                'if ($patchMapName.containsKey($key) && '
                '$patchMapName[$key] is! ListPatchDelta<${shape.valueType}>) '
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
  /// - a `List<E>` field carries a `ListPatchDelta<E>` — granular ops, never a
  ///   whole-list overwrite;
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
    List<String> knownClasses = const [],
  }) => Method((m) {
    final patchName = _baseName(patchRef);
    m
      ..name = 'diff'
      ..static = true
      ..returns = referType(patchRef);
    // A static member cannot see the class's type variables, so a generic
    // patch declares them on `diff` itself — the caller supplies them from
    // the two entities it passes in.
    for (final generic in genericTypeNames) {
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
          case _FieldShapeKind.list when shape.isNullable:
            b.statements.add(
              Code(
                'if (previous.$member != null && next.$member != null) {',
              ),
            );
            b.statements.add(
              Code(
                '  final ${member}Delta = '
                'ListPatchDelta.diff<${shape.valueType}>('
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
              Code(
                'if (previous.$member == null || next.$member == null) {',
              ),
            );
            b.statements.add(
              Code(
                '  if (previous.$member != next.$member) '
                'changes.$patchMapName[$key] = next.$member;',
              ),
            );
            b.statements.add(const Code('}'));
          case _FieldShapeKind.list:
            b.statements.add(
              Code(
                'final ${member}Delta = '
                'ListPatchDelta.diff<${shape.valueType}>(previous.$member, '
                'next.$member);',
              ),
            );
            b.statements.add(
              Code(
                'if (${member}Delta.isNotEmpty) '
                'changes.$patchMapName[$key] = ${member}Delta;',
              ),
            );
          case _FieldShapeKind.map when shape.isNullable:
            b.statements.add(
              Code(
                'if (previous.$member != null && next.$member != null) {',
              ),
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
              Code(
                'if (previous.$member == null || next.$member == null) {',
              ),
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
          _FieldShapeKind.list =>
            '$patchMapName[$key] is ListPatchDelta<${shape.valueType}>'
                ' ? ($patchMapName[$key] as ListPatchDelta<${shape.valueType}>)'
                '.toWire() : $patchMapName[$key]',
          _FieldShapeKind.map =>
            '$patchMapName[$key] is MapPatchDelta<${shape.valueType}>'
                ' ? ($patchMapName[$key] as MapPatchDelta<${shape.valueType}>)'
                '.toWire() : $patchMapName[$key]',
          _FieldShapeKind.nested =>
            '$patchMapName[$key] is PatchNested'
                ' ? ($patchMapName[$key] as PatchNested).toWire()'
                ' : $patchMapName[$key]',
          _ => '$patchMapName[$key]',
        };
        b.statements.add(
          Code(
            'if ($patchMapName.containsKey($key)) '
            'wire[${_stringLiteral(member)}] = $wireValue;',
          ),
        );
      }
      b.statements.add(const Code('return wire;'));
    });
  });

  static String _stringLiteral(String value) =>
      "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";

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
    final parameterType =
        (type.endsWith('?') ||
            type == 'dynamic' ||
            type.startsWith('dynamic<') ||
            type.startsWith('dynamic '))
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
    if (genericTypeNames.contains(type)) return false;
    if (genericTypeNames.any((g) => type.contains(g))) return false;
    if (type.startsWith(r'$')) return true;
    return knownClasses.contains(type);
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
