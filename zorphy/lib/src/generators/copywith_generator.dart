import '../helpers.dart' as helpers;
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

    final sb = StringBuffer();
    sb.writeln(
      helpers.getCopyWith(
        metadata.allFields,
        copyWithClassName,
        config.generateCopyWithFn,
      ),
    );

    // Generate interface-specific copyWith methods
    sb.writeln(
      helpers.getInterfaceCopyWithMethods(
        metadata.allValueTInterfaces,
        metadata.allFields,
        metadata.cleanName,
      ),
    );

    // Generate interface-specific copyWithFn methods if enabled
    if (config.generateCopyWithFn) {
      sb.writeln(
        helpers.getInterfaceCopyWithFnMethods(
          metadata.allValueTInterfaces,
          metadata.allFields,
          metadata.cleanName,
          metadata.allFields,
        ),
      );
    }

    return sb.toString();
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
