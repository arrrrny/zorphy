import 'package:analyzer/dart/element/element.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/classes.dart';
import 'package:zorphy/src/factory_method.dart';
import 'package:zorphy/src/helpers.dart';

/// Generates the code block for a single Zorphy-annotated class.
String createZorphy(
  bool isAbstract,
  List<NameTypeClassComment> allFieldsDistinct,
  String elementName,
  String docComment,
  List<InterfaceWithComment> interfaces,
  List<Interface> allValueTInterfaces,
  List<NameTypeClassComment> classGenerics,
  bool hasConstConstructor,
  bool generateJson,
  bool hidePublicConstructor,
  List<Interface> typesExplicit,
  bool nonSealed,
  bool explicitToJson,
  bool generateCompareTo,
  bool generateCopyWithFn,
  List<FactoryMethodInfo> factoryMethods,
  Map<String, ClassElement> allAnnotatedClasses,
  Set<String> ownFields,
) {
  var sb = StringBuffer();

  // No imports in part files - they belong in the main file

  if (docComment.isNotEmpty) {
    sb.writeln(docComment);
  }

  // Don't add @JsonSerializable to:
  // 1. Sealed classes - they can't be instantiated
  // 2. Abstract classes with explicitSubTypes - they only dispatch to subtypes
  var isSealedClass = elementName.startsWith("\$\$") && !nonSealed;
  var isAbstractWithSubtypes =
      elementName.startsWith("\$\$") && typesExplicit.isNotEmpty;
  if (generateJson && !isSealedClass && !isAbstractWithSubtypes) {
    var constructorParam = hidePublicConstructor ? ", constructor: '_'" : "";
    // For non-generic classes: createFactory: false — we generate fromJson inline
    // with _zc<T> safe casts. For generic classes, json_serializable still handles
    // _$FooFromJson since type parameters require fromJsonT callbacks.
    var createFactoryParam = classGenerics.isEmpty
        ? ", createFactory: false"
        : "";
    sb.writeln(
      "@JsonSerializable(explicitToJson: $explicitToJson$createFactoryParam$constructorParam)",
    );
  }

  var className = elementName.replaceAll("\$", "");
  // Preserve the original prefix for abstractClassName
  // If elementName starts with $$, keep it as $$, otherwise use $
  var abstractClassName = elementName.startsWith("\$\$")
      ? elementName
      : "\$$className";

  String trimInterfaceName(String name) {
    if (name.startsWith("\$\$")) return name.substring(2);
    if (name.startsWith("\$")) return name.substring(1);
    return name;
  }

  var implementsClauseRaw = interfaces
      .map((i) => i.interfaceName)
      .where((name) => name.isNotEmpty)
      .join(", ");

  var implementsClauseTrimmed = interfaces
      .map((i) => trimInterfaceName(i.interfaceName))
      .where((name) => name.isNotEmpty)
      .join(", ");

  var extendsStr = "";
  var implementsStr = "";

  if (isAbstract) {
    // Abstract class implements its interfaces
    if (implementsClauseRaw.isNotEmpty) {
      implementsStr = " implements $implementsClauseRaw";
    }
  } else {
    // Concrete class
    // When there are factory methods, use implements for the abstract class
    var useImplementsForAbstract = factoryMethods.isNotEmpty;

    if (useImplementsForAbstract) {
      // Factory constructors: implements $ClassName, extends parent
      implementsStr = " implements $abstractClassName";
    }

    // Check if we have a sealed parent - if so, implement it directly instead of extending
    var sealedParent = interfaces.firstWhere(
      (i) => i.isSealed,
      orElse: () => InterfaceWithComment(
        "", // type
        [], // typeArgsTypes
        [], // typeParamsNames
        [], // fields
        comment: null,
        isSealed: false,
        hidePublicConstructor: false,
      ),
    );

    if (sealedParent.interfaceName.isNotEmpty) {
      // Concrete class in sealed hierarchy - implement the generated sealed class
      var sealedClassName = sealedParent.interfaceName.replaceAll("\$", "");
      if (useImplementsForAbstract) {
        // Already have implements for abstract, add sealed parent
        implementsStr += ", $sealedClassName";
      } else {
        implementsStr = " implements $sealedClassName";
      }
      // Add other interfaces
      if (implementsClauseTrimmed.isNotEmpty) {
        var otherInterfaces = implementsClauseTrimmed
            .split(", ")
            .where((name) => name != sealedClassName)
            .toList();
        if (otherInterfaces.isNotEmpty) {
          implementsStr += ", ${otherInterfaces.join(', ')}";
        }
      }
    } else {
      // Non-sealed - check if we have an abstract parent with explicitSubTypes
      // OR a single-$ parent (which generates a concrete class)
      // If so, extend the generated concrete parent class
      var concreteParent = interfaces.firstWhere(
        (i) =>
            (i.interfaceName.startsWith("\$\$") && !i.isSealed) ||
            (i.interfaceName.startsWith("\$") &&
                !i.interfaceName.startsWith("\$\$")),
        orElse: () => InterfaceWithComment(
          "", // type
          [], // typeArgsTypes
          [], // typeParamsNames
          [], // fields
          comment: null,
          isSealed: false,
          hidePublicConstructor: false,
        ),
      );

      if (concreteParent.interfaceName.isNotEmpty) {
        // Extend the generated concrete parent class
        var parentClassName = concreteParent.interfaceName.replaceAll("\$", "");
        extendsStr = " extends $parentClassName";
        // Add other interfaces to implements clause (excluding parent)
        if (implementsClauseTrimmed.isNotEmpty) {
          var otherInterfaces = implementsClauseTrimmed
              .split(", ")
              .where((name) => name != parentClassName)
              .toList();
          if (otherInterfaces.isNotEmpty) {
            if (useImplementsForAbstract) {
              // Already have implements, add others
              implementsStr += ", ${otherInterfaces.join(', ')}";
            } else {
              implementsStr = " implements ${otherInterfaces.join(', ')}";
            }
          }
        }
      } else {
        // Regular case
        if (!useImplementsForAbstract) {
          // No factory: extend abstract parent
          extendsStr = " extends $abstractClassName";
        }
        if (implementsClauseTrimmed.isNotEmpty) {
          if (useImplementsForAbstract) {
            implementsStr += ", $implementsClauseTrimmed";
          } else {
            implementsStr = " implements $implementsClauseTrimmed";
          }
        }
      }
    }
  }

  var genericsStr = "";
  if (classGenerics.isNotEmpty) {
    genericsStr =
        "<${classGenerics.map((g) => g.name + (g.type != null ? " extends ${g.type}" : "")).join(", ")}>";
  }

  if (isAbstract) {
    var sealedModifier = nonSealed ? "" : "sealed ";
    var abstractModifier = nonSealed ? "abstract " : "";
    // For $$prefix or $prefix with explicitSubTypes, use className directly
    // For $prefix without explicitSubTypes, add $ prefix
    var generatedClassName =
        (elementName.startsWith("\$\$") || typesExplicit.isNotEmpty)
        ? className
        : "\$$className";
    // For sealed classes ($$prefix), implement the source abstract class
    var sealedImplementsStr = implementsStr;
    if (elementName.startsWith("\$\$")) {
      var sourceClassName = elementName; // e.g., $$Attachment
      if (sealedImplementsStr.isEmpty) {
        sealedImplementsStr = " implements $sourceClassName";
      } else {
        sealedImplementsStr = sealedImplementsStr.replaceFirst(
          " implements ",
          " implements $sourceClassName, ",
        );
      }
    }
    sb.writeln(
      "${sealedModifier}${abstractModifier}class $generatedClassName$genericsStr$sealedImplementsStr {",
    );
    // For sealed classes with explicit subtypes, don't generate _internal constructor
    var isSealedWithSubtypes = isSealedClass && typesExplicit.isNotEmpty;
    sb.writeln(
      getPropertiesAbstract(
        allFieldsDistinct,
        generatedClassName,
        generateCopyWithFn,
        isSealedWithSubtypes: isSealedWithSubtypes,
        hasConstConstructor: hasConstConstructor,
      ),
    );
  } else {
    // Don't add const modifier to concrete classes - only abstract classes can be const
    sb.writeln("class $className$genericsStr$extendsStr$implementsStr {");
    // Determine if class extends abstract parent (needs @override) or just implements (no @override)
    // hasExtends is true only when we actually extend, false when we only implement
    var hasExtendsParam = extendsStr.isNotEmpty;

    // Check if we're extending an abstract parent
    var extendsAbstractClass = false;
    if (hasExtendsParam) {
      // If extending own abstract parent ($Person extends $Person), don't call super
      if (extendsStr.contains(abstractClassName)) {
        // Extending own abstract parent - no super call needed
        extendsAbstractClass = true;
      } else {
        // Extending another parent - find which one and check if it's abstract
        // Extract the parent class name from extendsStr
        final extendsMatch = RegExp(r'extends\s+(\S+)').firstMatch(extendsStr);
        if (extendsMatch != null) {
          final parentName = extendsMatch.group(1)!;
          // Check if this parent is abstract ($$) with explicitSubTypes
          extendsAbstractClass = interfaces.any(
            (i) =>
                i.interfaceName.replaceAll('\$', '') == parentName &&
                i.interfaceName.startsWith('\$\$') &&
                !i.isSealed,
          );
        }
      }
    }
    // Get parent fields if extending a concrete parent
    var parentFields = <String>{};
    if (hasExtendsParam && !extendsAbstractClass) {
      // For concrete parents, pass all inherited fields
      // This handles inheritance chains where parent gets fields from its parents
      parentFields = allFieldsDistinct
          .map((f) => f.name)
          .toSet()
          .difference(ownFields);

      // If we have multiple source interfaces, be more selective
      if (interfaces.length > 1) {
        // Find the specific parent class we're extending
        final extendsMatch = RegExp(r'extends\s+(\S+)').firstMatch(extendsStr);
        if (extendsMatch != null) {
          final parentName = extendsMatch.group(1)!;
          // Only pass fields from the specific parent interface
          var specificParentFields = <String>{};
          for (final iface in interfaces) {
            final ifaceName = iface.interfaceName.replaceAll('\$', '');
            if (ifaceName == parentName) {
              specificParentFields = iface.fields.map((f) => f.name).toSet();
              break;
            }
          }
          // Use specific parent fields if found, otherwise use all inherited
          if (specificParentFields.isNotEmpty) {
            parentFields = specificParentFields;
          }
        }
      }
    }

    // All fields from parent interfaces (for @override detection)
    var allParentInterfaceFields = <String>{};
    for (final iface in interfaces) {
      allParentInterfaceFields.addAll(iface.fields.map((f) => f.name));
    }
    var parentHasConstConstructor = true;
    if (hasExtendsParam && !extendsAbstractClass) {
      final extendsMatch = RegExp(r'extends\s+(\S+)').firstMatch(extendsStr);
      if (extendsMatch != null) {
        final parentName = extendsMatch.group(1)!;
        final parentElement =
            allAnnotatedClasses[parentName] ??
            allAnnotatedClasses['\$$parentName'];
        parentHasConstConstructor =
            parentElement?.constructors.any((e) => e.isConst) ?? false;
      }
    }
    var shouldGenerateConstConstructor =
        hasConstConstructor && (!hasExtendsParam || parentHasConstConstructor);

    sb.writeln(
      getProperties(
        allFieldsDistinct,
        className,
        false,
        hidePublicConstructor,
        generateCopyWithFn,
        generateJson,
        shouldGenerateConstConstructor,
        hasExtendsParam,
        extendsAbstractClass: extendsAbstractClass,
        parentFields: parentFields,
        ownFields: ownFields,
        allInheritedFields: allParentInterfaceFields,
      ),
    );
  }

  if (!isAbstract || generateCopyWithFn) {
    var copyWithClassName = isAbstract
        ? (elementName.startsWith("\$\$") ? className : "\$$className")
        : className;
    sb.writeln(
      getCopyWith(
        allFieldsDistinct,
        copyWithClassName,
        generateCopyWithFn,
        interfaces: allValueTInterfaces,
        ownFields: ownFields,
      ),
    );
  }

  if (!isAbstract && factoryMethods.isNotEmpty) {
    for (var factory in factoryMethods) {
      sb.writeln(generateFactoryMethod(factory, className, allFieldsDistinct));
    }
  }

  // Add patchWith method for non-abstract classes
  if (!isAbstract) {
    sb.writeln(
      getPatchWithMethod(
        allFieldsDistinct,
        className,
        hidePublicConstructor: hidePublicConstructor,
      ),
    );
    sb.writeln(
      getInterfaceCopyWithMethods(interfaces, allFieldsDistinct, className),
    );
    if (generateCopyWithFn) {
      sb.writeln(
        getInterfaceCopyWithFnMethods(
          interfaces,
          allFieldsDistinct,
          className,
          allFieldsDistinct,
        ),
      );
    }
    sb.writeln(
      getInterfacePatchWithMethods(
        interfaces,
        allFieldsDistinct,
        className,
        hidePublicConstructor: hidePublicConstructor,
      ),
    );
  }

  if (!isAbstract) {
    sb.writeln(getEqualsAndHashCode(allFieldsDistinct, className));
  }

  if (!isAbstract) {
    sb.writeln(getToString(allFieldsDistinct, className));
  }

  // Add factory fromJson constructor for JSON serialization
  // For abstract classes (sealed or non-sealed) with explicitSubTypes, generate fromJson that dispatches to subtypes
  var shouldGenerateJson = generateJson && !isAbstract;
  var shouldGenerateAbstractJson =
      generateJson && isAbstract && typesExplicit.isNotEmpty;
  if (shouldGenerateJson || shouldGenerateAbstractJson) {
    var classNameTrimmed = className.replaceAll("\$", "");
    sb.writeln();
    sb.writeln("  /// Creates a [${classNameTrimmed}] instance from JSON");
    if (typesExplicit.isEmpty && classGenerics.isEmpty) {
      // Simple case — no generics, no explicit subtypes.
      // Generate inline fromJson with _zc<T>() safe casts for field-level error messages.
      sb.writeln(
        "  factory ${classNameTrimmed}.fromJson(Map<String, dynamic> json) {",
      );
      sb.writeln("    return ${classNameTrimmed}(");
      for (var f in allFieldsDistinct) {
        var jsonKeyName = f.jsonKeyInfo?.name ?? f.name;
        var rawType = f.type ?? "dynamic";
        var cleanType = rawType.replaceAll(r'$', '');
        var isNullable = cleanType.endsWith('?');
        var baseType = isNullable
            ? cleanType.substring(0, cleanType.length - 1)
            : cleanType;

        // Check for custom converter (manual fromJson like includeFromJson: false + fromJson: fn)
        var manualConverter = f.jsonKeyInfo != null &&
            f.jsonKeyInfo!.fromJson != null &&
            f.jsonKeyInfo!.includeFromJson == false;
        if (manualConverter) {
          var jn = f.jsonKeyInfo!.name ?? f.name;
          if (isNullable) {
            sb.writeln(
              "      ${f.name}: json['$jn'] != null"
              " ? ${f.jsonKeyInfo!.fromJson}(json['$jn']"
              " as Map<String, dynamic>) as $rawType"
              " : null,",
            );
          } else {
            sb.writeln(
              "      ${f.name}: ${f.jsonKeyInfo!.fromJson}(json['$jn']"
              " as Map<String, dynamic>) as $rawType,",
            );
          }
          continue;
        }

        // Default value handling
        var hasDefault = f.jsonKeyInfo?.defaultValue != null;
        var effectiveIsNullable = isNullable || hasDefault;

        // Generate the expression
        var expr = _legacyFieldExpr(
          baseType, effectiveIsNullable, jsonKeyName, f, rawType,
        );

        // Handle default value
        if (hasDefault) {
          var nullableExpr = _legacyFieldExpr(
            baseType, true, jsonKeyName, f, rawType,
          );
          expr = "$nullableExpr ?? ${f.jsonKeyInfo!.defaultValue}";
        }

        sb.writeln("      ${f.name}: $expr,");
      }
      sb.writeln("    );");
      sb.writeln("  }");
      // _zc helper is no longer generated per-class — ZorphyJsonHelper.cast is used instead
      // from the shared annotation package
    } else if (shouldGenerateAbstractJson) {
      // Sealed class with explicit subtypes - dispatch to subtypes only, no fallback
      sb.writeln(
        "  factory ${classNameTrimmed}.fromJson(Map<String, dynamic> json) {",
      );
      for (var i = 0; i < typesExplicit.length; i++) {
        var c = typesExplicit[i];
        var interfaceName = c.interfaceName.replaceAll("\$", "");
        var genericTypes = c.typeParams.map((e) => "'_${e.name}_'").join(",");
        var prefix = i == 0 ? "if" : "} else if";
        if (c.typeParams.isNotEmpty) {
          sb.writeln(
            "    $prefix (json['__typename'] == \"$interfaceName\") {",
          );
          sb.writeln("      var fn_fromJson = getFromJsonToGenericFn(");
          sb.writeln("        ${interfaceName}_Generics_Sing().fns,");
          sb.writeln("        json,");
          sb.writeln("        [$genericTypes],");
          sb.writeln("      );");
          sb.writeln("      return fn_fromJson(json);");
        } else {
          sb.writeln(
            "    $prefix (json['__typename'] == \"$interfaceName\") {",
          );
          sb.writeln("      return $interfaceName.fromJson(json);");
        }
      }
      sb.writeln("    }");
      sb.writeln(
        "    throw UnsupportedError(\"The __typename '" +
            r"${json['__typename']}" +
            "' is not supported by the ${classNameTrimmed}.fromJson constructor.\");",
      );
      sb.writeln("  }");

      // Generate concrete toJson for non-sealed abstract classes with explicitSubTypes
      // Sealed classes don't need toJson (only factory fromJson)
      if (nonSealed) {
        sb.writeln("");
        sb.writeln("  Map<String, dynamic> toJson() {");
        sb.writeln(
          "    if (this is ${typesExplicit[0].interfaceName.replaceAll('\$', '')}) {",
        );
        sb.writeln(
          "      return (this as ${typesExplicit[0].interfaceName.replaceAll('\$', '')}).toJson();",
        );
        for (var i = 1; i < typesExplicit.length; i++) {
          var subtype = typesExplicit[i].interfaceName.replaceAll('\$', '');
          sb.writeln("    } else if (this is $subtype) {");
          sb.writeln("      return (this as $subtype).toJson();");
        }
        sb.writeln("    }");
        sb.writeln(
          "    throw UnsupportedError(\"Unknown subtype: \$runtimeType\");",
        );
        sb.writeln("  }");
      }
    } else {
      sb.writeln(
        "  factory ${classNameTrimmed}.fromJson(Map<String, dynamic> json) {",
      );
      // Inline the self-case body since createFactory: false means
      // _\$FooFromJson won't exist from json_serializable.
      sb.writeln("    if (json['__typename'] == null) {");
      sb.writeln("      return ${classNameTrimmed}(");
      for (var f in allFieldsDistinct) {
        var jsonKeyName = f.jsonKeyInfo?.name ?? f.name;
        var rawType = f.type ?? "dynamic";
        var cleanType = rawType.replaceAll(r'$', '');
        var isNullable = cleanType.endsWith('?');
        var baseType = isNullable
            ? cleanType.substring(0, cleanType.length - 1)
            : cleanType;
        var manualConverter = f.jsonKeyInfo != null &&
            f.jsonKeyInfo!.fromJson != null &&
            f.jsonKeyInfo!.includeFromJson == false;
        if (manualConverter) {
          var jn = f.jsonKeyInfo!.name ?? f.name;
          sb.writeln(
            isNullable
                ? "        ${f.name}: json['$jn'] != null ? ${f.jsonKeyInfo!.fromJson}(json['$jn'] as Map<String, dynamic>) as $rawType : null,"
                : "        ${f.name}: ${f.jsonKeyInfo!.fromJson}(json['$jn'] as Map<String, dynamic>) as $rawType,",
          );
          continue;
        }
        var hasDefault = f.jsonKeyInfo?.defaultValue != null;
        var effectiveIsNullable = isNullable || hasDefault;
        var expr = _legacyFieldExpr(baseType, effectiveIsNullable, jsonKeyName, f, rawType);
        if (hasDefault) {
          var nullableExpr = _legacyFieldExpr(baseType, true, jsonKeyName, f, rawType);
          expr = "$nullableExpr ?? ${f.jsonKeyInfo!.defaultValue}";
        }
        sb.writeln("        ${f.name}: $expr,");
      }
      sb.writeln("      );");
      sb.writeln("    }");
      var classesForJson = <Interface>[
        ...typesExplicit,
        Interface.fromGenerics(
          className,
          classGenerics.map((g) => NameType(g.name, g.type)).toList(),
          [],
          false,
        ),
      ];
      for (var i = 0; i < classesForJson.length; i++) {
        var c = classesForJson[i];
        var interfaceName = c.interfaceName.replaceAll("\$", "");
        var genericTypes = c.typeParams.map((e) => "'_${e.name}_'").join(",");
        var isCurrentClass = interfaceName == classNameTrimmed;
        var prefix = i == 0 ? "if" : "} else if";
        if (c.typeParams.isNotEmpty) {
          sb.writeln(
            "    $prefix (json['__typename'] == \"$interfaceName\") {",
          );
          sb.writeln("      var fn_fromJson = getFromJsonToGenericFn(");
          sb.writeln("        ${interfaceName}_Generics_Sing().fns,");
          sb.writeln("        json,");
          sb.writeln("        [$genericTypes],");
          sb.writeln("      );");
          sb.writeln("      return fn_fromJson(json);");
        } else {
          sb.writeln(
            "    $prefix (json['__typename'] == \"$interfaceName\") {",
          );
          if (isCurrentClass) {
            // Inline self-body since createFactory: false means
            // _$FooFromJson won't exist from json_serializable.
            sb.writeln("      return $interfaceName(");
            for (var innerF in allFieldsDistinct) {
              var jkn = innerF.jsonKeyInfo?.name ?? innerF.name;
              var rt = innerF.type ?? "dynamic";
              var ct = rt.replaceAll(r'$', '');
              var innerNullable = ct.endsWith('?');
              var bt = innerNullable ? ct.substring(0, ct.length - 1) : ct;
              var mc = innerF.jsonKeyInfo != null &&
                  innerF.jsonKeyInfo!.fromJson != null &&
                  innerF.jsonKeyInfo!.includeFromJson == false;
              if (mc) {
                var jn = innerF.jsonKeyInfo!.name ?? innerF.name;
                sb.writeln(
                  innerNullable
                      ? "          ${innerF.name}: json['$jn'] != null ? ${innerF.jsonKeyInfo!.fromJson}(json['$jn'] as Map<String, dynamic>) as $rt : null,"
                      : "          ${innerF.name}: ${innerF.jsonKeyInfo!.fromJson}(json['$jn'] as Map<String, dynamic>) as $rt,",
                );
                continue;
              }
              var hd = innerF.jsonKeyInfo?.defaultValue != null;
              var ei = innerNullable || hd;
              var e = _legacyFieldExpr(bt, ei, jkn, innerF, rt);
              if (hd) {
                var ne = _legacyFieldExpr(bt, true, jkn, innerF, rt);
                e = "$ne ?? ${innerF.jsonKeyInfo!.defaultValue}";
              }
              sb.writeln("          ${innerF.name}: $e,");
            }
            sb.writeln("      );");
          } else {
            sb.writeln(
              "      return $interfaceName.fromJson(json);",
            );
          }
        }
      }
      sb.writeln("    }");
      sb.writeln(
        "    throw UnsupportedError(\"The __typename '" +
            r"${json['__typename']}" +
            "' is not supported by the ${classNameTrimmed}.fromJson constructor.\");",
      );
      sb.writeln("  }");
    }

    // Don't generate toJsonLean for sealed classes - they don't have @JsonSerializable
    if (!shouldGenerateAbstractJson) {
      sb.writeln("");
      sb.writeln("  Map<String, dynamic> toJsonLean() {");
      sb.writeln(
        "    final Map<String, dynamic> data = _\$${className}ToJson(this);",
      );
      sb.writeln("    return _sanitizeJson(data);");
      sb.writeln("  }");
      sb.writeln("");
      sb.writeln("  dynamic _sanitizeJson(dynamic json) {");
      sb.writeln("    if (json is Map<String, dynamic>) {");
      sb.writeln("      json.remove('__typename');");
      sb.writeln("      return json..forEach((key, value) {");
      sb.writeln("        json[key] = _sanitizeJson(value);");
      sb.writeln("      });");
      sb.writeln("    } else if (json is List) {");
      sb.writeln("      return json.map((e) => _sanitizeJson(e)).toList();");
      sb.writeln("    }");
      sb.writeln("    return json;");
      sb.writeln("  }");
    }
  }

  sb.writeln("}");

  // Add enum and patch class for non-abstract classes
  if (!isAbstract) {
    var knownClasses = allAnnotatedClasses.keys
        .map((k) => k.replaceAll('\$', ''))
        .toList();
    var genericTypeNames = classGenerics.map((g) => g.name).toList();

    sb.writeln(getEnumPropertyList(allFieldsDistinct, className));
    sb.writeln(
      getPatchClass(
        allFieldsDistinct,
        className,
        knownClasses,
        genericTypeNames,
      ),
    );
  }

  if (generateJson && !isAbstract) {
    sb.writeln();
    sb.writeln(
      "extension ${className}Serialization on $className$genericsStr {",
    );
    sb.writeln(
      "  Map<String, dynamic> toJson() => _\$${className}ToJson(this);",
    );
    sb.writeln("  Map<String, dynamic> toJsonLean() {");
    sb.writeln(
      "    final Map<String, dynamic> data = _\$${className}ToJson(this);",
    );
    sb.writeln("    return _sanitizeJson(data);");
    sb.writeln("  }");
    sb.writeln("");
    sb.writeln("  dynamic _sanitizeJson(dynamic json) {");
    sb.writeln("    if (json is Map<String, dynamic>) {");
    sb.writeln("      json.remove('__typename');");
    sb.writeln("      return json..forEach((key, value) {");
    sb.writeln("        json[key] = _sanitizeJson(value);");
    sb.writeln("      });");
    sb.writeln("    } else if (json is List) {");
    sb.writeln("      return json.map((e) => _sanitizeJson(e)).toList();");
    sb.writeln("    }");
    sb.writeln("    return json;");
    sb.writeln("  }");
    sb.writeln("}");
  }

  // Add compareTo extension if requested
  if (generateCompareTo && !isAbstract) {
    var classNameTrimmed = className.replaceAll("\$", "");
    sb.writeln(
      getCompareToExtension(
        classNameTrimmed,
        allFieldsDistinct,
        allValueTInterfaces,
      ),
    );
  }

  // Add changeTo extension for explicitSubTypes
  // Generate for abstract classes with explicitSubTypes so all subtypes can use it
  if (typesExplicit.isNotEmpty) {
    var knownClasses = allAnnotatedClasses.keys
        .map((k) => k.replaceAll('\$', ''))
        .toList();
    sb.writeln(
      getChangeToExtension(
        sourceFields: allFieldsDistinct,
        sourceClassName: className,
        explicitSubTypes: typesExplicit,
        knownClasses: knownClasses,
      ),
    );
  }

  return sb.toString();
}

