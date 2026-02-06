import 'package:dartx/dartx.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/classes.dart';
import 'package:zorphy/src/factory_method.dart';

List<NameTypeClassComment> getDistinctFields(
  List<NameTypeClassComment> allFields,
  List<Interface> interfaces,
) {
  var allFieldsDistinct = <NameTypeClassComment>[];

  // Add interface fields first (deduplicate by name)
  for (var i in interfaces) {
    for (var f in i.fields) {
      // Skip if already added from another interface
      if (allFieldsDistinct.any((x) => x.name == f.name)) {
        continue;
      }

      var field = allFields.firstOrNullWhere((x) => x.name == f.name);
      if (field != null) {
        allFieldsDistinct.add(field);
      } else {
        allFieldsDistinct.add(
          NameTypeClassComment(f.name, f.type, i.interfaceName),
        );
      }
    }
  }

  // Add class fields that aren't in interfaces
  for (var f in allFields) {
    if (!allFieldsDistinct.any((x) => x.name == f.name)) {
      allFieldsDistinct.add(f);
    }
  }

  return allFieldsDistinct;
}

String getProperties(
  List<NameTypeClassComment> fields,
  String className,
  bool isAbstract,
  bool hidePublicConstructor,
  bool generateCopyWithFn,
  bool generateJson,
  bool hasExtends, {
  bool extendsAbstractClass = false,
  Set<String> parentFields = const {},
  Set<String> ownFields = const {},
  Set<String> allInheritedFields = const {},
}) {
  var sb = StringBuffer();
  var classNameTrimmed = className.replaceAll("\$", "");

  for (var f in fields) {
    // Add JsonKey annotation if present from source
    if (f.jsonKeyInfo != null) {
      sb.writeln("  ${f.jsonKeyInfo!.toAnnotationString()}");
    }

    // Add additional annotations
    for (var a in f.additionalAnnotations) {
      sb.writeln("  $a");
    }

    // Determine the field type
    // For concrete classes, replace $-prefixed types with concrete class names
    var fieldType = f.type;
    if (!isAbstract && fieldType != null) {
      fieldType = _replaceDollarTypesWithConcrete(fieldType);
    }

    if (isAbstract) {
      sb.writeln("  ${fieldType} get ${f.name};");
    } else {
      // Add @override if field exists in any parent interface
      if (hasExtends && allInheritedFields.contains(f.name)) {
        sb.writeln("  @override");
      }
      sb.writeln("  final ${fieldType} ${f.name};");
    }
  }

  if (!isAbstract && !hidePublicConstructor) {
    // Constructor
    sb.writeln("");
    if (fields.isEmpty) {
      sb.writeln("  ${classNameTrimmed}()");
    } else {
      sb.writeln("  ${classNameTrimmed}({");
      for (var f in fields) {
        // Determine the field type (same logic as above for field declarations)
        var fieldType = f.type;
        if (fieldType != null) {
          fieldType = _replaceDollarTypesWithConcrete(fieldType);
        }

        // Check if field is nullable - if it ends with ?, don't add required
        // Use the transformed fieldType to check for nullability
        var isNullable = fieldType != null && fieldType.endsWith('?');
        var requiredKeyword = isNullable ? "" : "required ";
        sb.writeln("    ${requiredKeyword}this.${f.name},");
      }
      sb.writeln("  })");
    }

    // Add super call when extending abstract class
    if (hasExtends && extendsAbstractClass) {
      // Extending abstract class - call super()
      sb.writeln("  : super();");
    } else if (hasExtends && !extendsAbstractClass) {
      // Extending concrete class - call super() with parent fields only
      sb.writeln("  : super(");
      for (var f in fields) {
        if (parentFields.contains(f.name)) {
          sb.writeln("      ${f.name}: ${f.name},");
        }
      }
      sb.writeln("    );");
    } else {
      sb.writeln("  ;");
    }

    // Named constructor for copyWith
    if (generateCopyWithFn) {
      sb.writeln("");
      if (fields.isEmpty) {
        sb.writeln("  ${classNameTrimmed}.copyWith() : ");
      } else {
        sb.writeln("  ${classNameTrimmed}.copyWith({");
        for (var f in fields) {
          var fieldType = f.type != null
              ? _replaceDollarTypesWithConcrete(f.type!)
              : f.type;
          // For copyWith, we want all parameters to be nullable, so add ? if not already present
          var nullableFieldType = fieldType!.endsWith('?')
              ? fieldType
              : '${fieldType}?';
          sb.writeln("    $nullableFieldType ${f.name},");
        }
        sb.writeln("  }) : ");
      }
      for (var i = 0; i < fields.length; i++) {
        var f = fields[i];
        var comma = i == fields.length - 1 ? ";" : ",";
        sb.writeln(
          "    ${f.name} = ${f.name} ?? (() { throw ArgumentError(\"${f.name} is required\"); })()$comma",
        );
      }
    }
  }

  return sb.toString();
}

