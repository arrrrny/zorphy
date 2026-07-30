import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates patchWith methods and Patch class
/// Wraps the existing getPatchWithMethod, getInterfacePatchWithMethods,
/// and getPatchClass functions
class PatchGenerator extends ConcreteClassGenerator {
  /// Creates a generator for patchWith methods.
  PatchGenerator();

  @override
  /// Generates patchWith methods for the class.
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Generate patchWith method
    sb.writeln(
      helpers.getPatchWithMethod(
        metadata.allFields,
        className,
        hidePublicConstructor: context.config.hidePublicConstructor,
      ),
    );

    // Generate interface-specific patchWith methods
    sb.writeln(
      helpers.getInterfacePatchWithMethods(
        metadata.interfaces,
        metadata.allFields,
        className,
        hidePublicConstructor: context.config.hidePublicConstructor,
      ),
    );

    return sb.toString();
  }

  @override
  /// Returns true when patch generation is enabled for the context.
  bool shouldGenerate(GenerationContext context) {
    // Don't generate patchWith for classes with explicitSubTypes
    // (can't be instantiated). Fieldless explicit subtypes still need
    // patchWith — their patch class's applyTo calls it.
    if (!context.config.generatePatch || context.metadata.isAbstract) {
      return false;
    }
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.isInParentExplicitSubtypes;
  }
}

/// Generates the Patch class for a class
class PatchClassGenerator extends ConcreteClassGenerator {
  /// Creates a generator for Patch classes.
  PatchClassGenerator();

  @override
  /// Generates the Patch class implementation.
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
  /// Returns true when Patch classes should be generated.
  bool shouldGenerate(GenerationContext context) {
    // Generate patch class even for explicitSubTypes (needed for changeTo
    // methods). Fieldless explicit subtypes still need a patch class —
    // changeTo extensions on sibling subtypes reference it.
    if (!context.config.generatePatch || context.metadata.isAbstract) {
      return false;
    }
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.isInParentExplicitSubtypes;
  }
}

/// Generates the enum for field names (used by patch system)
class FieldEnumGenerator extends ConcreteClassGenerator {
  /// Creates a generator for field-name enums.
  FieldEnumGenerator();

  @override
  /// Generates the enum of field names for patching.
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    return helpers.getEnumPropertyList(metadata.allFields, metadata.cleanName);
  }

  @override
  /// Returns true when field enums should be generated.
  bool shouldGenerate(GenerationContext context) {
    // Generate enum even for explicitSubTypes (needed for patch classes)
    return context.config.generatePatch &&
        context.metadata.allFields.isNotEmpty;
  }
}
