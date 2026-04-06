import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import '../common/NameType.dart';
import '../common/helpers.dart' as common_helpers;
import '../helpers.dart' as codegen_helpers;
import '../factory_method.dart';
import '../models/class_metadata.dart';
import '../models/interface_metadata.dart';
import 'interface_collector.dart';
import 'field_resolver.dart';

/// Analyzes a @Zorphy-annotated class and extracts all metadata
/// This replaces the analysis phase in ZorphyGenerator.generateForAnnotatedElement
class ClassAnalyzer {
  /// Analyze a class element and extract complete metadata
  static ClassMetadata analyze(
    ClassElement classElement,
    ConstantReader annotation,
    Map<String, ClassElement> allAnnotatedClasses,
    Set<String> classesInExplicitSubtypes,
  ) {
    final className = classElement.name ?? '';
    final isAbstract = className.startsWith(r'$$');
    final nonSealed = annotation.read('nonSealed').boolValue;
    final isSealed = isAbstract && !nonSealed;

    // Validate that class uses implements, not extends
    _validateClassStructure(classElement);

    // Collect interfaces (handles inheritance hierarchy)
    final interfaceMetadataList = InterfaceCollector.collect(
      classElement,
      allAnnotatedClasses,
    );

    // Convert to Interface objects for JSON serialization
    final allValueTInterfaces = _convertToValueTInterfaces(
      interfaceMetadataList,
      className,
      allAnnotatedClasses,
    );

    // Extract explicit subtypes from annotation
    final explicitSubtypes = _extractExplicitSubtypes(
      annotation,
      allAnnotatedClasses,
    );

    // Resolve all fields (inherited + own)
    final allFields = FieldResolver.resolve(classElement, allAnnotatedClasses);

    // Get distinct fields (no duplicates, interface fields first)
    final allFieldsDistinct = codegen_helpers.getDistinctFields(
      allFields,
      allValueTInterfaces,
    );

    // Extract generic type parameters
    final generics = _extractGenerics(classElement);

    // Get own fields (defined directly on this class)
    final ownFieldNames = _extractOwnFieldNames(classElement);

    // Collect factory methods
    final factoryMethods = _extractFactoryMethods(classElement);

    return ClassMetadata(
      originalName: className,
      cleanName: className.replaceAll(r'$', ''),
      isAbstract: isAbstract,
      isSealed: isSealed,
      nonSealed: nonSealed,
      hasConstConstructor: classElement.constructors.any((e) => e.isConst),
      docComment: classElement.documentationComment ?? '',
      generics: generics,
      interfaces: interfaceMetadataList,
      allValueTInterfaces: allValueTInterfaces,
      allFields: allFieldsDistinct,
      ownFieldNames: ownFieldNames,
      factoryMethods: factoryMethods,
      explicitSubtypes: explicitSubtypes,
      isInParentExplicitSubtypes: _isInParentExplicitSubtypes(
        className,
        classesInExplicitSubtypes,
      ),
      classElement: classElement,
      allAnnotatedClasses: allAnnotatedClasses,
      polymorphicSubtypes: _extractPolymorphicSubtypes(
        classElement,
        annotation,
        allAnnotatedClasses,
      ),
    );
  }

  /// Extract all subtypes in the polymorphic hierarchy
  static List<Interface> _extractPolymorphicSubtypes(
    ClassElement classElement,
    ConstantReader annotation,
    Map<String, ClassElement> allAnnotatedClasses,
  ) {
    // 1. If this class has explicit subtypes, those are the ones
    final ownSubtypes = _extractExplicitSubtypes(
      annotation,
      allAnnotatedClasses,
    );
    if (ownSubtypes.isNotEmpty) return ownSubtypes;

    // 2. Otherwise, check interfaces to see if any of them define a polymorphic hierarchy
    final zorphyChecker = const TypeChecker.fromUrl(
      'package:zorphy_annotation/src/annotations.dart#Zorphy',
    );

    for (final interfaceType in classElement.allSupertypes) {
      final interfaceElement = interfaceType.element;
      if (interfaceElement is ClassElement) {
        final interfaceAnnotation = zorphyChecker.firstAnnotationOf(
          interfaceElement,
        );
        if (interfaceAnnotation != null) {
          final reader = ConstantReader(interfaceAnnotation);
          final field = reader.peek('explicitSubTypes');
          if (field != null && !field.isNull) {
            return _extractExplicitSubtypes(reader, allAnnotatedClasses);
          }
        }
      }
    }

    return const [];
  }

  /// Validate that class uses implements, not extends
  static void _validateClassStructure(ClassElement classElement) {
    if (classElement.supertype?.element.name != "Object") {
      throw Exception("you must use implements, not extends");
    }
  }

