import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates compareTo extension method
/// Wraps the existing getCompareToExtension function
class CompareToExtensionGenerator extends ConcreteClassGenerator {
  /// Creates a generator for compareTo extensions.
  CompareToExtensionGenerator();

  @override
  /// Generates a compareTo extension for the class.
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final className = metadata.cleanName;

    return helpers.getCompareToExtension(
      className,
      metadata.allFields,
      metadata.allValueTInterfaces,
    );
  }

  @override
  /// Returns true when compareTo generation is enabled.
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateCompareTo;
  }
}

/// Generates changeTo extension methods for explicit subtypes
/// Wraps the existing getChangeToExtension function
class ChangeToExtensionGenerator extends UniversalGenerator {
  /// Creates a generator for changeTo extensions.
  ChangeToExtensionGenerator();

  @override
  /// Generates changeTo extensions for explicit subtypes.
  String generate(GenerationContext context) {
    final metadata = context.metadata;

    if (metadata.explicitSubtypes.isEmpty) {
      return '';
    }

    final knownClasses = metadata.allAnnotatedClasses.keys
        .map((k) => k.replaceAll(r'$', ''))
        .toList();

    return helpers.getChangeToExtension(
      sourceFields: metadata.allFields,
      sourceClassName: metadata.cleanName,
      explicitSubTypes: metadata.explicitSubtypes,
      knownClasses: knownClasses,
    );
  }

  @override
  /// Returns true when explicit subtypes are defined.
  bool shouldGenerate(GenerationContext context) {
    return context.metadata.explicitSubtypes.isNotEmpty;
  }
}
