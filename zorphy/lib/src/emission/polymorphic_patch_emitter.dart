import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import '../common/NameType.dart';
import '../emission/emitter.dart';
import '../helpers.dart' as helpers;

/// Emits the polymorphic patch surface for a sealed hierarchy (ISSUE-009).
///
/// A polymorphic root (`abstract class $$Notification`) gets no patch from
/// `PatchEmitter`: the root is abstract, so `PatchClassGenerator` returns
/// early. A caller holding a heterogeneous `List<Notification>` therefore
/// cannot apply a shared-field update (`markAllRead`) without downcasting every
/// element first.
///
/// This emitter closes the gap with:
///
/// * [emitRoot] — the surface the issue names:
///   - `sealed class <Root>Patch implements ZorphyPatch<<Root>>`, declaring the
///     root's shared fields as [PatchValue] getters, and
///   - `<Root>SharedPatch`, the concrete patch the const `.shared(...)` factory
///     redirects to. Its `apply` dispatches on the target's runtime type and
///     delegates to that subtype's own patch, so one shared update reaches
///     every concrete subtype while preserving each element's type.
/// * [emitSubtypePatch] — the concrete `<Subtype>Patch`, which extends the root
///   patch and narrows `apply` to its own entity.
///
/// ## Why subtypes extend rather than implement two patch interfaces
///
/// The issue's sketch has `<Subtype>Patch implements <Root>Patch,
/// ZorphyPatch<<Subtype>>`. That is not expressible in Dart: a class gets one
/// signature per member name, and those two interfaces demand different ones
/// (`compose(ZorphyPatch<Root>)` vs `compose(ZorphyPatch<Subtype>)`), while
/// `ZorphyPatch` uses its type parameter in both parameter and return
/// position, so the two instantiations are unrelated types.
///
/// Extending the root patch keeps the property the issue is after — a mixed
/// collection holds every subtype's patch behind `<Root>Patch`, and one shared
/// update applies to all of it — and the subtype still narrows `apply`:
///
/// * the return type narrows covariantly (`OrderNotification` is a
///   `Notification`), and
/// * the parameter narrows via `covariant` (legal for overrides), so applying
///   an `OrderNotificationPatch` to a `PriceDropNotification` fails with a
///   `TypeError` at the call rather than silently skipping the element — the
///   loud failure a bulk update needs, since a silently skipped element in a
///   mixed collection is data loss nobody sees.
///
/// ## The `copyWith` contract a patch relies on
///
/// Every emitted `apply` rebuilds its target through the entity's own
/// `copyWith`, passing `field.isUnchanged ? target.field : field.valueOrNull`.
/// That is the correct call for a patch — `valueOrNull` is `null` only for a
/// deliberate [PatchValue.set(null)] — but the guarantee "a nullable field can
/// be cleared" holds only when that `copyWith` can tell an explicit `null`
/// apart from an omitted argument. A `copyWith` written as
/// `readAt: readAt ?? this.readAt` cannot: it treats a deliberate clear as
/// "keep the current value" and the update is silently dropped.
///
/// The entity-side contract is therefore:
///
/// * an **omitted** argument keeps the current value, and
/// * an argument passed as `null` **clears** the field.
///
/// A `copyWith` that satisfies it uses a sentinel default for its nullable
/// parameters (`Object? readAt = _unset`) instead of `T? readAt` with `??`.
/// See the runtime fixture `test/runtime/fixtures/notification.dart` for the
/// shape, and `polymorphic_patch_test.dart` for the clearing cases.
///
/// Everything is assembled as [Spec] objects and formatted by [ZorphyEmitter]:
/// no source text is concatenated here, matching `PatchEmitter`.
class PolymorphicPatchEmitter {
  /// Creates an emitter. Stateless: one instance serves every hierarchy.
  const PolymorphicPatchEmitter();

  /// The name of the `apply` member — narrowed on subtypes.
  static const String applyMethodName = 'apply';

  /// The const factory that builds a root-typed update.
  static const String sharedConstructorName = 'shared';

  /// Suffix of the concrete class [sharedConstructorName] redirects to.
  static const String sharedPatchSuffix = 'SharedPatch';

