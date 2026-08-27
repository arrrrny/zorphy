import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates patchWith methods as native [Method] specs.
///
/// Previously returned [Code] strings which leaked to top-level.
class PatchGenerator extends ConcreteClassGenerator {
  PatchGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    if (!context.config.generatePatch) return false;
    // NonSealed abstract bases need Patch because parent entities
    // reference them in their own Patch generation (withXxxPatch methods).
    if (context.metadata.isAbstract && !context.metadata.nonSealed)
      return false;
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.isInParentExplicitSubtypes;
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;
    final classNameTrimmed = metadata.cleanName.replaceAll(r'$', '');
    final specs = <Spec>[];

    // Main patchWith method — skip for nonSealed abstract bases (can't instantiate).
    final fields = metadata.allFields;
    if (metadata.isAbstract && metadata.nonSealed) {
      // Abstract nonSealed base: no patchWith or applyTo needed. Interface
      // patchWith methods would construct this class, which is impossible —
      // return before the interface loop.
      return specs;
    }
    if (fields.isEmpty) {
      // Fieldless class: identity patchWith
      specs.add(
        Method((m) {
          m.name = 'patchWith$classNameTrimmed';
          m.returns = referType(classNameTrimmed);
          m.optionalParameters.add(
            Parameter((p) {
              p.name = 'patchInput';
              p.type = referType('${classNameTrimmed}Patch?');
            }),
          );
          m.lambda = true;
          m.body = Code('this');
        }),
      );
    } else {
      specs.add(
        _buildPatchWithMethod(
          methodName: 'patchWith$classNameTrimmed',
          patchTypeName: '${classNameTrimmed}Patch',
          fields: fields,
          classNameTrimmed: classNameTrimmed,
          enumName: '${classNameTrimmed}\$',
          constructorSuffix: config.hidePublicConstructor ? '._' : '',
        ),
      );
    }

    // Interface patchWith methods
    final classFieldNames = fields.map((f) => f.name).toSet();
    for (final iface in metadata.interfaces) {
      final interfaceName = iface.interfaceName;
      if (!interfaceName.startsWith('\$') || interfaceName.startsWith('\$\$')) {
        continue;
      }
      final interfaceNameTrimmed = interfaceName.replaceAll('\$', '');
      if (interfaceNameTrimmed == classNameTrimmed) continue;

      final seenFields = <String>{};
      final interfaceFields = iface.fields.where((f) {
        if (classFieldNames.contains(f.name) && !seenFields.contains(f.name)) {
          seenFields.add(f.name);
          return true;
        }
        return false;
      }).toList();
      if (interfaceFields.isEmpty) continue;

      final interfaceFieldNames = interfaceFields.map((f) => f.name).toSet();
      final enumName = '${interfaceNameTrimmed}\$';

      // Build body with interface fields patched, class fields passed through
      final bodyLines = <String>[];
      bodyLines.add(
        "final _patcher = patchInput ?? ${interfaceNameTrimmed}Patch();",
      );
      bodyLines.add('final _patchMap = _patcher.patchMap;');
      final constructorSuffix = config.hidePublicConstructor ? '._' : '';
      bodyLines.add('return $classNameTrimmed$constructorSuffix(');

      for (var i = 0; i < fields.length; i++) {
        final f = fields[i];
        final comma = i == fields.length - 1 ? '' : ',';
        if (interfaceFieldNames.contains(f.name)) {
          bodyLines.add(
            "${f.name}: _patchMap.containsKey($enumName.${helpers.enumMemberName(f.name)}) ? ( (_patchMap[$enumName.${helpers.enumMemberName(f.name)}] is Function) ? _patchMap[$enumName.${helpers.enumMemberName(f.name)}](this.${f.name}) : (_patchMap[$enumName.${helpers.enumMemberName(f.name)}] is Patch) ? _patchMap[$enumName.${helpers.enumMemberName(f.name)}].applyTo(this.${f.name}) : _patchMap[$enumName.${helpers.enumMemberName(f.name)}] ) as ${f.type!.replaceAll(r'$', '')} : this.${f.name}$comma",
          );
        } else {
          bodyLines.add('${f.name}: this.${f.name},');
        }
      }

      bodyLines.add(');');

      specs.add(
        Method((m) {
          m.name = 'patchWith$interfaceNameTrimmed';
          m.returns = referType(classNameTrimmed);
          m.optionalParameters.add(
            Parameter((p) {
              p.name = 'patchInput';
              p.type = referType('${interfaceNameTrimmed}Patch?');
            }),
          );
          m.body = Code(bodyLines.join('\n'));
        }),
      );
    }

