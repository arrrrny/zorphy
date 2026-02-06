import '../factory_method.dart';

/// Configuration for code generation
/// This replaces the many parameters passed to createZorphy
class GenerationConfig {
  /// Output file extension (.zorphy.dart or .zorphy2.dart)
  final String outputExtension;

  /// Whether to generate JSON serialization methods
  final bool generateJson;

  /// Whether to generate toJson with explicit parameter
  final bool explicitToJson;

  /// Whether to generate copyWith methods
  final bool generateCopyWith;

  /// Whether to generate function-based copyWith methods
  final bool generateCopyWithFn;

  /// Whether to generate compareTo methods
  final bool generateCompareTo;

  /// Whether to generate patch methods and patch classes
  final bool generatePatch;

  /// Whether to hide the public constructor
  final bool hidePublicConstructor;

  /// Factory methods for the class
  final List<FactoryMethodInfo> factoryMethods;

  /// Field names defined directly on this class (not inherited)
  final Set<String> ownFields;

  const GenerationConfig({
    required this.outputExtension,
    required this.generateJson,
    required this.explicitToJson,
    required this.generateCopyWith,
    required this.generateCopyWithFn,
    required this.generateCompareTo,
    required this.generatePatch,
    required this.hidePublicConstructor,
    required this.factoryMethods,
    required this.ownFields,
  });

  /// Create config for standard zorphy builder
  factory GenerationConfig.zorphy({
    required bool generateJson,
    required bool explicitToJson,
    required bool generateCopyWithFn,
    required bool generateCompareTo,
    required bool generatePatch,
    required bool hidePublicConstructor,
    required List<FactoryMethodInfo> factoryMethods,
    required Set<String> ownFields,
  }) {
    return GenerationConfig(
      outputExtension: '.zorphy.dart',
      generateJson: generateJson,
      explicitToJson: explicitToJson,
      generateCopyWith: true, // Always generate copyWith
      generateCopyWithFn: generateCopyWithFn,
      generateCompareTo: generateCompareTo,
      generatePatch: generatePatch,
      hidePublicConstructor: hidePublicConstructor,
      factoryMethods: factoryMethods,
      ownFields: ownFields,
    );
  }

  /// Create config for zorphy2 builder (first pass for circular dependencies)
  factory GenerationConfig.zorphy2() {
    return const GenerationConfig(
      outputExtension: '.zorphy2.dart',
      generateJson: true,
      explicitToJson: true,
      generateCopyWith: true,
      generateCopyWithFn: false,
      generateCompareTo: true,
      generatePatch: true,
      hidePublicConstructor: false,
      factoryMethods: [],
      ownFields: {},
    );
  }

  /// Create config for testing with custom values
  const GenerationConfig.test({
    this.outputExtension = '.zorphy.dart',
    this.generateJson = true,
    this.explicitToJson = true,
    this.generateCopyWith = true,
    this.generateCopyWithFn = false,
    this.generateCompareTo = true,
    this.generatePatch = true,
    this.hidePublicConstructor = false,
    this.factoryMethods = const [],
    this.ownFields = const {},
  });
}
