import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates patchWith methods and Patch class
/// Wraps the existing getPatchWithMethod, getInterfacePatchWithMethods,
/// and getPatchClass functions
class PatchGenerator extends ConcreteClassGenerator {
  PatchGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Generate patchWith method
    sb.writeln(helpers.getPatchWithMethod(metadata.allFields, className));

    // Generate interface-specific patchWith methods
    sb.writeln(
      helpers.getInterfacePatchWithMethods(
        metadata.interfaces,
        metadata.allFields,
        className,
      ),
    );

    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    // Don't generate patchWith for classes with explicitSubTypes (can't be instantiated)
    return context.config.generatePatch &&
        context.metadata.allFields.isNotEmpty &&
        !context.metadata.isAbstract;
  }
}

/// Generates the Patch class for a class
class PatchClassGenerator extends ConcreteClassGenerator {
  PatchClassGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;

    // Get known class names for nested patch handling
    final knownClasses = metadata.allAnnotatedClasses.keys
        .map((k) => k.replaceAll(r'$', ''))
        .toList();

    // Get generic type names
    final genericTypeNames = metadata.generics.map((g) => g.name).toList();

    return helpers.getPatchClass(
      metadata.allFields,
      metadata.cleanName,
      knownClasses,
      genericTypeNames,
    );
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    // Generate patch class even for explicitSubTypes (needed for changeTo methods)
    return context.config.generatePatch &&
        context.metadata.allFields.isNotEmpty;
  }
}

/// Generates the enum for field names (used by patch system)
class FieldEnumGenerator extends ConcreteClassGenerator {
  FieldEnumGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    return helpers.getEnumPropertyList(metadata.allFields, metadata.cleanName);
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    // Generate enum even for explicitSubTypes (needed for patch classes)
    return context.config.generatePatch &&
        context.metadata.allFields.isNotEmpty;
  }
}