/// Helper for the legacy pipeline: generates a ZorphyJsonHelper.cast-based fromJson expression for a field.
String _legacyFieldExpr(
  String baseType,
  bool isNullable,
  String jsonKeyName,
  NameTypeClassComment f,
  String rawType,
) {
  // Simple types
  if (baseType == 'String') {
    return isNullable
        ? "ZorphyJsonHelper.cast<String?>(json, '$jsonKeyName')"
        : "ZorphyJsonHelper.cast<String>(json, '$jsonKeyName')";
  }
  if (baseType == 'int') {
    return isNullable
        ? "(ZorphyJsonHelper.cast<num?>(json, '$jsonKeyName'))?.toInt()"
        : "(ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')).toInt()";
  }
  if (baseType == 'double') {
    return isNullable
        ? "(ZorphyJsonHelper.cast<num?>(json, '$jsonKeyName'))?.toDouble()"
        : "(ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')).toDouble()";
  }
  if (baseType == 'num') {
    return isNullable
        ? "ZorphyJsonHelper.cast<num?>(json, '$jsonKeyName')"
        : "ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')";
  }
  if (baseType == 'bool') {
    return isNullable
        ? "ZorphyJsonHelper.cast<bool?>(json, '$jsonKeyName')"
        : "ZorphyJsonHelper.cast<bool>(json, '$jsonKeyName')";
  }

  // DateTime - parse from string
  if (baseType == 'DateTime') {
    if (isNullable) {
      return "json['$jsonKeyName'] == null"
          " ? null"
          " : DateTime.parse(ZorphyJsonHelper.cast<String>(json, '$jsonKeyName'))";
    }
    return "DateTime.parse(ZorphyJsonHelper.cast<String>(json, '$jsonKeyName'))";
  }

  // Duration - parse from microseconds (num)
  if (baseType == 'Duration') {
    if (isNullable) {
      return "json['$jsonKeyName'] == null"
          " ? null"
          " : Duration(microseconds:"
          " (ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')).toInt())";
    }
    return "Duration(microseconds:"
        " (ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')).toInt())";
  }

  // Enum - use $enumDecode with ZorphyJsonHelper.cast<string> for field-name in error
  if (f.isEnum && f.enumValues.isNotEmpty) {
    var enumMapName = "_\$${baseType}EnumMap";
    if (isNullable) {
      return "\$enumDecodeNullable($enumMapName,"
          " ZorphyJsonHelper.cast<String?>(json, '$jsonKeyName'))";
    }
    return "\$enumDecode($enumMapName,"
        " ZorphyJsonHelper.cast<String>(json, '$jsonKeyName'))";
  }

  // List<E> - cast to List<dynamic>, then map elements
  if (baseType.startsWith('List<')) {
    var innerContent = _extractGenericArg(baseType);
    var innerExpr = _elementCastExpr(innerContent);

    if (isNullable) {
      return "(ZorphyJsonHelper.cast<List<dynamic>?>(json, '$jsonKeyName'))"
          "?.map((e) => $innerExpr).toList()";
    }
    return "(ZorphyJsonHelper.cast<List<dynamic>>(json, '$jsonKeyName'))"
        ".map((e) => $innerExpr).toList()";
  }

  // Map<K,V> - pass through with ZorphyJsonHelper.cast
  if (baseType.startsWith('Map<')) {
    return isNullable
        ? "ZorphyJsonHelper.cast<$baseType?>(json, '$jsonKeyName')"
        : "ZorphyJsonHelper.cast<$baseType>(json, '$jsonKeyName')";
  }

  // dynamic / Object / never / void
  if (baseType == 'dynamic' || baseType == 'Object' ||
      baseType == 'Never' || baseType == 'void') {
    return "json['$jsonKeyName']";
  }

  // Custom object - assume has fromJson(Map<String, dynamic>)
  if (isNullable) {
    return "json['$jsonKeyName'] == null"
        " ? null"
        " : ${baseType}.fromJson("
        "ZorphyJsonHelper.cast<Map<String, dynamic>>(json, '$jsonKeyName'))";
  }
  return "${baseType}.fromJson("
      "ZorphyJsonHelper.cast<Map<String, dynamic>>(json, '$jsonKeyName'))";
}

/// Extract the generic type argument from a type string like List<String> -> String
String _extractGenericArg(String type) {
  var start = type.indexOf('<');
  var end = type.lastIndexOf('>');
  if (start == -1 || end == -1) return type;
  return type.substring(start + 1, end).trim();
}

/// Generate a cast expression for a list element inside a .map() call.
String _elementCastExpr(String innerType) {
  var trimmed = innerType.trim();
  var isNullable = trimmed.endsWith('?');
  var baseType = isNullable
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;

  switch (baseType) {
    case 'String':
      return 'e as String';
    case 'int':
      return '(e as num).toInt()';
    case 'double':
      return '(e as num).toDouble()';
    case 'num':
      return 'e as num';
    case 'bool':
      return 'e as bool';
    case 'dynamic':
    case 'Object':
      return 'e';
    case 'DateTime':
      return 'DateTime.parse(e as String)';
  }

  if (baseType.startsWith('List<') || baseType.startsWith('Map<')) {
    return 'e as $trimmed';
  }

  // Custom object
  return '$baseType.fromJson(e as Map<String, dynamic>)';
}
