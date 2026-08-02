import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import 'base_generator.dart';

/// Generates the static Fields class containing Field descriptors for the entity.
///
/// Produces a native [Class] spec.
class FieldsClassGenerator extends UniversalGenerator {
  FieldsClassGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateFilter &&
        context.metadata.allFields.isNotEmpty;
  }

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
      c.modifier = ClassModifier.final$;
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
            m.name = '_\$$fieldName';
            m.static = true;
            for (final g in metadata.generics) {
              m.types.add(TypeReference((t) {
                t.symbol = g.name;
                if (g.bound != null) {
                  t.bound = referType(g.bound);
                }
              }));
            }
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
            for (final g in metadata.generics) {
              m.types.add(TypeReference((t) {
                t.symbol = g.name;
                if (g.bound != null) {
                  t.bound = referType(g.bound);
                }
              }));
            }
            m.returns = referType('Field<$classType, $fieldType>');
            m.body = Code(
              "return Field<$classType, $fieldType>('$fieldName', _\$$fieldName$genericsArgsStr);",
            );
          }));
        } else {
          c.methods.add(Method((m) {
            m.name = '_\$$fieldName';
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
            f.modifier = FieldModifier.constant;
            f.assignment = Code("Field<$className, $fieldType>('$fieldName', _\$$fieldName)");
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