String generateFactoryMethod(
  FactoryMethodInfo factory,
  String classNameTrimmed,
  List<NameTypeClassComment> allFields,
) {
  var sb = StringBuffer();

  sb.write("  factory ${classNameTrimmed}.${factory.name}(");

  if (factory.parameters.isNotEmpty) {
    if (factory.parameters.any((p) => p.isNamed)) {
      sb.write("{");
      sb.write(
        factory.parameters
            .map((p) {
              var prefix = p.isRequired ? "required " : "";
              var suffix = p.hasDefaultValue && p.defaultValue != null
                  ? " = ${p.defaultValue}"
                  : "";
              var cleanType = _replaceDollarTypesWithConcrete(p.type);
              return "${prefix}${cleanType} ${p.name}${suffix}";
            })
            .join(", "),
      );
      sb.write("}");
    } else {
      sb.write(
        factory.parameters
            .map((p) {
              var suffix = p.hasDefaultValue && p.defaultValue != null
                  ? " = ${p.defaultValue}"
                  : "";
              var cleanType = _replaceDollarTypesWithConcrete(p.type);
              return "${cleanType} ${p.name}${suffix}";
            })
            .join(", "),
      );
    }
  }

  sb.write(") => ");

  var bodyCode = factory.bodyCode;
  var useAbstractFactoryCall = bodyCode.trim().isEmpty;
  if (useAbstractFactoryCall) {
    var callArgs = factory.parameters
        .map((p) => p.isNamed ? "${p.name}: ${p.name}" : p.name)
        .join(", ");
    var abstractClassName = factory.className; // Use original name (e.g. $AssistantMessage)
    bodyCode = "${abstractClassName}.${factory.name}($callArgs)";
  }

  if (bodyCode.contains('return ') && bodyCode.endsWith(';')) {
    bodyCode = bodyCode.substring(7, bodyCode.length - 1);
  }

  if (!useAbstractFactoryCall) {
    bodyCode = bodyCode
        .replaceAll(
          '${factory.className.replaceAll('\$', '')}._',
          '${classNameTrimmed}._',
        )
        .replaceAll('\$', '');
  }

  sb.writeln("${bodyCode};");
  sb.writeln();

  return sb.toString();
}

/// Generates changeTo extension methods for explicitSubTypes
/// This allows converting from one concrete class to another explicit subtype
String getChangeToExtension({
  required List<NameTypeClassComment> sourceFields,
  required String sourceClassName,
  required List<Interface> explicitSubTypes,
  required List<String> knownClasses,
}) {
  var sb = StringBuffer();

  if (explicitSubTypes.isEmpty) {
    return '';
  }

  var sourceClassNameTrimmed = sourceClassName.replaceAll('\$', '');
  sb.writeln();
  sb.writeln(
    "extension ${sourceClassNameTrimmed}ChangeToE on $sourceClassNameTrimmed {",
  );

  for (var targetInterface in explicitSubTypes) {
    var targetClassName = targetInterface.interfaceName.replaceAll('\$', '');
    var targetFields = targetInterface.fields;
    var targetFieldsDistinct = <NameType>[];
    var targetFieldNames = <String>{};
    for (var field in targetFields) {
      if (targetFieldNames.add(field.name)) {
        targetFieldsDistinct.add(field);
      }
    }

    // Generate parameters for the target type - only include fields that aren't in source
    var sourceFieldNames = sourceFields.map((f) => f.name).toSet();
    var targetOnlyFields = targetFieldsDistinct
        .where((f) => !sourceFieldNames.contains(f.name))
        .toList();

    // Build parameter list
    var params = <String>[];
    for (var field in targetOnlyFields) {
      var fieldTypeRaw = field.type ?? '';
      var fieldType = _replaceDollarTypesWithConcrete(fieldTypeRaw);
      var fieldName = field.name;
      var isNullable = fieldType.endsWith('?');

      if (isNullable) {
        params.add('$fieldType $fieldName');
      } else {
        params.add('required $fieldType $fieldName');
      }
    }

    // Also include fields that exist in both but might want to override (nullable)
    for (var field in targetFieldsDistinct) {
      var fieldTypeRaw = field.type ?? '';
      var fieldType = _replaceDollarTypesWithConcrete(fieldTypeRaw);
      var fieldName = field.name;
      var isNullable = fieldType.endsWith('?');

      if (sourceFieldNames.contains(fieldName) && isNullable) {
        // Add optional parameter for fields that exist in both
        params.add('$fieldType $fieldName');
      }
    }

    // Generate method signature
    var paramsStr = params.join(", ");
    var paramClause = paramsStr.isNotEmpty ? '{$paramsStr}' : '';
    sb.writeln('  $targetClassName changeTo$targetClassName($paramClause) {');
    sb.writeln('    final _patcher = ${targetClassName}Patch();');

    // Set required fields
    for (var field in targetOnlyFields) {
      var fieldName = field.name;
      var fieldTypeRaw = field.type ?? '';
      var fieldType = _replaceDollarTypesWithConcrete(fieldTypeRaw);
      var isNullable = fieldType.endsWith('?');
      var fieldNameCap = fieldName[0].toUpperCase() + fieldName.substring(1);

      if (!isNullable) {
        sb.writeln('    _patcher.with$fieldNameCap($fieldName);');
      } else if (params.contains('$fieldType $fieldName')) {
        sb.writeln('    if ($fieldName != null) {');
        sb.writeln('      _patcher.with$fieldNameCap($fieldName);');
        sb.writeln('    }');
      }
    }

    // Set optional override fields
    for (var field in targetFieldsDistinct) {
      var fieldTypeRaw = field.type ?? '';
      var fieldType = _replaceDollarTypesWithConcrete(fieldTypeRaw);
      var fieldName = field.name;
      var isNullable = fieldType.endsWith('?');
      var fieldNameCap = fieldName[0].toUpperCase() + fieldName.substring(1);

      if (sourceFieldNames.contains(fieldName) &&
          isNullable &&
          params.contains('$fieldType $fieldName')) {
        sb.writeln('    if ($fieldName != null) {');
        sb.writeln('      _patcher.with$fieldNameCap($fieldName);');
        sb.writeln('    }');
      }
    }

    sb.writeln('    final _patchMap = _patcher.toPatch();');

    // Generate constructor call
    sb.write('    return $targetClassName(');

    var constructorParams = <String>[];
    for (var field in targetFieldsDistinct) {
      var fieldName = field.name;
      var fieldTypeRaw = field.type ?? '';
      var fieldType = _replaceDollarTypesWithConcrete(fieldTypeRaw);
      var fieldEnum = "${targetClassName}\$.$fieldName";
      var isNullable = fieldType.endsWith('?');

      // Check if field has special handling (needs patch handling)
      var baseType = fieldType.replaceAll('?', '');
      var needsPatchHandling = _needsPatchHandling(baseType, knownClasses);

      if (needsPatchHandling) {
        constructorParams.add(
          '      $fieldName: _patchMap.containsKey($fieldEnum)\n'
          '          ? (_patchMap[$fieldEnum] is Function)\n'
          '                ? _patchMap[$fieldEnum]($fieldName)\n'
          '                : _patchMap[$fieldEnum]\n'
          '          : $fieldName',
        );
      } else if (isNullable && params.contains('$fieldType $fieldName')) {
        // Optional parameter that might be in patch
        constructorParams.add(
          '      $fieldName: _patchMap.containsKey($fieldEnum)\n'
          '          ? (_patchMap[$fieldEnum] is Function)\n'
          '                ? _patchMap[$fieldEnum]($fieldName)\n'
          '                : _patchMap[$fieldEnum]\n'
          '          : $fieldName',
        );
      } else if (!sourceFieldNames.contains(fieldName)) {
        // Field only in target (required)
        constructorParams.add('      $fieldName: _patchMap[$fieldEnum]');
      } else {
        // Field in both - use patch or current value
        constructorParams.add(
          '      $fieldName: _patchMap.containsKey($fieldEnum)\n'
          '          ? (_patchMap[$fieldEnum] is Function)\n'
          '                ? _patchMap[$fieldEnum]($fieldName)\n'
          '                : _patchMap[$fieldEnum]\n'
          '          : $fieldName',
        );
      }
    }

    if (constructorParams.isNotEmpty) {
      sb.writeln();
      for (var i = 0; i < constructorParams.length; i++) {
        var isLast = i == constructorParams.length - 1;
        sb.write(constructorParams[i]);
        if (!isLast) {
          sb.writeln(',');
        } else {
          sb.writeln();
        }
      }
    }

    sb.writeln('    );');
    sb.writeln('  }');
    sb.writeln();
  }

  sb.writeln('}');

  return sb.toString();
}

