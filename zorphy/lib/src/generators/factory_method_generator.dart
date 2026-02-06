import '../helpers.dart' as helpers;
import 'base_generator.dart';

/// Generates factory method constructors
/// Wraps the existing generateFactoryMethod function
class FactoryMethodGenerator extends ConcreteClassGenerator {
  FactoryMethodGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;
    final sb = StringBuffer();

    if (config.factoryMethods.isNotEmpty) {
      final className = metadata.cleanName;
      for (var factory in config.factoryMethods) {
        // Only generate factory if:
        // 1. It was defined in this exact class (factory.className == metadata.originalName)
        // 2. The class doesn't extend another concrete class (to avoid recursive calls)
        //
        // When a factory is defined in $AssistantMessage and we generate AssistantMessage,
        // both names resolve to the same thing, so we need an additional check.
        // The key is: don't generate factories that would call themselves recursively.

        var factoryClass = factory.className;
        var currentClass = metadata.originalName;

        // Check if this factory would be recursive
        // A factory is recursive if: factory X.create calls X.create
        var wouldBeRecursive = factoryClass.replaceAll('\$', '') == className;

        if (factoryClass == currentClass && !wouldBeRecursive) {
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

    // Only generate if there's at least one non-recursive factory defined in this class
    return context.config.factoryMethods.any((f) {
      var factoryClass = f.className;
      var currentClass = metadata.originalName;
      var wouldBeRecursive = factoryClass.replaceAll('\$', '') == className;
      return factoryClass == currentClass && !wouldBeRecursive;
    });
  }
}
