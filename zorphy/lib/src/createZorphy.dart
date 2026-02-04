import 'package:analyzer/dart/element/element.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/classes.dart';
import 'package:zorphy/src/factory_method.dart';
import 'package:zorphy/src/helpers.dart';

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
  var isAbstractWithSubtypes = elementName.startsWith("\$\$") && typesExplicit.isNotEmpty;
  if (generateJson && !isSealedClass && !isAbstractWithSubtypes) {
    sb.writeln("@JsonSerializable(explicitToJson: $explicitToJson)");
  }

  var className = elementName.replaceAll("\$", "");
  // Preserve the original prefix for abstractClassName
  // If elementName starts with $$, keep it as $$, otherwise use $
  var abstractClassName =
      elementName.startsWith("\$\$") ? elementName : "\$$className";

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
        (i) => (i.interfaceName.startsWith("\$\$") && !i.isSealed) || 
               (i.interfaceName.startsWith("\$") && !i.interfaceName.startsWith("\$\$")),
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
    var generatedClassName = (elementName.startsWith("\$\$") || typesExplicit.isNotEmpty)
        ? className
        : "\$$className";
    // For sealed classes ($$prefix), implement the source abstract class
    var sealedImplementsStr = implementsStr;
    if (elementName.startsWith("\$\$")) {
      var sourceClassName = elementName; // e.g., $$Attachment
      if (sealedImplementsStr.isEmpty) {
        sealedImplementsStr = " implements $sourceClassName";
      } else {
        sealedImplementsStr =
            sealedImplementsStr.replaceFirst(" implements ", " implements $sourceClassName, ");
      }
    }
    sb.writeln(
        "${sealedModifier}${abstractModifier}class $generatedClassName$genericsStr$sealedImplementsStr {");
    // For sealed classes with explicit subtypes, don't generate _internal constructor
    var isSealedWithSubtypes = isSealedClass && typesExplicit.isNotEmpty;
    sb.writeln(getPropertiesAbstract(
        allFieldsDistinct, generatedClassName, generateCopyWithFn,
        isSealedWithSubtypes: isSealedWithSubtypes));
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
          extendsAbstractClass = interfaces.any((i) => 
            i.interfaceName.replaceAll('\$', '') == parentName && 
            i.interfaceName.startsWith('\$\$') && 
            !i.isSealed
          );
        }
      }
    }
    // Get parent fields if extending a concrete parent
    var parentFields = <String>{};
    if (hasExtendsParam && !extendsAbstractClass) {
      // Find the specific parent class we're extending
      final extendsMatch = RegExp(r'extends\s+(\S+)').firstMatch(extendsStr);
      if (extendsMatch != null) {
        final parentName = extendsMatch.group(1)!;
        // Find the interface for this specific parent and get only its fields
        for (final iface in interfaces) {
          final ifaceName = iface.interfaceName.replaceAll('\$', '');
          if (ifaceName == parentName) {
            parentFields = iface.fields.map((f) => f.name).toSet();
            break;
          }
        }
      }
    }
    
    // All fields from parent interfaces (for @override detection)
    var allParentInterfaceFields = <String>{};
    for (final iface in interfaces) {
      allParentInterfaceFields.addAll(iface.fields.map((f) => f.name));
    }
    
    sb.writeln(getProperties(
        allFieldsDistinct,
        className,
        false,
        hidePublicConstructor,
        generateCopyWithFn,
        generateJson,
        hasExtendsParam,
        extendsAbstractClass: extendsAbstractClass,
        parentFields: parentFields,
        ownFields: ownFields,
        allInheritedFields: allParentInterfaceFields));
  }

  if (!isAbstract || generateCopyWithFn) {
    var copyWithClassName = isAbstract
        ? (elementName.startsWith("\$\$") ? className : "\$$className")
        : className;
    sb.writeln(
        getCopyWith(allFieldsDistinct, copyWithClassName, generateCopyWithFn));
  }

  if (!isAbstract && factoryMethods.isNotEmpty) {
    for (var factory in factoryMethods) {
      sb.writeln(generateFactoryMethod(factory, className, allFieldsDistinct));
    }
  }

  // Add patchWith method for non-abstract classes
  if (!isAbstract) {
    sb.writeln(getPatchWithMethod(allFieldsDistinct, className));
    sb.writeln(
        getInterfaceCopyWithMethods(interfaces, allFieldsDistinct, className));
    if (generateCopyWithFn) {
      sb.writeln(getInterfaceCopyWithFnMethods(
          interfaces, allFieldsDistinct, className, allFieldsDistinct));
    }
    sb.writeln(
        getInterfacePatchWithMethods(interfaces, allFieldsDistinct, className));
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
      sb.writeln(
          "  factory ${classNameTrimmed}.fromJson(Map<String, dynamic> json) => _\$${classNameTrimmed}FromJson(json);");
    } else if (shouldGenerateAbstractJson) {
      // Sealed class with explicit subtypes - dispatch to subtypes only, no fallback
      sb.writeln(
          "  factory ${classNameTrimmed}.fromJson(Map<String, dynamic> json) {");
      for (var i = 0; i < typesExplicit.length; i++) {
        var c = typesExplicit[i];
        var interfaceName = c.interfaceName.replaceAll("\$", "");
        var genericTypes = c.typeParams.map((e) => "'_${e.name}_'").join(",");
        var prefix = i == 0 ? "if" : "} else if";
        if (c.typeParams.isNotEmpty) {
          sb.writeln(
              "    $prefix (json['_className_'] == \"$interfaceName\") {");
          sb.writeln("      var fn_fromJson = getFromJsonToGenericFn(");
          sb.writeln("        ${interfaceName}_Generics_Sing().fns,");
          sb.writeln("        json,");
          sb.writeln("        [$genericTypes],");
          sb.writeln("      );");
          sb.writeln("      return fn_fromJson(json);");
        } else {
          sb.writeln(
              "    $prefix (json['_className_'] == \"$interfaceName\") {");
          sb.writeln("      return $interfaceName.fromJson(json);");
        }
      }
      sb.writeln("    }");
      sb.writeln("    throw UnsupportedError(\"The _className_ '" +
          r"${json['_className_']}" +
          "' is not supported by the ${classNameTrimmed}.fromJson constructor.\");");
      sb.writeln("  }");
      
      // Generate concrete toJson for non-sealed abstract classes with explicitSubTypes
      // Sealed classes don't need toJson (only factory fromJson)
      if (nonSealed) {
        sb.writeln("");
        sb.writeln("  Map<String, dynamic> toJson() {");
        sb.writeln("    if (this is ${typesExplicit[0].interfaceName.replaceAll('\$', '')}) {");
        sb.writeln("      return (this as ${typesExplicit[0].interfaceName.replaceAll('\$', '')}).toJson();");
        for (var i = 1; i < typesExplicit.length; i++) {
          var subtype = typesExplicit[i].interfaceName.replaceAll('\$', '');
          sb.writeln("    } else if (this is $subtype) {");
          sb.writeln("      return (this as $subtype).toJson();");
        }
        sb.writeln("    }");
        sb.writeln("    throw UnsupportedError(\"Unknown subtype: \$runtimeType\");");
        sb.writeln("  }");
      }
    } else {
      sb.writeln(
          "  factory ${classNameTrimmed}.fromJson(Map<String, dynamic> json) {");
      sb.writeln("    if (json['_className_'] == null) {");
      sb.writeln("      return _\$${classNameTrimmed}FromJson(json);");
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
              "    $prefix (json['_className_'] == \"$interfaceName\") {");
          sb.writeln("      var fn_fromJson = getFromJsonToGenericFn(");
          sb.writeln("        ${interfaceName}_Generics_Sing().fns,");
          sb.writeln("        json,");
          sb.writeln("        [$genericTypes],");
          sb.writeln("      );");
          sb.writeln("      return fn_fromJson(json);");
        } else {
          sb.writeln(
              "    $prefix (json['_className_'] == \"$interfaceName\") {");
          sb.writeln(
              "      return ${isCurrentClass ? "_\$" : ""}$interfaceName${isCurrentClass ? "FromJson" : ".fromJson"}(json);");
        }
      }
      sb.writeln("    }");
      sb.writeln("    throw UnsupportedError(\"The _className_ '" +
          r"${json['_className_']}" +
          "' is not supported by the ${classNameTrimmed}.fromJson constructor.\");");
      sb.writeln("  }");
    }

    // Don't generate toJsonLean for sealed classes - they don't have @JsonSerializable
    if (!shouldGenerateAbstractJson) {
      sb.writeln("");
      sb.writeln("  Map<String, dynamic> toJsonLean() {");
      sb.writeln(
          "    final Map<String, dynamic> data = _\$${className}ToJson(this);");
      sb.writeln("    return _sanitizeJson(data);");
      sb.writeln("  }");
      sb.writeln("");
      sb.writeln("  dynamic _sanitizeJson(dynamic json) {");
      sb.writeln("    if (json is Map<String, dynamic>) {");
      sb.writeln("      json.remove('_className_');");
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
    var knownClasses =
        allAnnotatedClasses.keys.map((k) => k.replaceAll('\$', '')).toList();
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
        "extension ${className}Serialization on $className$genericsStr {");
    sb.writeln(
        "  Map<String, dynamic> toJson() => _\$${className}ToJson(this);");
    sb.writeln("  Map<String, dynamic> toJsonLean() {");
    sb.writeln(
        "    final Map<String, dynamic> data = _\$${className}ToJson(this);");
    sb.writeln("    return _sanitizeJson(data);");
    sb.writeln("  }");
    sb.writeln("");
    sb.writeln("  dynamic _sanitizeJson(dynamic json) {");
    sb.writeln("    if (json is Map<String, dynamic>) {");
    sb.writeln("      json.remove('_className_');");
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
    sb.writeln(getCompareToExtension(
        classNameTrimmed, allFieldsDistinct, allValueTInterfaces));
  }

  // Add changeTo extension for explicitSubTypes
  // Generate for abstract classes with explicitSubTypes so all subtypes can use it
  if (typesExplicit.isNotEmpty) {
    var knownClasses =
        allAnnotatedClasses.keys.map((k) => k.replaceAll('\$', '')).toList();
    sb.writeln(getChangeToExtension(
      sourceFields: allFieldsDistinct,
      sourceClassName: className,
      explicitSubTypes: typesExplicit,
      knownClasses: knownClasses,
    ));
  }

  return sb.toString();
}
