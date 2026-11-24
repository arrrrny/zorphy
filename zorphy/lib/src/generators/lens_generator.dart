import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates the compile-time lens surface for a Zorphy class (issue #185).
///
/// Two specs are produced:
///
/// 1. a `<Name>Lenses` accessor class holding one `ZorphyLens<Root, Field>`
///    getter per field, each pinned to the field's JSON-Pointer `path`, and
/// 2. a [ClassMemberCode] carrying the `static const <Name>Lenses lenses`
///    registry, which the orchestrator injects into the generated class
///    itself — so callers reach a lens as `<Name>.lenses.<field>`.
///
/// The emitted `set` routes through the class's own `copyWith`, which is why
/// the surface is gated on [GenerationConfig.generateCopyWith]: without it
/// there is no writer to route through, and a lens whose `set` cannot replace
/// its field would silently violate the get-put law. A NULLABLE field cannot be
/// cleared through `copyWith` (`field: field ?? this.field`), so — when
/// [GenerationConfig.generatePatch] is also on — its `set` routes an explicit
/// `null` through the generated Patch, whose `containsKey` gate can express it.
///
/// Static registries cannot be generic, and an abstract class has no
/// constructor to rebuild through, so both are skipped rather than emitted
/// half-working.
class LensGenerator extends ConcreteClassGenerator {
  /// Creates a lens-surface generator.
  LensGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    final metadata = context.metadata;
    return !metadata.isAbstract &&
        metadata.generics.isEmpty &&
        context.config.generateCopyWith &&
        _lensFields(metadata).isNotEmpty;
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    if (!shouldGenerate(context)) return [];

    final className = metadata.cleanName.replaceAll(r'$', '');
    // Concrete-only and non-generic by shouldGenerate, so this is the name the
    // generated class declares.
    final fields = _lensFields(metadata);

    final specs = <Spec>[
      _buildLensesClass(className, fields, context.config.generatePatch),
    ];

    // A model that declares its own `lenses` member cannot also carry the
    // static `lenses` registry (conflicting_static_and_instance), so the
    // registry moves to the first free name — or is skipped when a model
    // occupies every candidate, since an uncompilable part is worse than a
    // class without a registry (the `<Name>Lenses` accessor is still emitted
    // and reachable by constructor).
    final registryName = _registryFieldName(metadata);
    if (registryName != null) {
      specs.add(
        ClassMemberCode.field(
          Field((f) {
            f.name = registryName;
            f.static = true;
            f.modifier = FieldModifier.constant;
            f.type = referType('${className}Lenses');
            f.assignment = Code('${className}Lenses()');
          }),
        ),
      );
    }

    return specs;
  }

  /// The static registry field name, or `null` when no candidate is free.
  ///
  /// Prefers the documented `lenses`; a model that already declares a `lenses`
  /// member moves the registry to `lensesView` (then `$$lenses`). A model that
  /// occupies every candidate gets no registry at all rather than an
  /// uncompilable part.
  String? _registryFieldName(dynamic metadata) {
    final taken = <String>{
      for (final field in metadata.allFields)
        if (field.name != null) field.name as String,
      // A named constructor occupies the same namespace as a static member:
      // `@ZorphyNamedConstructor` on `lenses` would emit both
      // `Model.lenses(...)` and `static const lenses`, which Dart rejects
      // (`conflicting_static_and_instance`) even though no field holds the
      // name (CodeRabbit finding on lens_generator.dart:89).
      for (final constructor in metadata.namedConstructors)
        if ((constructor.name as String).isNotEmpty) constructor.name as String,
    };
    for (final candidate in const ['lenses', 'lensesView', r'$$lenses']) {
      if (!taken.contains(candidate)) return candidate;
    }
    return null;
  }

  /// The writable fields of this class, deduplicated by name.
  ///
  /// Getter-only fields are dropped: they have no storage to replace, so
  /// `copyWith` cannot accept them and the lens `set` would not compile.
  List<_LensField> _lensFields(dynamic metadata) {
    final seen = <String>{};
    final fields = <_LensField>[];
    for (final field in metadata.allFields) {
      if (field.isGetterOnly) continue;
      if (!seen.add(field.name)) continue;
      fields.add(
        _LensField(
          name: field.name,
          type: helpers.replaceDollarTypesWithConcrete(field.type ?? 'dynamic'),
        ),
      );
    }
    return fields;
  }

  Class _buildLensesClass(
    String className,
    List<_LensField> fields,
    bool generatePatch,
  ) {
    // Helper method names must be unique across the whole generated class —
    // including the public field getters — or two fields that differ only in
    // their first letter (`title` / `Title`) would both map to `_getTitle` /
    // `_setTitle` and emit duplicate static methods that do not compile.
    final usedNames = <String>{for (final field in fields) field.name};

    return Class((c) {
      c.name = '${className}Lenses';
      c.modifier = ClassModifier.final$;
      c.docs.add(
        '/// Typed lenses over [$className] — one per writable field.',
      );
      c.docs.add('///');
      c.docs.add('/// Compose with `then` to reach a nested value:');
      c.docs.add(
        '/// `$className.lenses.<field>.then(<Nested>.lenses.<leaf>)`.',
      );

      c.constructors.add(
        Constructor((con) {
          con.constant = true;
        }),
      );

      for (final field in fields) {
        final lensType = 'ZorphyLens<$className, ${field.type}>';
        final getter = _uniqueHelperName('get', field.name, usedNames);
        final setter = _uniqueHelperName('set', field.name, usedNames);

        c.methods.add(
          Method((m) {
            m.name = field.name;
            m.type = MethodType.getter;
            m.returns = referType(lensType);
            m.lambda = true;
            m.body = Code(
              'const $lensType('
              "path: '/${field.name}', "
              'get: $getter, set: $setter)',
            );
          }),
        );

        c.methods.add(
          Method((m) {
            m.name = getter;
            m.static = true;
            m.returns = referType(field.type);
            m.requiredParameters.add(
              Parameter((p) {
                p.name = 'root';
                p.type = referType(className);
              }),
            );
            m.lambda = true;
            m.body = Code('root.${field.name}');
          }),
        );

        c.methods.add(
          Method((m) {
            m.name = setter;
            m.static = true;
            m.returns = referType(className);
            m.requiredParameters.add(
              Parameter((p) {
                p.name = 'root';
                p.type = referType(className);
              }),
            );
            m.requiredParameters.add(
              Parameter((p) {
                p.name = 'value';
                p.type = referType(field.type);
              }),
            );
            // A nullable field's write must be null-capable: `copyWith` is
            // `field: field ?? this.field`, so it silently drops an explicit
            // null and breaks the put-get law documented on [ZorphyLens]. Route
            // the null through the generated Patch, whose `containsKey` gate can
            // express it (mirrors JsonPointerGenerator._setter). Gated on
            // generatePatch — without a Patch there is no null-capable writer.
            //
            // `dynamic` is included: it accepts `null` as a value, so a lens
            // typed `dynamic` must be able to clear it — the bare `?` test
            // excluded it and left `set(root, null)` silently keeping the old
            // value (CodeRabbit finding on lens_generator.dart:203).
            final hasNullBranch =
                (field.type.endsWith('?') || field.type.trim() == 'dynamic') &&
                generatePatch;
            if (hasNullBranch) {
              m.lambda = false;
              m.body = Code(
                'if (value == null) {\n'
                '  return root.patchWith$className('
                '${className}Patch()..with${_pascal(field.name)}(null));\n'
                '}\n'
                'return root.copyWith(${field.name}: value);',
              );
            } else {
              m.lambda = true;
              m.body = Code('root.copyWith(${field.name}: value)');
            }
          }),
        );
      }
    });
  }

  /// A static helper name (`_get<X>` / `_set<X>`) that no member of the
  /// generated class already uses, registered in [used] as it is allocated.
  String _uniqueHelperName(String prefix, String fieldName, Set<String> used) {
    var candidate = '_$prefix${_pascal(fieldName)}';
    while (used.contains(candidate)) {
      candidate = '_$candidate';
    }
    used.add(candidate);
    return candidate;
  }

  /// Upper-cases the first character so a field `editDraft` becomes the
  /// helper name `_getEditDraft`.
  String _pascal(String name) =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

/// One writable field, as the lens surface needs it.
class _LensField {
  /// The field name (also its JSON-Pointer path segment).
  final String name;

  /// The field's declared type, `$`-stripped and ready for emission.
  final String type;

  const _LensField({required this.name, required this.type});
}
