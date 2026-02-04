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
    if (element != null && (element.name == name || element.name == name)) {
      return annotation;
    }
  }
  return null;
}

JsonKeyInfo? extractJsonKeyInfo(FieldElement field) {
  try {
    var metadata = field.metadata;
    var annotation = metadata.annotations.isNotEmpty
        ? findAnnotation(metadata.annotations, 'JsonKey') ??
              findAnnotation(metadata.annotations, 'jsonKey')
        : null;

    if (annotation == null && field.getter != null) {
      var getterMetadata = field.getter!.metadata;
      annotation = getterMetadata.annotations.isNotEmpty
          ? findAnnotation(getterMetadata.annotations, 'JsonKey') ??
                findAnnotation(getterMetadata.annotations, 'jsonKey')
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

    if (name != null ||
        ignore != null ||
        defaultValue != null ||
        required != null ||
        includeIfNull != null ||
        includeFromJson != null ||
        includeToJson != null ||
        toJson != null ||
        fromJson != null) {
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
  var currentClassName = element.name?.replaceAll('\$', '');

  var superTypeFields = interfaceTypes
      .where((x) => x.element.name != "Object")
      .flatMap(
        (st) => st.element.fields.map(
          (f) => NameTypeClassComment(
            f.name ?? "",
            typeToString(f.type, currentClassName: currentClassName),
            st.element.name ?? "",
            comment: f.getter?.documentationComment,
            jsonKeyInfo: extractJsonKeyInfo(f),
            isEnum: f.type.element is EnumElement,
          ),
        ),
      )
      .toList();

  var classFields = element.fields
      .map(
        (f) => NameTypeClassComment(
          f.name ?? "",
          typeToString(f.type, currentClassName: currentClassName),
          element.name ?? "",
          comment: f.getter?.documentationComment,
          jsonKeyInfo: extractJsonKeyInfo(f),
          isEnum: f.type.element is EnumElement,
        ),
      )
      .toList();

  return (classFields + superTypeFields).distinctBy((x) => x.name).toList();
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
  } else if (type is ParameterizedType) {
    final arguments = type.typeArguments.isEmpty
        ? ''
        : "<${type.typeArguments.map((t) => typeToString(t, currentClassName: currentClassName)).join(', ')}>";
    final typeName = type.element?.name ?? 'InvalidType';
    // Handle self-reference: if type is InvalidType and we have currentClassName, use it
    if (typeName == 'InvalidType' && currentClassName != null) {
      manual = "\$$currentClassName$arguments";
    } else {
      manual = "$typeName$arguments";
    }
  }

  return manual != null ? "$manual$nullMarker" : type.toString();
}
