import 'package:analyzer/dart/element/element.dart';
import 'agent_directive_info.dart';
import 'named_constructor_info.dart';
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

  /// Custom JSON key for polymorphic type dispatch.
  /// When null, `'__typename'` is used.
  final String? typeKey;

  /// Custom wire value for this subtype in the base class's polymorphic
  /// JSON dispatch. When null, the clean class name is used.
  ///
  /// Only meaningful on **subtype** classes (those listed in a parent's
  /// `explicitSubTypes`). The value must match what the remote API sends.
  final String? subtypeWireValue;

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

  /// Whether this class is listed in a parent's explicitSubTypes
  /// If true, the parent handles polymorphic JSON, so this class shouldn't generate JSON methods
  final bool isInParentExplicitSubtypes;

  /// The original ClassElement from Dart analyzer
  final ClassElement classElement;

  /// Parsed agent annotation data (from @AgentTool, @AgentRisk, etc.).
  final AgentDirectiveInfo agentDirectiveInfo;

  /// User-declared named constructors (from @ZorphyNamedConstructor).
  /// These are generated on the concrete class with the same parameters
  /// as the default constructor, plus the declared body.
  final List<NamedConstructorInfo> namedConstructors;

  /// All annotated classes discovered so far (for polymorphic JSON)
  final Map<String, ClassElement> allAnnotatedClasses;

  /// All subtypes in this hierarchy (for polymorphic property helpers)
  final List<Interface> polymorphicSubtypes;

  /// Creates a complete metadata record for a Zorphy class.
  const ClassMetadata({
    required this.originalName,
    required this.cleanName,
    required this.isAbstract,
    required this.isSealed,
    required this.nonSealed,
    this.typeKey,
    this.subtypeWireValue,
    required this.hasConstConstructor,
    required this.docComment,
    required this.generics,
    required this.interfaces,
    required this.allValueTInterfaces,
    required this.allFields,
    required this.ownFieldNames,
    required this.factoryMethods,
    required this.explicitSubtypes,
    required this.isInParentExplicitSubtypes,
    required this.classElement,
    required this.allAnnotatedClasses,
    this.agentDirectiveInfo = const AgentDirectiveInfo(),
    this.namedConstructors = const [],
    this.polymorphicSubtypes = const [],
  });

  /// Get class name with $ prefix for generated abstract class
  /// If original starts with $$, keep it; otherwise use $
  /// Returns the generated abstract class name with $ prefix.
  String get abstractClassName =>
      originalName.startsWith(r'$$') ? originalName : r'$' + cleanName;

  /// Whether JSON serialization should be generated
  /// For sealed classes or abstract classes with explicitSubtypes, only fromJson is generated
  /// Returns true when a fromJson factory should be generated.
  bool get shouldGenerateJsonFactory =>
      explicitSubtypes.isNotEmpty || (isAbstract && !isSealed);

  /// Whether this is a concrete class that can be instantiated
  /// Returns true when the class can be instantiated.
  bool get isConcrete => !isAbstract;

  @override
  /// Returns a readable summary of this metadata.
  String toString() =>
      'ClassMetadata($originalName, abstract=$isAbstract, sealed=$isSealed)';
}

/// Metadata about a generic type parameter
class GenericParameterMetadata {
  final String name;
  final String? bound;

  /// Creates a generic type parameter descriptor.
  const GenericParameterMetadata({required this.name, this.bound});

  @override
  /// Returns a readable representation of the generic parameter.
  String toString() => bound != null ? '$name extends $bound' : name;

  // Alias for compatibility with code expecting 'type'
  /// Returns the bound as a type alias for compatibility.
  String? get type => bound;
}
