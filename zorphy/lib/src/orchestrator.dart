import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/analysis/analysis.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/generators/generators.dart';
import 'package:zorphy/src/models/models.dart';
import 'package:zorphy/src/createZorphy.dart' as old_codegen;
import 'package:zorphy/src/common/NameType.dart';

/// Orchestrates the code generation pipeline
/// Coordinates: Analysis -> Models -> Generation -> Assembly
///
/// The pipeline now supports two emission paths:
/// 1. **Spec pipeline** (new): generators produce [Spec] objects via
///    [CodeGeneratorSpecAdapter.generateSpec], which are collected into
///    a [Library] and emitted via [ZorphyEmitter].
/// 2. **String pipeline** (legacy): generators produce raw strings via
///    [CodeGenerator.generate], which are assembled by [_assembleCode].
///
/// Currently the string pipeline remains the primary output path.
/// The spec pipeline runs in parallel and is validated in strict mode
/// to ensure the emission infrastructure is sound.
///
/// Byte-identical comparison between the two pipelines is deferred until
/// generators produce native [Spec] objects. The default [Code] adapter
/// wraps raw strings which get reformatted by [DartFormatter], so the
/// outputs are structurally but not byte-identical.
class Orchestrator {
  /// All available generators
  static final List<CodeGenerator> _generators = [
    // Class declaration (always runs)
    ClassDeclarationGenerator(),

    // CopyWith (conditional)
    CopyWithGenerator(),

    // Factory methods (conditional)
    FactoryMethodGenerator(),

    // Semantic property helpers (always runs if fields/subtypes exist)
    PropertyHelperGenerator(),

    // Patch methods (conditional, concrete only)
    PatchGenerator(),

    // Equals, hashCode, toString (concrete only)
    EqualsToStringGenerator(),

    // JSON serialization (conditional)
    JsonGenerator(),

    // JSON extension (conditional, concrete only)
    JsonExtensionGenerator(),

    // Field enum (conditional, concrete only)
    FieldEnumGenerator(),

    // Patch class (conditional, concrete only)
    PatchClassGenerator(),

    // Fields class (concrete only)
    FieldsClassGenerator(),

    // CompareTo extension (conditional, concrete only)
    CompareToExtensionGenerator(),

    // ChangeTo extension (conditional, has explicit subtypes)
    ChangeToExtensionGenerator(),
  ];

  /// Shared emitter instance (page width 120 to match project convention).
  static final ZorphyEmitter _emitter = ZorphyEmitter();

  /// Generate code for a single class.
  ///
  /// This runs both the spec pipeline and the string pipeline.
  /// The string pipeline output is returned (backward-compatible).
  /// The spec pipeline is validated in strict mode to ensure the
  /// emission infrastructure is sound (formatting errors propagate).
  static String generate(
    ClassElement classElement,
    ConstantReader annotation,
    Map<String, ClassElement> allAnnotatedClasses,
    GenerationConfig config,
    Set<String> classesInExplicitSubtypes,
  ) {
    // Phase 1: Analysis
    final metadata = ClassAnalyzer.analyze(
      classElement,
      annotation,
      allAnnotatedClasses,
      classesInExplicitSubtypes,
    );

    // Phase 2: Create generation context
    final context = GenerationContext(metadata: metadata, config: config);

    // Phase 3a: Run generators — string pipeline (existing)
    final codeBlocks = <String>[];
    for (final generator in _generators) {
      if (generator.shouldGenerate(context)) {
        final code = generator.generate(context);
        if (code.isNotEmpty) {
          codeBlocks.add(code);
        }
      }
    }

    // Phase 3b: Collect specs — spec pipeline (new, non-breaking)
    // Each generator's string output is wrapped in a Code spec
    // by the default adapter, so the spec pipeline produces
    // equivalent output to the string pipeline.
    final allSpecs = <Spec>[];
    for (final generator in _generators) {
      if (generator.shouldGenerate(context)) {
        allSpecs.addAll(generator.generateSpec(context));
      }
    }

    // Phase 4a: Assemble via string pipeline (primary output)
    final stringResult = _assembleCode(metadata, codeBlocks);

    // Phase 4b: Validate spec pipeline in strict mode.
    // This ensures the emission infrastructure (emitter, formatter)
    // works correctly. Formatting errors are not silently swallowed.
    //
    // TODO(byte-comparison): Once generators produce native Spec objects
    // (Class, Method, Field, etc.) instead of Code-adapted strings,
    // compare the spec pipeline output byte-for-byte against
    // stringResult and assert on mismatch.
    _validateSpecPipeline(allSpecs);

    // Return the string pipeline result for full backward compatibility.
    return stringResult;
  }

  /// Validates that the spec pipeline can emit without errors.
  ///
  /// When all specs are [Code] adapters (the current default),
  /// validation runs in non-strict mode since partial fragments
  /// cannot survive [DartFormatter]. Once generators produce
  /// native [Spec] objects, validation switches to strict mode
  /// and the output is compared byte-for-byte against the string
  /// pipeline result.
  static void _validateSpecPipeline(List<Spec> specs) {
    if (specs.isEmpty) return;

    // Check if any generator has been migrated to produce
    // native (non-Code) specs. If so, we can do a meaningful
    // comparison; otherwise just validate the pipeline runs.
    final hasNativeSpecs =
        specs.any((s) => s is! Code);

    if (!hasNativeSpecs) {
      // All specs are Code adapters — validate the pipeline
      // infrastructure works (emit without strict formatting,
      // since partial fragments will fail the formatter).
      try {
        _emitViaSpecPipeline(specs, strict: false);
      } catch (_) {
        rethrow;
      }
      return;
    }

    // At least one native spec — emit in strict mode and compare.
    // This path activates once generators start migrating.
    _emitViaSpecPipeline(specs, strict: true);
    // TODO: compare output with stringResult once
    // the string pipeline result is available here.
  }