  /// Emits the root's polymorphic patch surface: the sealed `<Root>Patch` and
  /// the `<Root>SharedPatch` its `.shared(...)` factory builds.
  ///
  /// [fields] are the root's shared fields, in declaration order.
  /// [subtypeNames] are the concrete subtype class names (without `$`); each
  /// must also get an [emitSubtypePatch] result so the shared patch's dispatch
  /// arms resolve.
  ///
  /// Throws [ArgumentError] when [subtypeNames] is empty: a sealed root with no
  /// concrete subtypes has nothing to dispatch to, so a shared patch for it
  /// could never apply, and emitting one would be a silent trap.
  String emitRoot({
    required String rootName,
    required List<NameTypeClassComment> fields,
    required List<String> subtypeNames,
    Map<String, Map<String, String>> subtypeFieldTypes = const {},
  }) {
    _requireSubtypes(subtypeNames);
    return _emit([
      buildRootClass(
        rootName: rootName,
        fields: fields,
        subtypeNames: subtypeNames,
      ),
      buildSharedClass(
        rootName: rootName,
        fields: fields,
        subtypeNames: subtypeNames,
        subtypeFieldTypes: subtypeFieldTypes,
      ),
    ]);
  }

  /// Emits the concrete `<Subtype>Patch` for a subtype of a polymorphic root.
  ///
  /// The result extends `<Root>Patch`, so a mixed collection can hold every
  /// subtype's patch behind one type, and narrows [applyMethodName] to
  /// [subtypeName].
  String emitSubtypePatch({
    required String subtypeName,
    required String rootName,
    required List<NameTypeClassComment> fields,
    required List<String> sharedFields,
  }) {
    return _emit([
      buildSubtypeClass(
        subtypeName: subtypeName,
        rootName: rootName,
        fields: fields,
        sharedFields: sharedFields,
      ),
    ]);
  }

  /// Formats each spec individually and joins them.
  ///
  /// [ZorphyEmitter.emitSpecs] formats only when it receives a single spec and
  /// otherwise hands the specs through unformatted, so a multi-class emission
  /// (root + shared) goes out one formatted class at a time.
  static String _emit(List<Spec> specs) => specs
      .map((spec) => ZorphyEmitter().emitSpecs([spec]).trim())
      .where((source) => source.isNotEmpty)
      .join('\n\n');

  /// Builds the sealed root patch [Class] spec.
  ///
  /// Exposed separately from [emitRoot] so a caller can fold the spec into a
  /// larger library instead of re-parsing emitted text.
  Class buildRootClass({
    required String rootName,
    required List<NameTypeClassComment> fields,
    required List<String> subtypeNames,
  }) {
    _requireSubtypes(subtypeNames);
    final root = _clean(rootName);
    final patchName = '${root}Patch';

    return Class((c) {
      c
        ..name = patchName
        ..sealed = true
        ..implements.add(referType('ZorphyPatch<$root>'));

      // A const constructor is what every concrete patch extends.
      c.constructors.add(
        Constructor((con) {
          con.constant = true;
        }),
      );

      // The `.shared(...)` factory the issue names: one call builds a
      // root-typed update for a whole heterogeneous collection. It is a
      // FACTORY, not a redirecting const constructor — Dart forbids a
      // redirecting constructor from carrying optional parameters, and the
      // shared fields are exactly that.
      c.constructors.add(
        Constructor((con) {
          con
            ..name = sharedConstructorName
            ..factory = true;
          for (final field in fields) {
            con.optionalParameters.add(_fieldParameter(field));
          }
          con.body = Code(
            'return $root$sharedPatchSuffix('
            '${fields.map((f) => '${_memberName(f.name)}: ${_memberName(f.name)}').join(', ')}'
            ');',
          );
        }),
      );

      // The root's shared fields, one abstract getter each. `PatchValue<V>`
      // carries V INCLUDING its nullability (`PatchValue<String?>` for
      // `String?`), so a nullable field can be set to null deliberately
      // instead of being indistinguishable from "unchanged".
      for (final field in fields) {
        c.methods.add(_patchValueGetter(field));
      }

      c.methods.add(_isEmptyGetter(fields));
      c.methods.add(_isNotEmptyGetter());
      c.methods.add(_rootApplyMethod(root));
      c.methods.add(_rootComposeMethod(root));
      c.methods.add(_rootInvertMethod(root));
      c.methods.add(_rootToWireMethod(fields));
      c.methods.add(_rootToEnvelopeMethod(fields));
      c.methods.add(
        _rootFromWireMethod(root, fields, subtypeNames: subtypeNames),
      );
    });
  }