/// Check if a type needs patch handling (is a known Zorphy class)
bool _needsPatchHandling(String baseType, List<String> knownClasses) {
  return knownClasses.contains(baseType);
}

/// Replace $-prefixed types with concrete class names for JSON serialization
/// For example: $TreeNode -> TreeNode, List<$TreeNode> -> List<TreeNode>
String _replaceDollarTypesWithConcrete(String type) {
  // Handle outer nullability
  final isOuterNullable = type.endsWith('?');
  final baseType = isOuterNullable ? type.substring(0, type.length - 1) : type;

  // Handle List<$Type> or List<$Type?>
  if (baseType.startsWith('List<') && baseType.endsWith('>')) {
    final innerType = baseType.substring(5, baseType.length - 1);
    final isInnerNullable = innerType.endsWith('?');
    final baseInnerType = isInnerNullable
        ? innerType.substring(0, innerType.length - 1)
        : innerType;

    if (baseInnerType.startsWith('\$')) {
      final trimmedType = baseInnerType.replaceAll('\$', '');
      return 'List<$trimmedType${isInnerNullable ? '?' : ''}>${isOuterNullable ? '?' : ''}';
    }
    return type;
  }

  // Handle Map<K, $Type> or Map<K, $Type?>
  if (baseType.startsWith('Map<') && baseType.endsWith('>')) {
    final content = baseType.substring(4, baseType.length - 1);
    final commaIndex = content.lastIndexOf(',');
    if (commaIndex != -1) {
      final keyPart = content.substring(0, commaIndex).trim();
      final valuePart = content.substring(commaIndex + 1).trim();

      final isValueNullable = valuePart.endsWith('?');
      final baseValueType = isValueNullable
          ? valuePart.substring(0, valuePart.length - 1)
          : valuePart;

      if (baseValueType.startsWith('\$')) {
        final trimmedType = baseValueType.replaceAll('\$', '');
        return 'Map<$keyPart, $trimmedType${isValueNullable ? '?' : ''}>${isOuterNullable ? '?' : ''}';
      }
    }
    return type;
  }

  // Handle direct $Type or $Type?
  if (baseType.startsWith('\$')) {
    final trimmedType = baseType.replaceAll('\$', '');
    return '$trimmedType${isOuterNullable ? '?' : ''}';
  }

  return type;
}

