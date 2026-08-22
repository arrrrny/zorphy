import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dartx/dartx.dart';
import 'package:source_gen/source_gen.dart';

import 'NameType.dart';
import 'classes.dart';

/// Finds an annotation by name on a list of metadata entries.
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

/// Extracts JsonKey configuration from a field or accessor.
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
      final dynamic dynAccessor = element;
      Element? variable;
      try {
        variable = dynAccessor.variable;
      } catch (_) {
        try {
          variable = dynAccessor.variable;
        } catch (_) {}
      }
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
    bool? disallowNullValue;
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
      final disallowNullValueValue = reader.read('disallowNullValue');
      if (!disallowNullValueValue.isNull)
        disallowNullValue = disallowNullValueValue.boolValue;
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
        disallowNullValue != null ||
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
        disallowNullValue: disallowNullValue,
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

/// Builds a merged doc comment string for a class and its interfaces.
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

/// Collects fields from interfaces and a concrete class element.
List<NameTypeClassComment> getAllFields(
  List<InterfaceType> interfaceTypes,
  InterfaceElement element, {
  LibraryElement? library,
}) {
  library ??= element.library;
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
        final dynamic dynAccessor = element;
        Element? variable;
        try {
          variable = dynAccessor.variable;
        } catch (_) {
          try {
            variable = dynAccessor.variable;
          } catch (_) {}
        }
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
    var fields = elem.children.whereType<FieldElement>().map((f) {
      return NameTypeClassComment(
        f.name ?? "",
        _resolveFieldType(
          f,
          f.type,
          currentClassName: currentClassName,
          library: library,
        ),
        elem.name ?? "",
        comment: f.getter?.documentationComment,
        jsonKeyInfo: extractJsonKeyInfo(f),
        additionalAnnotations: _collectAdditionalAnnotations(f),
        isEnum: f.type.element is EnumElement,
        isGetterOnly:
            f.isOriginGetterSetter && f.getter != null && f.setter == null,
      );
    });

    var getters = elem.children
        .whereType<PropertyAccessorElement>()
        .where((a) => a is GetterElement && a.isOriginDeclaration)
        .map((a) {
          bool isGetterOnly;
          try {
            isGetterOnly =
                a is GetterElement && (a as dynamic).variable == null;
          } catch (_) {
            // Fallback for different analyzer versions or unexpected states
            isGetterOnly = true;
          }

          return NameTypeClassComment(
            a.name ?? "",
            _resolveFieldType(
              a,
              a.returnType,
              currentClassName: currentClassName,
              library: library,
            ),
            elem.name ?? "",
            comment: a.documentationComment,
            jsonKeyInfo: extractJsonKeyInfo(a),
            additionalAnnotations: _collectAdditionalAnnotations(a),
            isEnum: a.returnType.element is EnumElement,
            isGetterOnly: isGetterOnly,
            enumValues: a.returnType.element is EnumElement
                ? (a.returnType.element as EnumElement).children
                      .whereType<FieldElement>()
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

/// Converts a Dart type to a normalized string representation.
String typeToString(
  DartType type, {
  String? currentClassName,
  LibraryElement? library,
}) {
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
        : "<${alias.typeArguments.map((t) => typeToString(t, currentClassName: currentClassName, library: library)).join(', ')}>";
    manual = "${alias.element.name}$args";
  } else if (type is FunctionType) {
    final generics = type.typeParameters.isNotEmpty
        ? "<${type.typeParameters.map((param) {
            final bound = param.bound;
            return "${param.name}${bound == null ? "" : " = ${typeToString(bound, currentClassName: currentClassName, library: library)}"}";
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
              ? typeToString(
                  param.type,
                  currentClassName: currentClassName,
                  library: library,
                )
              : "${typeToString(param.type, currentClassName: currentClassName, library: library)} $paramName";
        })
        .join(', ');
    final named = type.formalParameters
        .where((param) => param.isNamed)
        .map((param) {
          final paramName = sanitizeParameterName(param.name);
          final prefix = param.isRequiredNamed ? 'required ' : '';
          return paramName.isEmpty
              ? "${prefix}${typeToString(param.type, currentClassName: currentClassName, library: library)}"
              : "${prefix}${typeToString(param.type, currentClassName: currentClassName, library: library)} $paramName";
        })
        .join(', ');
    final optional = type.formalParameters
        .where((param) => param.isOptionalPositional)
        .map((param) {
          final paramName = sanitizeParameterName(param.name);
          return paramName.isEmpty
              ? typeToString(
                  param.type,
                  currentClassName: currentClassName,
                  library: library,
                )
              : "${typeToString(param.type, currentClassName: currentClassName, library: library)} $paramName";
        })
        .join(', ');
    final parts = [
      if (normal.isNotEmpty) normal,
      if (named.isNotEmpty) "{$named}",
      if (optional.isNotEmpty) "[$optional]",
    ].join(', ');
    manual =
        "${typeToString(type.returnType, currentClassName: currentClassName, library: library)} Function$generics($parts)";
  } else if (type is RecordType) {
    final positional = type.positionalFields
        .map(
          (e) => typeToString(
            e.type,
            currentClassName: currentClassName,
            library: library,
          ),
        )
        .join(', ');
    final named = type.namedFields
        .map(
          (e) =>
              "${typeToString(e.type, currentClassName: currentClassName, library: library)} ${e.name}",
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
        ? "<${type.typeArguments.map((t) => typeToString(t, currentClassName: currentClassName, library: library)).join(', ')}>"
        : '';

    var typeName = type is ParameterizedType ? type.element?.name : null;
    typeName ??= 'InvalidType';

    final ds = type.getDisplayString();

    // Handle library prefixes for resolved types
    if (library != null &&
        type.element?.library != null &&
        type.element?.library != library &&
        typeName != 'InvalidType' &&
        typeName != 'dynamic') {
      final imports = library.firstFragment.libraryImports;
      final typeLibrary = type.element?.library;
      final typeLibraryUri = typeLibrary?.firstFragment.source.uri;

      for (final import in imports) {
        final importedLibrary = import.importedLibrary;
        final importedLibraryUri = importedLibrary?.firstFragment.source.uri;

        // Compare by element first, then by URI string if elements don't match
        if (importedLibrary == typeLibrary ||
            (typeLibraryUri != null &&
                importedLibraryUri != null &&
                typeLibraryUri.toString() == importedLibraryUri.toString())) {
          final prefix = import.prefix?.name;
          if (prefix != null) {
            typeName = "$prefix.$typeName";
          }
          break;
        }
      }
    }

    // Handle self-reference and deps: if type is InvalidType, try to use the name from the element's display string
    // This happens when the file is not yet generated
    if (typeName == 'InvalidType' || typeName == 'dynamic') {
      var displayName = type.element?.displayName;

      // Fallback to display string if element name is missing (common for InvalidType)
      if (displayName == null ||
          displayName == 'dynamic' ||
          displayName == 'InvalidType') {
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

    // CRITICAL: Ensure we don't accidentally strip a prefix that was already present in the display string
    // if we end up with something like "Document" when display string was "dws.Document"
    if (!manual.contains('.') && ds.contains('.')) {
      final lastDot = ds.lastIndexOf('.');
      final dsPrefix = ds.substring(0, lastDot);
      // Ensure we're not just getting a generic prefix (like "List")
      if (dsPrefix.isNotEmpty &&
          !dsPrefix.contains('<') &&
          !dsPrefix.contains('(') &&
          !manual.startsWith(dsPrefix + '.')) {
        manual = "$dsPrefix.$manual";
      }
    }
  }

  return manual != null ? "$manual$nullMarker" : type.toString();
}


/// Strips Dart keywords and annotations from a recovered raw type string.
///
/// Ported verbatim from `ClassAnalyzer._cleanRecoveredType` so that field
/// recovery uses the same cleaning rules as method/parameter recovery.
String cleanRecoveredType(String rawString) {
  var result = rawString;
  // Basic cleanup of keywords and annotations
  final keywords = [
    'static',
    'required',
    'final',
    'const',
    'var',
    'covariant',
    'late',
    'external',
    'abstract',
    'get',
    'set',
  ];
  for (final kw in keywords) {
    if (result.startsWith(kw + ' ')) {
      result = result.substring(kw.length).trim();
    }
    result = result.replaceAll(RegExp(r'\b' + kw + r'\b'), '').trim();
  }

  // Remove annotations (anything starting with @ up to whitespace or end)
  while (result.startsWith('@')) {
    final endIdx = result.indexOf(' ');
    if (endIdx != -1) {
      result = result.substring(endIdx).trim();
    } else {
      // Handle @Annotation(...)
      if (result.startsWith('@') && result.contains(')')) {
        final closeIdx = result.indexOf(')');
        result = result.substring(closeIdx + 1).trim();
      } else {
        break;
      }
    }
  }
  return result;
}

/// Attempts to recover the original type string from source code when the
/// analyzer returns `InvalidType`.
///
/// This handles the cross-entity reference case (issue #351): when a Zorphy
/// entity has a field whose declared type is the CONCRETE form of another
/// Zorphy entity (e.g. `ParentThing? get parent` with no `$` prefix), the
/// analyzer cannot resolve the type during `build_runner` because the
/// concrete class is generated into a `.zorphy.dart` PART file that is not
/// yet in the analysis session. `typeToString` then falls back to
/// `InvalidType`, which breaks `json_serializable`.
///
/// The recovery walks the source text backwards from the element's
/// `nameOffset` (or falls back to a text search) to extract the type token
/// that appears immediately before the field/getter/parameter name.
///
/// Ported verbatim from `ClassAnalyzer._recoverTypeFromSource` so it can be
/// called from `getAllFields` (which lives in this file) without a circular
/// import on `class_analyzer.dart`.
String recoverTypeFromSource(Element element, String currentType) {
  try {
    final dynamic dynElem = element;

    // Try to get source from various places dynamically
    dynamic sourceObj;
    try {
      sourceObj = dynElem.source;
    } catch (_) {}

    if (sourceObj == null) {
      try {
        sourceObj = (dynElem.library as dynamic)?.source;
      } catch (_) {}
    }

    if (sourceObj == null) {
      try {
        sourceObj = (dynElem.enclosingElement as dynamic)?.source;
      } catch (_) {}
    }

    String? source;
    if (sourceObj != null) {
      try {
        source = (sourceObj as dynamic).contents.data.toString();
      } catch (_) {}
    }

    // Try various offset properties
    int? nameOffset;
    try {
      nameOffset = dynElem.nameOffset as int?;
    } catch (_) {}

    if (nameOffset == null) {
      try {
        nameOffset = dynElem.offset as int?;
      } catch (_) {}
    }

    if (source == null) {
      return currentType;
    }


    // Treat -1 / 0 as "no offset" — the analyzer returns these for synthetic
    // or unresolved elements. Fall through to the text-search fallback.
    final hasValidOffset = nameOffset != null && nameOffset > 0;

    // If nameOffset is missing, try to find the element in the source text
    if (!hasValidOffset) {
      // Fallback: Text search
      final containerName =
          (dynElem.enclosingElement as dynamic)?.name as String?;
      final entityName = element.name;

      // Strip `///` and `//` comment lines so comment text isn't swept into
      // a recovered type (issue #88). Done up front because the parameter
      // recovery below also needs the comment-free source.
      final commentFreeSource = source
          .split('\n')
          .where((line) => !line.trim().startsWith('//'))
          .join('\n');

      // Parameters must be recovered from their enclosing executable's
      // signature, never from a same-named class member (getter/field).
      // A polymorphic static factory such as
      // `fromUrlSpark({required UrlSpark spark})` has a parameter `spark`
      // whose analyzer type is `InvalidType` (the subtype `UrlSpark` isn't
      // resolved yet during generation); the getter/field patterns below
      // would otherwise match the class getter `Spark? get spark` and
      // recover the wrong type. We instead match the parameter as `Type name`
      // inside the enclosing executable's parameter list, anchored to that
      // executable when it has a name (methods, named constructors).
      // Detect a parameter element without depending on the concrete
      // ParameterElement type (not always in scope here). ParameterElements
      // report an ElementKind of PARAMETER.
      final dynamic _elKind = (element as dynamic).kind;
      final bool isParameter =
          _elKind != null && _elKind.toString().contains('PARAMETER');

      if (isParameter && entityName != null) {
        final exec = element.enclosingElement;
        final execName = exec?.name ?? '';
        // Anchor to the enclosing executable's parameter list. The type is
        // captured non-greedily so a `required Type name` / generic
        // `Type<X, Y> name` param is recovered whole (the original greedy
        // capture overmatched `required Type name`). No trailing `,`/`)`/`}`
        // is required because named parameters close with `}` (e.g.
        // `fromUrlSpark({required UrlSpark spark})`). Anchoring to the
        // executable name also prevents matching a same-named class member
        // (getter/field) such as `Spark? get spark`.
        final anchor = execName.isNotEmpty
            ? r'\b' + RegExp.escape(execName) + r'\b\s*\([\s\S]*?'
            : r'[\s\S]*?';
        final paramPattern = RegExp(
          anchor + r'([\w<>,?.\s]+?)\s+\b' + RegExp.escape(entityName) + r'\b',
        );
        final pm = paramPattern.firstMatch(commentFreeSource);
        if (pm != null) {
          final candidate = cleanRecoveredType(pm.group(1)!.trim());
          if (candidate.isNotEmpty &&
              !candidate.contains('InvalidType') &&
              !candidate.contains('//')) {
            return candidate;
          }
        }
        // No executable-anchored parameter match — do NOT fall through to the
        // getter/field patterns (they would recover a wrong same-named member
        // type). Keep the analyzer's (possibly InvalidType) result so the
        // caller can skip the factory instead of emitting broken code.
        return currentType;
      }

      if (containerName != null && entityName != null) {
        // Try constructor-parameter pattern first (original behavior —
        // preserves the recovery for method params that was already working).
        final ctorPattern = RegExp(
          '\b' + containerName + r'\b\s*\([\s\S]*?([\w<>,? ]+)\s+\b' + entityName + r'\b',
        );
        var match = ctorPattern.firstMatch(commentFreeSource);
        if (match != null) {
          var extracted = match.group(1)!;
          if (extracted.contains(',')) {
            extracted = extracted.split(',').last;
          }
          var candidate = cleanRecoveredType(extracted.trim());
          if (candidate.isNotEmpty && !candidate.contains('InvalidType')) {
            return candidate;
          }
        }

        // Field/getter pattern (issue #351): matches `Type get name` or
        // `Type name;` / `Type name =` / `Type name,` inside the class body.
        // The capture group grabs the type token sequence before the name,
        // stopping at the class/member delimiter ( `{` `;` `}` or newline
        // followed by indentation). We use a non-greedy match scoped to the
        // enclosing class body so we don't accidentally match a same-named
        // identifier in a sibling class.
        //
        // We try the getter form first (`Type get name`), then the plain
        // field form (`Type name;`).
        final escapedName = RegExp.escape(entityName);
        final getterPattern = RegExp(
          r'([\w<>,?\s]+?)\s+get\s+\b' + escapedName + r'\b',
        );
        final fieldPattern = RegExp(
          r'([\w<>,?\s]+?)\s+\b' + escapedName + r'\b\s*[;=,]',
        );
        for (final pattern in [getterPattern, fieldPattern]) {
          match = pattern.firstMatch(commentFreeSource);
          if (match != null) {
            var candidate = cleanRecoveredType(match.group(1)!.trim());
            // Reject obviously wrong matches: the type must not contain
            // the entity name itself, must not be empty, and must not be
            // a comment fragment.
            if (candidate.isNotEmpty &&
                !candidate.contains('InvalidType') &&
                !candidate.contains('//') &&
                candidate != entityName) {
              return candidate;
            }
          }
        }

        // Method (incl. static factory) return-type pattern.
        //
        // A static `create` factory often returns the class's CONCRETE
        // generated type (e.g. `AppConfig`), which the analyzer cannot
        // resolve during `build_runner` — so `getDisplayString()` yields
        // `InvalidType`. The getter/field patterns above don't match a
        // `Type name(` method signature, so a static factory whose return
        // type is a generated class was silently dropped. This pattern
        // captures the return type that precedes `name(`.
        final methodPattern = RegExp(
          r'(?:\b(?:static|final|const|factory|external|covariant|abstract|late)\s+)*([\w<>,?.\s]+?)\s+\b' +
              escapedName +
              r'\b\s*\(',
        );
        match = methodPattern.firstMatch(commentFreeSource);
        if (match != null) {
          final candidate = cleanRecoveredType(match.group(1)!.trim());
          if (candidate.isNotEmpty &&
              !candidate.contains('InvalidType') &&
              !candidate.contains('//') &&
              candidate != entityName) {
            return candidate;
          }
        }
      }

      return currentType;
    }

    var i = nameOffset - 1;

    // Skip whitespace backwards from name
    while (i >= 0 && source.codeUnitAt(i) <= 32) i--;

    if (i < 0) return currentType;

    // If the token immediately before the name is `get` (i.e., this is a
    // getter declaration `Type get name`), skip past `get` and its leading
    // whitespace so the type scan doesn't include the `get` keyword.
    final beforeName = source.substring(i > 3 ? i - 3 : 0, i + 1);
    if (beforeName.endsWith('get') || beforeName.endsWith('get ')) {
      // Back up past 'get' (3 chars) and any whitespace.
      i -= 3;
      while (i >= 0 && source.codeUnitAt(i) <= 32) i--;
      if (i < 0) return currentType;
    }

    final typeEnd = i + 1;
    int depth = 0; // <> depth
    int parenDepth = 0; // () depth (for annotations)

    // Scan backwards to find start of type
    int typeStart = 0;

    while (i >= 0) {
      final char = source[i];

      if (char == '>')
        depth++;
      else if (char == '<')
        depth--;
      else if (char == ')')
        parenDepth++;
      else if (char == '(')
        parenDepth--;

      // Stop at delimiters if we are at top level
      if (depth == 0 && parenDepth == 0) {
        if (char == ',' || char == '(' || char == '{' || char == ';') {
          typeStart = i + 1;
          break;
        }
      }
      i--;
    }

    var rawString = source.substring(typeStart, typeEnd).trim();

    // Issue #88: the backwards scan above does not treat `///` or `//`
    // comment lines as type-boundary delimiters — only `,`, `(`, `{`,
    // and `;` are recognized. So when a field/getter is preceded by a
    // doc-comment block (very common in zikzak_inappwebview settings
    // docs, e.g. `///- Android native WebView` / `///- iOS`), those
    // comment lines are swept into `rawString` alongside the actual
    // type token. The result is a multi-line "type" like:
    //
    //   ///Supported on:
    //   ///- macOS
    //   Bar?
    //
    // which code_builder emits verbatim as a parameter/field type, and
    // dart_style then mis-parses (the `///` markers vanish as comment
    // delimiters, but the bare token `macOS` survives and leaks into
    // the generated constructor as a stray identifier).
    //
    // Fix: strip every line whose trimmed form starts with `//` (this
    // covers both `///` doc comments and `//` line comments) before
    // passing the candidate to `cleanRecoveredType`. What remains is
    // just the actual type token (`Bar?` in the example above).
    final commentStripped = rawString
        .split('\n')
        .where((line) => !line.trim().startsWith('//'))
        .join('\n')
        .trim();
    if (commentStripped.isNotEmpty) {
      rawString = commentStripped;
    }

    var candidate = cleanRecoveredType(rawString);

    // Defense in depth: reject candidates that still contain `//` (the
    // text-search fallback path already does this; the scan-backwards
    // path did not, which is why issue #88 only manifested for cross-
    // entity concrete references that trigger source recovery). A
    // candidate containing `//` cannot be a valid Dart type token, so
    // fall through to `return currentType`.
    if (candidate.isNotEmpty &&
        !candidate.contains('InvalidType') &&
        !candidate.contains('//')) {
      return candidate;
    }

    return currentType;
  } catch (e) {
    print('ZORPHY DEBUG: Error recovering type: ' + e.toString());
    return currentType;
  }
}

/// Resolves a field/getter type, falling back to source recovery when the
/// analyzer returns `InvalidType`. Used by `getAllFields` so that
/// cross-entity concrete references (issue #351) don't break the build.
String _resolveFieldType(
  Element element,
  DartType type, {
  String? currentClassName,
  LibraryElement? library,
}) {
  var result = typeToString(
    type,
    currentClassName: currentClassName,
    library: library,
  );
  if (result.contains('InvalidType')) {
    final recovered = recoverTypeFromSource(element, result);
    if (!recovered.contains('InvalidType')) {
      return recovered;
    }
  }
  return result;
}

