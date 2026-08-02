import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/analysis/analysis.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/generators/generators.dart';
import 'package:zorphy/src/models/models.dart';

/// Orchestrates the code generation pipeline.
///
/// Coordinates: Analysis -> Models -> Generation -> Spec Assembly -> Emission
///
/// Generators produce [Spec] objects which are collected into a [Library]
/// and emitted via [ZorphyEmitter]. Generators that produce [Method] specs
/// have them merged into the primary [Class]; top-level specs (Extension,
/// Enum, additional Class, Code) go directly into the Library body.
class Orchestrator {
  /// All available generators.
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
  /// Runs all generators, collects their [Spec] outputs, assembles them
  /// into a [Library], and emits via [ZorphyEmitter].
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

    // Phase 3: Collect specs from all generators
    final allSpecs = <Spec>[];
    for (final generator in _generators) {
      if (generator.shouldGenerate(context)) {
        allSpecs.addAll(generator.generateSpec(context));
      }
    }

    // Phase 4: Assemble and emit via spec pipeline
    return _emitViaSpecPipeline(allSpecs);
  }

  /// Emits a list of [Spec] objects through the code_builder pipeline.
  ///
  /// Assembly strategy:
  /// - [Class] specs: the first one becomes the primary class;
  ///   [Method]/[Constructor] specs are added as its members.
  /// - [Extension]/[Enum]/[Class] (non-primary): go to library level.
  /// - [Code] specs: placed at library level (top-level declarations).
  static String _emitViaSpecPipeline(List<Spec> specs) {
    if (specs.isEmpty) return '';

    // 1. Separate specs by category.
    Class? primaryClass;
    final memberSpecs = <Method>[]; // Method -> into Class
    final topLevelSpecs = <Spec>[]; // Everything else -> library level

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

    return _emitter.emit(library);
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
}