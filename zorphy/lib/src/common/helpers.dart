import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dartx/dartx.dart';
import 'package:source_gen/source_gen.dart';

import 'NameType.dart';
import 'classes.dart';

ElementAnnotation? findAnnotation(
  List<ElementAnnotation> annotations,
  String name,
) {
  for (final annotation in annotations) {
    final element = annotation.element;
    if (element != null) {
      final String? elementName = element.name;
      if (elementName == name ||
          elementName?.toLowerCase() == name.toLowerCase()) {
        return annotation;
      }
      // Check enclosing element for constructors
      try {
        final dynamic dynElem = element;
        final String? enclosingName = dynElem.enclosingElement?.name;
        if (enclosingName == name ||
            enclosingName?.toLowerCase() == name.toLowerCase()) {
          return annotation;
        }
      } catch (_) {}
    }

    // Final fallback to source check
    try {
      final source = annotation.toSource();
      if (source.contains('@$name') ||
          source.contains('@${name.toLowerCase()}')) {
        return annotation;
      }
    } catch (_) {}
  }
  return null;
}

/// Extracts annotations from an element's metadata, handling both
/// old API (List<ElementAnnotation>) and new API (Metadata object with .annotations).
List<ElementAnnotation> _extractAnnotations(dynamic rawMetadata) {
  if (rawMetadata is List) {
    return rawMetadata.cast<ElementAnnotation>();
  }
  try {
    final annotations = rawMetadata.annotations;
    if (annotations is List) {
      return annotations.cast<ElementAnnotation>();
    }
  } catch (_) {}
  return [];
}

JsonKeyInfo? extractJsonKeyInfo(Element element) {
  try {
    final dynamic dynElem = element;
    final annotations = _extractAnnotations(dynElem.metadata);
    var annotation = annotations.isNotEmpty
        ? findAnnotation(annotations, 'JsonKey') ??
              findAnnotation(annotations, 'jsonKey')
        : null;

    if (annotation == null &&
        element is FieldElement &&
        dynElem.getter != null) {
      final getterAnnotations = _extractAnnotations(dynElem.getter.metadata);

      annotation = getterAnnotations.isNotEmpty
          ? findAnnotation(getterAnnotations, 'JsonKey') ??
                findAnnotation(getterAnnotations, 'jsonKey')
          : null;
    }

    // Also check if we are a getter and the field/variable has it
    if (annotation == null && element is PropertyAccessorElement) {
      dynamic variable;
      try {
        variable = dynElem.variable2;
      } catch (_) {}
      try {
        variable ??= dynElem.variable;
      } catch (_) {}
      if (variable != null) {
        final varAnnotations = _extractAnnotations(variable.metadata);

        annotation = varAnnotations.isNotEmpty
            ? findAnnotation(varAnnotations, 'JsonKey') ??
                  findAnnotation(varAnnotations, 'jsonKey')
            : null;
      }
    }

    if (annotation == null) return null;

    final reader = ConstantReader(annotation.computeConstantValue());

    String? name;
    bool? ignore;
    dynamic defaultValue;
    bool? required;
    bool? includeIfNull;
    bool? includeFromJson;
    bool? includeToJson;
    String? toJson;
    String? fromJson;
    String? converter;

    try {
      final nameValue = reader.read('name');
      if (!nameValue.isNull) name = nameValue.stringValue;
    } catch (_) {}

    try {
      final ignoreValue = reader.read('ignore');
      if (!ignoreValue.isNull) ignore = ignoreValue.boolValue;
    } catch (_) {}

    try {
      // First try to extract from source to preserve exact syntax
      final source = annotation.toSource();
      defaultValue = _extractDefaultValue(source);

      // Fallback to reader if not found (or if source extraction failed somehow)
      if (defaultValue == null) {
        final defaultValueObj = reader.read('defaultValue');
        if (!defaultValueObj.isNull) {
          if (defaultValueObj.isString) {
            // Add quotes for string values to ensure valid Dart code
            defaultValue = "'${defaultValueObj.stringValue}'";
          } else if (defaultValueObj.isBool) {
            defaultValue = defaultValueObj.boolValue.toString();
          } else if (defaultValueObj.isInt) {
            defaultValue = defaultValueObj.intValue.toString();
          } else if (defaultValueObj.isDouble) {
            defaultValue = defaultValueObj.doubleValue.toString();
          } else {
            // Best effort for other types
            defaultValue = defaultValueObj.objectValue.toString();
          }
        }
      }
    } catch (_) {}

    try {
      final requiredValue = reader.read('required');
      if (!requiredValue.isNull) required = requiredValue.boolValue;
    } catch (_) {}

    try {
      final includeIfNullValue = reader.read('includeIfNull');
      if (!includeIfNullValue.isNull)
        includeIfNull = includeIfNullValue.boolValue;
    } catch (_) {}

    try {
      final includeFromJsonValue = reader.read('includeFromJson');
      if (!includeFromJsonValue.isNull)
        includeFromJson = includeFromJsonValue.boolValue;
    } catch (_) {}

    try {
      final includeToJsonValue = reader.read('includeToJson');
      if (!includeToJsonValue.isNull)
        includeToJson = includeToJsonValue.boolValue;
    } catch (_) {}

    try {
      final source = annotation.toSource();

      final match = RegExp(r'toJson\s*:\s*([^,)]+)').firstMatch(source);
      if (match != null) {
        toJson = match.group(1)!.trim();
      }

      if (toJson == null) {
        final toJsonValue = reader.read('toJson');
        if (!toJsonValue.isNull) toJson = toJsonValue.objectValue.toString();
      }
    } catch (_) {}

    try {
      final source = annotation.toSource();
      final match = RegExp(r'fromJson\s*:\s*([^,)]+)').firstMatch(source);
      if (match != null) {
        fromJson = match.group(1)!.trim();
      }

      if (fromJson == null) {
        final fromJsonValue = reader.read('fromJson');
        if (!fromJsonValue.isNull)
          fromJson = fromJsonValue.objectValue.toString();
      }
    } catch (_) {}

    try {
      final converterValue = reader.read('converter');
      if (!converterValue.isNull) {
        final revived = converterValue.revive();
        final typeName = converterValue.objectValue.type?.getDisplayString();
        if (typeName != null) {
          final accessor = revived.accessor.isNotEmpty
              ? ".${revived.accessor}"
              : "";
          converter = "$typeName$accessor()";
        } else {
          converter = converterValue.objectValue.toString();
        }
      }
    } catch (_) {}

    if (name != null ||
        ignore != null ||
        defaultValue != null ||
        required != null ||
        includeIfNull != null ||
        includeFromJson != null ||
        includeToJson != null ||
        toJson != null ||
        fromJson != null ||
        converter != null) {
      return JsonKeyInfo(
        name: name,
        ignore: ignore,
        defaultValue: defaultValue,
        required: required,
        includeIfNull: includeIfNull,
        includeFromJson: includeFromJson,
        includeToJson: includeToJson,
        toJson: toJson,
        fromJson: fromJson,
        converter: converter,
      );
    }
  } catch (e) {
    return null;
  }

  return null;
}

