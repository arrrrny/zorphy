/// IR-native `ZorphyEntityDescriptor<T>` emitter for the v3 archetypes
/// (issue #251 / ZRP-003).
///
/// A generic container (`ZfaStore`, `ZfaDocument<T>`) needs an entity's
/// principal key, fields, diff, patch and wire codec at runtime, but Dart AOT
/// has no `dart:mirrors` — the type alone cannot yield them. This emitter
/// closes that gap the same way [LensEmitter] closes the lens gap: it reads the
/// resolved [PolymorphicIr] and emits, for every emittable `@ZorphyEntity`
/// node,
///
/// 1. a `static const <Entity>descriptor = _<Entity>Descriptor();` field spliced
///    INTO the generated class (through [PolymorphicClassEmitter]'s
///    `extraFields` hook), and
/// 2. a top-level `final class _<Entity>Descriptor implements
///    ZorphyEntityDescriptor<<Entity>>` appended to the library fragment.
///
/// The descriptor is the first generic seam over two STATIC surfaces the
/// composer already emits: `fromWire` (a static on the entity) and `diff` (a
/// static on `<Entity>Patch`). The generated class closes over both, so a caller
/// holding only `ZorphyEntityDescriptor<T>` round-trips an entity it never names
/// concretely — no `runtimeType` switch, no reflective field lookup, valid
/// under AOT.
///
/// What is emitted per node is exactly what needs the concrete type:
/// `typeName`, `principalKeyField`, `fields`, `diff`, `applyPatch`, `toWire`,
/// `fromWire`. The rest of the interface (`principalKeyOf`, `fieldByPath`,
/// `conflictingPaths`, `composePatches`) has reflection-free DEFAULT
/// implementations over those, so the generated class stays minimal and the
/// contract lives in one place.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/type_ref.dart';
import '../parser/polymorphic_ir.dart';

/// Emits the v3 `ZorphyEntityDescriptor` surface for every emittable entity.
final class EntityDescriptorGenerator {
  /// Creates a descriptor generator over [ir], the whole library graph — a
  /// node's visible payload walks its ancestors, so the emitter needs every
  /// node, not just the one it is emitting.
  const EntityDescriptorGenerator(this.ir);

  /// The whole resolved library graph.
  final PolymorphicIr ir;

  /// The `static const <Entity>descriptor` field for every emittable entity,
  /// keyed by `className` (`$Product`) — the shape
  /// [PolymorphicClassEmitter]'s `extraFields` map takes.
  ///
  /// A node whose model already declares a member named `descriptor` moves the
  /// registry to `entityDescriptor` (then `$$descriptor`); a node occupying
  /// every candidate gets no descriptor rather than an uncompilable class.
  Map<String, Field> descriptorFields() {
    final result = <String, Field>{};
    for (final node in ir.nodes.values) {
      if (!_emittable(node)) continue;
      final fieldName = _descriptorFieldName(node);
      if (fieldName == null) continue;
      final name = node.cleanName;
      result[node.className] = Field((f) {
        f.name = fieldName;
        f.static = true;
        f.modifier = FieldModifier.constant;
        f.type = referType('ZorphyEntityDescriptor<$name>');
        f.assignment = Code('_${name}Descriptor._()');
      });
    }
    return result;
  }

  /// The top-level `_<Entity>Descriptor` class for every emittable entity, as
  /// specs the composer appends to the library fragment.
  List<Spec> descriptorClasses() {
    final specs = <Spec>[];
    for (final node in ir.nodes.values) {
      if (!_emittable(node)) continue;
      specs.add(_buildDescriptorClass(node));
    }
    return specs;
  }

  /// A node is emittable when it is a non-generic, non-intent entity ROOT — a
  /// standalone entity or a sealed hierarchy root — with a principal key.
  ///
  /// A root's patch is SELF-TYPED: `<Root>Patch implements ZorphyPatch<<Root>>`
  /// and its static `diff` returns `<Root>Patch`, so the descriptor's
  /// `diff`/`applyPatch` type-check at `ZorphyPatch<<Root>>`. A hierarchy LEAF's
  /// patch extends the root patch (`<Leaf>Patch extends <Root>Patch`), so it is
  /// a `ZorphyPatch<<Root>>`, NOT a `ZorphyPatch<<Leaf>>` — a leaf descriptor
  /// could not return one. An abstract intermediate's patch is a typedef with
  /// no reachable static `diff`. Both are excluded; a generic container is
  /// parameterised by the root type it stores anyway. Intents carry no patch.
  bool _emittable(ZorphyNodeIr node) =>
      node.archetype == ArchetypeKind.entity &&
      node.typeParameters.isEmpty &&
      node.superTypes.isEmpty &&
      node.principalKey != null;

  /// The node's whole visible payload — own fields first, then each ancestor's,
  /// the first declaration of a name winning (a covariant redeclaration keeps
  /// the leaf's narrowed type). Every entry names a real getter on [node], so
  /// the emitted extractor closures compile.
  List<_DescriptorField> _visibleFields(ZorphyNodeIr node) {
    final seen = <String>{};
    final fields = <_DescriptorField>[];
    for (final owner in <ZorphyNodeIr>[node, ...node.superTypes]) {
      for (final field in owner.fields) {
        if (!seen.add(field.name)) continue;
        fields.add(_DescriptorField(name: field.name));
      }
    }
    return fields;
  }

