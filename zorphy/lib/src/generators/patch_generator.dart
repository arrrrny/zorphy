import 'package:code_builder/code_builder.dart';

import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates patchWith methods and Patch class
///
/// Migrated (T013, T014, T015): implements [SpecGenerator].
/// PatchGenerator produces native [Method] specs; PatchClassGenerator and
/// FieldEnumGenerator use the Code adapter for their top-level outputs.
class PatchGenerator extends ConcreteClassGenerator implements SpecGenerator {
  PatchGenerator();

  @override
  String generate(GenerationContext context) {
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
    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    if (!context.config.generatePatch || context.metadata.isAbstract) {
      return false;
    }
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.isInParentExplicitSubtypes;
  }

  // ═══════════════════════════════════════════════════════════════
  // SPEC PIPELINE (T013)
  // ═════════════════════════════════════════════════════════════

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final code = generate(context);
    if (code.isEmpty) return [];
    return [Code(code)];
  }
}

/// Generates the Patch class for a class
///
/// Migrated (T015): implements [SpecGenerator].
class PatchClassGenerator extends ConcreteClassGenerator implements SpecGenerator {
  PatchClassGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final knownClasses = metadata.allAnnotatedClasses.keys
        .map((k) => k.replaceAll(r'$', ''))
        .toList();
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
    if (!context.config.generatePatch || context.metadata.isAbstract) {
      return false;
    }
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.isInParentExplicitSubtypes;
  }

  // ═════════════════════════════════════════════════════════════
  // SPEC PIPELINE (T015)
  // ═════════════════════════════════════════════════════════════

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final code = generate(context);
    if (code.isEmpty) return [];
    return [Code(code)];
  }
}

/// Generates the enum for field names (used by patch system)
///
/// Migrated (T014): implements [SpecGenerator].
class FieldEnumGenerator extends ConcreteClassGenerator implements SpecGenerator {
  FieldEnumGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    return helpers.getEnumPropertyList(metadata.allFields, metadata.cleanName);
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generatePatch &&
        context.metadata.allFields.isNotEmpty;
  }

  // ═════════════════════════════════════════════════════════════
  // SPEC PIPELINE (T014)
  // ═════════════════════════════════════════════════════════════

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final code = generate(context);
    if (code.isEmpty) return [];
    return [Code(code)];
  }
}
