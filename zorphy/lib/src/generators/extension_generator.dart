import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates compareTo extension method.
///
/// Produces a native [Extension] spec.
class CompareToExtensionGenerator extends ConcreteClassGenerator {
  CompareToExtensionGenerator();

  @override
  bool shouldGenerate(GenerationContext context) =>
      context.config.generateCompareTo;

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    return [_buildCompareToExtension(metadata.cleanName, metadata.allFields)];
  }

  Extension _buildCompareToExtension(String classNameTrimmed, List<dynamic> allFields) {
    final body = <String>[];
    body.add('final Map<String, dynamic> diff = {};');
    for (final field in allFields) {
      final fieldType = field.type ?? '';
      final fieldName = field.name;
      if (fieldType.contains('Function')) continue;
      body.add('');
      body.add("if ($fieldName != other.$fieldName) {");
      body.add("  diff['$fieldName'] = () => other.$fieldName;");
      body.add('}');
    }
    body.add('return diff;');
    return Extension((e) {
      e.name = '${classNameTrimmed}CompareE';
      e.on = referType(classNameTrimmed);
      e.methods.add(Method((m) {
        m.name = 'compareTo${classNameTrimmed}';
        m.returns = referType('Map<String, dynamic>');
        m.requiredParameters.add(Parameter((p) {
          p.name = 'other';
          p.type = referType(classNameTrimmed);
        }));
        m.body = Code(body.join('\n'));
      }));
    });
  }
}

/// Generates changeTo extension methods for explicit subtypes.
///
/// Produces a native [Extension] spec.
class ChangeToExtensionGenerator extends UniversalGenerator {
  ChangeToExtensionGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateChangeTo &&
        context.metadata.explicitSubtypes.isNotEmpty;
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    if (metadata.explicitSubtypes.isEmpty) return [];
    final knownClasses = metadata.allAnnotatedClasses.keys
        .map((k) => k.replaceAll(r'\$', ''))
        .toList();
    return [_buildChangeToExtension(
      sourceFields: metadata.allFields,
      sourceClassName: metadata.cleanName,
      explicitSubTypes: metadata.explicitSubtypes,
      knownClasses: knownClasses,
    )];
  }

  Extension _buildChangeToExtension({
    required List<dynamic> sourceFields,
    required String sourceClassName,
    required List<dynamic> explicitSubTypes,
    required List<String> knownClasses,
  }) {
    final sourceClassNameTrimmed = sourceClassName.replaceAll(r'\$', '');
    final methods = <Method>[];

    for (final targetInterface in explicitSubTypes) {
      final targetClassName = targetInterface.interfaceName.replaceAll(r'\$', '');
      final targetFields = targetInterface.fields;
      final targetFieldsDistinct = <dynamic>[];
      final targetFieldNames = <String>{};
      for (final field in targetFields) {
        if (targetFieldNames.add(field.name)) targetFieldsDistinct.add(field);
      }

      final sourceFieldMap = {for (final f in sourceFields) f.name: f};
      final params = <Parameter>[];
      final setFieldNames = <String, bool>{};

      for (final field in targetFieldsDistinct) {
        final fieldName = field.name;
        final fieldType = helpers.replaceDollarTypesWithConcrete(field.type ?? '');
        final isTargetNullable = fieldType.endsWith('?');
        final existsInSource = sourceFieldMap.containsKey(fieldName);

        if (existsInSource) {
          final sourceField = sourceFieldMap[fieldName]!;
          final sourceFieldType = helpers.replaceDollarTypesWithConcrete(
            sourceField.type ?? '',
          );
          final isSourceNullable = sourceFieldType.endsWith('?');

          if (isSourceNullable && !isTargetNullable) {
            params.add(Parameter((p) {
              p.name = fieldName;
              p.type = referType(fieldType);
              p.required = true;
              p.named = true;
            }));
            setFieldNames[fieldName] = true;
          } else if (isTargetNullable) {
            params.add(Parameter((p) {
              p.name = fieldName;
              p.type = referType(fieldType);
              p.named = true;
            }));
            setFieldNames[fieldName] = false;
          } else {
            params.add(Parameter((p) {
              p.name = fieldName;
              p.type = referType('${fieldType}?');
              p.named = true;
            }));
            setFieldNames[fieldName] = false;
          }
        } else {
          if (isTargetNullable) {
            params.add(Parameter((p) {
              p.name = fieldName;
              p.type = referType(fieldType);
              p.named = true;
            }));
            setFieldNames[fieldName] = false;
          } else {
            params.add(Parameter((p) {
              p.name = fieldName;
              p.type = referType(fieldType);
              p.required = true;
              p.named = true;
            }));
            setFieldNames[fieldName] = true;
          }
        }
      }

      final body = <String>[];
      body.add('final _patcher = ${targetClassName}Patch();');

      for (final field in targetFieldsDistinct) {
        final fieldName = field.name;
        final fieldNameCap =
            fieldName[0].toUpperCase() + fieldName.substring(1);
        final isRequired = setFieldNames[fieldName] ?? false;

        if (isRequired) {
          body.add('_patcher.with$fieldNameCap($fieldName);');
        } else {
          body.add('if ($fieldName != null) {');
          body.add('  _patcher.with$fieldNameCap($fieldName);');
          body.add('}');
        }
      }

      body.add(
        "final _json = Map<String, dynamic>.from((this as dynamic).toJson());",
      );
      body.add('_json.addAll(_patcher.toJson());');
      body.add('return $targetClassName.fromJson(_json);');

      methods.add(Method((m) {
        m.name = 'changeTo$targetClassName';
        m.returns = referType(targetClassName);
        m.optionalParameters.addAll(params);
        m.body = Code(body.join('\n'));
      }));
    }

    return Extension((e) {
      e.name = '${sourceClassNameTrimmed}ChangeToE';
      e.on = referType(sourceClassNameTrimmed);
      e.methods.addAll(methods);
    });
  }
}
