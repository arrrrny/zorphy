import 'package:dartx/dartx.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/classes.dart';
import 'package:zorphy/src/factory_method.dart';

/// Deduplicates fields, prioritizing interface definitions first.
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
              var cleanType = replaceDollarTypesWithConcrete(p.type);
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
              var cleanType = replaceDollarTypesWithConcrete(p.type);
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
    var abstractClassName =
        factory.className; // Use original name (e.g. $AssistantMessage)
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

String replaceDollarTypesWithConcrete(String type) {
  // Handle outer nullability
  final isOuterNullable = type.endsWith('?');
  final baseType = isOuterNullable ? type.substring(0, type.length - 1) : type;

  // Recursively process nested generics
  String _processNestedType(String input) {
    // 1. If it's a generic type like List<...>, Map<...>, or Prefixed.Type<...>
    // First find the last top-level generic bracket pair
    final firstBracket = input.indexOf('<');
    final lastBracket = input.lastIndexOf('>');

    if (firstBracket != -1 && lastBracket > firstBracket) {
      final baseType = input.substring(0, firstBracket);
      final innerContent = input.substring(firstBracket + 1, lastBracket);

      // Split inner content by commas, but only at top level (not inside nested brackets)
      final arguments = <String>[];
      var bracketDepth = 0;
      var currentArgument = StringBuffer();

      for (var i = 0; i < innerContent.length; i++) {
        final char = innerContent[i];
        if (char == '<') {
          bracketDepth++;
          currentArgument.write(char);
        } else if (char == '>') {
          bracketDepth--;
          currentArgument.write(char);
        } else if (char == ',' && bracketDepth == 0) {
          arguments.add(currentArgument.toString().trim());
          currentArgument.clear();
        } else {
          currentArgument.write(char);
        }
      }
      arguments.add(currentArgument.toString().trim());

      final processedArgs = arguments
          .map((arg) => _processNestedType(arg))
          .join(', ');

      // Remove $ only from the base type name if it has a prefix
      final cleanedBase = baseType.contains('.')
          ? baseType.substring(0, baseType.lastIndexOf('.') + 1) +
                baseType
                    .substring(baseType.lastIndexOf('.') + 1)
                    .replaceAll('\$', '')
          : baseType.replaceAll('\$', '');

      return '$cleanedBase<$processedArgs>';
    }

    // 2. Simple types (potentially with prefix and nullability)
    final isNullable = input.endsWith('?');
    final base = isNullable ? input.substring(0, input.length - 1) : input;

    final cleanedBase = base.contains('.')
        ? base.substring(0, base.lastIndexOf('.') + 1) +
              base.substring(base.lastIndexOf('.') + 1).replaceAll('\$', '')
        : base.replaceAll('\$', '');

    return '$cleanedBase${isNullable ? '?' : ''}';
  }

  final result = _processNestedType(baseType);
  return '${result}${isOuterNullable ? '?' : ''}';
}

/// Generates abstract property declarations and optional copyWith factory.

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

