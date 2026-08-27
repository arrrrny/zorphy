import 'package:code_builder/code_builder.dart';

import '../models/class_metadata.dart';
import '../models/generation_config.dart';

/// Context passed to generators containing all metadata.
class GenerationContext {
  final ClassMetadata metadata;
  final GenerationConfig config;

  /// Creates a generation context for a single class.
  const GenerationContext({required this.metadata, required this.config});
}

/// Base interface for code generators.
///
/// Each generator produces [Spec] objects via [generateSpec], which are
/// assembled into a [Library] and emitted by the orchestrator.
abstract class CodeGenerator {
  /// Generate a list of [Spec] objects for the given context.
  ///
  /// Implementations should return specs that can be assembled into a
  /// [Library] and emitted via [ZorphyEmitter].
  List<Spec> generateSpec(GenerationContext context);

  /// Whether this generator should run for the given context.
  bool shouldGenerate(GenerationContext context);
}

/// Base class for generators that only run for concrete classes.
abstract class ConcreteClassGenerator implements CodeGenerator {
  @override
  /// Returns true when the target class is concrete.
  bool shouldGenerate(GenerationContext context) =>
      !context.metadata.isAbstract;
}

/// Base class for generators that only run for abstract classes.
abstract class AbstractClassGenerator implements CodeGenerator {
  @override
  /// Returns true when the target class is abstract.
  bool shouldGenerate(GenerationContext context) => context.metadata.isAbstract;
}

/// Base class for generators that run for both abstract and concrete.
abstract class UniversalGenerator implements CodeGenerator {
  @override
  /// Always returns true for universal generators.
  bool shouldGenerate(GenerationContext context) => true;
}
