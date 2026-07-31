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
/// Generators that have been migrated (T008-T012) produce native
/// [Spec] objects (Class, Method, Constructor, Extension). The
/// orchestrator assembles them: members go into the Class spec,
/// top-level items (Extension, Enum, non-member Code) go into the
/// Library. Non-migrated generators still produce [Code] adapters.
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

  /// Shared emitter instance (page width 80 — Dart style guide default).
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
    _validateSpecPipeline(allSpecs);

    // Return the string pipeline result for full backward compatibility.
    return stringResult;
  }

  /// Validates that the spec pipeline can emit without errors.
  static void _validateSpecPipeline(List<Spec> specs) {
    if (specs.isEmpty) return;

    // Check if any generator has been migrated to produce
    // native (non-Code) specs.
    final hasNativeSpecs = specs.any((s) => s is! Code);

    if (!hasNativeSpecs) {
      // All specs are Code adapters — validate infrastructure.
      try {
        _emitViaSpecPipeline(specs, strict: false);
      } catch (_) {
        rethrow;
      }
      return;
    }

    // At least one native spec — emit in strict mode.
    _emitViaSpecPipeline(specs, strict: true);
  }

  /// Emits a list of [Spec] objects through the code_builder pipeline.
  ///
  /// Assembly strategy:
  /// - [Class] specs: the first one becomes the primary class;
  ///   [Method]/[Constructor] specs are added as its members.
  /// - [Extension]/[Enum]/[Class] (non-primary): go to library level.
  /// - [Code] specs: heuristically placed — if the content starts
  ///   with a top-level declaration keyword, it goes to library
  ///   level; otherwise it's added to the primary class body.
  static String _emitViaSpecPipeline(List<Spec> specs, {bool strict = true}) {
    if (specs.isEmpty) return '';

    // 1. Separate specs by category.
    Class? primaryClass;
    final memberSpecs = <Method>[]; // Method → into Class
    final topLevelSpecs = <Spec>[]; // Everything else → library level

    for (final spec in specs) {
      if (spec is Class && primaryClass == null) {
        primaryClass = spec;
      } else if (spec is Method) {
        memberSpecs.add(spec);
      } else {
        // Code, Extension, Enum, Class, Library, etc.
        topLevelSpecs.add(spec);
      }
    }

    // 2. Build the Library.
    final library = Library((b) {
      // Add primary class with member specs merged in.
      if (primaryClass != null) {
        final rebuiltClass = _mergeMembersIntoClass(
          primaryClass,
          memberSpecs,
        );
        b.body.add(rebuiltClass);
      }

      // Add top-level specs.
      for (final spec in topLevelSpecs) {
        b.body.add(spec);
      }
    });

    return _emitter.emit(library, strict: strict);
  }

  /// Merges [memberSpecs] into a [Class] spec.
  ///
  /// Methods are appended to the class methods list.
  /// Code specs remain at library level (not added here).
  static Spec _mergeMembersIntoClass(Class cls, List<Method> memberSpecs) {
    if (memberSpecs.isEmpty) return cls;

    // Rebuild the class with additional methods.
    return Class((c) {
      c.name = cls.name;
      c.abstract = cls.abstract;
      c.sealed = cls.sealed;
      c.extend = cls.extend;
      c.types.addAll(cls.types);
      c.implements.addAll(cls.implements);
      c.mixins.addAll(cls.mixins);
      c.annotations.addAll(cls.annotations);
      c.docs.addAll(cls.docs);
      c.fields.addAll(cls.fields);
      c.methods.addAll(cls.methods);
      c.constructors.addAll(cls.constructors);
      c.methods.addAll(memberSpecs);
    });
  }

  /// Assemble code blocks into final output
  static String _assembleCode(
      ClassMetadata metadata, List<String> codeBlocks) {
    if (codeBlocks.isEmpty) return '';

    final className = metadata.cleanName;
    final abstractName = metadata.abstractClassName;

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
    sb.writeln(mainClassBlock);

    for (final block in codeBlocks) {
      if (block == mainClassBlock) continue;
      final trimmed = block.trim();
      final isTopLevelClass =
          trimmed.startsWith('enum ') ||
          trimmed.startsWith('extension ') ||
          _isClassDeclaration(trimmed);
      if (isTopLevelClass) continue;
      sb.writeln(block);
    }

    sb.writeln('}');

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

  static bool _isClassDeclaration(String trimmed) {
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.contains('class');
  }

  /// Temporary bridge to old createZorphy function
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