  /// Builds `<Root>SharedPatch`, the concrete patch `.shared(...)` returns.
  ///
  /// Its [applyMethodName] dispatches on the target's runtime type: each arm
  /// builds that subtype's patch from the shared fields and lets the subtype's
  /// own narrowing check run, so a mismatch is still loud.
  Class buildSharedClass({
    required String rootName,
    required List<NameTypeClassComment> fields,
    required List<String> subtypeNames,
    Map<String, Map<String, String>> subtypeFieldTypes = const {},
  }) {
    _requireSubtypes(subtypeNames);
    final root = _clean(rootName);
    final sharedName = '$root$sharedPatchSuffix';

    return Class((c) {
      c
        ..name = sharedName
        ..modifier = ClassModifier.final$
        ..extend = referType('${root}Patch');

      c.constructors.add(
        Constructor((con) {
          for (final field in fields) {
            con.optionalParameters.add(_fieldParameter(field));
            con.initializers.add(_fieldInitializer(field));
          }
        }),
      );

      for (final field in fields) {
        c.fields.add(_patchValueField(field, overridesRoot: true));
      }

      c.methods.add(_isEmptyGetter(fields));
      c.methods.add(_isNotEmptyGetter());
      c.methods.add(
        _sharedApplyMethod(root, fields, subtypeNames, subtypeFieldTypes),
      );
      c.methods.add(_concreteComposeMethod(root, fields, sharedName));
      c.methods.add(
        _concreteInvertMethod(
          root,
          fields,
          sharedName,
          entityName: root,
          guardKind: false,
        ),
      );
      c.methods.add(_concreteToWireMethod(fields));
      c.methods.add(
        _concreteToEnvelopeMethod(
          entityType: root,
          fields: fields,
          patchKind: 'shared',
        ),
      );
      c.methods.add(_sharedFromWireMethod(root, fields));
    });
  }

  /// Builds a concrete subtype patch [Class] spec that extends the root.
  ///
  /// Exposed separately so a caller can fold it into a library;
  /// [emitSubtypePatch] wraps it in formatted source.
  Class buildSubtypeClass({
    required String subtypeName,
    required String rootName,
    required List<NameTypeClassComment> fields,
    required List<String> sharedFields,
  }) {
    final subtype = _clean(subtypeName);
    final root = _clean(rootName);
    final patchName = '${subtype}Patch';
    final shared = sharedFields.toSet();

    return Class((c) {
      c
        ..name = patchName
        ..modifier = ClassModifier.final$
        ..extend = referType('${root}Patch');

      c.constructors.add(
        Constructor((con) {
          for (final field in fields) {
            con.optionalParameters.add(_fieldParameter(field));
            con.initializers.add(_fieldInitializer(field));
          }
        }),
      );

      for (final field in fields) {
        final isShared =
            shared.contains(field.name) ||
            shared.contains(_memberName(field.name));
        c.fields.add(_patchValueField(field, overridesRoot: isShared));
      }

      c.methods.add(_isEmptyGetter(fields));
      c.methods.add(_isNotEmptyGetter());
      c.methods.add(_subtypeApplyMethod(subtype, fields));
      c.methods.add(_concreteComposeMethod(root, fields, patchName));
      c.methods.add(
        _concreteInvertMethod(
          root,
          fields,
          patchName,
          entityName: subtype,
          guardKind: true,
        ),
      );
      c.methods.add(_concreteToWireMethod(fields));
      c.methods.add(
        _concreteToEnvelopeMethod(
          entityType: subtype,
          fields: fields,
          patchKind: subtype,
        ),
      );
      c.methods.add(_subtypeFromWireMethod(subtype, root, fields, shared));
    });
  }

  // ── shared member builders ──────────────────────────────────────────────

  /// The field's type as a CONCRETE, `$`-free spelling.
  ///
  /// `metadata.allFields` carries the interface's own declaration, so a nested
  /// value type arrives as `$DraftA`. A `PatchValue<$DraftA>` does not compile
  /// — `$`-classes are interfaces with no concrete getter — and its
  /// `valueOrNull` would be `$DraftA?`, so `apply` could not hand it to the
  /// concrete `copyWith(payload: …)` (`argument_type_not_assignable`, seen on
  /// the covariant_nested fixture). The generators that consume these specs
  /// all work in the concrete space, so the patch surface must too.
  static String _concreteType(String? type) =>
      helpers.replaceDollarTypesWithConcrete(type ?? '');

  Method _patchValueGetter(NameTypeClassComment field) => Method((m) {
    m
      ..name = _memberName(field.name)
      ..type = MethodType.getter
      ..returns = referType('PatchValue<${_concreteType(field.type)}>');
  });

