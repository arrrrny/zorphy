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
    // typeKey: own value takes precedence; otherwise inherit from the
    // nearest @Zorphy/@Zorphy2-annotated supertype that declares
    // explicitSubTypes. Subtypes inherit so the generated subtype
    // toJson() emits the same discriminator key the base's fromJson
    // dispatches on.
    final typeKey = annotation.peek('typeKey')?.stringValue ??
        _resolveInheritedTypeKey(classElement);
    // subtypeWireValue: per-subtype override of the wire value the base
    // emits/matches for this subtype. Null -> clean class name at codegen.
    final subtypeWireValue = annotation.peek('subtypeWireValue')?.stringValue;

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
      typeKey: typeKey,
      subtypeWireValue: subtypeWireValue,
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

      // Read the subtype's own @Zorphy(subtypeWireValue: ...) so the
      // base's dispatch can match the wire value the remote API sends.
      // Defaults to null -> clean class name (resolved at codegen time).
      final subtypeWireValue =
          _readSubtypeAnnotation(el)?.peek('subtypeWireValue')?.stringValue;
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
        false,
        false,
        subtypeWireValue,
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
    // Delegate to the shared helper so field/getter recovery (issue #351)
    // uses the same algorithm as method/parameter recovery.
    return common_helpers.recoverTypeFromSource(element, currentType);
  }


  /// Check if this class is listed in any parent's explicitSubTypes
  static bool _isInParentExplicitSubtypes(
    String className,
    Set<String> classesInExplicitSubtypes,
  ) {
    return classesInExplicitSubtypes.contains(className);
  }

  /// Walks [classElement]'s supertype chain to find the nearest
  /// `@Zorphy`/`@Zorphy2`-annotated base that declares `explicitSubTypes`,
  /// and returns that base's `typeKey`. Returns `null` when no such base
  /// exists or the base didn't customize its `typeKey`.
  ///
  /// Subtypes inherit the base's `typeKey` so the generated subtype
  /// `toJson()` emits the same discriminator key the base's `fromJson`
  /// dispatches on.
  static String? _resolveInheritedTypeKey(ClassElement classElement) {
    final zorphyChecker = const TypeChecker.fromUrl(
      'package:zorphy_annotation/src/annotations.dart#Zorphy',
    );
    final zorphy2Checker = const TypeChecker.fromUrl(
      'package:zorphy_annotation/src/annotations.dart#Zorphy2',
    );
    for (final supertype in classElement.allSupertypes) {
      final el = supertype.element;
      if (el is! ClassElement) continue;
      final annot = zorphyChecker.firstAnnotationOf(el) ??
          zorphy2Checker.firstAnnotationOf(el);
      if (annot == null) continue;
      final reader = ConstantReader(annot);
      final subs = reader.peek('explicitSubTypes');
      if (subs == null || subs.isNull) continue;
      // Found the polymorphic base - return its typeKey (may still be null).
      return reader.peek('typeKey')?.stringValue;
    }
    return null;
  }

  /// Returns a [ConstantReader] for the first `@Zorphy` or `@Zorphy2`
  /// annotation on [el], or `null` when the class isn't annotated.
  ///
  /// Used by [_extractExplicitSubtypes] to read each subtype's
  /// `subtypeWireValue` regardless of which annotation flavor it uses.
  static ConstantReader? _readSubtypeAnnotation(ClassElement el) {
    final zorphyChecker = const TypeChecker.fromUrl(
      'package:zorphy_annotation/src/annotations.dart#Zorphy',
    );
    final zorphy2Checker = const TypeChecker.fromUrl(
      'package:zorphy_annotation/src/annotations.dart#Zorphy2',
    );
    final annot = zorphyChecker.firstAnnotationOf(el) ??
        zorphy2Checker.firstAnnotationOf(el);
    return annot == null ? null : ConstantReader(annot);
  }
}
