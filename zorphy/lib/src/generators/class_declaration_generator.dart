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
/// Produces a native [Class] spec.
class ClassDeclarationGenerator extends UniversalGenerator {
  /// Creates a generator for class declarations and constructors.
  ClassDeclarationGenerator();

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
        c.implements.add(referType(_trimInterfaceName(iface.interfaceName)));
      }
      for (final f in metadata.allFields) {
        c.methods.add(
          Method((m) {
            m.type = MethodType.getter;
            m.name = f.name;
            var fieldType = f.type != null
                ? helpers.replaceDollarTypesWithConcrete(f.type!)
                : f.type;
            m.returns = _referFieldType(fieldType);

            // JsonKey annotation
            if (f.jsonKeyInfo != null) {
              m.annotations.add(
                CodeExpression(Code(f.jsonKeyInfo!.toAnnotationString())),
              );
            }
          }),
        );
      }

      // Constructor for non-sealed abstract classes
      if (!isSealedWithSubtypes) {
        c.constructors.add(
          Constructor((con) {
            if (metadata.hasConstConstructor) {
              con.constant = true;
            }
          }),
        );
      }
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
        (!hasConcreteParent || parentHasConst) &&
        !config.autoId; // autoId injects a runtime uuid default — never const

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
      // NOTE: Do NOT include the `@` prefix here — code_builder's
      // DartEmitter adds `@` automatically when emitting annotations.
      final hasFactoryMethods = config.factoryMethods.isNotEmpty;
      final isAbstractClass = metadata.originalName.startsWith(r'$$');
      final shouldSkipJsonAnnotation = hasFactoryMethods && isAbstractClass;

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
          c.implements.add(referType(_trimInterfaceName(iface.interfaceName)));
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
        //
        // Issue #89: function-typed fields (callback fields like
        // `void Function(WebUri? url)?`) cannot be JSON-serialized by
        // json_serializable — it errors with "Could not generate `fromJson`
        // code for `<field>`". When the field type is a function type and
        // the user has not already opted out via their own @JsonKey, we
        // auto-emit `@JsonKey(includeFromJson: false, includeToJson: false)`
        // so json_serializable skips it. This mirrors the migrator's pattern
        // and preserves the field on the concrete class so the abstract
        // `$Foo` interface contract is still satisfied.
        final effectiveJsonKey = _effectiveJsonKeyForField(f);
        if (effectiveJsonKey != null) {
          fd.annotations.add(
            CodeExpression(
              Code(
                effectiveJsonKey.toAnnotationString(includeDefaultValue: true),
              ),
            ),
          );
        }

        // Additional annotations
        // Strip leading '@' — code_builder's DartEmitter adds it
        // automatically.
        for (final ann in f.additionalAnnotations) {
          final clean = ann.startsWith('@') ? ann.substring(1) : ann;
          fd.annotations.add(CodeExpression(Code(clean)));
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
      // autoId: the `id` field becomes an optional `String?` constructor
      // param that falls back to a fresh `Uuid().v4()` at construction
      // time. This is what makes `ChatMessage(role: ..., content: ...)`
      // valid without callers supplying an identity — see zuraffa#307.
      if (config.autoId && f.name == 'id') {
        params.add(
          Parameter((p) {
            p.name = f.name;
            p.type = referType('String?');
            p.named = true;
          }),
        );
        initializers.add('this.${f.name} = ${f.name} ?? const Uuid().v4()');
        continue;
      }

      // Skip getter-only without default value
      if (f.isGetterOnly && f.jsonKeyInfo?.defaultValue == null) {
        continue;
      }

      final defaultValue = f.jsonKeyInfo?.defaultValue;
      final hasDefaultValue = defaultValue != null;
      var fieldType = f.type != null
          ? helpers.replaceDollarTypesWithConcrete(f.type!)
          : f.type;

      final isNullable = fieldType != null &&
        (fieldType.endsWith('?') ||
         fieldType == 'dynamic' ||
         fieldType.startsWith('dynamic<') ||
         fieldType.startsWith('dynamic '));

      final isParentField =
          hasExtends &&
          !extendsAbstractClass &&
          parentFields.contains(f.name) &&
          !ownFields.contains(f.name);

      if (isParentField) {
        var safeFieldType = fieldType ?? 'dynamic';
        var isNull = safeFieldType.endsWith('?');
        var paramType = (isNull || hasDefaultValue)
            ? (safeFieldType.endsWith('?') ? safeFieldType : '$safeFieldType?')
            : safeFieldType;
        params.add(
          Parameter((p) {
            p.name = f.name;
            p.type = referType(paramType);
            p.named = true;
            p.required = !(isNull || hasDefaultValue);
          }),
        );
      } else if (hasDefaultValue) {
        var safeFieldType = fieldType ?? 'dynamic';
        var isNull = safeFieldType.endsWith('?');
        var paramType = isNull ? safeFieldType : '$safeFieldType?';
        params.add(
          Parameter((p) {
            p.name = f.name;
            p.type = referType(paramType);
            p.named = true;
          }),
        );

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

        initializers.add('this.${f.name} = ${f.name} ?? $defaultValueString');
      } else {
        var safeFieldType = fieldType ?? 'dynamic';
        params.add(Parameter((p) {
          p.name = f.name;
          p.type = referType(safeFieldType);
          p.named = true;
          p.required = !isNullable;
          p.toThis = true;
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
        // Super call with parent fields
        final superArgs = <String>[];
        for (final f in fields) {
          if (parentFields.contains(f.name)) {
            superArgs.add('${f.name}: ${f.name}');
          }
        }
        initParts.add('super(${superArgs.join(', ')})');
      } else {
        initParts.addAll(initializers);
      }

      // Set initializers as Code expressions
      for (final init in initParts) {
        con.initializers.add(Code(init));
      }
    });

    c.constructors.add(constructor);

    // Named constructor for copyWith (generateCopyWithFn)
    if (config.generateCopyWithFn) {
      final copyWithParams = <Parameter>[];
      for (final f in fields) {
        if (f.isGetterOnly && f.jsonKeyInfo?.defaultValue == null) {
          continue;
        }
        var fieldType = f.type != null
            ? helpers.replaceDollarTypesWithConcrete(f.type!)
            : f.type;
        // `dynamic` is already nullable — appending `?` produces
        // `dynamic?` which is redundant (issue #351 secondary).
        var alreadyNullable = fieldType!.endsWith('?') ||
            fieldType == 'dynamic' ||
            fieldType.startsWith('dynamic<') ||
            fieldType.startsWith('dynamic ');
        var nullableFieldType = alreadyNullable
            ? fieldType
            : '$fieldType?';
        copyWithParams.add(
          Parameter((p) {
            p.name = f.name;
            p.type = referType(nullableFieldType);
            p.named = true;
          }),
        );
      }

      final copyWithInitializers = <String>[];
      final copyWithFields = fields
          .where(
            (f) => !(f.isGetterOnly && f.jsonKeyInfo?.defaultValue == null),
          )
          .toList();
      for (final f in copyWithFields) {
        copyWithInitializers.add(
          '${f.name} = ${f.name} ?? (() { throw ArgumentError("${f.name} is required"); })()',
        );
      }

      c.constructors.add(
        Constructor((con) {
          con.name = 'copyWith';
          con.optionalParameters.addAll(copyWithParams);
          for (final init in copyWithInitializers) {
            con.initializers.add(Code(init));
          }
        }),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Null-safe type reference helper.
  TypeReference _referFieldType(String? type) {
    if (type == null || type.isEmpty) return referType('dynamic');
    return referType(type);
  }

  bool _parentHasConstConstructor(
    ClassMetadata metadata,
    String parentConcreteClassName,
  ) {
    for (final iface in metadata.interfaces) {
      final ifaceName = iface.element.name ?? '';
      final trimmedIfaceName = _trimInterfaceName(iface.interfaceName);
      if (ifaceName == parentConcreteClassName ||
          ifaceName == '\$$parentConcreteClassName' ||
          trimmedIfaceName == parentConcreteClassName) {
        return iface.element.constructors.any((e) => e.isConst);
      }
    }
    final parentElement =
        metadata.allAnnotatedClasses[parentConcreteClassName] ??
        metadata.allAnnotatedClasses['\$$parentConcreteClassName'];
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

  String _buildExtendsClause(ClassMetadata metadata, GenerationConfig config) {
    final parent = _getExtendedParentName(metadata, config);
    if (parent.isEmpty) return '';
    return ' extends ${_trimInterfaceName(parent)}';
  }

  String? _getConcreteParentName(ClassMetadata metadata) {
    for (final iface in metadata.interfaces) {
      final name = iface.interfaceName;
      if (name.startsWith(r'$') && !name.startsWith(r'$$')) {
        final trimmedName = _trimInterfaceName(name);
        final parentElement = metadata.allAnnotatedClasses[trimmedName];
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

  // ═══════════════════════════════════════════════════════════════
  // ISSUE #89 HELPERS — function-typed field JSON serialization
  // ═══════════════════════════════════════════════════════════════

  /// Returns true when [type] is a function type (e.g.
  /// `void Function(WebUri? url)?`, `String Function(int)`).
  ///
  /// Function-typed fields cannot be JSON-serialized by json_serializable
  /// — they need `@JsonKey(includeFromJson: false, includeToJson: false)`.
  /// We detect them by looking for ` Function(` (with a leading space to
  /// avoid matching a class named `Function`), allowing any return type
  /// prefix. The check is intentionally permissive: it matches the
  /// existing `type.contains('Function')` heuristic used in
  /// `helpers.getPatchClass` (helpers.dart line 221).
  bool _isFunctionType(String? type) {
    if (type == null || type.isEmpty) return false;
    // A function type always contains `Function(` (possibly with `<typeArgs>`
    // between `Function` and `(`, e.g. `T Function<U>(U)` — rare but valid).
    // Strip whitespace differences by checking for `Function` followed by
    // optional `<...>` then `(`. We don't need a full parser — any type
    // string that contains this pattern is a function type for our purposes.
    final cleaned = type.replaceAll(' ', '');
    // Look for `Function(` or `Function<` after stripping spaces. Both forms
    // indicate a function type.
    return cleaned.contains('Function(') || cleaned.contains('Function<');
  }

  /// Computes the effective [JsonKeyInfo] to emit for [field].
  ///
  /// - If the user provided no @JsonKey and the field is NOT function-typed,
  ///   returns null (no annotation emitted — preserves existing behavior).
  /// - If the user provided no @JsonKey and the field IS function-typed,
  ///   returns a synthetic `JsonKey(includeFromJson: false, includeToJson: false)`.
  /// - If the user provided an @JsonKey:
  ///   - For non-function-typed fields, returns it as-is (existing behavior).
  ///   - For function-typed fields, returns an augmented copy with
  ///     `includeFromJson: false` and `includeToJson: false` forced to false
  ///     UNLESS the user already set them explicitly. This prevents
  ///     json_serializable from trying to generate a serializer for the
  ///     function type while still honoring user-provided name/defaultValue/
  ///     fromJson/toJson settings.
  JsonKeyInfo? _effectiveJsonKeyForField(NameTypeClassComment field) {
    final isFn = _isFunctionType(field.type);
    final user = field.jsonKeyInfo;

    if (user == null) {
      if (!isFn) return null;
      // Function-typed field with no user-provided @JsonKey — auto-emit
      // the skip-serialization JsonKey.
      return const JsonKeyInfo(
        includeFromJson: false,
        includeToJson: false,
      );
    }

    if (!isFn) {
      // Non-function-typed field with user-provided @JsonKey — respect as-is.
      return user;
    }

    // Function-typed field WITH user-provided @JsonKey. Augment with
    // includeFromJson=false / includeToJson=false unless the user already
    // set them explicitly.
    if (user.includeFromJson == false && user.includeToJson == false) {
      return user; // User already opted out — leave alone.
    }
    return JsonKeyInfo(
      name: user.name,
      ignore: user.ignore,
      defaultValue: user.defaultValue,
      required: user.required,
      includeIfNull: user.includeIfNull,
      includeFromJson: user.includeFromJson ?? false,
      includeToJson: user.includeToJson ?? false,
      disallowNullValue: user.disallowNullValue,
      toJson: user.toJson,
      fromJson: user.fromJson,
      converter: user.converter,
    );
  }
}
