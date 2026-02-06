import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates factory method constructors
/// Wraps the existing generateFactoryMethod function
class FactoryMethodGenerator extends ConcreteClassGenerator {
  FactoryMethodGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();

    if (metadata.factoryMethods.isNotEmpty) {
      final className = metadata.cleanName;
      for (var factory in metadata.factoryMethods) {
        var factoryClass = factory.className;

        // A factory is truly recursive if it's in the same class it tried to create
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

    // Run if it's a concrete class (handled by base class) AND has factory methods
    if (metadata.isAbstract) return false;

    return metadata.factoryMethods.any((f) {
      var factoryClass = f.className;
      var isTrulyRecursive = factoryClass == className;
      return !isTrulyRecursive;
    });
  }
}
