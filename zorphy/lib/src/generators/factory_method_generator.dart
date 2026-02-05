import '../helpers.dart' as helpers;
import '../models/class_metadata.dart';
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
        sb.writeln(
          helpers.generateFactoryMethod(factory, className, metadata.allFields),
        );
      }
    }

    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.factoryMethods.isNotEmpty;
  }
}