String? _extractDefaultValue(String annotationSource) {
  final match = RegExp(r"defaultValue\s*:\s*").firstMatch(annotationSource);
  if (match == null) return null;

  final start = match.end;
  var depth = 0;
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var i = start;

  for (; i < annotationSource.length; i++) {
    final char = annotationSource[i];

    if (inSingleQuote) {
      if (char == "'" && annotationSource[i - 1] != '\\') {
        inSingleQuote = false;
      }
      continue;
    }

    if (inDoubleQuote) {
      if (char == '"' && annotationSource[i - 1] != '\\') {
        inDoubleQuote = false;
      }
      continue;
    }

    if (char == "'") {
      inSingleQuote = true;
      continue;
    }

    if (char == '"') {
      inDoubleQuote = true;
      continue;
    }

    if (char == '(' || char == '[' || char == '{') {
      depth++;
      continue;
    }

    if (char == ')' || char == ']' || char == '}') {
      if (depth == 0) {
        break;
      }
      depth--;
      continue;
    }

    if (char == ',' && depth == 0) {
      break;
    }
  }

  return annotationSource.substring(start, i).trim();
}

String getClassComment(List<Interface> interfaces, String? classComment) {
  var a = interfaces
      .where((e) => e is InterfaceWithComment && e.comment != classComment)
      .map((e) {
        var interfaceComment = e is InterfaceWithComment && e.comment != null
            ? "\n${e.comment}"
            : "";
        return "///implements [${e.interfaceName}]\n///\n$interfaceComment\n///";
      })
      .toList();

  if (classComment != null) a.insert(0, classComment + "\n///");

  return a.join("\n").trim() + "\n";
}