String getPropertiesAbstract(
  List<NameTypeClassComment> fields,
  String className,
  bool generateCopyWithFn, {
  bool isSealedWithSubtypes = false,
}) {
  var sb = StringBuffer();

  for (var f in fields) {
    // Add JsonKey annotation if present
    if (f.jsonKeyInfo != null) {
      sb.writeln("  ${f.jsonKeyInfo!.toAnnotationString()}");
    }
    var fieldType = f.type != null
        ? _replaceDollarTypesWithConcrete(f.type!)
        : f.type;
    sb.writeln("  $fieldType get ${f.name};");
  }

  // Constructor for abstract classes
  if (!isSealedWithSubtypes) {
    // Abstract class - add public constructor (can't use _internal as it's library-private)
    sb.writeln("");
    sb.writeln("  ${className}();");
  }
  // Sealed classes with subtypes don't need a constructor

  // Named constructor for copyWith
  if (generateCopyWithFn) {
    sb.writeln("");
    sb.writeln("  factory ${className}.copyWith({");
    for (var f in fields) {
      var cwFieldType = f.type != null
          ? _replaceDollarTypesWithConcrete(f.type!)
          : f.type;
      sb.writeln("    $cwFieldType? ${f.name},");
    }
    sb.writeln("  }) = _\$${className}CopyWith;");
  }

  return sb.toString();
}

String getCopyWith(
  List<NameTypeClassComment> fields,
  String className,
  bool generateCopyWithFn,
) {
  var sb = StringBuffer();
  var classNameTrimmed = className.replaceAll("\$", "");

  // Regular copyWith method (standard convention)
  if (fields.isEmpty) {
    sb.writeln("  $classNameTrimmed copyWith() {");
  } else {
    sb.writeln("  $classNameTrimmed copyWith({");
    for (var f in fields) {
      var fieldType = _replaceDollarTypesWithConcrete(f.type ?? 'dynamic');
      var nullableType = fieldType.endsWith('?') ? fieldType : '$fieldType?';
      sb.writeln("    $nullableType ${f.name},");
    }
    sb.writeln("  }) {");
  }
  sb.writeln("    return $classNameTrimmed(");
  for (var f in fields) {
    sb.writeln("      ${f.name}: ${f.name} ?? this.${f.name},");
  }
  sb.writeln("    );");
  sb.writeln("  }");

  // Alias: copyWith{Entity} for polymorphic/disambiguation cases
  // This delegates to the standard copyWith method
  sb.writeln("");
  if (fields.isEmpty) {
    sb.writeln("  $classNameTrimmed copyWith$classNameTrimmed() {");
  } else {
    sb.writeln("  $classNameTrimmed copyWith$classNameTrimmed({");
    for (var f in fields) {
      var fieldType = _replaceDollarTypesWithConcrete(f.type ?? 'dynamic');
      var nullableType = fieldType.endsWith('?') ? fieldType : '$fieldType?';
      sb.writeln("    $nullableType ${f.name},");
    }
    sb.writeln("  }) {");
  }
  sb.writeln("    return copyWith(");
  if (fields.isNotEmpty) {
    var params = fields.map((f) => "${f.name}: ${f.name}").join(", ");
    sb.writeln("      $params,");
  }
  sb.writeln("    );");
  sb.writeln("  }");

  // Function-based copyWith if enabled
  if (generateCopyWithFn) {
    sb.writeln("");
    if (fields.isEmpty) {
      sb.writeln("  $classNameTrimmed copyWithFn() {");
    } else {
      sb.writeln("  $classNameTrimmed copyWithFn({");
      for (var f in fields) {
        var fieldType = _replaceDollarTypesWithConcrete(f.type ?? 'dynamic');
        // Function parameter and return type match the field type exactly
        // Only the function itself is nullable
        sb.writeln("    $fieldType Function($fieldType)? ${f.name},");
      }
      sb.writeln("  }) {");
    }
    sb.writeln("    return $classNameTrimmed(");
    for (var f in fields) {
      sb.writeln(
        "      ${f.name}: ${f.name} != null ? ${f.name}(this.${f.name}) : this.${f.name},",
      );
    }
    sb.writeln("    );");
    sb.writeln("  }");
  }

  return sb.toString();
}

String getInterfaceCopyWithMethods(
  List<Interface> interfaces,
  List<NameTypeClassComment> classFields,
  String className,
) {
  var sb = StringBuffer();
  var classNameTrimmed = className.replaceAll("\$", "");
  var classFieldNames = classFields.map((f) => f.name).toSet();

  for (var i in interfaces) {
    var interfaceName = i.interfaceName;
    if (!interfaceName.startsWith("\$") || interfaceName.startsWith("\$\$")) {
      continue;
    }
    var interfaceNameTrimmed = interfaceName.replaceAll("\$", "");
    if (interfaceNameTrimmed == classNameTrimmed) continue;

    var interfaceFields = i.fields
        .where((f) => classFieldNames.contains(f.name))
        .toList();
    if (interfaceFields.isEmpty) continue;

    sb.writeln("");
    sb.writeln("  $classNameTrimmed copyWith$interfaceNameTrimmed({");
    for (var f in interfaceFields) {
      var fieldType = _replaceDollarTypesWithConcrete(f.type ?? 'dynamic');
      var nullableType = fieldType.endsWith('?') ? fieldType : '$fieldType?';
      sb.writeln("    $nullableType ${f.name},");
    }
    sb.writeln("  }) {");
    sb.writeln("    return copyWith(");
    var params = interfaceFields.map((f) => "${f.name}: ${f.name}").join(", ");
    sb.writeln("      $params,");
    sb.writeln("    );");
    sb.writeln("  }");
  }

  return sb.toString();
}