/// Generates a Patch class for partial updates.
String getPatchClass(
  List<NameTypeClassComment> fields,
  String className,
  List<String> knownClasses, [
  List<String> genericTypeNames = const [],
]) {
  String classNameTrimmed = '${className.replaceAll("\$", "")}';
  String enumName = '${classNameTrimmed}\$';

  var sb = StringBuffer();

  // Add Patch<T> implementation
  sb.writeln(
    "class ${classNameTrimmed}Patch extends PatchBase<$classNameTrimmed, $enumName> {",
  );
  sb.writeln();

  sb.writeln("  $classNameTrimmed applyTo($classNameTrimmed entity) {");
  sb.writeln("    return entity.patchWith$classNameTrimmed(patchInput: this);");
  sb.writeln("  }");
  sb.writeln();

  if (fields.isEmpty) {
    // Fieldless class (e.g. an empty explicit subtype): emit a minimal
    // patch class — changeTo extensions on sibling subtypes reference it.
    // PatchBase's type parameters are used covariantly, so a shared
    // placeholder enum keeps the generic signature satisfied.
    sb.writeln('}');
    sb.writeln();
    sb.writeln('/// Placeholder field enum for fieldless [$classNameTrimmed].');
    sb.writeln('enum $enumName { none }');
    return sb.toString();
  }

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
    sb.writeln("    patchMap[$enumName.$name] = value;");
    sb.writeln("    return this;");
    sb.writeln("  }");
    sb.writeln();

    // Generate cross-file nested patch methods for Zorphy types
    var fieldType = field.type ?? "";
    var fieldTypeWithoutDollars = getDataTypeWithoutDollars(fieldType);
    var innerType = fieldTypeWithoutDollars.replaceAll("?", "");

    // Check if this is a Zorphy type (starts with $ and not a generic)
    bool isKnownClassType(String type, bool isEnum) {
      if (isEnum) return false;
      if (type.contains('Function'))
        return false; // Function types are not Zorphy types
      if (type.startsWith("\$")) return true;
      if (knownClasses.any((k) => type == k)) return true;

      // Only treat it as Zorphy type if it's NOT a primitive AND it's NOT a generic
      // AND it's NOT an enum (usually enums don't have $ prefix)
      // Since we don't have full type info for cross-file types, we use the $ prefix
      // as the primary indicator for Zorphy entities.
      return false;
    }

    var isZorphyType =
        isKnownClassType(innerType, field.isEnum) ||
        (innerType.startsWith("List<") &&
            isKnownClassType(
              innerType.replaceAll(RegExp(r'^List<(.+)>$'), r'$1'),
              false, // Lists are not enums themselves
            )) ||
        (innerType.startsWith("Map<") &&
            isKnownClassType(
              innerType.replaceAll(RegExp(r'^Map<(.+, .+)>$'), r'$2'),
              false, // Maps are not enums themselves
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
              isKnownClassType(elementTypeWithoutDollars, false);
          // Don't generate updateAt for abstract classes ($$) as they don't have Patch classes
          // Check the original field type to see if it had $$
          var isAbstractType = fieldType.contains("\$\$");
          if (elementTypeIsZorphy && !isAbstractType) {
            var elementPatchType = elementTypeWithoutDollars + "Patch";
            sb.writeln(
              "  ${classNameTrimmed}Patch update${capitalizedName}At(int index, $elementPatchType Function($elementPatchType) patch) {",
            );
            sb.writeln(
              "    patchMap[$enumName.$name] = (List<dynamic> list) {",
            );
            sb.writeln(
              "      var updatedList = List<$elementTypeWithoutDollars>.from(list);",
            );
            sb.writeln("      if (index >= 0 && index < updatedList.length) {");
            sb.writeln(
              "        updatedList[index] = patch($elementPatchType()).applyTo(updatedList[index] as ${elementTypeWithoutDollars.replaceAll("?", "")});",
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
              isKnownClassType(valueTypeWithoutDollars, false);
          if (valueTypeIsZorphy) {
            var valuePatchType = valueTypeWithoutDollars + "Patch";
            sb.writeln(
              "  ${classNameTrimmed}Patch update${capitalizedName}Value($keyType key, $valuePatchType Function($valuePatchType) patch) {",
            );
            sb.writeln(
              "    patchMap[$enumName.$name] = (Map<dynamic, dynamic> map) {",
            );
            sb.writeln("      var updatedMap = Map.from(map);");
            sb.writeln("      if (updatedMap.containsKey(key)) {");
            sb.writeln(
              "        updatedMap[key] = patch($valuePatchType()).applyTo(updatedMap[key] as ${valueTypeWithoutDollars.replaceAll("?", "")});",
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
        // Don't generate patch methods for abstract/sealed types (starting with $$)
        // as they don't have concrete Patch classes we can instantiate
        if (fieldType.trim().startsWith(r'$$')) {
          continue;
        }

        var patchType = innerType + "Patch";
        // with{CapitalizedName}Patch method for direct patch application
        sb.writeln(
          "  ${classNameTrimmed}Patch with${capitalizedName}Patch($patchType patch) {",
        );
        sb.writeln("    patchMap[$enumName.$name] = patch;");
        sb.writeln("    return this;");
        sb.writeln("  }");
        sb.writeln();

        // with{CapitalizedName}PatchFunc method for function-based patching
        var funcParamType = "$patchType Function($patchType)";
        sb.writeln(
          "  ${classNameTrimmed}Patch with${capitalizedName}PatchFunc($funcParamType patch) {",
        );
        sb.writeln("    patchMap[$enumName.$name] = (dynamic current) {");
        sb.writeln("      var currentPatch = $patchType();");
        sb.writeln(
          "      return patch(currentPatch).applyTo(current as ${innerType.replaceAll("?", "")});",
        );
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

/// Strips all $ prefixes from a Dart type string.
String getDataTypeWithoutDollars(String type) {
  return type.replaceAll('\$', '');
}

const PRIMITIVE_TYPES = [
  'BigInt',
  'bool',
  'DateTime',
  'double',
  'Duration',
  'dynamic',
  'Enum',
  'Function',
  'int',
  'Iterable',
  'List',
  'Map',
  'Never',
  'Null',
  'num',
  'Object',
  'Record',
  'Runes',
  'Set',
  'String',
  'Symbol',
  'Uri',
  'void',
];

/// Generates a patchWith method for a class.
String getPatchWithMethod(
  List<NameTypeClassComment> fields,
  String className, {
  bool hidePublicConstructor = false,
}) {
  var classNameTrimmed = className.replaceAll("\$", "");
  var enumName = '${classNameTrimmed}\$';

  if (fields.isEmpty) {
    // Fieldless class: emit an identity patchWith so a generated patch
    // class's applyTo has a target (changeTo chains depend on it).
    return "  $classNameTrimmed patchWith$classNameTrimmed({"
        "$classNameTrimmed"
        "Patch? patchInput}) => this;\n";
  }

  var sb = StringBuffer();

  sb.writeln("  $classNameTrimmed patchWith$classNameTrimmed({");
  sb.writeln("    $classNameTrimmed" + "Patch? patchInput,");
  sb.writeln("  }) {");
  sb.writeln(
    "    final _patcher = patchInput ?? $classNameTrimmed" + "Patch();",
  );
  sb.writeln("    final _patchMap = _patcher.patchMap;");

  var constructorSuffix = hidePublicConstructor ? "._" : "";
  sb.writeln("    return $classNameTrimmed$constructorSuffix(");

  for (var i = 0; i < fields.length; i++) {
    var f = fields[i];
    var comma = i == fields.length - 1 ? "" : ",";
    sb.writeln(
      "      ${f.name}: _patchMap.containsKey($enumName.${f.name}) ? (_patchMap[$enumName.${f.name}] is Function) ? _patchMap[$enumName.${f.name}](this.${f.name}) : (_patchMap[$enumName.${f.name}] is Patch) ? _patchMap[$enumName.${f.name}].applyTo(this.${f.name}) : _patchMap[$enumName.${f.name}] : this.${f.name}$comma",
    );
  }

  sb.writeln("    );");
  sb.writeln("  }");

  return sb.toString();
}

/// Generates patchWith methods for implemented interfaces.
String getInterfacePatchWithMethods(
  List<Interface> interfaces,
  List<NameTypeClassComment> classFields,
  String className, {
  bool hidePublicConstructor = false,
}) {
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

    var seenFields = <String>{};
    var interfaceFields = i.fields.where((f) {
      if (classFieldNames.contains(f.name) && !seenFields.contains(f.name)) {
        seenFields.add(f.name);
        return true;
      }
      return false;
    }).toList();
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
    sb.writeln("    final _patchMap = _patcher.patchMap;");

    var constructorSuffix = hidePublicConstructor ? "._" : "";
    sb.writeln("    return $classNameTrimmed$constructorSuffix(");

    for (var f in classFields) {
      if (interfaceFieldNames.contains(f.name)) {
        sb.writeln(
          "      ${f.name}: _patchMap.containsKey($enumName.${f.name}) ? (_patchMap[$enumName.${f.name}] is Function) ? _patchMap[$enumName.${f.name}](this.${f.name}) : (_patchMap[$enumName.${f.name}] is Patch) ? _patchMap[$enumName.${f.name}].applyTo(this.${f.name}) : _patchMap[$enumName.${f.name}] : this.${f.name},",
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

/// Generates a compareTo extension for diffing fields.
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