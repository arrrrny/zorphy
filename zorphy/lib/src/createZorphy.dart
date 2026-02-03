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
) {
  var sb = StringBuffer();

  // No imports in part files - they belong in the main file

  if (docComment.isNotEmpty) {
    sb.writeln(docComment);
  }

  if (generateJson) {
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
    // Check if we have factory methods - if so, use implements instead of extends
    if (factoryMethods.isNotEmpty) {
      // Use implements when there are factory constructors (can't extend a class with only factory constructors)
      var allImplements = <String>[abstractClassName];
      if (implementsClauseTrimmed.isNotEmpty) {
        allImplements.addAll(implementsClauseTrimmed.split(", "));
      }
      implementsStr = " implements ${allImplements.join(', ')}";
    } else {
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
        // Concrete class in sealed hierarchy - implements the sealed interface directly
        // Add $$ prefix if the interface doesn't already have it
        var sealedInterfaceName = sealedParent.interfaceName.startsWith("\$\$")
            ? sealedParent.interfaceName
            : "\$\$" + sealedParent.interfaceName;
        implementsStr = " implements $sealedInterfaceName";
      } else {
        // Non-sealed - extend abstract parent
        extendsStr = " extends $abstractClassName";
        if (implementsClauseTrimmed.isNotEmpty) {
          implementsStr = " implements $implementsClauseTrimmed";
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
    sb.writeln(
        "${sealedModifier}${abstractModifier}class \$$className$genericsStr$implementsStr {");
    sb.writeln(getPropertiesAbstract(
        allFieldsDistinct, "\$$className", generateCopyWithFn));
  } else {
    // Don't add const modifier to concrete classes - only abstract classes can be const
    sb.writeln(
        "class $className$genericsStr$extendsStr$implementsStr {");
    // Determine if class extends abstract parent (needs @override) or just implements (no @override)
    // hasExtends is true only when we actually extend, false when we only implement
    var hasExtendsParam = extendsStr.isNotEmpty && factoryMethods.isEmpty;
    sb.writeln(getProperties(
        allFieldsDistinct,
        className,
        false,
        hidePublicConstructor,
        generateCopyWithFn,
        generateJson,
        hasExtendsParam));
  }

  if (!isAbstract || generateCopyWithFn) {
    sb.writeln(getCopyWith(allFieldsDistinct,
        isAbstract ? "\$$className" : className, generateCopyWithFn));
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
  if (generateJson && !isAbstract) {
    var classNameTrimmed = className.replaceAll("\$", "");
    sb.writeln();
    sb.writeln("  /// Creates a [${classNameTrimmed}] instance from JSON");
    if (typesExplicit.isEmpty && classGenerics.isEmpty) {
      sb.writeln(
          "  factory ${classNameTrimmed}.fromJson(Map<String, dynamic> json) => _\$${classNameTrimmed}FromJson(json);");
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
  if (typesExplicit.isNotEmpty && !isAbstract) {
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