  /// The static descriptor field name, or `null` when no candidate is free.
  String? _descriptorFieldName(ZorphyNodeIr node) {
    final taken = <String>{
      for (final owner in <ZorphyNodeIr>[node, ...node.superTypes])
        for (final field in owner.fields) field.name,
    };
    for (final candidate in const [
      'descriptor',
      'entityDescriptor',
      r'$$descriptor',
    ]) {
      if (!taken.contains(candidate)) return candidate;
    }
    return null;
  }

  Class _buildDescriptorClass(ZorphyNodeIr node) {
    final name = node.cleanName;
    final principalKey = node.principalKey!;
    final fields = _visibleFields(node);

    final fieldsList =
        '[${fields.map((field) => "Field<$name, Object?>('${field.name}', "
            '(entity) => entity.${field.name})').join(', ')}]';

    return Class((c) {
      c.name = '_${name}Descriptor';
      c.modifier = ClassModifier.final$;
      c.implements.add(referType('ZorphyEntityDescriptor<$name>'));
      c.docs.add(
        '/// The reflection-free descriptor for [$name] (issue #251).',
      );
      c.constructors.add(
        Constructor((ctor) {
          ctor.name = '_';
          ctor.constant = true;
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'typeName'
            ..type = MethodType.getter
            ..returns = referType('String')
            ..body = Code("return '$name';");
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'principalKeyField'
            ..type = MethodType.getter
            ..returns = referType('Field<$name, Object?>')
            ..body = Code(
              "return Field<$name, Object?>('$principalKey', "
              '(entity) => entity.$principalKey);',
            );
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'fields'
            ..type = MethodType.getter
            ..returns = referType('List<Field<$name, Object?>>')
            ..body = Code('return $fieldsList;');
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'diff'
            ..returns = referType('ZorphyPatch<$name>')
            ..requiredParameters.addAll([
              Parameter(
                (p) => p
                  ..name = 'previous'
                  ..type = referType(name),
              ),
              Parameter(
                (p) => p
                  ..name = 'next'
                  ..type = referType(name),
              ),
            ])
            ..body = Code('return ${name}Patch.diff(previous, next);');
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'applyPatch'
            ..returns = referType(name)
            ..requiredParameters.addAll([
              Parameter(
                (p) => p
                  ..name = 'entity'
                  ..type = referType(name),
              ),
              Parameter(
                (p) => p
                  ..name = 'patch'
                  ..type = referType('ZorphyPatch<$name>'),
              ),
            ])
            ..body = Code('return patch.apply(entity);');
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'toWire'
            ..returns = referType('Map<String, Object?>')
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'entity'
                  ..type = referType(name),
              ),
            )
            ..body = Code('return entity.toWire();');
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'fromWire'
            ..returns = referType('ZorphyBoundaryResult<$name>')
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'raw'
                  ..type = referType('Map<String, Object?>'),
              ),
            )
            ..body = Code('return $name.fromWire(raw);');
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'principalKeyOf'
            ..returns = referType('Object')
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'entity'
                  ..type = referType(name),
              ),
            )
            ..body = Code('return entity.$principalKey;');
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'fieldByPath'
            ..returns = referType('Field<$name, Object?>?')
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'jsonPointer'
                  ..type = refer('String'),
              ),
            )
            ..body = Code(
              "final name = jsonPointer.startsWith('/') "
              '? jsonPointer.substring(1) : jsonPointer;\n'
              'for (final field in fields) {\n'
              '  if (field.name == name) return field;\n'
              '}\n'
              'return null;',
            );
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'conflictingPaths'
            ..returns = referType('Set<String>')
            ..requiredParameters.addAll([
              Parameter(
                (p) => p
                  ..name = 'a'
                  ..type = referType('ZorphyPatch<$name>'),
              ),
              Parameter(
                (p) => p
                  ..name = 'b'
                  ..type = referType('ZorphyPatch<$name>'),
              ),
            ])
            ..body = Code(
              'final mine = a.toWire().keys.toSet();\n'
              'final theirs = b.toWire().keys.toSet();\n'
              "return <String>{for (final key in mine.intersection(theirs)) "
              "'/\$key'};",
            );
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'composePatches'
            ..returns = referType('ZorphyPatch<$name>')
            ..requiredParameters.addAll([
              Parameter(
                (p) => p
                  ..name = 'base'
                  ..type = referType('ZorphyPatch<$name>'),
              ),
              Parameter(
                (p) => p
                  ..name = 'next'
                  ..type = referType('ZorphyPatch<$name>'),
              ),
            ])
            ..body = Code('return base.compose(next);');
        }),
      );
    });
  }
}

/// One visible field of the emitting node — only its name is needed, since the
/// extractor closure reads `entity.<name>` and the field is widened to
/// `Object?`.
final class _DescriptorField {
  final String name;

  const _DescriptorField({required this.name});
}
