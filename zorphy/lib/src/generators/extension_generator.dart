import '../helpers.dart' as helpers;
import '../models/class_metadata.dart';
import 'base_generator.dart';

/// Generates compareTo extension method
/// Wraps the existing getCompareToExtension function
class CompareToExtensionGenerator extends ConcreteClassGenerator {
  CompareToExtensionGenerator();

  @override
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
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateCompareTo;
  }
}

/// Generates changeTo extension methods for explicit subtypes
/// Wraps the existing getChangeToExtension function
class ChangeToExtensionGenerator extends UniversalGenerator {
  ChangeToExtensionGenerator();

  @override
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
  bool shouldGenerate(GenerationContext context) {
    return context.metadata.explicitSubtypes.isNotEmpty;
  }
}