  Field _patchValueField(
    NameTypeClassComment field, {
    required bool overridesRoot,
  }) => Field((f) {
    f
      ..name = _memberName(field.name)
      ..modifier = FieldModifier.final$
      ..type = referType('PatchValue<${_concreteType(field.type)}>');
    if (overridesRoot) f.annotations.add(refer('override'));
  });

  Parameter _fieldParameter(NameTypeClassComment field) => Parameter((p) {
    p
      ..name = _memberName(field.name)
      ..named = true
      ..defaultTo = const Code('const PatchValue.unchanged()')
      ..type = referType('PatchValue<${_concreteType(field.type)}>');
  });

  Code _fieldInitializer(NameTypeClassComment field) {
    final name = _memberName(field.name);
    return Code('$name = $name');
  }

  /// `bool get isEmpty` — every declared field is unchanged.
  Method _isEmptyGetter(List<NameTypeClassComment> fields) => Method((m) {
    m
      ..name = 'isEmpty'
      ..type = MethodType.getter
      ..returns = referType('bool');
    m.annotations.add(refer('override'));
    m.body = fields.isEmpty
        ? const Code('return true;')
        : Code(
            'return ${fields.map((f) => '${_memberName(f.name)}.isUnchanged').join(' && ')};',
          );
  });

  /// `bool get isNotEmpty` — the `ZorphyPatch` contract declares it alongside
  /// [isEmpty] with a default body, and an interface's default does NOT satisfy
  /// an implementor, so a concrete patch must restate it.
  Method _isNotEmptyGetter() => Method((m) {
    m
      ..name = 'isNotEmpty'
      ..type = MethodType.getter
      ..returns = referType('bool');
    m.annotations.add(refer('override'));
    m.body = const Code('return !isEmpty;');
  });

  /// The root's `apply`, abstract and covariant so subtypes may narrow it.
  Method _rootApplyMethod(String root) => Method((m) {
    m
      ..name = applyMethodName
      ..returns = referType(root)
      ..requiredParameters.add(_covariantTarget(root));
    m.annotations.add(refer('override'));
  });