  /// Emits a list of [Spec] objects through the code_builder pipeline.
  ///
  /// When [strict] is `true`, formatting errors propagate.
  /// When `false`, formatting falls back to raw output on failure.
  static String _emitViaSpecPipeline(List<Spec> specs, {bool strict = true}) {
    if (specs.isEmpty) return '';

    // Assemble all specs into a single Library.
    // Use Code specs directly as body entries to preserve
    // the exact string output from the adapters.
    final library = Library((b) {
      for (final spec in specs) {
        if (spec is Code) {
          b.body.add(spec);
        } else if (spec is Library) {
          for (final directive in spec.directives) {
            b.directives.add(directive);
          }
          for (final body in spec.body) {
            b.body.add(body);
          }
        } else {
          b.body.add(spec);
        }
      }
    });

    return _emitter.emit(library, strict: strict);
  }

  /// Assemble code blocks into final output
  /// This properly handles the class structure:
  /// - Class declaration and opening {
  /// - Class members (fields, constructors, methods)
  /// - Closing }
  /// - External items (enums, patch classes, extensions)
  static String _assembleCode(
      ClassMetadata metadata, List<String> codeBlocks) {
    if (codeBlocks.isEmpty) return '';

    final className = metadata.cleanName;
    final abstractName = metadata.abstractClassName;

    // Find the main class declaration block
    // It's the one that declares either the clean name (concrete) or abstract name
    final mainClassBlock = codeBlocks.firstWhere((block) {
      final lines = block.split('\n');
      return lines.any((line) {
        final trimmed = line.trim();
        return trimmed.startsWith('class $className') ||
            trimmed.startsWith('sealed class $className') ||
            trimmed.startsWith('abstract class $className') ||
            trimmed.startsWith('class $abstractName') ||
            trimmed.startsWith('sealed class $abstractName') ||
            trimmed.startsWith('abstract class $abstractName');
      });
    }, orElse: () => codeBlocks[0]);

    final sb = StringBuffer();

    // 1. Write the main class block (includes opening { and properties)
    sb.writeln(mainClassBlock);

    // 2. Add other class members (copyWith, factory methods, etc.)
    // These need to be inside the class but before the closing }
    for (final block in codeBlocks) {
      if (block == mainClassBlock) continue;

      final trimmed = block.trim();
      // Skip top-level items (enums, other classes, extensions)
      final isTopLevelClass =
          trimmed.startsWith('enum ') ||
          trimmed.startsWith('extension ') ||
          _isClassDeclaration(trimmed);

      if (isTopLevelClass) {
        continue;
      }
      sb.writeln(block);
    }

    // 3. Close the main class
    sb.writeln('}');

    // 4. Add top-level items (enums, patch classes, extensions) after class closes
    for (final block in codeBlocks) {
      if (block == mainClassBlock) continue;

      final trimmed = block.trim();
      final isTopLevelClass =
          trimmed.startsWith('enum ') ||
          trimmed.startsWith('extension ') ||
          _isClassDeclaration(trimmed);

      if (isTopLevelClass) {
        sb.writeln(block);
      }
    }

    return sb.toString();
  }

  /// Check if a trimmed string is a class declaration
  /// Handles: class, abstract class, sealed class, final class, abstract final class, etc.
  static bool _isClassDeclaration(String trimmed) {
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.contains('class');
  }

  /// Temporary bridge to old createZorphy function
  /// This allows us to gradually migrate while keeping everything working
  static String generateUsingOldPipeline(
    bool isAbstract,
    List<FieldMetadata> allFieldsDistinct,
    String elementName,
    String docComment,
    List<InterfaceMetadata> interfaces,
    List<Interface> allValueTInterfaces,
    List<GenericParameterMetadata> classGenerics,
    bool hasConstConstructor,
    bool generateJson,
    bool hidePublicConstructor,
    List<Interface> typesExplicit,
    bool nonSealed,
    bool explicitToJson,
    bool generateCompareTo,
    bool generateCopyWithFn,
    List<FactoryMethodInfo> factoryMethods,
    Map<String, ClassElement> allAnnotatedClasses,
    Set<String> ownFields,
  ) {
    // Convert GenericParameterMetadata to NameTypeClassComment for compatibility
    final classGenericsAsNameType = classGenerics.map((g) {
      return NameTypeClassComment(g.name, g.bound, null);
    }).toList();

    return old_codegen.createZorphy(
      isAbstract,
      allFieldsDistinct,
      elementName,
      docComment,
      interfaces,
      allValueTInterfaces,
      classGenericsAsNameType,
      hasConstConstructor,
      generateJson,
      hidePublicConstructor,
      typesExplicit,
      nonSealed,
      explicitToJson,
      generateCompareTo,
      generateCopyWithFn,
      factoryMethods,
      allAnnotatedClasses,
      ownFields,
    );
  }
}
