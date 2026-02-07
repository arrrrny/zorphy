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

    // Fields class (concrete only)
    FieldsClassGenerator(),

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
  static String _assembleCode(ClassMetadata metadata, List<String> codeBlocks) {
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
      // Check for class declarations more carefully - they can have modifiers
      final isTopLevelClass = trimmed.startsWith('enum ') ||
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
      final isTopLevelClass = trimmed.startsWith('enum ') ||
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
    // Split by whitespace and look for 'class' keyword
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