String getInterfaceCopyWithFnMethods(
  List<Interface> interfaces,
  List<NameTypeClassComment> classFields,
  String className,
  List<NameTypeClassComment> allFieldsDistinct,
) {
  var sb = StringBuffer();
  var classNameTrimmed = className.replaceAll("\$", "");

  for (var i in interfaces) {
    var interfaceName = i.interfaceName;
    if (!interfaceName.startsWith("\$") || interfaceName.startsWith("\$\$")) {
      continue;
    }
    var interfaceNameTrimmed = interfaceName.replaceAll("\$", "");
    if (interfaceNameTrimmed == classNameTrimmed) continue;

    var interfaceFields = i.fields
        .where((f) => allFieldsDistinct.any((af) => af.name == f.name))
        .toList();
    if (interfaceFields.isEmpty) continue;

    sb.writeln("");
    sb.writeln("  $classNameTrimmed copyWith${interfaceNameTrimmed}Fn({");
    for (var f in interfaceFields) {
      var fieldType = _replaceDollarTypesWithConcrete(f.type ?? 'dynamic');
      var nullableType = fieldType.endsWith('?') ? fieldType : '$fieldType?';
      sb.writeln("    $nullableType Function()? ${f.name},");
    }
    sb.writeln("  }) {");
    sb.writeln("    return copyWith(");
    var params = interfaceFields
        .map(
          (f) => "${f.name}: ${f.name} != null ? ${f.name}() : this.${f.name}",
        )
        .join(", ");
    sb.writeln("      $params,");
    sb.writeln("    );");
    sb.writeln("  }");
  }

  return sb.toString();
}

String getEqualsAndHashCode(
  List<NameTypeClassComment> fields,
  String className,
) {
  var sb = StringBuffer();

  // equals operator
  sb.writeln("  @override");
  sb.writeln("  bool operator ==(Object other) {");
  sb.writeln("    if (identical(this, other)) return true;");
  if (fields.isEmpty) {
    sb.writeln("    return other is $className;");
  } else {
    sb.writeln("    return other is $className &&");
    for (var i = 0; i < fields.length; i++) {
      var f = fields[i];
      var comma = i == fields.length - 1 ? ";" : " &&";
      sb.writeln("        ${f.name} == other.${f.name}$comma");
    }
  }
  sb.writeln("  }");

  // hashCode
  sb.writeln("");
  sb.writeln("  @override");
  sb.writeln("  int get hashCode {");
  if (fields.isEmpty) {
    sb.writeln("    return 0;");
  } else if (fields.length == 1) {
    // For single field, use Object.hash() with the field and 0
    sb.writeln("    return Object.hash(${fields[0].name}, 0);");
  } else if (fields.length <= 20) {
    // For 2-20 fields, use Object.hash() directly
    sb.writeln("    return Object.hash(");
    for (var i = 0; i < fields.length; i++) {
      var f = fields[i];
      var comma = i == fields.length - 1 ? ");" : ",";
      sb.writeln("      this.${f.name}$comma");
    }
  } else {
    // For >20 fields, split into multiple Object.hash() calls and combine
    var chunkSize = 20;
    var chunks = (fields.length / chunkSize).ceil();

    for (var c = 0; c < chunks; c++) {
      var start = c * chunkSize;
      var end = (start + chunkSize).clamp(0, fields.length);
      var chunkFields = fields.sublist(start, end);

      if (c == 0) {
        sb.write("    return Object.hash(");
        for (var i = 0; i < chunkFields.length; i++) {
          var f = chunkFields[i];
          var comma = i == chunkFields.length - 1 ? ")" : ",";
          sb.write("this.${f.name}$comma");
        }
      } else {
        sb.write(" ^ Object.hash(");
        for (var i = 0; i < chunkFields.length; i++) {
          var f = chunkFields[i];
          var comma = i == chunkFields.length - 1 ? ")" : ",";
          sb.write("this.${f.name}$comma");
        }
      }
    }
    sb.writeln(";");
  }
  sb.writeln("  }");

  return sb.toString();
}

String getToString(List<NameTypeClassComment> fields, String className) {
  var sb = StringBuffer();

  sb.writeln("  @override");
  sb.writeln("  String toString() {");
  if (fields.isEmpty) {
    sb.writeln("    return '$className()';");
  } else {
    sb.writeln("    return '$className(' +");

    for (var i = 0; i < fields.length; i++) {
      var f = fields[i];
      var isLast = i == fields.length - 1;
      sb.write("        '${f.name}: \${${f.name}}");
      if (isLast) {
        sb.writeln(")';");
      } else {
        sb.writeln("' + ', ' +");
      }
    }
  }
  sb.writeln("  }");

  return sb.toString();
}

