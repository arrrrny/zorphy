import '../common/helpers.dart' as helpers;
import '../models/class_metadata.dart';
import 'base_generator.dart';

/// Generates copyWith methods
/// Wraps the existing getCopyWith function
class CopyWithGenerator extends UniversalGenerator {
  CopyWithGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    // Don't generate copyWith for abstract classes unless generateCopyWithFn is true
    if (metadata.isAbstract && !config.generateCopyWithFn) {
      return '';
    }

    final copyWithClassName = metadata.isAbstract
        ? (metadata.originalName.startsWith(r'$$')
            ? metadata.cleanName
            : '\$${metadata.cleanName}')
        : metadata.cleanName;

    return helpers.getCopyWith(
      metadata.allFields,
      copyWithClassName,
      config.generateCopyWithFn,
    );
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    // CopyWith is always generated for concrete classes
    // For abstract classes, only if generateCopyWithFn is true
    if (context.metadata.isAbstract) {
      return context.config.generateCopyWithFn;
    }
    return true;
  }
}
