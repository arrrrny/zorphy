import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/analysis/analysis.dart';
import 'package:zorphy/src/generators/generators.dart';
import 'package:zorphy/src/models/models.dart';
import 'package:zorphy/src/createZorphy.dart' as old_codegen;
import 'package:zorphy/src/common/NameType.dart';

/// Orchestrates the code generation pipeline
/// Coordinates: Analysis → Models → Generation → Assembly
class Orchestrator {
  /// All available generators
  static final List<CodeGenerator> _generators = [
    // Class declaration (always runs)
    ClassDeclarationGenerator(),

    // CopyWith (conditional)
    CopyWithGenerator(),

    // Factory methods (conditional)
    FactoryMethodGenerator(),

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

    // CompareTo extension (conditional, concrete only)
    CompareToExtensionGenerator(),

    // ChangeTo extension (conditional, has explicit subtypes)
    ChangeToExtensionGenerator(),
  ];

  /// Generate code for a single class
  /// This is the new refactored pipeline
  static String generate(
    ClassElement classElement,
    ConstantReader annotation,
    Map<String, ClassElement> allAnnotatedClasses,
    GenerationConfig config,
  ) {
    // Phase 1: Analysis
    final metadata = ClassAnalyzer.analyze(
      classElement,
      annotation,
      allAnnotatedClasses,
    );

    // Phase 2: Create generation context
    final context = GenerationContext(
      metadata: metadata,
      config: config,
    );

    // Phase 3: Run generators
    final codeBlocks = <String>[];
    for (final generator in _generators) {
      if (generator.shouldGenerate(context)) {
        final code = generator.generate(context);
        if (code.isNotEmpty) {
          codeBlocks.add(code);
        }
      }
    }

    // Phase 4: Assemble final code
    return _assembleCode(metadata, codeBlocks);
  }

  /// Assemble code blocks into final output
  /// This properly handles the class structure:
  /// - Class declaration and opening {
  /// - Class members (fields, constructors, methods)
  /// - Closing }
  /// - External items (enums, patch classes, extensions)
  static String _assembleCode(
    ClassMetadata metadata,
    List<String> codeBlocks,
  ) {
    final sb = StringBuffer();

    // Find class declaration block (first one with "class " in it)
    final classDeclaration = codeBlocks.firstWhere(
      (block) => block.trim().startsWith('class ') ||
                 block.trim().startsWith('sealed class ') ||
                 block.trim().startsWith('abstract class '),
      orElse: () => '',
    );

    // Add class declaration (includes opening { and properties)
    if (classDeclaration.isNotEmpty) {
      sb.writeln(classDeclaration);
    }

    // Add other class members (copyWith, factory methods, etc.)
    // These need to be inside the class but before the closing }
    for (final block in codeBlocks) {
      if (block == classDeclaration) continue;
      final trimmed = block.trim();
      if (trimmed.startsWith('enum ') ||
          trimmed.startsWith('class ') ||
          trimmed.startsWith('extension ')) {
        // Skip - these are added after the class closes
        continue;
      }
      sb.writeln(block);
    }

    // Close the class
    sb.writeln('}');

    // Add external items (enums, patch classes, extensions) after class closes
    for (final block in codeBlocks) {
      if (block == classDeclaration) continue; // Skip the main class declaration
      final trimmed = block.trim();
      if (trimmed.startsWith('enum ') ||
          (trimmed.startsWith('class ') && trimmed.contains('Patch')) ||
          trimmed.startsWith('extension ')) {
        sb.writeln(block);
      }
    }

    return sb.toString();
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

