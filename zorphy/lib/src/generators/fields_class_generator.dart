import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import 'base_generator.dart';

/// Generates the static Fields class containing Field descriptors for the entity
///
/// Migrated (T016): [generateSpec] now produces native [Class] spec
/// instead of building strings via StringBuffer.
class FieldsClassGenerator extends UniversalGenerator implements SpecGenerator {
  FieldsClassGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final className = metadata.cleanName;
    if (metadata.allFields.isEmpty) return '';

    final hasGenerics = metadata.generics.isNotEmpty;
    final genericsArgsStr = hasGenerics
        ? '<${metadata.generics.map((g) => g.name).join(', ')}>'
        : '';
    final genericsDefStr = hasGenerics
        ? '<${metadata.generics.map((g) => g.bound != null ? '${g.name} extends ${g.bound}' : g.name).join(', ')}>'
        : '';
    final classType = '$className$genericsArgsStr';

    final sb = StringBuffer();
    sb.writeln('');
    sb.writeln('/// Field descriptors for [$className] query construction');
    sb.writeln('abstract final class ${className}Fields {');

    for (final field in metadata.allFields) {
      final fieldName = field.name;
      var fieldType = field.type ?? 'dynamic';
      fieldType = _cleanType(fieldType);

      if (hasGenerics) {
        sb.writeln(
          '  static $fieldType _\$get$fieldName$genericsDefStr($classType e) => e.$fieldName;',
        );
        sb.writeln(
          '  static Field<$classType, $fieldType> $fieldName$genericsDefStr() => Field<$classType, $fieldType>(\'$fieldName\', _\$get$fieldName$genericsArgsStr);',
        );
      } else {
        sb.writeln(
          '  static $fieldType _\$get$fieldName($className e) => e.$fieldName;',
        );
        sb.writeln(
          "  static const $fieldName = Field<$className, $fieldType>('\$fieldName', _\$get$fieldName);",
        );
      }
    }

    sb.writeln('}');
    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateFilter &&
        context.metadata.allFields.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPEC PIPELINE (T016)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  List<Spec> generateSpec(GenerationContext context) {
    if (context.metadata.allFields.isEmpty) return [];
    return [_buildFieldsClassSpec(context.metadata)];
  }

  Class _buildFieldsClassSpec(dynamic metadata) {
    final className = metadata.cleanName;
    final hasGenerics = metadata.generics.isNotEmpty;
    final genericsArgsStr = hasGenerics
        ? '<${metadata.generics.map((g) => g.name).join(', ')}>'
        : '';
    final classType = '$className$genericsArgsStr';

    return Class((c) {
      c.name = '${className}Fields';
      c.abstract = true;
      c.docs.add('Field descriptors for [$className] query construction');

      for (final g in metadata.generics) {
        c.types.add(referType(
          g.bound != null ? '${g.name} extends ${g.bound}' : g.name,
        ));
      }

      for (final field in metadata.allFields) {
        final fieldName = field.name;
        var fieldType = field.type ?? 'dynamic';
        fieldType = _cleanType(fieldType);

        if (hasGenerics) {
          c.methods.add(Method((m) {
            m.name = '_\$get$fieldName';
            m.static = true;
            m.returns = referType(fieldType);
            m.requiredParameters.add(Parameter((p) {
              p.name = 'e';
              p.type = referType(classType);
            }));
            m.body = Code('return e.$fieldName;');
          }));
          c.methods.add(Method((m) {
            m.name = fieldName;
            m.static = true;
            m.returns = referType('Field<$classType, $fieldType>');
            m.body = Code(
              "return Field<$classType, $fieldType>('$fieldName', _\$get$fieldName$genericsArgsStr);",
            );
          }));
        } else {
          c.methods.add(Method((m) {
            m.name = '_\$get$fieldName';
            m.static = true;
            m.returns = referType(fieldType);
            m.requiredParameters.add(Parameter((p) {
              p.name = 'e';
              p.type = referType(className);
            }));
            m.body = Code('return e.$fieldName;');
          }));
          c.fields.add(Field((f) {
            f.name = fieldName;
            f.type = referType('Field<$className, $fieldType>');
            f.modifier = FieldModifier.constant;
            f.assignment = Code("Field('$fieldName', _\$get$fieldName)");
          }));
        }
      }
    });
  }

  String _cleanType(String type) {
    if (type.contains('<')) {
      if (!type.contains('.')) return type.replaceAll(r'\$', '');
      return type
          .split('.')
          .map((part) {
            if (part.contains('<')) {
              final base = part.substring(0, part.indexOf('<'));
              final rest = part.substring(part.indexOf('<'));
              return base.replaceAll(r'\$', '') + rest.replaceAll(r'\$', '');
            }
            return part.replaceAll(r'\$', '');
          })
          .join('.');
    }
    if (type.contains('.')) {
      final lastDot = type.lastIndexOf('.');
      final prefix = type.substring(0, lastDot + 1);
      final name = type.substring(lastDot + 1);
      return prefix + name.replaceAll(r'\$', '');
    }
    return type.replaceAll(r'\$', '');
  }
}