  /// The root's `compose`, abstract. Takes the root patch so the whole
  /// hierarchy composes through one type.
  Method _rootComposeMethod(String root) => Method((m) {
    m
      ..name = 'compose'
      ..returns = referType('${root}Patch')
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'next'
            ..covariant = true
            ..type = referType('${root}Patch');
        }),
      );
    m.annotations.add(refer('override'));
  });

  /// The root's `invert`, abstract: it captures what it needs from a root.
  Method _rootInvertMethod(String root) => Method((m) {
    m
      ..name = 'invert'
      ..returns = referType('${root}Patch')
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'before'
            ..type = referType(root);
        }),
      );
    m.annotations.add(refer('override'));
  });

  /// The root's `toWire`, abstract.
  Method _rootToWireMethod(List<NameTypeClassComment> fields) => Method((m) {
    m
      ..name = 'toWire'
      ..returns = referType('Map<String, Object?>');
    m.annotations.add(refer('override'));
  });

  /// The root's `toEnvelope`, abstract — every concrete patch answers with the
  /// envelope its own class name requires.
  Method _rootToEnvelopeMethod(List<NameTypeClassComment> fields) =>
      Method((m) {
        m
          ..name = 'toEnvelope'
          ..returns = referType('Map<String, Object?>');
      });

  /// The shared patch's `apply`: dispatch each concrete subtype to its own
  /// patch, so the target keeps its subtype and its own fields survive.
  Method _sharedApplyMethod(
    String root,
    List<NameTypeClassComment> fields,
    List<String> subtypeNames,
    Map<String, Map<String, String>> subtypeFieldTypes,
  ) => Method((m) {
    m
      ..name = applyMethodName
      ..returns = referType(root)
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'target'
            ..type = referType(root);
        }),
      );
    m.annotations.add(refer('override'));

    final lines = <String>['if (isEmpty) return target;'];
    for (final subtypeName in subtypeNames) {
      final subtype = _clean(subtypeName);
      // Dispatch through `copyWith`, the one rebuild surface every generated
      // entity carries. Emitting `CirclePatch(...)` here would couple the root
      // to a class the root's own library may never declare — the analyze gate
      // emits roots alone, and #142 withholds sealing across libraries — so the
      // dispatch must survive a subtype patch that does not exist.
      lines.add('if (target is $subtype) {');
      // The patch carries the ROOT's declaration of each shared field, so a
      // covariant redeclaration (`$$Node.payload: $DraftA`,
      // `$Child.payload: $DraftB`) makes `valueOrNull` a `DraftA?` while this
      // arm's `copyWith(payload: …)` expects `DraftB?`. The subtype is known
      // HERE, so the narrowed type — when the subtype declares its own — is
      // what the write must cast to.
      lines.add('return target.copyWith(');
      for (final f in fields) {
        final name = _memberName(f.name);
        final narrowed = subtypeFieldTypes[subtype]?[f.name];
        final value = '${name}.valueOrNull';
        final written = narrowed == null
            ? value
            : '$value as ${_concreteType(narrowed)}';
        lines.add('  $name: $name.isUnchanged ? target.$name : $written,');
      }
      lines.add(');');
      lines.add('}');
    }
    lines.add(
      'throw ArgumentError.value(target, \'target\', '
      '\'${root}Patch cannot apply to \${target.runtimeType}\');',
    );
    m.body = Code(lines.join('\n'));
  });

  /// The subtype's `apply`, narrowed to the subtype.
  Method _subtypeApplyMethod(
    String subtype,
    List<NameTypeClassComment> fields,
  ) => Method((m) {
    m
      ..name = applyMethodName
      ..returns = referType(subtype)
      ..requiredParameters.add(_covariantTarget(subtype));
    m.annotations.add(refer('override'));

    if (fields.isEmpty) {
      m.body = const Code('return target;');
      return;
    }

    // Rebuild through the entity's own copyWith: the patch never mutates, and
    // an unchanged field keeps the target's value by not being passed.
    final lines = <String>[
      'if (isEmpty) return target;',
      'return target.copyWith(',
    ];
    for (final field in fields) {
      final name = _memberName(field.name);
      lines.add(
        '  $name: $name.isUnchanged ? target.$name : $name.valueOrNull,',
      );
    }
    lines.add(');');
    m.body = Code(lines.join('\n'));
  });

  /// `compose` for a concrete patch: `next`'s set fields win, this one's fill
  /// the rest. Kinds must match — merging a sibling subtype's patch, or a
  /// subtype patch into a shared one, would silently drop the other side's
  /// subtype-only fields.
  Method _concreteComposeMethod(
    String root,
    List<NameTypeClassComment> fields,
    String selfName,
  ) => Method((m) {
    m
      ..name = 'compose'
      ..returns = referType('${root}Patch')
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'next'
            ..covariant = true
            ..type = referType('${root}Patch');
        }),
      );
    m.annotations.add(refer('override'));

    // `next` is statically the ROOT patch. The type guard is what promotes it
    // for the fields below, and it is also the loud failure every concrete
    // patch needs: composing a SIBLING's patch would silently drop that
    // sibling's fields, and a shared patch composed with a SUBTYPE patch would
    // drop the subtype's own fields the same way. The guard fires for both
    // directions, so neither is a silent data loss.
    final lines = <String>[
      'if (next.isEmpty) return this;',
      'if (isEmpty) return next;',
    ];
    lines.addAll([
      'if (next is! $selfName) {',
      '  throw ArgumentError.value(next, \'next\', '
          '\'$selfName cannot compose \${next.runtimeType}\');',
      '}',
    ]);
    if (fields.isEmpty) {
      lines.add('return this;');
    } else {
      final args = fields
          .map((f) {
            final name = _memberName(f.name);
            return '$name: next.$name.isUnchanged ? $name : next.$name';
          })
          .join(', ');
      lines.add('return $selfName($args);');
    }
    m.body = Code(lines.join('\n'));
  });

  /// `invert` for a concrete patch: the prior value of every field it sets.
  ///
  /// The parameter stays ROOT-typed — it is what the contract declares, and a
  /// covariance-narrowed version would not be a valid override — while the
  /// return type narrows to the concrete patch, which IS covariant.
  Method _concreteInvertMethod(
    String root,
    List<NameTypeClassComment> fields,
    String selfName, {
    required String entityName,
    required bool guardKind,
  }) => Method((m) {
    m
      ..name = 'invert'
      ..returns = referType(selfName)
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'before'
            ..type = referType(root);
        }),
      );
    m.annotations.add(refer('override'));

    if (fields.isEmpty) {
      m.body = const Code('return this;');
      return;
    }

    // `before` is statically the ROOT; promote it to this patch's own entity
    // so subtype-only fields resolve. A wrong-element call must fail loudly.
    // The shared patch reads only root fields, so its parameter needs no
    // narrowing; a subtype patch guards the element kind so a sibling's prior
    // value is never read off a mismatched entity.
    final shared = <String>[];
    if (guardKind) {
      shared.add('if (before is! $entityName) {');
      shared.add(
        '  throw ArgumentError.value(before, \'before\', '
        '\'$selfName cannot invert \${before.runtimeType}\');',
      );
      shared.add('}');
    }
    final args = fields
        .map((f) {
          final name = _memberName(f.name);
          return '$name: $name.isUnchanged '
              '? const PatchValue.unchanged() '
              ': PatchValue.set(before.$name)';
        })
        .join(', ');
    m.body = Code([...shared, 'return $selfName($args);'].join('\n'));
  });

  /// `toWire` for a concrete patch: only the fields it actually sets.
  Method _concreteToWireMethod(List<NameTypeClassComment> fields) =>
      Method((m) {
        m
          ..name = 'toWire'
          ..returns = referType('Map<String, Object?>');
        m.annotations.add(refer('override'));

        if (fields.isEmpty) {
          m.body = const Code('return const {};');
          return;
        }

        final lines = <String>['final wire = <String, Object?>{};'];
        for (final field in fields) {
          final name = _memberName(field.name);
          lines.add(
            'if ($name.isSet) wire[\'${field.name}\'] = $name.valueOrNull;',
          );
        }
        lines.add('return wire;');
        m.body = Code(lines.join('\n'));
      });

  Parameter _covariantTarget(String type) => Parameter((p) {
    p
      ..name = 'target'
      ..covariant = true
      ..type = referType(type);
  });

  /// The root's `static fromWire(raw)` — dispatch on the envelope's
  /// `patchKind` (ISSUE-017).
  ///
  /// The root patch is ABSTRACT, so it can build no instance of its own: a
  /// decode reads `patchKind` and builds the concrete patch that answers to
  /// it. `shared` is the hierarchy's own [sharedPatchSuffix] class.
  ///
  /// ## Why a subtype kind decodes onto the SHARED surface
  ///
  /// A generated library gives the sealed root [emitRoot]'s patch but gives
  /// each concrete leaf its own `PatchEmitter` patch, and that one extends
  /// `PatchBase<Leaf, Leaf$>` — NOT the root patch. So a leaf patch is not a
  /// `RootPatch`, and a root-typed `fromWire` cannot return one; the
  /// polymorphism here is real only when [emitSubtypePatch] built the leaves,
  /// which the code generator does not do (the same constraint
  /// `_sharedApplyMethod` documents: dispatch must survive a subtype patch
  /// that does not exist).
  ///
  /// A subtype envelope therefore decodes onto the SHARED surface, and every
  /// op key that surface cannot express is a `FieldViolation` at
  /// `/ops/<field>` — never a silently dropped change. A caller that wants the
  /// subtype's own patch decodes the same `ops` through that subtype's
  /// `fromWire`, which `PatchEmitter` emits for every concrete leaf.
  ///
  /// `entityType` is validated against the WHOLE hierarchy — the root name or
  /// any subtype — because a subtype patch names its own entity, and only a
  /// name outside the hierarchy is a decode error.
  Method _rootFromWireMethod(
    String root,
    List<NameTypeClassComment> fields, {
    required List<String> subtypeNames,
  }) => Method((m) {
    final patchName = '${root}Patch';
    final sharedName = '$root$sharedPatchSuffix';
    m
      ..name = 'fromWire'
      ..static = true
      ..returns = referType('ZorphyBoundaryResult<$patchName>')
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'raw'
            ..type = referType('Map<String, Object?>');
        }),
      );

    final cleanSubtypes = subtypeNames.map(_clean).toList();
    final kinds = ['shared', ...cleanSubtypes].join(', ');
    final hierarchy =
        "const <String>['$root'"
        '${cleanSubtypes.map((s) => ", '$s'").join()}]';
    final sharedKeys = fields.map((f) => _memberName(f.name)).toList();
    final sharedKeyList =
        'const <String>['
        '${sharedKeys.map((k) => "'$k'").join(', ')}]';

    final lines = <String>[
      'final kind = ZorphyPatchWire.patchKindOf(raw);',
      'if (kind == null) {',
      '  return BoundaryErr<$patchName>('
          "targetType: '$patchName', violations: <FieldViolation>["
          'FieldViolation('
          "path: '/$_patchKindKey', "
          "expected: 'String (one of: $kinds)', "
          'actual: ZorphyPatchWire.describe(null))]);',
      '}',
      'final hierarchy = $hierarchy;',
      'final entityType = ZorphyPatchWire.entityTypeOf(raw);',
      'if (entityType != null && !hierarchy.contains(entityType)) {',
      '  return BoundaryErr<$patchName>('
          "targetType: '$patchName', violations: <FieldViolation>["
          'FieldViolation('
          "path: '/$_entityTypeKey', "
          "expected: 'one of: \${hierarchy.join(', ')}', "
          'actual: ZorphyPatchWire.describe(entityType))]);',
      '}',
      "final ops = ZorphyPatchWire.opsOf(raw, '', <FieldViolation>[]);",
      'if (ops == null) {',
      '  return BoundaryErr<$patchName>('
          "targetType: '$patchName', violations: <FieldViolation>["
          'FieldViolation('
          "path: '/$_opsKey', expected: 'Map<String, Object?>', "
          "actual: ZorphyPatchWire.describe(raw['$_opsKey']))]);",
      '}',
      'if (kind == \'shared\' || hierarchy.contains(kind)) {',
      // Shared-surface decode: the shared patch IS a root patch, and it is the
      // one concrete root-typed patch a generated library always declares.
      '  final prefix = ZorphyPatchWire.opsPathOf(raw);',
      '  final decoded = $sharedName.fromWire(ops);',
      '  if (kind == \'shared\') return decoded'
          '.fold<ZorphyBoundaryResult<$patchName>>(',
      '    (value) => BoundaryOk<$patchName>(value),',
      '    (error) => BoundaryErr<$patchName>('
          'targetType: error.targetType, '
          'violations: ZorphyPatchWire.prefix(error.violations, prefix)),',
      '  );',
      // A subtype envelope carries that subtype's ops; the root patch can only
      // express the shared fields, so anything else is a violation rather than
      // a silently dropped change.
      '  final sharedKeys = $sharedKeyList;',
      '  final unknown = <FieldViolation>[];',
      '  for (final key in ops.keys) {',
      '    if (!sharedKeys.contains(key)) {',
      '      unknown.add(FieldViolation('
          "path: '/$_opsKey/\$key', "
          "expected: 'one of: \${sharedKeys.join(', ')}', "
          'actual: ZorphyPatchWire.describe(ops[key])));',
      '    }',
      '  }',
      '  return decoded.fold<ZorphyBoundaryResult<$patchName>>(',
      '    (value) => unknown.isEmpty',
      '        ? BoundaryOk<$patchName>(value)',
      '        : BoundaryErr<$patchName>('
          "targetType: '$patchName', violations: unknown),",
      '    (error) => BoundaryErr<$patchName>('
          'targetType: error.targetType, '
          'violations: <FieldViolation>[...error.violations, ...unknown]),',
      '  );',
      '}',
      'return BoundaryErr<$patchName>('
          "targetType: '$patchName', violations: <FieldViolation>["
          'FieldViolation('
          "path: '/$_patchKindKey', "
          "expected: 'String (one of: $kinds)', "
          'actual: ZorphyPatchWire.describe(kind))]);',
    ];
    m.body = Code(lines.join('\n'));
  });

  /// A concrete subtype's `static fromWire(raw)` — its own ops map.
  Method _subtypeFromWireMethod(
    String subtype,
    String root,
    List<NameTypeClassComment> fields,
    Set<String> shared,
  ) => _concreteFromWire('${subtype}Patch', fields);

  /// The shared patch's `static fromWire(raw)` — the root fields' ops map.
  ///
  /// The root's `fromWire` dispatches `patchKind: 'shared'` here, so the
  /// shared patch has to be decodable on its own even though the sealed ROOT
  /// patch is what a caller usually holds.
  Method _sharedFromWireMethod(
    String root,
    List<NameTypeClassComment> fields,
  ) => _concreteFromWire('$root$sharedPatchSuffix', fields);

  /// The `fromWire` body both concrete patches share.
  ///
  /// Accepts the bare `toWire()` map and the envelope's `ops` alike, so the
  /// root's dispatch and a transport that already knows the kind both reach
  /// the same decode. A field absent from the map stays
  /// [PatchValue.unchanged]; a field present but corrupt is a violation and
  /// makes the whole result an error.
  Method _concreteFromWire(
    String patchName,
    List<NameTypeClassComment> fields,
  ) => Method((m) {
    m
      ..name = 'fromWire'
      ..static = true
      ..returns = referType('ZorphyBoundaryResult<$patchName>')
      ..requiredParameters.add(
        Parameter((p) {
          p
            ..name = 'raw'
            ..type = referType('Map<String, Object?>');
        }),
      );

    final lines = <String>[
      'final violations = <FieldViolation>[];',
      "final ops = ZorphyPatchWire.opsOf(raw, '', violations);",
    ];
    for (final field in fields) {
      final name = _memberName(field.name);
      final declaredType = _concreteType(field.type);
      lines
        ..add('PatchValue<$declaredType>? ${name}Value;')
        ..add("if (ops != null && ops.containsKey('$name')) {")
        ..add(
          '  final Object? rawValue = ZorphyPatchWire.fieldValue('
          "ops['$name'], '/$name', violations);",
        )
        ..add(
          '  ${name}Value = '
          '${_wireDecodeExpression(field, 'rawValue', nome: name)};',
        )
        ..add('}');
    }
    final args = fields
        .map((f) {
          final name = _memberName(f.name);
          final declaredType = _concreteType(f.type);
          return '$name: ${name}Value ?? '
              'const PatchValue<$declaredType>.unchanged()';
        })
        .join(', ');
    lines
      ..add('if (violations.isNotEmpty) {')
      ..add(
        '  return BoundaryErr<$patchName>('
        "targetType: '$patchName', violations: violations);",
      )
      ..add('}')
      ..add('return BoundaryOk<$patchName>($patchName($args));');
    m.body = Code(lines.join('\n'));
  });

  /// The decode expression for one field's wire value.
  ///
  /// Every arm answers a `PatchValue<T>?`: `PatchValue.set(<decoded>)` on a
  /// clean read, `null` when the read recorded a violation.
  String _wireDecodeExpression(
    NameTypeClassComment field,
    String value, {
    required String nome,
  }) {
    final declared = _concreteType(field.type);
    final bare = declared.replaceAll('?', '').trim();
    final path = _literal('/$nome');
    final String read;
    if (field.isEnum) {
      read =
          'ZorphyPatchWire.enumByName<$bare>('
          '$bare.values, $value, $path, violations)';
    } else if (bare == 'DateTime') {
      read = 'ZorphyPatchWire.asDateTime($value, $path, violations)';
    } else if (bare == 'double' || bare == 'num') {
      read = 'ZorphyPatchWire.asDouble($value, $path, violations)';
    } else {
      read = 'ZorphyPatchWire.as<$declared>($value, $path, violations)';
    }
    // A local is what promotes: `switch` over a nullable result does not
    // narrow the binder itself, and `PatchValue.set` needs the non-null value.
    final local = '${nome}Decoded';
    return '(() { final $local = $read; '
        'return $local == null '
        '? null '
        ': PatchValue<$declared>.set($local); })()';
  }

  /// `toEnvelope()` — the polymorphic envelope a concrete patch travels in.
  ///
  /// `entityType` names the ENTITY the ops belong to and `patchKind` names the
  /// discriminator a receiver dispatches on: `shared` for the hierarchy-wide
  /// patch, the subtype name for a narrowing one. The two differ on purpose —
  /// a subtype patch is still about that subtype's entity, while `shared` is
  /// the only kind that is not an entity name.
  Method _concreteToEnvelopeMethod({
    required String entityType,
    required List<NameTypeClassComment> fields,
    required String patchKind,
  }) => Method((m) {
    m
      ..name = 'toEnvelope'
      ..returns = referType('Map<String, Object?>');
    m.body = Code(
      'return <String, Object?>{'
      "'$_entityTypeKey': '$entityType', "
      "'$_patchKindKey': '$patchKind', "
      "'$_opsKey': toWire(),"
      '};',
    );
  });

  static String _literal(String value) =>
      "'${value.replaceAll('\\', '\\\\').replaceAll("'", "\\'")}'";

  /// The envelope key naming the entity (or hierarchy root) type.
  static const String _entityTypeKey = 'entityType';

  /// The envelope key naming which patch class the ops belong to.
  static const String _patchKindKey = 'patchKind';

  /// The envelope key carrying a patch's own `toWire()` map.
  static const String _opsKey = 'ops';

  static void _requireSubtypes(List<String> subtypeNames) {
    if (subtypeNames.isEmpty) {
      throw ArgumentError.value(
        subtypeNames,
        'subtypeNames',
        'a polymorphic root patch needs at least one concrete subtype to '
            'dispatch to — a root with none can never be applied',
      );
    }
  }

  static String _clean(String name) => name.replaceAll(r'$', '');

  static String _memberName(String name) =>
      name.startsWith('_') ? name.substring(1) : name;
}
