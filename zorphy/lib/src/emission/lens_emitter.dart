/// IR-native typed-lens surface for the v3 archetypes (ISSUE-0230,
/// arrrrny/zorphy#230).
///
/// The legacy [LensGenerator] (`generators/lens_generator.dart`) produces the
/// same surface but consumes the analyzer's `ClassMetadata`/`GenerationContext`,
/// which the v3 production path (`PolymorphicIr` -> [ArchetypeComposer]) never
/// builds. This emitter is the IR-native twin: it reads a [ZorphyNodeIr] and
/// emits, for every non-generic CONCRETE node (a leaf, or a standalone root
/// that is its own leaf):
///
/// 1. a top-level `final class <Name>Lenses` with one
///    `ZorphyLens<<Name>, Field>` getter per writable field, each pinned to the
///    field's JSON-Pointer `path`, and
/// 2. the `static const <Name>Lenses lenses` registry field the composer splices
///    INTO the generated class — so a caller reaches a lens as
///    `<Name>.lenses.<field>`.
///
/// The emitted `set` routes through the class's own `copyWith`. A v3 concrete
/// class ALWAYS carries one, and its nullable parameters default to the
/// library `_sentinel`, so `copyWith(field: null)` CLEARS the field — the
/// get-put/put-get laws [ZorphyLens] documents hold for nullable fields too,
/// with no Patch round-trip (the legacy generator needs one because its
/// `copyWith` is `field ?? this.field`).
///
/// A sealed root is abstract and has no `copyWith` to rebuild through, so it
/// gets no registry — the same decline the legacy generator makes for an
/// abstract class. Its CONCRETE leaves each carry their own.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/type_ref.dart';
import '../parser/polymorphic_ir.dart';
import 'emission_name_helpers.dart';

/// Emits the v3 `<Name>Lenses` accessor classes and their registry fields.
final class LensEmitter {
  /// Creates a lens emitter.
  const LensEmitter();

  /// The `static const <Name>Lenses lenses` registry field for every concrete,
  /// non-generic node, keyed by `className` (`$Product`) — the shape
  /// [PolymorphicClassEmitter.extraMethods]'s sibling expects.
  ///
  /// A node whose model already declares a member named `lenses` moves the
  /// registry to `lensesView` (then `$$lenses`); a node occupying every
  /// candidate gets no registry rather than an uncompilable class.
  Map<String, Field> registryFields(PolymorphicIr ir) {
    final result = <String, Field>{};
    for (final node in ir.nodes.values) {
      if (!_emittable(node)) continue;
      // A node with no writable field gets no `<Name>Lenses` class, so it must
      // get no registry referencing one (an undefined class otherwise).
      if (_writableFields(node).isEmpty) continue;
      final registryName = _registryFieldName(node);
      if (registryName == null) continue;
      final name = node.cleanName;
      result[node.className] = Field((f) {
        f.name = registryName;
        f.static = true;
        f.modifier = FieldModifier.constant;
        f.type = referType('${name}Lenses');
        f.assignment = Code('${name}Lenses()');
      });
    }
    return result;
  }

  /// The top-level `<Name>Lenses` accessor class for every concrete, non-generic
  /// node, as specs the composer appends to the library fragment.
  List<Spec> lensClasses(PolymorphicIr ir) {
    final specs = <Spec>[];
    for (final node in ir.nodes.values) {
      if (!_emittable(node)) continue;
      final fields = _writableFields(node);
      if (fields.isEmpty) continue;
      specs.add(_buildLensesClass(node.cleanName, fields));
    }
    return specs;
  }

  /// A node is emittable when it is a concrete, non-generic, non-intent value
  /// the caller can instantiate and rebuild through `copyWith`. Intents are
  /// emitted by `IntentEmitter` and carry no `copyWith`, so a lens over one
  /// would reference a member that does not exist.
  bool _emittable(ZorphyNodeIr node) =>
      node.archetype != ArchetypeKind.intent &&
      node.isConcreteLeaf &&
      node.typeParameters.isEmpty;

  /// The node's whole writable payload — own fields first, then each ancestor's,
  /// the first declaration of a name winning (a covariant redeclaration keeps
  /// the leaf's narrowed type).
  List<_LensField> _writableFields(ZorphyNodeIr node) {
    final seen = <String>{};
    final fields = <_LensField>[];
    for (final owner in <ZorphyNodeIr>[node, ...node.superTypes]) {
      for (final field in owner.fields) {
        if (!seen.add(field.name)) continue;
        fields.add(
          _LensField(
            name: field.name,
            type: concreteTypeName(
              field.isNullable ? '${field.type}?' : field.type,
            ),
          ),
        );
      }
    }
    return fields;
  }

  /// The static registry field name, or `null` when no candidate is free.
  String? _registryFieldName(ZorphyNodeIr node) {
    final taken = <String>{
      for (final owner in <ZorphyNodeIr>[node, ...node.superTypes])
        for (final field in owner.fields) field.name,
    };
    for (final candidate in const ['lenses', 'lensesView', r'$$lenses']) {
      if (!taken.contains(candidate)) return candidate;
    }
    return null;
  }

  Class _buildLensesClass(String className, List<_LensField> fields) {
    // Helper method names must be unique across the whole generated class —
    // including the public field getters — or two fields that differ only in
    // their first letter (`title` / `Title`) would emit duplicate `_getTitle` /
    // `_setTitle` statics that do not compile.
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
            // v3 `copyWith` defaults a nullable parameter to the library
            // sentinel, so an explicit `null` reaches the field and CLEARS it —
            // no Patch round-trip, and the lens laws hold for nullable fields.
            m.lambda = true;
            m.body = Code('root.copyWith(${field.name}: value)');
          }),
        );
      }
    });
  }

  /// A static helper name (`_get<X>` / `_set<X>`) no member already uses,
  /// registered in [used] as it is allocated.
  String _uniqueHelperName(String prefix, String fieldName, Set<String> used) {
    var candidate = '_$prefix${pascalCase(fieldName)}';
    while (used.contains(candidate)) {
      candidate = '_$candidate';
    }
    used.add(candidate);
    return candidate;
  }
}

/// One writable field, as the lens surface needs it.
final class _LensField {
  /// The field name (also its JSON-Pointer path segment).
  final String name;

  /// The field's declared type, `$`-stripped and ready for emission.
  final String type;

  const _LensField({required this.name, required this.type});
}