  /// Convert InterfaceWithComment list to Interface list
  /// This is for JSON serialization compatibility
  static List<Interface> _convertToValueTInterfaces(
    List<InterfaceMetadata> interfaces,
    String currentClassName,
    Map<String, ClassElement> allAnnotatedClasses,
  ) {
    return interfaces.map((e) {
      var interfaceName = e.interfaceName;
      var fields = _getAllFieldsIncludingSubtypes(
        e.element,
        allAnnotatedClasses,
      ).where((f) => f.name != "hashCode").toList();

      var nameTypeFields = fields
          .map((f) => NameType(f.name, f.type ?? ""))
          .toList();

      return Interface.fromGenerics(
        interfaceName, // Keep the original interface name with $ prefix
        e.typeArguments.asMap().entries.map((entry) {
          final index = entry.key;
          final typeArg = entry.value;
          final paramName = e.element.typeParameters.length > index
              ? e.element.typeParameters[index].name ?? "T$index"
              : "T$index";
          return NameType(
            paramName,
            common_helpers.typeToString(
              typeArg,
              currentClassName: currentClassName,
            ),
          );
        }).toList(),
        nameTypeFields,
        false,
        interfaceName.startsWith(r'$$'),
        false,
      );
    }).toList();
  }

  /// Extract explicit subtypes from annotation
  static List<Interface> _extractExplicitSubtypes(
    ConstantReader annotation,
    Map<String, ClassElement> allAnnotatedClasses,
  ) {
    final typesExplicit = <Interface>[];
    if (annotation.read('explicitSubTypes').isNull) {
      return typesExplicit;
    }

    return annotation.read('explicitSubTypes').listValue.map((x) {
      var typeValue = x.toTypeValue();
      if (typeValue?.element is! ClassElement) {
        throw Exception(
          "each type for the explicitSubTypes must all be classes",
        );
      }

      var el = typeValue!.element as ClassElement;
      // Register this class
      allAnnotatedClasses[el.name ?? ""] = el;

      var fields = _getAllFieldsIncludingSubtypes(
        el,
        allAnnotatedClasses,
      ).where((f) => f.name != "hashCode").toList();

      var nameTypeFields = fields
          .map((f) => NameType(f.name, f.type ?? ""))
          .toList();

      return Interface.fromGenerics(
        el.name ?? "",
        el.typeParameters.map((tp) {
          final bound = tp.bound;
          return NameType(
            tp.name ?? "",
            bound == null ? null : common_helpers.typeToString(bound),
          );
        }).toList(),
        nameTypeFields,
        true,
      );
    }).toList();
  }

  /// Get all fields including those from annotated supertypes
  static List<NameTypeClassComment> _getAllFieldsIncludingSubtypes(
    ClassElement element,
    Map<String, ClassElement> allAnnotatedClasses,
  ) {
    var fields = <NameTypeClassComment>[];
    var processedTypes = <String>{};

    void addFields(ClassElement elem) {
      var elemName = elem.name ?? "";
      if (processedTypes.contains(elemName)) return;
      processedTypes.add(elemName);

      fields.addAll(
        common_helpers
            .getAllFields(
              elem.allSupertypes.whereType<InterfaceType>().toList(),
              elem,
            )
            .where((x) => x.name != "hashCode" && x.name != "runtimeType"),
      );

      for (var supertype in elem.allSupertypes) {
        var supertypeName = supertype.element.name ?? "";
        if (allAnnotatedClasses.containsKey(supertypeName)) {
          addFields(allAnnotatedClasses[supertypeName]!);
        }
      }
    }

    addFields(element);
    return fields.toSet().toList();
  }

  /// Extract generic type parameters from class
  static List<GenericParameterMetadata> _extractGenerics(
    ClassElement classElement,
  ) {
    return classElement.typeParameters.map((e) {
      final bound = e.bound;
      return GenericParameterMetadata(
        name: e.name ?? '',
        bound: bound == null ? null : common_helpers.typeToString(bound),
      );
    }).toList();
  }

  /// Extract field names defined directly on this class
  static Set<String> _extractOwnFieldNames(ClassElement classElement) {
    final fields = classElement.children
        .whereType<FieldElement>()
        .where((f) => f.name != "hashCode" && f.name != "runtimeType")
        .map((f) => f.name);

    final getters = classElement.children
        .whereType<PropertyAccessorElement>()
        .where((a) => a is GetterElement && a.isOriginDeclaration)
        .where((a) => a.name != "hashCode" && a.name != "runtimeType")
        .map((a) => a.name);

    return {...fields.whereType<String>(), ...getters.whereType<String>()};
  }

