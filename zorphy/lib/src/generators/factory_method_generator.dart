import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates factory method constructors.
///
/// Migrated (T011): [generateSpec] is intentionally NOT overridden
/// because code_builder's [Constructor] does not implement [Spec],
/// so factory constructors cannot be returned as standalone specs.
/// The default [CodeGeneratorSpecAdapter.generateSpec] wraps the
/// string output in a [Code] spec, which the orchestrator places
/// inside the Class body.
///
/// The legacy [generate] path is preserved for backward compatibility.
class FactoryMethodGenerator extends ConcreteClassGenerator {
  /// Creates a generator for factory constructors.
  FactoryMethodGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();

    if (metadata.factoryMethods.isNotEmpty) {
      final className = metadata.cleanName;
      for (var factory in metadata.factoryMethods) {
        var factoryClass = factory.className;
        var isTrulyRecursive = factoryClass == className;

        if (!isTrulyRecursive) {
          sb.writeln(
            helpers.generateFactoryMethod(
              factory,
              className,
              metadata.allFields,
            ),
          );
        }
      }
    }

    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    final metadata = context.metadata;
    final className = metadata.cleanName;

    if (metadata.isAbstract) return false;

    return metadata.factoryMethods.any((f) {
      var factoryClass = f.className;
      var isTrulyRecursive = factoryClass == className;
      return !isTrulyRecursive;
    });
  }
}
