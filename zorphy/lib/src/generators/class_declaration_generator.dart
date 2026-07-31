import 'package:code_builder/code_builder.dart';

import '../analysis/field_resolver.dart';
import '../ast/ast.dart';
import '../common/NameType.dart';
import '../helpers.dart' as helpers;
import '../models/class_metadata.dart';
import '../models/generation_config.dart';
import '../models/interface_metadata.dart';
import 'base_generator.dart';

/// Generates class declaration, properties, and constructor.
///
/// Migrated (T008): [generateSpec] now produces a native [Class] spec
/// instead of building strings via StringBuffer. The legacy [generate]
/// path is preserved for backward compatibility with the string pipeline.
class ClassDeclarationGenerator extends UniversalGenerator
    implements SpecGenerator {
  /// Creates a generator for class declarations and constructors.
  ClassDeclarationGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (metadata.isAbstract) {
      return _generateAbstractClass(metadata, config);
    } else {
      return _generateConcreteClass(metadata, config);
    }
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (metadata.isAbstract) {
      return [_buildAbstractClassSpec(metadata, config)];
    } else {
      return [_buildConcreteClassSpec(metadata, config)];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STRING PIPELINE (legacy — preserved for backward compat)
  // ═══════════════════════════════════════════════════════════════

  String _generateAbstractClass(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.originalName.startsWith(r'$$')
        ? metadata.cleanName
        : '\$${metadata.cleanName}';

    final sealedModifier = metadata.nonSealed ? '' : 'sealed ';
    final abstractModifier = metadata.nonSealed ? 'abstract ' : '';
    final implementsStr = _buildImplementsClause(
      metadata,
      config,
      isAbstract: true,
    );
    final genericsStr = _buildGenericsString(metadata);

    final sb = StringBuffer();
    final isSealedWithSubtypes =
        metadata.isSealed && metadata.explicitSubtypes.isNotEmpty;

    sb.writeln(
      '${sealedModifier}${abstractModifier}class $className$genericsStr$implementsStr {',
    );
    sb.writeln(
      helpers.getPropertiesAbstract(
        metadata.allFields,
        className,
        config.generateCopyWithFn,
        isSealedWithSubtypes: isSealedWithSubtypes,
        hasConstConstructor: metadata.hasConstConstructor,
      ),
    );

    return sb.toString();
  }

  String _generateConcreteClass(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.cleanName;
    final genericsStr = _buildGenericsString(metadata);
    final extendsStr = _buildExtendsClause(metadata, config);
    final implementsStr = _buildImplementsClause(
      metadata,
      config,
      isAbstract: false,
    );

    final sb = StringBuffer();

    final hasFactoryMethods = config.factoryMethods.isNotEmpty;
    final isAbstractClass = metadata.originalName.startsWith(r'$$');
    final shouldSkipJsonAnnotation =
        hasFactoryMethods && isAbstractClass;

    if (config.generateJson && !shouldSkipJsonAnnotation) {
      final genericParams = metadata.generics.isNotEmpty
          ? ', genericArgumentFactories: true'
          : '';
      final constructorParam = config.hidePublicConstructor
          ? ", constructor: '_'"
          : "";
      sb.writeln(
        '@JsonSerializable(explicitToJson: ${config.explicitToJson}, checked: true$genericParams$constructorParam)',
      );
    }

    sb.writeln('class $className$genericsStr$extendsStr$implementsStr {');

    final hasExtendsParam = extendsStr.isNotEmpty;
    final extendsAbstractClass = _determineExtendsAbstractClass(
      metadata,
      config,
    );
    final parentConcreteClassName = _getConcreteParentName(metadata);
    final hasConcreteParent = parentConcreteClassName != null;
    final parentHasConst = hasConcreteParent
        ? _parentHasConstConstructor(metadata, parentConcreteClassName)
        : true;
    final shouldGenerateConstConstructor =
        metadata.hasConstConstructor &&
        (!hasConcreteParent || parentHasConst);

    final fieldsToGenerate = metadata.allFields;
    final parentFields = hasConcreteParent
        ? _getParentFieldsForSuper(metadata, config)
        : <String>{};

    final allParentInterfaceFields = <String>{};
    for (final iface in metadata.interfaces) {
      allParentInterfaceFields.addAll(iface.fields.map((f) => f.name));
    }

    sb.writeln(
      helpers.getProperties(
        fieldsToGenerate,
        className,
        false,
        config.hidePublicConstructor,
        config.generateCopyWithFn,
        config.generateJson,
        shouldGenerateConstConstructor,
        hasExtendsParam,
        extendsAbstractClass: extendsAbstractClass,
        parentFields: parentFields,
        ownFields: metadata.ownFieldNames,
        allInheritedFields: allParentInterfaceFields,
      ),
    );

    return sb.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // SPEC PIPELINE (new — code_builder native specs)
  // ═══════════════════════════════════════════════════════════════

  /// Builds a [Class] spec for an abstract class.
  Class _buildAbstractClassSpec(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.originalName.startsWith(r'$$')
        ? metadata.cleanName
        : '\$${metadata.cleanName}';

    final isSealedWithSubtypes =
        metadata.isSealed && metadata.explicitSubtypes.isNotEmpty;

    return Class((c) {
      c.name = className;

      // Modifiers
      if (metadata.isSealed) {
        c.sealed = true;
      } else if (metadata.nonSealed) {
        c.abstract = true;
      }

      // Type parameters
      for (final g in metadata.generics) {
        c.types.add(mapGenericParameter(g));
      }

      // Implements
      for (final iface in metadata.interfaces) {
        c.implements.add(referType(iface.interfaceName));
      }
      for (final f in metadata.allFields) {
        c.methods.add(Method((m) {
          m.type = MethodType.getter;
          m.name = f.name;
          var fieldType = f.type != null
              ? helpers.replaceDollarTypesWithConcrete(f.type!)
              : f.type;
          m.returns = _referFieldType(fieldType);

          // JsonKey annotation
          if (f.jsonKeyInfo != null) {
            final annStr = f.jsonKeyInfo!.toAnnotationString();
            final cleanAnn = annStr.startsWith('@') ? annStr.substring(1) : annStr;
            m.annotations.add(
              CodeExpression(
                Code(cleanAnn),
              ),
            );
          }
        }));
      }

      // Constructor for non-sealed abstract classes
      if (!isSealedWithSubtypes) {
        c.constructors.add(Constructor((con) {
          if (metadata.hasConstConstructor) {
            con.constant = true;
          }
        }));
      }

      // Named copyWith factory constructor (abstract classes with
      // generateCopyWithFn) is handled by the string pipeline via
      // helpers.getPropertiesAbstract. The code_builder Class spec doesn't
      // support redirecting factory constructors, so the spec path omits it.
      // The string pipeline remains the primary output.
    });
  }

  /// Builds a [Class] spec for a concrete class.
  Class _buildConcreteClassSpec(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.cleanName;
    final extendsStr = _buildExtendsClause(metadata, config);
    final hasExtendsParam = extendsStr.isNotEmpty;
    final extendsAbstractClass =
        _determineExtendsAbstractClass(metadata, config);

    final parentConcreteClassName = _getConcreteParentName(metadata);
    final hasConcreteParent = parentConcreteClassName != null;
    final parentHasConst = hasConcreteParent
        ? _parentHasConstConstructor(metadata, parentConcreteClassName)
        : true;
    final shouldGenerateConstConstructor =
        metadata.hasConstConstructor &&
        (!hasConcreteParent || parentHasConst);

    final parentFields = hasConcreteParent
        ? _getParentFieldsForSuper(metadata, config)
        : <String>{};

    final allParentInterfaceFields = <String>{};
    for (final iface in metadata.interfaces) {
      allParentInterfaceFields.addAll(iface.fields.map((f) => f.name));
    }

    return Class((c) {
      c.name = className;

      // @JsonSerializable annotation
      final hasFactoryMethods = config.factoryMethods.isNotEmpty;
      final isAbstractClass = metadata.originalName.startsWith(r'$$');
      final shouldSkipJsonAnnotation =
          hasFactoryMethods && isAbstractClass;

      if (config.generateJson && !shouldSkipJsonAnnotation) {
        final genericParams = metadata.generics.isNotEmpty
            ? ', genericArgumentFactories: true'
            : '';
        final constructorParam = config.hidePublicConstructor
            ? ", constructor: '_'"
            : "";
        c.annotations.add(
          CodeExpression(
            Code(
              'JsonSerializable(explicitToJson: ${config.explicitToJson}, checked: true$genericParams$constructorParam)',
            ),
          ),
        );
      }

      // Type parameters
      for (final g in metadata.generics) {
        c.types.add(mapGenericParameter(g));
      }

      // Extends
      final extendsName = _getExtendedParentName(metadata, config);
      if (extendsName.isNotEmpty) {
        final parentName = _trimInterfaceName(extendsName);
        c.extend = referType(parentName);
      }

      // Implements
      final extendedParent = _getExtendedParentName(metadata, config);
      for (final iface in metadata.interfaces) {
        final trimmedName = _trimInterfaceName(iface.interfaceName);
        if (trimmedName != _trimInterfaceName(extendedParent) &&
            trimmedName.isNotEmpty) {
          c.implements.add(referType(iface.interfaceName));
        }
      }

      // Fields
      _addConcreteFields(
        c,
        metadata.allFields,
        metadata,
        config,
        hasExtendsParam,
        extendsAbstractClass,
        parentFields,
        allParentInterfaceFields,
      );

      // Constructor
      _addConcreteConstructor(
        c,
        metadata.allFields,
        className,
        config,
        shouldGenerateConstConstructor,
        hasExtendsParam,
        extendsAbstractClass,
        parentFields,
        metadata.ownFieldNames,
      );
    });
  }

  /// Adds final fields to a concrete class spec.
  void _addConcreteFields(
    ClassBuilder c,
    List<NameTypeClassComment> fields,
    ClassMetadata metadata,
    GenerationConfig config,
    bool hasExtends,
    bool extendsAbstractClass,
    Set<String> parentFields,
    Set<String> allInheritedFields,
  ) {
    for (final f in fields) {
      final isInheritedOnly =
          !metadata.isAbstract &&
          hasExtends &&
          !extendsAbstractClass &&
          parentFields.contains(f.name) &&
          !metadata.ownFieldNames.contains(f.name);

      if (isInheritedOnly) continue;

      // Getter-only without default value: skip
      if (f.isGetterOnly &&
          metadata.ownFieldNames.contains(f.name) &&
          f.jsonKeyInfo?.defaultValue == null) {
        continue;
      }

      if (f.isGetterOnly &&
          !metadata.isAbstract &&
          f.jsonKeyInfo?.defaultValue == null) {
        continue;
      }

      final fieldType = f.type != null
          ? helpers.replaceDollarTypesWithConcrete(f.type!)
          : f.type;

      final field = Field((fd) {
        fd.name = f.name;
        fd.type = _referFieldType(fieldType);
        fd.modifier = FieldModifier.final$;

        // @override for inherited interface fields
        if (hasExtends &&
            allInheritedFields.contains(f.name) &&
            !f.additionalAnnotations.contains('@override')) {
          fd.annotations.add(refer('override'));
        }

        // JsonKey annotation
        if (f.jsonKeyInfo != null) {
          final annStr = f.jsonKeyInfo!
              .toAnnotationString(includeDefaultValue: true);
          final cleanAnn = annStr.startsWith('@') ? annStr.substring(1) : annStr;
          fd.annotations.add(
            CodeExpression(
              Code(cleanAnn),
            ),
          );
        }

        // Additional annotations
        for (final ann in f.additionalAnnotations) {
          final cleanAnn = ann.startsWith('@') ? ann.substring(1) : ann;
          fd.annotations.add(CodeExpression(Code(cleanAnn)));
        }
      });

      c.fields.add(field);
    }
  }

  /// Adds the primary constructor to a concrete class spec.
  void _addConcreteConstructor(
    ClassBuilder c,
    List<NameTypeClassComment> fields,
    String className,
    GenerationConfig config,
    bool shouldGenerateConstConstructor,
    bool hasExtends,
    bool extendsAbstractClass,
    Set<String> parentFields,
    Set<String> ownFields,
  ) {
    final isPrivate = config.hidePublicConstructor;

    final params = <Parameter>[];
    final initializers = <String>[];

    for (final f in fields) {
      // Skip getter-only without default value
      if (f.isGetterOnly &&
          f.jsonKeyInfo?.defaultValue == null) {
        continue;
      }

      final defaultValue = f.jsonKeyInfo?.defaultValue;
      final hasDefaultValue = defaultValue != null;
      var fieldType = f.type != null
          ? helpers.replaceDollarTypesWithConcrete(f.type!)
          : f.type;

      final isNullable =
          fieldType != null && fieldType.endsWith('?');

      final isParentField = hasExtends &&
          !extendsAbstractClass &&
          parentFields.contains(f.name) &&
          !ownFields.contains(f.name);

      if (isParentField) {
        var safeFieldType = fieldType ?? 'dynamic';
        var isNull = safeFieldType.endsWith('?');
        var paramType = (isNull || hasDefaultValue)
            ? (safeFieldType.endsWith('?')
                ? safeFieldType
                : '$safeFieldType?')
            : safeFieldType;
        params.add(Parameter((p) {
          p.name = f.name;
          p.type = referType(paramType);
          p.named = true;
          p.required = !(isNull || hasDefaultValue);
        }));
      } else if (hasDefaultValue) {
        var safeFieldType = fieldType ?? 'dynamic';
        var isNull = safeFieldType.endsWith('?');
        var paramType = isNull ? safeFieldType : '$safeFieldType?';
        params.add(Parameter((p) {
          p.name = f.name;
          p.type = referType(paramType);
          p.named = true;
        }));

        var defaultValueString = defaultValue.toString();
        if (!defaultValueString.startsWith('const ') &&
            !defaultValueString.startsWith("'") &&
            !defaultValueString.startsWith('"') &&
            !RegExp(r'^-?\d').hasMatch(defaultValueString) &&
            defaultValueString != 'true' &&
            defaultValueString != 'false' &&
            defaultValueString != 'null') {
          if (defaultValueString.startsWith('[') ||
              defaultValueString.startsWith('{') ||
              RegExp(
                r'^[a-zA-Z_\$][a-zA-Z0-9_\$]*(\.[a-zA-Z_\$][a-zA-Z0-9_\$]*)?(\s*<[^>]+>)?\s*\(',
              ).hasMatch(defaultValueString)) {
            defaultValueString = 'const $defaultValueString';
          }
        }

        initializers.add(
          'this.${f.name} = ${f.name} ?? $defaultValueString',
        );
      } else {
        params.add(Parameter((p) {
          p.name = f.name;
          p.toThis = true;
          p.named = true;
          p.required = !isNullable;
        }));
      }
    }

    // Build constructor
    final constructor = Constructor((con) {
      if (isPrivate) {
        con.name = '_';
      }
      if (shouldGenerateConstConstructor) {
        con.constant = true;
      }
      con.optionalParameters.addAll(params);

      // Initializer list
      final initParts = <String>[];

      if (hasExtends && extendsAbstractClass) {
        initParts.addAll(initializers);
        initParts.add('super()');
      } else if (hasExtends && !extendsAbstractClass) {
        initParts.addAll(initializers);
        // Super call with parent fields (only those present in params)
        final paramNames = params.map((p) => p.name).toSet();
        final superArgs = <String>[];
        for (final f in fields) {
          if (parentFields.contains(f.name) && paramNames.contains(f.name)) {
            superArgs.add('${f.name}: ${f.name}');
          }
        }
        initParts.add('super(${superArgs.join(', ')})');
      } else {
        initParts.addAll(initializers);
      }

      // Set initializers as Code expressions
      // Note: code_builder's Constructor.initializers takes Expression objects
      for (final init in initParts) {
        con.initializers.add(Code(init));
      }
    });

    c.constructors.add(constructor);

    // Named constructor for copyWith (generateCopyWithFn)
    if (config.generateCopyWithFn) {
      final copyWithParams = <Parameter>[];
      for (final f in fields) {
        if (f.isGetterOnly &&
            f.jsonKeyInfo?.defaultValue == null) {
          continue;
        }
        var fieldType = f.type != null
            ? helpers.replaceDollarTypesWithConcrete(f.type!)
            : f.type;
        var nullableFieldType = fieldType!.endsWith('?')
            ? fieldType
            : '$fieldType?';
        copyWithParams.add(Parameter((p) {
          p.name = f.name;
          p.type = referType(nullableFieldType);
          p.named = true;
        }));
      }

      final copyWithInitializers = <String>[];
      final copyWithFields = fields
          .where((f) =>
              !(f.isGetterOnly &&
                  f.jsonKeyInfo?.defaultValue == null))
          .toList();
      for (final f in copyWithFields) {
        copyWithInitializers.add(
          '${f.name} = ${f.name} ?? (() { throw ArgumentError("${f.name} is required"); })()',
        );
      }

      c.constructors.add(Constructor((con) {
        con.name = 'copyWith';
        con.optionalParameters.addAll(copyWithParams);
        // Constructor.initializers accepts Expression objects; code_builder handles separators
        for (final init in copyWithInitializers) {
          con.initializers.add(Code(init));
        }
      }));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED HELPERS (used by both pipelines)
  // ═══════════════════════════════════════════════════════════════

  /// Null-safe type reference helper.
  TypeReference _referFieldType(String? type) {
    if (type == null || type.isEmpty) return referType('dynamic');
    return referType(type);
  }

  String _buildGenericsString(ClassMetadata metadata) {
    if (metadata.generics.isEmpty) return '';
    final parts = metadata.generics
        .map((g) {
          if (g.bound != null && g.bound!.isNotEmpty) {
            return '${g.name} extends ${g.bound}';
          }
          return g.name;
        })
        .join(', ');
    return '<$parts>';
  }

  String _buildImplementsClause(
    ClassMetadata metadata,
    GenerationConfig config, {
    required bool isAbstract,
  }) {
    final interfaces = metadata.interfaces;

    if (isAbstract) {
      final clause = interfaces
          .map((i) => i.interfaceName)
          .where((name) => name.isNotEmpty)
          .join(', ');
      return clause.isNotEmpty ? ' implements $clause' : '';
    } else {
      final extendedParent = _getExtendedParentName(metadata, config);
      final clauseParts = interfaces
          .map((i) => _trimInterfaceName(i.interfaceName))
          .where(
            (name) =>
                name.isNotEmpty &&
                    name != _trimInterfaceName(extendedParent),
          )
          .toList();
      final clause = clauseParts.join(', ');
      return clause.isNotEmpty ? ' implements $clause' : '';
    }
  }

  bool _parentHasConstConstructor(
    ClassMetadata metadata,
    String parentConcreteClassName,
  ) {
    for (final iface in metadata.interfaces) {
      final ifaceName = iface.element.name ?? '';
      final trimmedIfaceName =
          _trimInterfaceName(iface.interfaceName);
      if (ifaceName == parentConcreteClassName ||
          ifaceName == '\$$parentConcreteClassName' ||
          trimmedIfaceName == parentConcreteClassName) {
        return iface.element.constructors.any((e) => e.isConst);
      }
    }
    final parentElement =
        metadata.allAnnotatedClasses[parentConcreteClassName] ??
            metadata
                .allAnnotatedClasses['\$$parentConcreteClassName'];
    return parentElement?.constructors.any((e) => e.isConst) ?? false;
  }

  String _getExtendedParentName(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    for (final iface in metadata.interfaces) {
      final name = iface.interfaceName;
      if (name.startsWith(r'$$') && !iface.isSealed) {
        return name;
      }
      if (name.startsWith(r'$') && !name.startsWith(r'$$')) {
        return name;
      }
    }
    return '';
  }

  String _buildExtendsClause(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final parent = _getExtendedParentName(metadata, config);
    if (parent.isEmpty) return '';
    return ' extends ${_trimInterfaceName(parent)}';
  }

  String? _getConcreteParentName(ClassMetadata metadata) {
    for (final iface in metadata.interfaces) {
      final name = iface.interfaceName;
      if (name.startsWith(r'$') && !name.startsWith(r'$$')) {
        final trimmedName = _trimInterfaceName(name);
        final parentElement =
            metadata.allAnnotatedClasses[trimmedName];
        if (parentElement != null) {
          final parentIsAbstract =
              parentElement.name?.startsWith(r'$$') ?? false;
          if (!parentIsAbstract) {
            return trimmedName;
          }
        }
        return trimmedName;
      }
    }
    return null;
  }

  String _trimInterfaceName(String name) {
    if (name.startsWith(r'$$')) return name.substring(2);
    if (name.startsWith(r'$')) return name.substring(1);
    return name;
  }

  bool _determineExtendsAbstractClass(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final parent = _getExtendedParentName(metadata, config);
    if (parent.isEmpty) return false;
    if (parent.startsWith(r'$$')) return true;
    return false;
  }

  Set<String> _getParentFieldsForSuper(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final parentName = _getExtendedParentName(metadata, config);
    if (parentName.isEmpty) return <String>{};

    InterfaceMetadata? parentIface;
    for (final iface in metadata.interfaces) {
      if (iface.interfaceName == parentName) {
        parentIface = iface;
        break;
      }
    }

    if (parentIface == null) return <String>{};

    final resolvedParentFields = FieldResolver.resolve(
      parentIface.element,
      metadata.allAnnotatedClasses,
    );

    return resolvedParentFields.map((f) => f.name).toSet();
  }
}
