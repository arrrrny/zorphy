import 'package:analyzer/dart/element/element.dart';
import '../common/classes.dart';
import '../factory_method.dart';
import 'field_metadata.dart';
import 'interface_metadata.dart';

/// Complete metadata about a Zorphy-annotated class
/// This replaces the ad-hoc parameters passed to createZorphy
class ClassMetadata {
  /// Original class name with $ prefix (e.g., "$User", "$$Shape")
  final String originalName;

  /// Clean class name without $ prefix (e.g., "User", "Shape")
  final String cleanName;

  /// Whether this is an abstract class (starts with $$)
  final bool isAbstract;

  /// Whether this is a sealed class (starts with $$ and !nonSealed)
  final bool isSealed;

  /// Whether nonSealed: true was set in annotation
  final bool nonSealed;

  /// Whether the class has a const constructor
  final bool hasConstConstructor;

  /// Documentation comment from the source
  final String docComment;

  /// Generic type parameters for the class
  final List<GenericParameterMetadata> generics;

  /// All interfaces this class implements (including inherited)
  final List<InterfaceMetadata> interfaces;

  /// All interfaces as simplified Interface objects (for JSON serialization)
  final List<Interface> allValueTInterfaces;

  /// All fields (inherited + own), distinct
  final List<FieldMetadata> allFields;

  /// Fields defined directly on this class (not inherited)
  final Set<String> ownFieldNames;

  /// Factory methods defined in the class
  final List<FactoryMethodInfo> factoryMethods;

  /// Explicit subtypes declared in @Zorphy(explicitSubTypes: [...])
  final List<Interface> explicitSubtypes;

  /// The original ClassElement from Dart analyzer
  final ClassElement classElement;

  /// All annotated classes discovered so far (for polymorphic JSON)
  final Map<String, ClassElement> allAnnotatedClasses;

  const ClassMetadata({
    required this.originalName,
    required this.cleanName,
    required this.isAbstract,
    required this.isSealed,
    required this.nonSealed,
    required this.hasConstConstructor,
    required this.docComment,
    required this.generics,
    required this.interfaces,
    required this.allValueTInterfaces,
    required this.allFields,
    required this.ownFieldNames,
    required this.factoryMethods,
    required this.explicitSubtypes,
    required this.classElement,
    required this.allAnnotatedClasses,
  });

  /// Get class name with $ prefix for generated abstract class
  /// If original starts with $$, keep it; otherwise use $
  String get abstractClassName =>
      originalName.startsWith(r'$$') ? originalName : r'$' + cleanName;

  /// Whether JSON serialization should be generated
  /// For sealed classes or abstract classes with explicitSubtypes, only fromJson is generated
  bool get shouldGenerateJsonFactory =>
      explicitSubtypes.isNotEmpty || (isAbstract && !isSealed);

  /// Whether this is a concrete class that can be instantiated
  bool get isConcrete => !isAbstract;

  @override
  String toString() =>
      'ClassMetadata($originalName, abstract=$isAbstract, sealed=$isSealed)';
}

/// Metadata about a generic type parameter
class GenericParameterMetadata {
  final String name;
  final String? bound;

  const GenericParameterMetadata({
    required this.name,
    this.bound,
  });

  @override
  String toString() => bound != null ? '$name extends $bound' : name;

  // Alias for compatibility with code expecting 'type'
  String? get type => bound;
}
