import 'package:code_builder/code_builder.dart';

import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates factory method constructors.
///
/// Produces [Code] specs wrapping the helper output.
class FactoryMethodGenerator extends ConcreteClassGenerator {
  /// Creates a generator for factory constructors.
  FactoryMethodGenerator();

  @override
  List<Spec> generateSpec(GenerationContext context) {
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

    final code = sb.toString();
    if (code.trim().isEmpty) return [];
    return [Code(code)];
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