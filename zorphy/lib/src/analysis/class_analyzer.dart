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
    );
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
    return classElement.fields
        .where((f) => f.name != "hashCode" && f.name != "runtimeType")
        .map((f) => f.name ?? "")
        .toSet();
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
        final returnType = method.returnType.getDisplayString();
        final returnTypeString = method.returnType.toString();

        bool matchesType =
            returnType == className ||
            returnType == classNameTrimmed ||
            returnTypeString == className ||
            returnTypeString == classNameTrimmed;

        // If it's an unresolved type, check the element display name
        if (!matchesType &&
            (returnType == 'dynamic' || returnType.contains('InvalidType'))) {
          final elementDisplayName = method.returnType.element?.displayName;
          if (elementDisplayName == classElement.displayName ||
              elementDisplayName == classNameTrimmed ||
              elementDisplayName == className) {
            matchesType = true;
          }
        }

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
        } else if (method.isStatic &&
            method.name == 'create' &&
            (returnType.contains('InvalidType') || returnType == 'dynamic')) {
          // Special fallback for 'create' method if return type is unresolved
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
    return parameters.map((param) {
      final paramType = param.type.getDisplayString(withNullability: false);

      // Handle self-referencing types
      if (paramType.contains('InvalidType') || paramType == 'dynamic') {
        final classNameTrimmed = className.replaceAll(r'$', '');

        // Check if this is a self-reference to the current class
        if (param.type.element?.displayName == classElement.displayName ||
            param.type.element?.displayName == classNameTrimmed) {
          return FactoryParameterInfo(
            name: param.name as String,
            type: classNameTrimmed,
            isRequired: param.isRequiredNamed || param.isRequiredPositional,
            isNamed: param.isNamed,
            hasDefaultValue: param.hasDefaultValue,
            defaultValue: param.defaultValueCode,
          );
        } else {
          return FactoryParameterInfo(
            name: param.name as String,
            type: 'dynamic',
            isRequired: param.isRequiredNamed || param.isRequiredPositional,
            isNamed: param.isNamed,
            hasDefaultValue: param.hasDefaultValue,
            defaultValue: param.defaultValueCode,
          );
        }
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

  /// Check if this class is listed in any parent's explicitSubTypes
  static bool _isInParentExplicitSubtypes(
    String className,
    Set<String> classesInExplicitSubtypes,
  ) {
    return classesInExplicitSubtypes.contains(className);
  }
}
