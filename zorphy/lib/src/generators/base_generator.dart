import '../models/class_metadata.dart';
import '../models/generation_config.dart';

/// Context passed to generators containing all metadata
class GenerationContext {
  final ClassMetadata metadata;
  final GenerationConfig config;

  const GenerationContext({
    required this.metadata,
    required this.config,
  });
}

/// Base interface for code generators
/// Each generator is responsible for generating a specific piece of code
abstract class CodeGenerator {
  /// Generate code for the given context
  /// Returns the generated code as a string
  String generate(GenerationContext context);

  /// Whether this generator should run for the given context
  bool shouldGenerate(GenerationContext context);
}

/// Base class for generators that only run for concrete classes
abstract class ConcreteClassGenerator implements CodeGenerator {
  @override
  bool shouldGenerate(GenerationContext context) =>
      !context.metadata.isAbstract;
}

/// Base class for generators that only run for abstract classes
abstract class AbstractClassGenerator implements CodeGenerator {
  @override
  bool shouldGenerate(GenerationContext context) =>
      context.metadata.isAbstract;
}

/// Base class for generators that run for both abstract and concrete
abstract class UniversalGenerator implements CodeGenerator {
  @override
  bool shouldGenerate(GenerationContext context) => true;
}