String getEnumPropertyList(
  List<NameTypeClassComment> fields,
  String className,
) {
  if (fields.isEmpty) return '';

  String classNameTrimmed = '${className.replaceAll("\$", "")}';
  String enumName = '${classNameTrimmed}\$';

  var sb = StringBuffer();

  // Generate enum
  sb.writeln("enum $enumName {");
  sb.writeln(
    fields
        .map((e) => e.name.startsWith("_") ? e.name.substring(1) : e.name)
        .join(","),
  );
  sb.writeln("}\n");
  return sb.toString();
}

String getPatchClass(
  List<NameTypeClassComment> fields,
  String className,
  List<String> knownClasses, [
  List<String> genericTypeNames = const [],
]) {
  if (fields.isEmpty) {
    // Don't generate patch classes for classes with no fields
    return '';
  }

  String classNameTrimmed = '${className.replaceAll("\$", "")}';
  String enumName = '${classNameTrimmed}\$';

  var sb = StringBuffer();

  // Add Patch<T> implementation
  sb.writeln(
    "class ${classNameTrimmed}Patch implements Patch<$classNameTrimmed> {",
  );
  sb.writeln("  final Map<$enumName, dynamic> _patch = {};");
  sb.writeln();

  // Static factory methods
  sb.writeln(
    "  static ${classNameTrimmed}Patch create([Map<String, dynamic>? diff]) {",
  );
  sb.writeln("    final patch = ${classNameTrimmed}Patch();");
  sb.writeln("    if (diff != null) {");
  sb.writeln("      diff.forEach((key, value) {");
  sb.writeln("        try {");
  sb.writeln(
    "          final enumValue = $enumName.values.firstWhere((e) => e.name == key);",
  );
  sb.writeln("          if (value is Function) {");
  sb.writeln("            patch._patch[enumValue] = value();");
  sb.writeln("          } else {");
  sb.writeln("            patch._patch[enumValue] = value;");
  sb.writeln("          }");
  sb.writeln("        } catch (_) {}");
  sb.writeln("      });");
  sb.writeln("    }");
  sb.writeln("    return patch;");
  sb.writeln("  }");
  sb.writeln();

  // Generate fromPatch
  sb.writeln(
    "  static ${classNameTrimmed}Patch fromPatch(Map<${classNameTrimmed}\$, dynamic> patch) {",
  );
  sb.writeln("    final _patch = ${classNameTrimmed}Patch();");
  sb.writeln("    _patch._patch.addAll(patch);");
  sb.writeln("    return _patch;");
  sb.writeln("  }");
  sb.writeln();

  // Convert to map method
  sb.writeln("  Map<$enumName, dynamic> toPatch() => Map.from(_patch);");
  sb.writeln();

  sb.writeln("  $classNameTrimmed applyTo($classNameTrimmed entity) {");
  sb.writeln("    return entity.patchWith$classNameTrimmed(patchInput: this);");
  sb.writeln("  }");
  sb.writeln();

  // Add toJson method with _className_
  sb.writeln("  Map<String, dynamic> toJson() {");
  sb.writeln("    final json = <String, dynamic>{};");
  sb.writeln("    _patch.forEach((key, value) {");
  sb.writeln("      if (value != null) {");
  sb.writeln("        if (value is Function) {");
  sb.writeln("          final result = value();");
  sb.writeln("          json[key.name] = _convertToJson(result);");
  sb.writeln("        } else {");
  sb.writeln("          json[key.name] = _convertToJson(value);");
  sb.writeln("        }");
  sb.writeln("      }");
  sb.writeln("    });");
  sb.writeln("    return json;");
  sb.writeln("  }");
  sb.writeln();

  // Add convertToJson method
  sb.writeln("  dynamic _convertToJson(dynamic value) {");
  sb.writeln("    if (value == null) return null;");
  sb.writeln("    if (value is DateTime) return value.toIso8601String();");
  sb.writeln("    if (value is Enum) return value.toString().split('.').last;");
  sb.writeln(
    "    if (value is List) return value.map((e) => _convertToJson(e)).toList();",
  );
  sb.writeln(
    "    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));",
  );
  sb.writeln(
    "    if (value is num || value is bool || value is String) return value;",
  );
  sb.writeln("    try {");
  sb.writeln(
    "        if (value?.toJsonLean != null) return value.toJsonLean();",
  );
  sb.writeln("      } catch (_) {}");
  sb.writeln("    if (value?.toJson != null) return value.toJson();");
  sb.writeln("    return value.toString();");
  sb.writeln("  }");
  sb.writeln();

  // Add fromJson factory
  sb.writeln(
    "  static ${classNameTrimmed}Patch fromJson(Map<String, dynamic> json) {",
  );
  sb.writeln("    return create(json);");
  sb.writeln("  }");
  sb.writeln();

  // Generate with methods
  for (var field in fields) {
    var name = field.name.startsWith("_")
        ? field.name.substring(1)
        : field.name;
    var baseType = getDataTypeWithoutDollars(field.type ?? "dynamic");
    var capitalizedName =
        name.substring(0, 1).toUpperCase() + name.substring(1);

    var cleanBaseType = baseType.replaceAll("?", "");
    var isGenericType =
        genericTypeNames.contains(cleanBaseType) ||
        baseType.contains('<') &&
            genericTypeNames.any((g) => baseType.contains(g));

    var parameterType = isGenericType
        ? 'dynamic'
        : (baseType.endsWith('?') ? baseType : "$baseType?");

    sb.writeln(
      "  ${classNameTrimmed}Patch with$capitalizedName($parameterType value) {",
    );
    sb.writeln("    _patch[$enumName.$name] = value;");
    sb.writeln("    return this;");
    sb.writeln("  }");
    sb.writeln();

    // Generate cross-file nested patch methods for Zorphy types
    var fieldType = field.type ?? "";
    var fieldTypeWithoutDollars = getDataTypeWithoutDollars(fieldType);
    var innerType = fieldTypeWithoutDollars.replaceAll("?", "");

    // Check if this is a Zorphy type (starts with $ and not a generic)
    bool isKnownClassType(String type) {
      if (type.startsWith("\$")) return true;
      return knownClasses.any((k) => type == k);
    }

    var isZorphyType =
        isKnownClassType(innerType) ||
        (innerType.startsWith("List<") &&
            isKnownClassType(
              innerType.replaceAll(RegExp(r'^List<(.+)>$'), r'$1'),
            )) ||
        (innerType.startsWith("Map<") &&
            isKnownClassType(
              innerType.replaceAll(RegExp(r'^Map<(.+, .+)>$'), r'$2'),
            ));

    if (isZorphyType && !isGenericType) {
      // Handle List types
      if (innerType.startsWith("List<")) {
        var listMatch = RegExp(r'^List<(.+)>$').firstMatch(innerType);
        if (listMatch != null) {
          var elementType = listMatch.group(1) ?? "";
          var elementTypeWithoutDollars = getDataTypeWithoutDollars(
            elementType,
          );
          var elementTypeIsZorphy =
              elementType.startsWith("\$") ||
              knownClasses.contains(elementTypeWithoutDollars);
          // Don't generate updateAt for abstract classes ($$) as they don't have Patch classes
          // Check the original field type to see if it had $$
          var isAbstractType = fieldType.contains("\$\$");
          if (elementTypeIsZorphy && !isAbstractType) {
            var elementPatchType = elementTypeWithoutDollars + "Patch";
            sb.writeln(
              "  ${classNameTrimmed}Patch update${capitalizedName}At(int index, $elementPatchType Function($elementPatchType) patch) {",
            );
            sb.writeln("    _patch[$enumName.$name] = (List<dynamic> list) {");
            sb.writeln("      var updatedList = List.from(list);");
            sb.writeln("      if (index >= 0 && index < updatedList.length) {");
            sb.writeln(
              "        updatedList[index] = patch(updatedList[index] as $elementPatchType);",
            );
            sb.writeln("      }");
            sb.writeln("      return updatedList;");
            sb.writeln("    };");
            sb.writeln("    return this;");
            sb.writeln("  }");
            sb.writeln();
          }
        }
      }
      // Handle Map types
      else if (innerType.startsWith("Map<")) {
        var mapMatch = RegExp(r'^Map<(.+), (.+)>$').firstMatch(innerType);
        if (mapMatch != null) {
          var keyType = mapMatch.group(1) ?? "";
          var valueType = mapMatch.group(2) ?? "";
          var valueTypeWithoutDollars = getDataTypeWithoutDollars(valueType);
          var valueTypeIsZorphy =
              valueType.startsWith("\$") ||
              knownClasses.contains(valueTypeWithoutDollars);
          if (valueTypeIsZorphy) {
            var valuePatchType = valueTypeWithoutDollars + "Patch";
            sb.writeln(
              "  ${classNameTrimmed}Patch update${capitalizedName}Value($keyType key, $valuePatchType Function($valuePatchType) patch) {",
            );
            sb.writeln(
              "    _patch[$enumName.$name] = (Map<dynamic, dynamic> map) {",
            );
            sb.writeln("      var updatedMap = Map.from(map);");
            sb.writeln("      if (updatedMap.containsKey(key)) {");
            sb.writeln(
              "        updatedMap[key] = patch(updatedMap[key] as $valuePatchType);",
            );
            sb.writeln("      }");
            sb.writeln("      return updatedMap;");
            sb.writeln("    };");
            sb.writeln("    return this;");
            sb.writeln("  }");
            sb.writeln();
          }
        }
      }
      // Handle single object types (nullable and non-nullable)
      else {
        var patchType = innerType + "Patch";
        // with{CapitalizedName}Patch method for direct patch application
        sb.writeln(
          "  ${classNameTrimmed}Patch with${capitalizedName}Patch($patchType patch) {",
        );
        sb.writeln("    _patch[$enumName.$name] = patch;");
        sb.writeln("    return this;");
        sb.writeln("  }");
        sb.writeln();

        // with{CapitalizedName}PatchFunc method for function-based patching
        var funcParamType = "$patchType Function($patchType)";
        sb.writeln(
          "  ${classNameTrimmed}Patch with${capitalizedName}PatchFunc($funcParamType patch) {",
        );
        sb.writeln("    _patch[$enumName.$name] = (dynamic current) {");
        sb.writeln("      var currentPatch = $patchType();");
        sb.writeln("      if (current != null) {");
        sb.writeln("        currentPatch = current as $patchType;");
        sb.writeln("      }");
        sb.writeln("      return patch(currentPatch);");
        sb.writeln("    };");
        sb.writeln("    return this;");
        sb.writeln("  }");
        sb.writeln();
      }
    }
  }

  sb.writeln("}");

  return sb.toString();
}