List<NameTypeClassComment> getAllFields(
  List<InterfaceType> interfaceTypes,
  ClassElement element,
) {
  var currentClassName = element.name?.replaceAll('\$', '') ?? '';

  List<String> _collectAdditionalAnnotations(Element element) {
    try {
      final dynamic dynElem = element;
      final elemAnnotations = _extractAnnotations(dynElem.metadata);
      final List<String> annotations = [];

      for (final m in elemAnnotations) {
        final source = m.toSource();
        if (!source.startsWith('@JsonKey') && !source.startsWith('@jsonKey')) {
          annotations.add(source);
        }
      }

      // If it's a field, also check its getter
      if (element is FieldElement && element.getter != null) {
        final dynamic dynGetter = element.getter;
        final getterAnnotations = _extractAnnotations(dynGetter.metadata);
        for (final m in getterAnnotations) {
          final source = m.toSource();
          if (!source.startsWith('@JsonKey') &&
              !source.startsWith('@jsonKey')) {
            if (!annotations.contains(source)) annotations.add(source);
          }
        }
      }

      // If it's a getter, also check its variable
      if (element is PropertyAccessorElement) {
        dynamic variable;
        try {
          variable = (element as dynamic).variable2;
        } catch (_) {}
        try {
          variable ??= (element as dynamic).variable;
        } catch (_) {}
        if (variable != null) {
          final varAnnotations = _extractAnnotations(variable.metadata);
          for (final m in varAnnotations) {
            final source = m.toSource();
            if (!source.startsWith('@JsonKey') &&
                !source.startsWith('@jsonKey')) {
              if (!annotations.contains(source)) annotations.add(source);
            }
          }
        }
      }

      return annotations;
    } catch (e) {
      return [];
    }
  }

  List<NameTypeClassComment> collectFromElement(InterfaceElement elem) {
    var fields = elem.fields.map((f) {
      return NameTypeClassComment(
        f.name ?? "",
        typeToString(f.type, currentClassName: currentClassName),
        elem.name ?? "",
        comment: f.getter?.documentationComment,
        jsonKeyInfo: extractJsonKeyInfo(f),
        additionalAnnotations: _collectAdditionalAnnotations(f),
        isEnum: f.type.element is EnumElement,
      );
    });

    // Get getters using dynamic to bypass analyzer version differences
    final dynamic dynamicElem = elem;
    final List<dynamic> gettersList = (dynamicElem.getters as List? ?? []);

    var getters = gettersList
        .where((a) => (a as dynamic).isSynthetic == false)
        .map((a) {
          final dynamic dynA = a;
          return NameTypeClassComment(
            dynA.name ?? "",
            typeToString(
              (dynA as dynamic).returnType,
              currentClassName: currentClassName,
            ),
            elem.name ?? "",
            comment: (dynA as dynamic).documentationComment,
            jsonKeyInfo: extractJsonKeyInfo(dynA as Element),
            additionalAnnotations: _collectAdditionalAnnotations(dynA),
            isEnum: (dynA as dynamic).returnType?.element is EnumElement,
            enumValues: (dynA as dynamic).returnType?.element is EnumElement
                ? ((dynA as dynamic).returnType!.element as EnumElement).fields
                      .where((f) => f.isEnumConstant)
                      .map((f) => f.name ?? "")
                      .where((name) => name.isNotEmpty)
                      .toList()
                : const [],
          );
        });

    return [...getters, ...fields];
  }

  var superTypeFields = interfaceTypes
      .where((x) => x.element.name != "Object")
      .flatMap((st) => collectFromElement(st.element))
      .toList();

  var classFields = collectFromElement(element);

  return (classFields + superTypeFields)
      .where((f) => f.name != "hashCode" && f.name != "runtimeType")
      .toList() // Materialize list
      .distinctBy((x) => x.name)
      .toList();
}

