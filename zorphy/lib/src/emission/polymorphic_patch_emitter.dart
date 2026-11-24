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
