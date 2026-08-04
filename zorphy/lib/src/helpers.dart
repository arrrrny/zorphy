import 'package:dartx/dartx.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/classes.dart';

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
      var currentArgument = <String>[];

      for (var i = 0; i < innerContent.length; i++) {
        final char = innerContent[i];
        if (char == '<') {
          bracketDepth++;
          currentArgument.add(char);
        } else if (char == '>') {
          bracketDepth--;
          currentArgument.add(char);
        } else if (char == ',' && bracketDepth == 0) {
          arguments.add(currentArgument.join().trim());
          currentArgument = <String>[];
        } else {
          currentArgument.add(char);
        }
      }
      arguments.add(currentArgument.join().trim());

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

  final lines = <String>[];

  // Generate enum
  lines.add("enum $enumName {");
  lines.add(
    fields
        .map((e) => e.name.startsWith("_") ? e.name.substring(1) : e.name)
        .join(","),
  );
  lines.add("}");
  lines.add('');
  return lines.join('\n');
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

  final lines = <String>[];

  // Add Patch<T> implementation
  lines.add(
    "class ${classNameTrimmed}Patch extends PatchBase<$classNameTrimmed, $enumName> {",
  );
  lines.add('');

  lines.add("  $classNameTrimmed applyTo($classNameTrimmed entity) {");
  lines.add("    return entity.patchWith$classNameTrimmed(this);");
  lines.add("  }");
  lines.add('');

  if (fields.isEmpty) {
    // Fieldless class (e.g. an empty explicit subtype): emit a minimal
    // patch class — changeTo extensions on sibling subtypes reference it.
    // PatchBase's type parameters are used covariantly, so a shared
    // placeholder enum keeps the generic signature satisfied.
    lines.add('}');
    lines.add('');
    lines.add('/// Placeholder field enum for fieldless [$classNameTrimmed].');
    lines.add('enum $enumName { none }');
    return lines.join('\n');
  }

  // Generate with methods
  for (var field in fields) {
    var name = field.name.startsWith("_")
        ? field.name.substring(1)
        : field.name;
    var baseType = field.type ?? "dynamic";
    baseType = baseType.replaceAll('\$', '');
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

    lines.add(
      "  ${classNameTrimmed}Patch with$capitalizedName($parameterType value) {",
    );
    lines.add("    patchMap[$enumName.$name] = value;");
    lines.add("    return this;");
    lines.add("  }");
    lines.add('');

    // Generate cross-file nested patch methods for Zorphy types
    var fieldType = field.type ?? "";
    var fieldTypeWithoutDollars = fieldType.replaceAll('\$', '');
    var innerType = fieldTypeWithoutDollars.replaceAll("?", "");

    // Check if this is a Zorphy type (starts with $ and not a generic)
    bool isKnownClassType(String type, bool isEnum) {
      if (isEnum) return false;
      if (type.contains('Function'))
        return false; // Function types are not Zorphy types
      if (type.startsWith("\$")) return true;
      if (knownClasses.any((k) => type == k)) return true;

      // Only treat it as a Zorphy type if it's NOT a primitive AND it's NOT a generic
      // AND it's NOT an enum (usually enums don't have $ prefix)
      // Since we don't have full type info for cross-file types, we use the $ prefix
      // as the primary indicator for Zorphy entities.
      return false;
    }

    var isZorphyType =
        isKnownClassType(innerType, field.isEnum) ||
        (innerType.startsWith("List<") &&
            isKnownClassType(
              innerType.replaceAll(RegExp(r'^List<(.+)>$'), r'\$1'),
              false, // Lists are not enums themselves
            )) ||
        (innerType.startsWith("Map<") &&
            isKnownClassType(
              innerType.replaceAll(RegExp(r'^Map<(.+, .+)>$'), r'\$2'),
              false, // Maps are not enums themselves
            ));

    if (isZorphyType && !isGenericType) {
      // Handle List types
      if (innerType.startsWith("List<")) {
        var listMatch = RegExp(r'^List<(.+)>$').firstMatch(innerType);
        if (listMatch != null) {
          var elementType = listMatch.group(1) ?? "";
          var elementTypeWithoutDollars = elementType.replaceAll('\$', '');
          var elementTypeIsZorphy =
              elementType.startsWith("\$") ||
              isKnownClassType(elementTypeWithoutDollars, false);
          // Don't generate updateAt for abstract classes ($$) as they don't have Patch classes
          // Check the original field type to see if it had $$
          var isAbstractType = fieldType.contains("\$\$");
          if (elementTypeIsZorphy && !isAbstractType) {
            var elementPatchType = elementTypeWithoutDollars + "Patch";
            lines.add(
              "  ${classNameTrimmed}Patch update${capitalizedName}At(int index, $elementPatchType Function($elementPatchType) patch) {",
            );
            lines.add(
              "    patchMap[$enumName.$name] = (List<dynamic> list) {",
            );
            lines.add(
              "      var updatedList = List<$elementTypeWithoutDollars>.from(list);",
            );
            lines.add("      if (index >= 0 && index < updatedList.length) {");
            lines.add(
              "        updatedList[index] = patch($elementPatchType()).applyTo(updatedList[index] as ${elementTypeWithoutDollars.replaceAll("?", "")});",
            );
            lines.add("      }");
            lines.add("      return updatedList;");
            lines.add("    };"
            );
            lines.add("    return this;");
            lines.add("  }");
            lines.add('');
          }
        }
      }
      // Handle Map types
      else if (innerType.startsWith("Map<")) {
        var mapMatch = RegExp(r'^Map<(.+), (.+)>$').firstMatch(innerType);
        if (mapMatch != null) {
          var keyType = mapMatch.group(1) ?? "";
          var valueType = mapMatch.group(2) ?? "";
          var valueTypeWithoutDollars = valueType.replaceAll('\$', '');
          var valueTypeIsZorphy =
              valueType.startsWith("\$") ||
              isKnownClassType(valueTypeWithoutDollars, false);
          if (valueTypeIsZorphy) {
            var valuePatchType = valueTypeWithoutDollars + "Patch";
            lines.add(
              "  ${classNameTrimmed}Patch update${capitalizedName}Value($keyType key, $valuePatchType Function($valuePatchType) patch) {",
            );
            lines.add(
              "    patchMap[$enumName.$name] = (Map<dynamic, dynamic> map) {",
            );
            lines.add("      var updatedMap = Map.from(map);");
            lines.add("      if (updatedMap.containsKey(key)) {");
            lines.add(
              "        updatedMap[key] = patch($valuePatchType()).applyTo(updatedMap[key] as ${valueTypeWithoutDollars.replaceAll("?", "")});",
            );
            lines.add("      }");
            lines.add("      return updatedMap;");
            lines.add("    };"
            );
            lines.add("    return this;");
            lines.add("  }");
            lines.add('');
          }
        }
      }
      // Handle single object types (nullable and non-nullable)
      else {
        // Don't generate patch methods for abstract/sealed types (starting with $$)
        // as they don't have concrete Patch classes we can instantiate
        if (fieldType.trim().startsWith(r'\$\$')) {
          continue;
        }

        var patchType = innerType + "Patch";
        // with{CapitalizedName}Patch method for direct patch application
        lines.add(
          "  ${classNameTrimmed}Patch with${capitalizedName}Patch($patchType patch) {",
        );
        lines.add("    patchMap[$enumName.$name] = patch;");
        lines.add("    return this;");
        lines.add("  }");
        lines.add('');

        // with{CapitalizedName}PatchFunc method for function-based patching
        var funcParamType = "$patchType Function($patchType)";
        lines.add(
          "  ${classNameTrimmed}Patch with${capitalizedName}PatchFunc($funcParamType patch) {",
        );
        lines.add("    patchMap[$enumName.$name] = (dynamic current) {");
        lines.add("      var currentPatch = $patchType();");
        lines.add(
          "      return patch(currentPatch).applyTo(current as ${innerType.replaceAll("?", "")});",
        );
        lines.add("    };"
        );
        lines.add("    return this;");
        lines.add("  }");
        lines.add('');
      }
    }
  }

  lines.add("}");

  return lines.join('\n');
}
