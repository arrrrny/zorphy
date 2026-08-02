import 'package:code_builder/code_builder.dart';

import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates patchWith methods.
///
/// Produces [Code] specs wrapping the string-based helper output.
class PatchGenerator extends ConcreteClassGenerator {
  PatchGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    if (!context.config.generatePatch || context.metadata.isAbstract) {
      return false;
    }
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.isInParentExplicitSubtypes;
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();
    final className = metadata.cleanName;
    sb.writeln(
      helpers.getPatchWithMethod(
        metadata.allFields,
        className,
        hidePublicConstructor: context.config.hidePublicConstructor,
      ),
    );
    sb.writeln(
      helpers.getInterfacePatchWithMethods(
        metadata.interfaces,
        metadata.allFields,
        className,
        hidePublicConstructor: context.config.hidePublicConstructor,
      ),
    );
    final code = sb.toString();
    if (code.trim().isEmpty) return [];
    return [Code(code)];
  }
}

/// Generates the Patch class for a class.
///
/// Produces [Code] specs wrapping the string-based helper output.
class PatchClassGenerator extends ConcreteClassGenerator {
  PatchClassGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    if (!context.config.generatePatch || context.metadata.isAbstract) {
      return false;
    }
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.isInParentExplicitSubtypes;
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final knownClasses = metadata.allAnnotatedClasses.keys
        .map((k) => k.replaceAll(r'$', ''))
        .toList();
    final genericTypeNames = metadata.generics.map((g) => g.name).toList();
    final code = helpers.getPatchClass(
      metadata.allFields,
      metadata.cleanName,
      knownClasses,
      genericTypeNames,
    );
    if (code.trim().isEmpty) return [];
    return [Code(code)];
  }
}

/// Generates the enum for field names (used by patch system).
///
/// Produces [Code] specs wrapping the string-based helper output.
class FieldEnumGenerator extends ConcreteClassGenerator {
  FieldEnumGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generatePatch &&
        !context.metadata.isAbstract &&
        context.metadata.allFields.isNotEmpty;
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final code = helpers.getEnumPropertyList(
      metadata.allFields,
      metadata.cleanName,
    );
    if (code.trim().isEmpty) return [];
    return [Code(code)];
  }
}