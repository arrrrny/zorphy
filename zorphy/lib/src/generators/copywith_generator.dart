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
/// Migrated (T010): produces native [Method] specs.
class CopyWithGenerator extends UniversalGenerator {
  /// Creates a generator for copyWith helpers.
  CopyWithGenerator();

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (metadata.isAbstract && !config.generateCopyWithFn) {
      return [];
    }

    final copyWithClassName = metadata.isAbstract
        ? (metadata.originalName.startsWith(r'\$\$')
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

    // Field-selector copyWithField (issue #131): replaces a single
    // field picked by a typed `Field<E, T>` selector.
    specs.add(
      _buildCopyWithFieldMethod(
        activeFields,
        classNameTrimmed,
        metadata.generics.map((g) => g.name).toList(),
      ),
    );

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
      ));
    }

    // 4. Interface-scoped copyWith methods
    specs.addAll(_buildInterfaceCopyWithMethods(
      metadata.allValueTInterfaces,
      metadata.allFields,
      metadata.cleanName,
      classNameTrimmed,
      covariantFields: _getCovariantFields(
        fields,
        metadata.allValueTInterfaces,
      ),
    ));

    // 4b. Interface-scoped copyWithField methods
    specs.addAll(_buildInterfaceCopyWithFieldMethods(
      metadata.allValueTInterfaces,
      metadata.allFields,
      metadata.cleanName,
      classNameTrimmed,
      metadata.generics.map((g) => g.name).toList(),
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
          (fieldType.endsWith('?') ||
                   fieldType == 'dynamic' ||
                   fieldType.startsWith('dynamic<') ||
                   fieldType.startsWith('dynamic '))
              ? fieldType
              : '$fieldType?';
      params.add(Parameter((p) {
        p.name = f.name;
        p.type = refer(nullableType);
        p.named = true;
        if (covariantFields.contains(f.name)) {
          p.covariant = true;
        }
      }));
    }

    final body = <String>[];
    final constructorSuffix = hidePublicConstructor ? '._' : '';
    body.add('return $classNameTrimmed$constructorSuffix(');
    for (final f in fields) {
      body.add('  ${f.name}: ${f.name} ?? this.${f.name},');
    }
    body.add(');');

    return Method((m) {
      m.name = 'copyWith';
      m.returns = refer(classNameTrimmed);
      m.optionalParameters.addAll(params);
      m.body = Code(body.join('\n'));
    });
  }

  // ── Field-selector copyWithField (issue #131) ──────────────────────────────

  /// Picks a name for the value type parameter of `copyWithField` that
  /// does not shadow any of the entity's own generic type parameters
  /// (a class like `Result<T>` must keep its `T` visible inside the
  /// `Field<Result<T>, ...>` parameter type).
  String _valueTypeParameterName(List<String> genericNames) {
    final taken = genericNames.toSet();
    var candidate = 'T';
    if (!taken.contains(candidate)) return candidate;
    candidate = 'TValue';
    var index = 2;
    while (taken.contains(candidate)) {
      candidate = 'TValue$index';
      index++;
    }
    return candidate;
  }

  /// Builds `E copyWithField<T>(Field<E, T> field, T value)` - a
  /// single-field copy driven by a typed field selector.
  ///
  /// The method delegates to the generated `copyWith`, so it inherits
  /// its construction rules (private constructors, custom constructor
  /// bodies) and its `??` semantics: a null [value] keeps the current
  /// value of a nullable field. Selectors for unknown or getter-only
  /// fields throw an [ArgumentError] instead of silently returning
  /// `this`.
  Method _buildCopyWithFieldMethod(
    List<NameTypeClassComment> fields,
    String classNameTrimmed,
    List<String> genericNames,
  ) {
    final hasGenerics = genericNames.isNotEmpty;
    // The entity type as seen from inside the class body: parameterized
    // for generic entities so `{ClassName}Fields<T>` selectors assign
    // directly to the parameter.
    final entityType = hasGenerics
        ? '$classNameTrimmed<${genericNames.join(', ')}>'
        : classNameTrimmed;
    final valueTypeParam = _valueTypeParameterName(genericNames);

    final body = <String>[];
    if (fields.isEmpty) {
      body.add(
        "throw ArgumentError.value(field.name, 'field', "
        "'$classNameTrimmed has no settable fields');",
      );
    } else {
      body.add('switch (field.name) {');
      for (final f in fields) {
        final fieldType = helpers.replaceDollarTypesWithConcrete(
          f.type ?? 'dynamic',
        );
        body.add("  case '${f.name}':");
        body.add('    return copyWith(${f.name}: value as $fieldType);');
      }
      body.add('  default:');
      body.add(
        "    throw ArgumentError.value(field.name, 'field', "
        "'$classNameTrimmed has no settable field with this name');",
      );
      body.add('}');
    }

    return Method((m) {
      m.docs.add(
        '/// Returns a copy of this entity with [field] set to [value].',
      );
      m.docs.add('///');
      m.docs.add(
        '/// Delegates to [copyWith]: the receiver is never mutated and a',
      );
      m.docs.add('/// null [value] keeps the current field value.');
      m.name = 'copyWithField';
      // Raw return type mirrors the existing copyWith emission: for
      // generic entities the copyWith constructor inference produces
      // the raw instantiation at runtime, so a parameterized return
      // type would require an unsafe cast.
      m.returns = refer(classNameTrimmed);
      m.types.add(refer(valueTypeParam));
      m.requiredParameters.add(Parameter((p) {
        p.name = 'field';
        p.type = refer('Field<$entityType, $valueTypeParam>');
      }));
      m.requiredParameters.add(Parameter((p) {
        p.name = 'value';
        p.type = refer(valueTypeParam);
      }));
      m.body = Code(body.join('\n'));
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
          (fieldType.endsWith('?') ||
                   fieldType == 'dynamic' ||
                   fieldType.startsWith('dynamic<') ||
                   fieldType.startsWith('dynamic '))
              ? fieldType
              : '$fieldType?';
      params.add(Parameter((p) {
        p.name = f.name;
        p.type = refer(nullableType);
        p.named = true;
      }));
    }

    final body = <String>[];
    body.add('return copyWith(');
    if (fields.isNotEmpty) {
      final paramStr = fields
          .map((f) => '${f.name}: ${f.name}')
          .join(', ');
      body.add('  $paramStr,');
    }
    body.add(');');

    return Method((m) {
      m.name = 'copyWith$classNameTrimmed';
      m.returns = refer(classNameTrimmed);
      m.optionalParameters.addAll(params);
      m.body = Code(body.join('\n'));
    });
  }

  // ── Function-based copyWithFn ──────────────────────────────────

  Method _buildCopyWithFnMethod(
    List<NameTypeClassComment> fields,
    String classNameTrimmed,
  ) {
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

    final body = <String>[];
    body.add('return $classNameTrimmed(');
    for (final f in fields) {
      body.add(
        '  ${f.name}: ${f.name} != null ? ${f.name}(this.${f.name}) : this.${f.name},',
      );
    }
    body.add(');');

    return Method((m) {
      m.name = 'copyWithFn';
      m.returns = refer(classNameTrimmed);
      m.optionalParameters.addAll(params);
      m.body = Code(body.join('\n'));
    });
  }

  // ── Interface-scoped copyWith ──────────────────────────────────

  List<Method> _buildInterfaceCopyWithMethods(
    List<Interface> interfaces,
    List<NameTypeClassComment> classFields,
    String className,
    String classNameTrimmed, {
    Set<String> covariantFields = const {},
  }) {
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
          if (covariantFields.contains(f.name)) {
            p.covariant = true;
          }
        }));
      }

      final body = <String>[];
      body.add('return copyWith(');
      final paramStr = interfaceFields
          .map((f) => '${f.name}: ${f.name}')
          .join(', ');
      body.add('  $paramStr,');
      body.add(');');

      methods.add(Method((m) {
        m.name = 'copyWith$interfaceNameTrimmed';
        m.returns = refer(classNameTrimmed);
        m.optionalParameters.addAll(params);
        m.body = Code(body.join('\n'));
      }));
    }

    return methods;
  }

  // ── Interface-scoped copyWithField ─────────────────────────────

  List<Method> _buildInterfaceCopyWithFieldMethods(
    List<Interface> interfaces,
    List<NameTypeClassComment> classFields,
    String className,
    String classNameTrimmed,
    List<String> genericNames,
  ) {
    final classFieldNames = classFields.map((f) => f.name).toSet();
    final methods = <Method>[];
    final hasGenerics = genericNames.isNotEmpty;
    final entityType = hasGenerics
        ? '$classNameTrimmed<${genericNames.join(', ')}>'
        : classNameTrimmed;
    final valueTypeParam = _valueTypeParameterName(genericNames);

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

      final body = <String>[];
      body.add('switch (field.name) {');
      for (final f in interfaceFields) {
        var classField = classFields.firstWhere(
          (cf) => cf.name == f.name,
          orElse: () => NameTypeClassComment(f.name, f.type, ''),
        );
        final fieldType = helpers.replaceDollarTypesWithConcrete(
          classField.type ?? f.type ?? 'dynamic',
        );
        body.add("  case '${f.name}':");
        body.add('    return copyWith(${f.name}: value as $fieldType);');
      }
      body.add('  default:');
      body.add(
        "    throw ArgumentError.value(field.name, 'field', "
        "'$interfaceNameTrimmed interface has no settable field with this name');",
      );
      body.add('}');

      methods.add(Method((m) {
        m.docs.add(
          '/// Returns a copy of this entity with the $interfaceNameTrimmed [field] set to [value].',
        );
        m.docs.add('///');
        m.docs.add(
          '/// Delegates to [copyWith]: the receiver is never mutated and a',
        );
        m.docs.add('/// null [value] keeps the current field value.');
        m.docs.add('///');
        m.docs.add(
          '/// Only fields exposed by the $interfaceNameTrimmed interface are accepted.',
        );
        m.name = 'copyWith${interfaceNameTrimmed}Field';
        m.returns = refer(classNameTrimmed);
        m.types.add(refer(valueTypeParam));
        m.requiredParameters.add(Parameter((p) {
          p.name = 'field';
          p.type = refer('Field<$entityType, $valueTypeParam>');
        }));
        m.requiredParameters.add(Parameter((p) {
          p.name = 'value';
          p.type = refer(valueTypeParam);
        }));
        m.body = Code(body.join('\n'));
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

      final body = <String>[];
      body.add('return copyWith(');
      final paramStr = interfaceFields
          .map(
            (f) =>
                '${f.name}: ${f.name} != null ? ${f.name}() : this.${f.name}',
          )
          .join(', ');
      body.add('  $paramStr,');
      body.add(');');

      methods.add(Method((m) {
        m.name = 'copyWith${interfaceNameTrimmed}Fn';
        m.returns = refer(classNameTrimmed);
        m.optionalParameters.addAll(params);
        m.body = Code(body.join('\n'));
      }));
    }

    return methods;
  }
}
