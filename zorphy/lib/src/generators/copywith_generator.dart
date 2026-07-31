import 'package:code_builder/code_builder.dart';

import '../common/NameType.dart';
import '../common/classes.dart';
import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Detects fields that have been overridden with a narrower type in a
/// child class. Returns a set of field names that need the `covariant`
/// keyword.
///
/// Duplicated from helpers.dart (which keeps the private `_getCovariantFields`)
/// so the spec-based path can access it without modifying non-target files.
Set<String> _getCovariantFields(
  List<NameTypeClassComment> classFields,
  List<Interface> interfaces,
) {
  var covariantFields = <String>{};
  for (var f in classFields) {
    var classType = helpers.replaceDollarTypesWithConcrete(
      f.type ?? 'dynamic',
    );
    for (var iface in interfaces) {
      var ifaceField = iface.fields.cast<NameType?>().firstWhere(
        (x) => x?.name == f.name,
        orElse: () => null,
      );
      if (ifaceField != null) {
        var ifaceType = helpers.replaceDollarTypesWithConcrete(
          ifaceField.type ?? 'dynamic',
        );
        if (classType != ifaceType) {
          covariantFields.add(f.name);
        }
      }
    }
  }
  return covariantFields;
}

/// Generates copyWith methods.
///
/// Migrated (T010): [generateSpec] now produces native [Method] specs
/// instead of delegating to string-based helpers. The legacy [generate]
/// path is preserved for backward compatibility with the string pipeline.
class CopyWithGenerator extends UniversalGenerator implements SpecGenerator {
  /// Creates a generator for copyWith helpers.
  CopyWithGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (metadata.isAbstract && !config.generateCopyWithFn) {
      return '';
    }

    final copyWithClassName = metadata.isAbstract
        ? (metadata.originalName.startsWith(r'$$')
              ? metadata.cleanName
              : '\$${metadata.cleanName}')
        : metadata.cleanName;

    final sb = StringBuffer();
    sb.writeln(
      helpers.getCopyWith(
        metadata.allFields,
        copyWithClassName,
        config.generateCopyWithFn,
        hidePublicConstructor: config.hidePublicConstructor,
        interfaces: metadata.allValueTInterfaces,
        ownFields: metadata.ownFieldNames,
      ),
    );

    sb.writeln(
      helpers.getInterfaceCopyWithMethods(
        metadata.allValueTInterfaces,
        metadata.allFields,
        metadata.cleanName,
      ),
    );

    if (config.generateCopyWithFn) {
      sb.writeln(
        helpers.getInterfaceCopyWithFnMethods(
          metadata.allValueTInterfaces,
          metadata.allFields,
          metadata.cleanName,
          metadata.allFields,
        ),
      );
    }

    return sb.toString();
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (metadata.isAbstract && !config.generateCopyWithFn) {
      return [];
    }

    final copyWithClassName = metadata.isAbstract
        ? (metadata.originalName.startsWith(r'$$')
              ? metadata.cleanName
              : '\$${metadata.cleanName}')
        : metadata.cleanName;

    final specs = <Spec>[];

    // Deduplicate fields by name
    final fields = <NameTypeClassComment>[];
    final seenNames = <String>{};
    for (var f in metadata.allFields) {
      if (seenNames.add(f.name)) {
        fields.add(f);
      }
    }

    final classNameTrimmed = copyWithClassName.replaceAll("\$", "");
    final activeFields = fields.where((f) => !f.isGetterOnly).toList();

    // 1. Standard copyWith
    specs.add(_buildCopyWithMethod(
      activeFields,
      classNameTrimmed,
      hidePublicConstructor: context.config.hidePublicConstructor,
      covariantFields: _getCovariantFields(
        fields,
        metadata.allValueTInterfaces,
      ),
    ));

    // 2. Alias: copyWith{ClassName}
    specs.add(_buildCopyWithAliasMethod(
      activeFields,
      classNameTrimmed,
    ));

    // 3. Function-based copyWithFn
    if (config.generateCopyWithFn) {
      specs.add(_buildCopyWithFnMethod(
        activeFields,
        classNameTrimmed,
        hidePublicConstructor: context.config.hidePublicConstructor,
      ));
    }

