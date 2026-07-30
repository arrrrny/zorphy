import 'package:code_builder/code_builder.dart';

import '../models/class_metadata.dart';
import '../models/generation_config.dart';

/// Context passed to generators containing all metadata
class GenerationContext {
  final ClassMetadata metadata;
  final GenerationConfig config;

  /// Creates a generation context for a single class.
  const GenerationContext({required this.metadata, required this.config});
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

/// Interface for generators that can produce [Spec] objects.
///
/// This is the new code_builder-aware generation path. Generators
/// implement this to emit structured specs instead of raw strings.
///
/// The default adapter wraps the existing [CodeGenerator.generate]
/// string output in a [Code] spec, so all generators immediately
/// produce a spec without any migration work.
abstract class SpecGenerator {
  /// Generate a list of [Spec] objects for the given context.
  ///
  /// Implementations should return specs that can be assembled
  /// into a [Library] and emitted via [ZorphyEmitter].
  List<Spec> generateSpec(GenerationContext context);
}

/// Extension that provides a default [SpecGenerator] adapter for any
/// existing [CodeGenerator], wrapping the string output in a [Code] spec.
extension CodeGeneratorSpecAdapter on CodeGenerator {
  /// Default adapter: wraps the string output of [generate] in a [Code] spec.
  /// This ensures every generator immediately participates in the spec
  /// pipeline without requiring individual migration.
  List<Spec> generateSpec(GenerationContext context) {
    final code = generate(context);
    if (code.isEmpty) return [];
    return [Code(code)];
  }
}

/// Base class for generators that only run for concrete classes
abstract class ConcreteClassGenerator implements CodeGenerator {
  @override
  /// Returns true when the target class is concrete.
  bool shouldGenerate(GenerationContext context) =>
      !context.metadata.isAbstract;
}

/// Base class for generators that only run for abstract classes
abstract class AbstractClassGenerator implements CodeGenerator {
  @override
  /// Returns true when the target class is abstract.
  bool shouldGenerate(GenerationContext context) => context.metadata.isAbstract;
}

/// Base class for generators that run for both abstract and concrete
abstract class UniversalGenerator implements CodeGenerator {
  @override
  /// Always returns true for universal generators.
  bool shouldGenerate(GenerationContext context) => true;
}