  /// Extract factory methods from class
  static List<FactoryMethodInfo> _extractFactoryMethods(
    ClassElement classElement,
  ) {
    var factoryMethods = <FactoryMethodInfo>[];
    var className = classElement.name ?? "";

    for (var constructor in classElement.constructors) {
      if (constructor.isFactory &&
          constructor.name != null &&
          constructor.name!.isNotEmpty) {
        var parameters = _extractParameters(
          constructor.formalParameters,
          className,
          classElement,
        );
        factoryMethods.add(
          FactoryMethodInfo(
            name: constructor.name!,
            parameters: parameters,
            bodyCode: "",
            className: className,
          ),
        );
      }
    }

    // Also extract static methods that return the class's type (clean or original)
    final classNameTrimmed = className.replaceAll(r'$', '');
    for (var method in classElement.methods) {
      if (method.isStatic && !method.isOperator) {
        var returnType = method.returnType.getDisplayString();
        var returnTypeString = method.returnType.toString();

        // If type is unresolved, try to recover from source
        if (returnType == 'dynamic' || returnType.contains('InvalidType')) {
          returnType = _recoverTypeFromSource(method, returnType);
          returnTypeString = returnType;
        }

        bool matchesType =
            returnType == className ||
            returnType == classNameTrimmed ||
            returnTypeString == className ||
            returnTypeString == classNameTrimmed;

        if (matchesType) {
          var parameters = _extractParameters(
            method.formalParameters,
            className,
            classElement,
          );
          factoryMethods.add(
            FactoryMethodInfo(
              name: method.name as String,
              parameters: parameters,
              bodyCode: "",
              className: className,
            ),
          );
        }
      }
    }

    return factoryMethods;
  }

  static List<FactoryParameterInfo> _extractParameters(
    List<dynamic> parameters,
    String className,
    ClassElement classElement,
  ) {
    final classNameTrimmed = className.replaceAll(r"$", "");
    return parameters.map((param) {
      // Use the robust typeToString helper which handles nullability and InvalidType/self-references
      var paramType = common_helpers.typeToString(
        param.type,
        currentClassName: classNameTrimmed,
        library: classElement.library,
      );

      // CRITICAL FIX: If type is still InvalidType, try to recover from source code directly
      if (paramType.contains('InvalidType')) {
        paramType = _recoverTypeFromSource(param as Element, paramType);
      }

      return FactoryParameterInfo(
        name: param.name as String,
        type: paramType,
        isRequired: param.isRequiredNamed || param.isRequiredPositional,
        isNamed: param.isNamed,
        hasDefaultValue: param.hasDefaultValue,
        defaultValue: param.defaultValueCode as String?,
      );
    }).toList();
  }

  /// Attempts to recover the original type string from source code
  /// Used when the analyzer returns InvalidType
  static String _recoverTypeFromSource(Element element, String currentType) {
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

      // If nameOffset is missing, try to find the element in the source text
      if (nameOffset == null || nameOffset == 0) {
        // Fallback: Text search
        final containerName =
            (dynElem.enclosingElement as dynamic)?.name as String?;
        final entityName = element.name;

        if (containerName != null && entityName != null) {
          RegExp pattern;
          if (element is MethodElement) {
            // Match return type before method name: Type methodName(
            pattern = RegExp(r'([\w<>,? ]+)\s+\b' + entityName + r'\b\s*\(');
          } else {
            // Match parameter type: methodName... ( ... Type paramName
            pattern = RegExp(
              '\\b$containerName\\b\\s*\\([\\s\\S]*?([\\w<>,? ]+)\\s+\\b$entityName\\b',
            );
          }

          final match = pattern.firstMatch(source);
          if (match != null) {
            var extracted = match.group(1)!;
            if (element is! MethodElement && extracted.contains(',')) {
              extracted = extracted.split(',').last;
            }

            var candidate = extracted.trim();
            candidate = _cleanRecoveredType(candidate);

            if (candidate.isNotEmpty && !candidate.contains('InvalidType')) {
              return candidate;
            }
          }
        }

        return currentType;
      }

      // print('ZORPHY DEBUG: Recovering ${element.name} from offset $nameOffset');

      var i = nameOffset - 1;

      // Skip whitespace backwards from name
      while (i >= 0 && source.codeUnitAt(i) <= 32) i--;

      if (i < 0) return currentType;

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
      var candidate = _cleanRecoveredType(rawString);

      if (candidate.isNotEmpty && !candidate.contains('InvalidType')) {
        return candidate;
      }

      return currentType;
    } catch (e, st) {
      print('ZORPHY DEBUG: Error recovering type: $e\n$st');
      return currentType;
    }
  }

  static String _cleanRecoveredType(String rawString) {
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

  /// Check if this class is listed in any parent's explicitSubTypes
  static bool _isInParentExplicitSubtypes(
    String className,
    Set<String> classesInExplicitSubtypes,
  ) {
    return classesInExplicitSubtypes.contains(className);
  }
}