    return specs;
  }

  Method _buildPatchWithMethod({
    required String methodName,
    required String patchTypeName,
    required List<dynamic> fields,
    required String classNameTrimmed,
    required String enumName,
    required String constructorSuffix,
  }) {
    final bodyLines = <String>[];
    bodyLines.add('final _patcher = patchInput ?? $patchTypeName();');
    bodyLines.add('final _patchMap = _patcher.patchMap;');
    bodyLines.add('return $classNameTrimmed$constructorSuffix(');

    for (var i = 0; i < fields.length; i++) {
      final f = fields[i];
      final comma = i == fields.length - 1 ? '' : ',';
      bodyLines.add(
        "${f.name}: _patchMap.containsKey($enumName.${helpers.enumMemberName(f.name)}) ? ( (_patchMap[$enumName.${helpers.enumMemberName(f.name)}] is Function) ? _patchMap[$enumName.${helpers.enumMemberName(f.name)}](this.${f.name}) : (_patchMap[$enumName.${helpers.enumMemberName(f.name)}] is Patch) ? _patchMap[$enumName.${helpers.enumMemberName(f.name)}].applyTo(this.${f.name}) : _patchMap[$enumName.${helpers.enumMemberName(f.name)}] ) as ${f.type!.replaceAll(r'$', '')} : this.${f.name}$comma",
      );
    }

    bodyLines.add(');');

    return Method((m) {
      m.name = methodName;
      m.returns = referType(classNameTrimmed);
      m.optionalParameters.add(
        Parameter((p) {
          p.name = 'patchInput';
          p.type = referType('$patchTypeName?');
        }),
      );
      m.body = Code(bodyLines.join('\n'));
    });
  }
}

/// Generates the Patch class for a class.
///
/// Produces [Code] specs wrapping the string-based helper output.
class PatchClassGenerator extends ConcreteClassGenerator {
  PatchClassGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    if (!context.config.generatePatch) return false;
    // NonSealed abstract bases need Patch because parent entities
    // reference them in their own Patch generation (withXxxPatch methods).
    if (context.metadata.isAbstract && !context.metadata.nonSealed)
      return false;
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.isInParentExplicitSubtypes;
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final knownClasses = metadata.allAnnotatedClasses.keys
        .map((k) => k.replaceAll(r'$', ''))
        .toList();
    final genericTypeNames = metadata.generics.map((g) => g.name).toList();

    // Abstract nonSealed bases: emit minimal abstract Patch stub (data holder
    // only, no applyTo). The full Patch with applyTo is for concrete classes.
    if (metadata.isAbstract && metadata.nonSealed) {
      final cleanName = metadata.cleanName.replaceAll(r'$', '');
      // Preserve the entity's generic parameters on the stub and use the
      // parameterized entity type in PatchBase (e.g. BasePatch<T, U extends
      // num> extends PatchBase<Base<T, U>, Base$>). The field enum stays
      // unparameterized.
      final genericParams = metadata.generics.map((g) => g.toString()).toList();
      final genericDecl = genericParams.isEmpty
          ? ''
          : '<${genericParams.join(', ')}>';
      final genericArgs = genericParams.isEmpty
          ? ''
          : '<${metadata.generics.map((g) => g.name).join(', ')}>';
      final stub = Code(
        'abstract class ${metadata.cleanName}Patch'
        '$genericDecl extends PatchBase<$cleanName$genericArgs, '
        '${metadata.cleanName}\$> {}',
      );
      if (metadata.allFields.isEmpty) {
        // Fieldless subtype: the stub references ${cleanName}$ but
        // getEnumPropertyList emits nothing for empty fields — emit the
        // same placeholder enum getPatchClass uses for fieldless classes.
        return [
          stub,
          Code(
            '/// Placeholder field enum for fieldless [$cleanName].\n'
            'enum ${metadata.cleanName}\$ { none }',
          ),
        ];
      }
      return [stub];
    }

    final code = helpers.getPatchClass(
      metadata.allFields,
      metadata.cleanName,
      knownClasses,
      genericTypeNames,
    );
    if (code.trim().isEmpty) return [];
    return [Code(code)];
  }
}

/// Generates the enum for field names (used by patch system).
///
/// Produces [Code] specs wrapping the string-based helper output.
class FieldEnumGenerator extends ConcreteClassGenerator {
  FieldEnumGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generatePatch &&
        (context.metadata.isAbstract && context.metadata.nonSealed
            ? context.metadata.allFields.isNotEmpty ||
                  context.metadata.isInParentExplicitSubtypes
            : !context.metadata.isAbstract &&
                  context.metadata.allFields.isNotEmpty);
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final code = helpers.getEnumPropertyList(
      metadata.allFields,
      metadata.cleanName,
    );
    if (code.trim().isEmpty) return [];
    return [Code(code)];
  }
}