String getDataTypeWithoutDollars(String type) {
  return type.replaceAll('\$', '');
}

const PRIMITIVE_TYPES = [
  'String',
  'int',
  'double',
  'num',
  'bool',
  'DateTime',
  'List',
  'Set',
  'Map',
  'BigInt',
  'Duration',
  'Uri',
  'dynamic',
];

String getPatchWithMethod(List<NameTypeClassComment> fields, String className) {
  if (fields.isEmpty) return '';

  var classNameTrimmed = className.replaceAll("\$", "");
  var enumName = '${classNameTrimmed}\$';

  var sb = StringBuffer();

  sb.writeln("  $classNameTrimmed patchWith$classNameTrimmed({");
  sb.writeln("    $classNameTrimmed" + "Patch? patchInput,");
  sb.writeln("  }) {");
  sb.writeln(
    "    final _patcher = patchInput ?? $classNameTrimmed" + "Patch();",
  );
  sb.writeln("    final _patchMap = _patcher.toPatch();");
  sb.writeln("    return $classNameTrimmed(");

  for (var i = 0; i < fields.length; i++) {
    var f = fields[i];
    var comma = i == fields.length - 1 ? "" : ",";
    sb.writeln(
      "      ${f.name}: _patchMap.containsKey($enumName.${f.name}) ? (_patchMap[$enumName.${f.name}] is Function) ? _patchMap[$enumName.${f.name}](this.${f.name}) : _patchMap[$enumName.${f.name}] : this.${f.name}$comma",
    );
  }

  sb.writeln("    );");
  sb.writeln("  }");

  return sb.toString();
}