    // 4. Interface-scoped copyWith methods
    specs.addAll(_buildInterfaceCopyWithMethods(
      metadata.allValueTInterfaces,
      metadata.allFields,
      metadata.cleanName,
      classNameTrimmed,
    ));

    // 5. Interface-scoped copyWithFn methods
    if (config.generateCopyWithFn) {
      specs.addAll(_buildInterfaceCopyWithFnMethods(
        metadata.allValueTInterfaces,
        metadata.allFields,
        metadata.cleanName,
        classNameTrimmed,
      ));
    }

    return specs;
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    if (context.metadata.isAbstract) {
      return context.config.generateCopyWithFn;
    }
    return context.config.generateCopyWith;
  }

  // ── Standard copyWith ──────────────────────────────────────────

  Method _buildCopyWithMethod(
    List<NameTypeClassComment> fields,
    String classNameTrimmed, {
    bool hidePublicConstructor = false,
    Set<String> covariantFields = const {},
  }) {
    final params = <Parameter>[];
    for (final f in fields) {
      final fieldType = helpers.replaceDollarTypesWithConcrete(
        f.type ?? 'dynamic',
      );
      final nullableType =
          fieldType.endsWith('?') ? fieldType : '$fieldType?';
      params.add(Parameter((p) {
        p.name = f.name;
        p.type = refer(nullableType);
        p.named = true;
        if (covariantFields.contains(f.name)) {
          p.covariant = true;
        }
      }));
    }

    final body = StringBuffer();
    final constructorSuffix = hidePublicConstructor ? '._' : '';
    body.writeln('return $classNameTrimmed$constructorSuffix(');
    for (final f in fields) {
      body.writeln('  ${f.name}: ${f.name} ?? this.${f.name},');
    }
    body.writeln(');');

    return Method((m) {
      m.name = 'copyWith';
      m.returns = refer(classNameTrimmed);
      m.optionalParameters.addAll(params);
      m.body = Code(body.toString());
    });
  }

  // ── Alias copyWith{ClassName} ──────────────────────────────────

  Method _buildCopyWithAliasMethod(
    List<NameTypeClassComment> fields,
    String classNameTrimmed,
  ) {
    final params = <Parameter>[];
    for (final f in fields) {
      final fieldType = helpers.replaceDollarTypesWithConcrete(
        f.type ?? 'dynamic',
      );
      final nullableType =
          fieldType.endsWith('?') ? fieldType : '$fieldType?';
      params.add(Parameter((p) {
        p.name = f.name;
        p.type = refer(nullableType);
        p.named = true;
      }));
    }

    final body = StringBuffer();
    body.writeln('return copyWith(');
    if (fields.isNotEmpty) {
      final paramStr = fields
          .map((f) => '${f.name}: ${f.name}')
          .join(', ');
      body.writeln('  $paramStr,');
    }
    body.writeln(');');

    return Method((m) {
      m.name = 'copyWith$classNameTrimmed';
      m.returns = refer(classNameTrimmed);
      m.optionalParameters.addAll(params);
      m.body = Code(body.toString());
    });
  }

  // ── Function-based copyWithFn ──────────────────────────────────

  Method _buildCopyWithFnMethod(
    List<NameTypeClassComment> fields,
    String classNameTrimmed, {
    bool hidePublicConstructor = false,
  }) {
    final params = <Parameter>[];
    for (final f in fields) {
      final fieldType = helpers.replaceDollarTypesWithConcrete(
        f.type ?? 'dynamic',
      );
      params.add(Parameter((p) {
        p.name = f.name;
        p.type = refer('$fieldType Function($fieldType)?');
        p.named = true;
      }));
    }

    final body = StringBuffer();
    final constructorSuffix = hidePublicConstructor ? '._' : '';
    body.writeln('return $classNameTrimmed$constructorSuffix(');
    for (final f in fields) {
      body.writeln(
        '  ${f.name}: ${f.name} != null ? ${f.name}(this.${f.name}) : this.${f.name},',
      );
    }
    body.writeln(');');

    return Method((m) {
      m.name = 'copyWithFn';
      m.returns = refer(classNameTrimmed);
      m.optionalParameters.addAll(params);
      m.body = Code(body.toString());
    });
  }

  // ── Interface-scoped copyWith ──────────────────────────────────

  List<Method> _buildInterfaceCopyWithMethods(
    List<Interface> interfaces,
    List<NameTypeClassComment> classFields,
    String className,
    String classNameTrimmed,
  ) {
    final classFieldNames = classFields.map((f) => f.name).toSet();
    final methods = <Method>[];

    for (var i in interfaces) {
      var interfaceName = i.interfaceName;
      if (!interfaceName.startsWith("\$") ||
          interfaceName.startsWith("\$\$")) {
        continue;
      }
      var interfaceNameTrimmed = interfaceName.replaceAll("\$", "");
      if (interfaceNameTrimmed == classNameTrimmed) continue;

      var seenFields = <String>{};
      var interfaceFields = i.fields.where((f) {
        if (classFieldNames.contains(f.name) &&
            !seenFields.contains(f.name)) {
          seenFields.add(f.name);
          return true;
        }
        return false;
      }).toList();
      if (interfaceFields.isEmpty) continue;

      final params = <Parameter>[];
      for (final f in interfaceFields) {
        var classField = classFields.firstWhere(
          (cf) => cf.name == f.name,
          orElse: () => NameTypeClassComment(f.name, f.type, ''),
        );
        var fieldType = helpers.replaceDollarTypesWithConcrete(
          classField.type ?? f.type ?? 'dynamic',
        );
        var nullableType =
            fieldType.endsWith('?') ? fieldType : '$fieldType?';
        params.add(Parameter((p) {
          p.name = f.name;
          p.type = refer(nullableType);
          p.named = true;
        }));
      }

      final body = StringBuffer();
      body.writeln('return copyWith(');
      final paramStr = interfaceFields
          .map((f) => '${f.name}: ${f.name}')
          .join(', ');
      body.writeln('  $paramStr,');
      body.writeln(');');

      methods.add(Method((m) {
        m.name = 'copyWith$interfaceNameTrimmed';
        m.returns = refer(classNameTrimmed);
        m.optionalParameters.addAll(params);
        m.body = Code(body.toString());
      }));
    }

    return methods;
  }

  // ── Interface-scoped copyWithFn ────────────────────────────────

  List<Method> _buildInterfaceCopyWithFnMethods(
    List<Interface> interfaces,
    List<NameTypeClassComment> classFields,
    String className,
    String classNameTrimmed,
  ) {
    final methods = <Method>[];

    for (var i in interfaces) {
      var interfaceName = i.interfaceName;
      if (!interfaceName.startsWith("\$") ||
          interfaceName.startsWith("\$\$")) {
        continue;
      }
      var interfaceNameTrimmed = interfaceName.replaceAll("\$", "");
      if (interfaceNameTrimmed == classNameTrimmed) continue;

      var seenFields = <String>{};
      var interfaceFields = i.fields.where((f) {
        if (classFields.any((af) => af.name == f.name) &&
            !seenFields.contains(f.name)) {
          seenFields.add(f.name);
          return true;
        }
        return false;
      }).toList();
      if (interfaceFields.isEmpty) continue;

      final params = <Parameter>[];
      for (final f in interfaceFields) {
        var classField = classFields.firstWhere(
          (cf) => cf.name == f.name,
          orElse: () => NameTypeClassComment(f.name, f.type, ''),
        );
        var fieldType = helpers.replaceDollarTypesWithConcrete(
          classField.type ?? f.type ?? 'dynamic',
        );
        var nullableType =
            fieldType.endsWith('?') ? fieldType : '$fieldType?';
        params.add(Parameter((p) {
          p.name = f.name;
          p.type = refer('$nullableType Function()?');
          p.named = true;
        }));
      }

      final body = StringBuffer();
      body.writeln('return copyWith(');
      final paramStr = interfaceFields
          .map(
            (f) =>
                '${f.name}: ${f.name} != null ? ${f.name}() : this.${f.name}',
          )
          .join(', ');
      body.writeln('  $paramStr,');
      body.writeln(');');

      methods.add(Method((m) {
        m.name = 'copyWith${interfaceNameTrimmed}Fn';
        m.returns = refer(classNameTrimmed);
        m.optionalParameters.addAll(params);
        m.body = Code(body.toString());
      }));
    }

    return methods;
  }
}