String typeToString(DartType type, {String? currentClassName}) {
  final nullMarker = type.nullabilitySuffix == NullabilitySuffix.question
      ? '?'
      : type.nullabilitySuffix == NullabilitySuffix.star
      ? '*'
      : '';

  final alias = type.alias;
  String? manual;
  if (alias != null) {
    final args = alias.typeArguments.isEmpty
        ? ''
        : "<${alias.typeArguments.map((t) => typeToString(t, currentClassName: currentClassName)).join(', ')}>";
    manual = "${alias.element.name}$args";
  } else if (type is FunctionType) {
    final generics = type.typeParameters.isNotEmpty
        ? "<${type.typeParameters.map((param) {
            final bound = param.bound;
            return "${param.name}${bound == null ? "" : " = ${typeToString(bound)}"}";
          }).join(', ')}>"
        : '';

    // Reserved keywords that cannot be used as identifiers
    const reservedKeywords = {
      'abstract',
      'as',
      'base',
      'break',
      'case',
      'catch',
      'class',
      'const',
      'continue',
      'covariant',
      'default',
      'deferred',
      'do',
      'dynamic',
      'else',
      'enum',
      'export',
      'extends',
      'extension',
      'external',
      'factory',
      'false',
      'final',
      'finally',
      'for',
      'Function',
      'get',
      'hide',
      'if',
      'implements',
      'import',
      'in',
      'interface',
      'is',
      'late',
      'library',
      'mixin',
      'new',
      'null',
      'on',
      'operator',
      'part',
      'rethrow',
      'return',
      'set',
      'show',
      'static',
      'super',
      'switch',
      'sync',
      'this',
      'throw',
      'true',
      'try',
      'type',
      'typedef',
      'var',
      'void',
      'while',
      'with',
      'yield',
    };

    String sanitizeParameterName(String? name) {
      if (name == null || reservedKeywords.contains(name)) {
        // If it's null or a reserved keyword, return the type without a name
        // This is valid for function type signatures
        return '';
      }
      return name;
    }

    final normal = type.formalParameters
        .where((param) => param.isRequiredPositional)
        .map((param) {
          final paramName = sanitizeParameterName(param.name);
          return paramName.isEmpty
              ? typeToString(param.type, currentClassName: currentClassName)
              : "${typeToString(param.type, currentClassName: currentClassName)} $paramName";
        })
        .join(', ');
    final named = type.formalParameters
        .where((param) => param.isNamed)
        .map((param) {
          final paramName = sanitizeParameterName(param.name);
          final prefix = param.isRequiredNamed ? 'required ' : '';
          return paramName.isEmpty
              ? "${prefix}${typeToString(param.type, currentClassName: currentClassName)}"
              : "${prefix}${typeToString(param.type, currentClassName: currentClassName)} $paramName";
        })
        .join(', ');
    final optional = type.formalParameters
        .where((param) => param.isOptionalPositional)
        .map((param) {
          final paramName = sanitizeParameterName(param.name);
          return paramName.isEmpty
              ? typeToString(param.type, currentClassName: currentClassName)
              : "${typeToString(param.type, currentClassName: currentClassName)} $paramName";
        })
        .join(', ');
    final parts = [
      if (normal.isNotEmpty) normal,
      if (named.isNotEmpty) "{$named}",
      if (optional.isNotEmpty) "[$optional]",
    ].join(', ');
    manual =
        "${typeToString(type.returnType, currentClassName: currentClassName)} Function$generics($parts)";
  } else if (type is RecordType) {
    final positional = type.positionalFields
        .map((e) => typeToString(e.type, currentClassName: currentClassName))
        .join(', ');
    final named = type.namedFields
        .map(
          (e) =>
              "${typeToString(e.type, currentClassName: currentClassName)} ${e.name}",
        )
        .join(', ');
    final trailing =
        type.positionalFields.length == 1 && type.namedFields.isEmpty
        ? ','
        : '';
    final parts = [
      if (positional.isNotEmpty) positional,
      if (named.isNotEmpty) "{$named}",
    ].join(', ');
    manual = "($parts$trailing)";
  } else if (type is ParameterizedType ||
      type.toString().contains('InvalidType') ||
      type.getDisplayString().contains('InvalidType')) {
    final arguments = type is ParameterizedType && type.typeArguments.isNotEmpty
        ? "<${type.typeArguments.map((t) => typeToString(t, currentClassName: currentClassName)).join(', ')}>"
        : '';

    var typeName = type is ParameterizedType ? type.element?.name : null;
    typeName ??= 'InvalidType';

    // Handle self-reference and deps: if type is InvalidType, try to use the name from the element's display string
    // This happens when the file is not yet generated
    if (typeName == 'InvalidType' || typeName == 'dynamic') {
      var displayName = type.element?.displayName;

      // Fallback to display string if element name is missing (common for InvalidType)
      if (displayName == null ||
          displayName == 'dynamic' ||
          displayName == 'InvalidType') {
        final ds = type.getDisplayString();
        // If it's a parameterized type like List<Attachment>, getDisplayString might return the whole thing
        // We just want the base name if possible.
        if (ds.contains('<')) {
          displayName = ds.substring(0, ds.indexOf('<'));
        } else {
          displayName = ds;
        }
      }

      if (displayName != 'dynamic' && displayName != 'InvalidType') {
        // Check if this is an enum - enums don't need $ prefix
        final isEnum = type.element is EnumElement;
        if (isEnum) {
          manual = "$displayName$arguments";
        } else {
          // For unresolved types, use the name exactly as it appears in source.
          // Do not force $ prefix, as it changes the type (e.g. List<Attachment> != List<$Attachment>)
          manual = "$displayName$arguments";
        }
      } else {
        manual = "$typeName$arguments";
      }
    } else {
      // If typeName is standard but arguments might contain InvalidType
      // check if the string representation has InvalidType
      if (arguments.contains('InvalidType') ||
          type.toString().contains('InvalidType')) {
        final ds = type.getDisplayString();
        // Extract the full type signature from display string to catch inner types
        // e.g. List<Attachment> instead of List<InvalidType>
        if (ds.contains('<')) {
          // If display string already has nullability marker at the end, strip it
          // because $nullMarker will be appended later
          if (ds.endsWith('?')) {
            manual = ds.substring(0, ds.length - 1);
          } else {
            manual = ds;
          }
        } else {
          manual = "$typeName$arguments";
        }
      } else {
        manual = "$typeName$arguments";
      }
    }
  }

  return manual != null ? "$manual$nullMarker" : type.toString();
}