String getInterfacePatchWithMethods(
  List<Interface> interfaces,
  List<NameTypeClassComment> classFields,
  String className,
) {
  var sb = StringBuffer();
  var classNameTrimmed = className.replaceAll("\$", "");
  var classFieldNames = classFields.map((f) => f.name).toSet();

  for (var i in interfaces) {
    var interfaceName = i.interfaceName;
    if (!interfaceName.startsWith("\$") || interfaceName.startsWith("\$\$")) {
      continue;
    }
    var interfaceNameTrimmed = interfaceName.replaceAll("\$", "");
    if (interfaceNameTrimmed == classNameTrimmed) continue;

    var interfaceFields = i.fields
        .where((f) => classFieldNames.contains(f.name))
        .toList();
    if (interfaceFields.isEmpty) continue;

    var enumName = '${interfaceNameTrimmed}\$';
    var interfaceFieldNames = interfaceFields.map((f) => f.name).toSet();

    sb.writeln("");
    sb.writeln("  $classNameTrimmed patchWith$interfaceNameTrimmed({");
    sb.writeln("    $interfaceNameTrimmed" + "Patch? patchInput,");
    sb.writeln("  }) {");
    sb.writeln(
      "    final _patcher = patchInput ?? $interfaceNameTrimmed" + "Patch();",
    );
    sb.writeln("    final _patchMap = _patcher.toPatch();");
    sb.writeln("    return $classNameTrimmed(");

    for (var f in classFields) {
      if (interfaceFieldNames.contains(f.name)) {
        sb.writeln(
          "      ${f.name}: _patchMap.containsKey($enumName.${f.name}) ? (_patchMap[$enumName.${f.name}] is Function) ? _patchMap[$enumName.${f.name}](this.${f.name}) : _patchMap[$enumName.${f.name}] : this.${f.name},",
        );
      } else {
        sb.writeln("      ${f.name}: this.${f.name},");
      }
    }

    sb.writeln("    );");
    sb.writeln("  }");
  }

  return sb.toString();
}

String getCompareToExtension(
  String classNameTrimmed,
  List<NameTypeClassComment> allFields,
  List<Interface> knownInterfaces,
) {
  var sb = StringBuffer();
  sb.writeln();
  sb.writeln("extension ${classNameTrimmed}CompareE on $classNameTrimmed {");
  sb.writeln(
    "  Map<String, dynamic> compareTo$classNameTrimmed($classNameTrimmed other) {",
  );
  sb.writeln("    final Map<String, dynamic> diff = {};");
  sb.writeln();

  for (var field in allFields) {
    var fieldType = field.type ?? '';
    var fieldName = field.name;
    var isNullable = fieldType.endsWith('?');

    if (fieldType.contains('Function')) {
      continue; // Skip functions
    }

    if (isNullable) {
      sb.writeln("    if ($fieldName != other.$fieldName) {");
      sb.writeln("      diff['$fieldName'] = () => other.$fieldName;");
      sb.writeln("    }");
    } else {
      sb.writeln("    if ($fieldName != other.$fieldName) {");
      sb.writeln("      diff['$fieldName'] = () => other.$fieldName;");
      sb.writeln("    }");
    }
  }

  sb.writeln("    return diff;");
  sb.writeln("  }");
  sb.writeln("}");

  return sb.toString();
}
