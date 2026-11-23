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
/// its field would silently violate the get-put law.
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

    return [
      _buildLensesClass(className, fields),
      ClassMemberCode.field(
        Field((f) {
          f.name = 'lenses';
          f.static = true;
          f.modifier = FieldModifier.constant;
          f.type = referType('${className}Lenses');
          f.assignment = Code('${className}Lenses()');
        }),
      ),
    ];
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

  Class _buildLensesClass(String className, List<_LensField> fields) {
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
        final getter = '_get${_pascal(field.name)}';
        final setter = '_set${_pascal(field.name)}';

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
            m.lambda = true;
            m.body = Code('root.copyWith(${field.name}: value)');
          }),
        );
      }
    });
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
