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

JsonKeyInfo? extractJsonKeyInfo(Element element) {
  try {
    final dynamic dynElem = element;
    final dynamic rawMetadata = dynElem.metadata;
    final List<dynamic> metadata = rawMetadata is List ? rawMetadata : [];

    var annotation = metadata.isNotEmpty
        ? findAnnotation(metadata.cast<ElementAnnotation>(), 'JsonKey') ??
              findAnnotation(metadata.cast<ElementAnnotation>(), 'jsonKey')
        : null;

    if (annotation == null &&
        element is FieldElement &&
        dynElem.getter != null) {
      final dynamic rawGetterMetadata = dynElem.getter.metadata;
      final List<dynamic> getterMetadata = rawGetterMetadata is List
          ? rawGetterMetadata
          : [];
      annotation = getterMetadata.isNotEmpty
          ? findAnnotation(
                  getterMetadata.cast<ElementAnnotation>(),
                  'JsonKey',
                ) ??
                findAnnotation(
                  getterMetadata.cast<ElementAnnotation>(),
                  'jsonKey',
                )
          : null;
    }

    // Also check if we are a getter and the field has it
    if (annotation == null &&
        element is PropertyAccessorElement &&
        dynElem.variable != null) {
      final dynamic rawVarMetadata = dynElem.variable.metadata;
      final List<dynamic> variableMetadata = rawVarMetadata is List
          ? rawVarMetadata
          : [];
      annotation = variableMetadata.isNotEmpty
          ? findAnnotation(
                  variableMetadata.cast<ElementAnnotation>(),
                  'JsonKey',
                ) ??
                findAnnotation(
                  variableMetadata.cast<ElementAnnotation>(),
                  'jsonKey',
                )
          : null;
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
      final defaultValueObj = reader.read('defaultValue');
      if (!defaultValueObj.isNull) {
        if (defaultValueObj.isString) {
          defaultValue = defaultValueObj.stringValue;
        } else if (defaultValueObj.isBool) {
          defaultValue = defaultValueObj.boolValue;
        } else if (defaultValueObj.isInt) {
          defaultValue = defaultValueObj.intValue;
        } else if (defaultValueObj.isDouble) {
          defaultValue = defaultValueObj.doubleValue;
        } else {
          defaultValue = defaultValueObj.objectValue.toString();
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
      final toJsonValue = reader.read('toJson');
      if (!toJsonValue.isNull) toJson = toJsonValue.objectValue.toString();
    } catch (_) {}

    try {
      final fromJsonValue = reader.read('fromJson');
      if (!fromJsonValue.isNull)
        fromJson = fromJsonValue.objectValue.toString();
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
      final dynamic rawMetadata = dynElem.metadata;
      final List<dynamic> metadata = rawMetadata is List ? rawMetadata : [];
      final List<String> annotations = [];

      for (final m in metadata) {
        final source = m.toSource() as String;
        if (!source.startsWith('@JsonKey') && !source.startsWith('@jsonKey')) {
          annotations.add(source);
        }
      }

      // If it's a field, also check its getter
      if (element is FieldElement && element.getter != null) {
        final dynamic dynGetter = element.getter;
        final dynamic rawGetterMetadata = dynGetter.metadata;
        final List<dynamic> getterMetadata = rawGetterMetadata is List
            ? rawGetterMetadata
            : [];
        for (final m in getterMetadata) {
          final source = m.toSource() as String;
          if (!source.startsWith('@JsonKey') &&
              !source.startsWith('@jsonKey')) {
            if (!annotations.contains(source)) annotations.add(source);
          }
        }
      }

      // If it's a getter, also check its variable
      if (element is PropertyAccessorElement &&
          (element as dynamic).variable != null) {
        final dynamic dynVar = (element as dynamic).variable;
        final dynamic rawVarMetadata = dynVar.metadata;
        final List<dynamic> varMetadata = rawVarMetadata is List
            ? rawVarMetadata
            : [];
        for (final m in varMetadata) {
          final source = m.toSource() as String;
          if (!source.startsWith('@JsonKey') &&
              !source.startsWith('@jsonKey')) {
            if (!annotations.contains(source)) annotations.add(source);
          }
        }
      }

      return annotations;
    } catch (e) {
      return [];
    }
  }

  List<NameTypeClassComment> collectFromElement(InterfaceElement elem) {
    var fields = elem.fields.map(
      (f) => NameTypeClassComment(
        f.name ?? "",
        typeToString(f.type, currentClassName: currentClassName),
        elem.name ?? "",
        comment: f.getter?.documentationComment,
        jsonKeyInfo: extractJsonKeyInfo(f),
        additionalAnnotations: _collectAdditionalAnnotations(f),
        isEnum: f.type.element is EnumElement,
      ),
    );

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
      if (displayName == null || displayName == 'dynamic' || displayName == 'InvalidType') {
        final ds = type.getDisplayString();
        // If it's a parameterized type like List<Attachment>, getDisplayString might return the whole thing
        // We just want the base name if possible.
        if (ds.contains('<')) {
          displayName = ds.substring(0, ds.indexOf('<'));
        } else {
          displayName = ds;
        }
      }

      if (displayName != 'dynamic' &&
          displayName != 'InvalidType') {
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
