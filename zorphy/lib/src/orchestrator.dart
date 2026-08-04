import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/analysis/analysis.dart';
import 'package:zorphy/src/ast/ast.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/generators/generators.dart';
import 'package:zorphy/src/models/models.dart';
import 'package:zorphy/src/plugins/plugin_context.dart';
import 'package:zorphy/src/plugins/plugin_registry.dart';

/// Orchestrates the code generation pipeline.
///
/// Coordinates: Analysis -> Models -> Generation -> Spec Assembly ->
/// Plugin Transform -> Emission
///
/// Generators produce [Spec] objects which are collected into a [Library]
/// and emitted via [ZorphyEmitter]. If a [PluginRegistry] is provided,
/// plugins run after spec collection and before emission, mutating
/// specs and accumulating imports into the [Library].
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
  /// Runs all generators, collects their [Spec] outputs, runs the
  /// plugin transform pass (if [pluginRegistry] is non-null and
  /// non-empty), assembles specs into a [Library], and emits
  /// via [ZorphyEmitter].
  static String generate(
    ClassElement classElement,
    ConstantReader annotation,
    Map<String, ClassElement> allAnnotatedClasses,
    GenerationConfig config,
    Set<String> classesInExplicitSubtypes, {
    PluginRegistry? pluginRegistry,
  }) {
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

    // Phase 4: Plugin transform pass (if registry provided and non-empty)
    PluginContext? pluginContext;
    if (pluginRegistry != null && !pluginRegistry.isEmpty) {
      pluginContext = _runPluginPass(
        allSpecs,
        pluginRegistry,
        metadata,
        config,
      );
    }

    // Phase 5: Assemble and emit via spec pipeline
    return _emitViaSpecPipeline(allSpecs, pluginImports: pluginContext?.imports);
  }

  /// Runs the plugin transform pass over collected specs.
  ///
  /// Plugins mutate the [Class], [Method], and [Field] specs
  /// in-place. Imports and diagnostics accumulate into the
  /// [PluginContext].
  ///
  /// Plugins are filtered by [ZorphyPlugin.decoratorNames]: only plugins
  /// whose decoratorNames are empty (unscoped) or intersect with the
  /// class's decorators will run. Once the annotation supports a
  /// `decorators` field, this filtering becomes active.
  static PluginContext _runPluginPass(
    List<Spec> specs,
    PluginRegistry registry,
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final pluginContext = PluginContext(
      metadata: metadata,
      config: config,
    );
    final orderedPlugins = registry.ordered();

    // Class decorators (empty set until annotation supports decorators field)
    final classDecorators = <String>{};

    for (final plugin in orderedPlugins) {
      // Check if plugin should run for this class based on decoratorNames
      final pluginDecorators = plugin.decoratorNames;
      final shouldRun = pluginDecorators.isEmpty ||
          classDecorators.any((d) => pluginDecorators.contains(d));

      if (!shouldRun) continue;

      for (int i = 0; i < specs.length; i++) {
        final spec = specs[i];
        if (spec is Class) {
          // Transform class-level, then its fields and methods.
          var transformed = plugin.transformClass(spec, pluginContext);
          if (transformed is Class) {
            final originalClass = transformed;
            // Transform fields within the class.
            final transformedFields = <Field>[];
            for (final field in originalClass.fields) {
              final fieldResult = plugin.transformField(
                field,
                pluginContext,
              );
              transformedFields.add(fieldResult is Field ? fieldResult : field);
            }
            // Transform methods within the class.
            final transformedMethods = <Method>[];
            for (final method in originalClass.methods) {
              final methodResult = plugin.transformMethod(
                method,
                pluginContext,
              );
              transformedMethods
                  .add(methodResult is Method ? methodResult : method);
            }
            // Rebuild the class with transformed members.
            transformed = Class((c) {
              c.name = originalClass.name;
              c.abstract = originalClass.abstract;
              c.sealed = originalClass.sealed;
              c.extend = originalClass.extend;
              c.types.addAll(originalClass.types);
              c.implements.addAll(originalClass.implements);
              c.mixins.addAll(originalClass.mixins);
              c.annotations.addAll(originalClass.annotations);
              c.docs.addAll(originalClass.docs);
              c.fields.addAll(transformedFields);
              c.methods.addAll(transformedMethods);
              c.constructors.addAll(originalClass.constructors);
            });
            specs[i] = transformed;
          } else {
            specs[i] = transformed;
          }
        } else if (spec is Method) {
          specs[i] = plugin.transformMethod(spec, pluginContext);
        } else if (spec is Field) {
          specs[i] = plugin.transformField(spec, pluginContext);
        }
      }
    }

    return pluginContext;
  }

  /// Emits a list of [Spec] objects through the code_builder pipeline.
  ///
  /// Assembly strategy:
  /// - [Class] specs: the first one becomes the primary class;
  ///   [Method] specs are added as its members.
  /// - [ClassMemberCode] specs: injected into the primary class body
  ///   (for constructs like factory constructors that cannot be
  ///   represented as native [Spec] objects but must live inside
  ///   the class to compile).
  /// - [Extension]/[Enum]/[Class] (non-primary): go to library level.
  /// - [Code] specs (plain): placed at library level.
  ///
  /// [pluginImports] are accumulated import directives from the
  /// plugin pass, folded into the [Library] directives.
  static String _emitViaSpecPipeline(
    List<Spec> specs, {
    List<Directive>? pluginImports,
  }) {
    if (specs.isEmpty) return '';

    // 1. Separate specs by category.
    Class? primaryClass;
    final memberSpecs = <Method>[]; // Method -> into Class
    final classMemberCodes = <ClassMemberCode>[]; // ClassMemberCode -> into Class
    final topLevelSpecs = <Spec>[]; // Everything else -> library level

    for (final spec in specs) {
      if (spec is Class && primaryClass == null) {
        primaryClass = spec;
      } else if (spec is Method) {
        memberSpecs.add(spec);
      } else if (spec is ClassMemberCode) {
        classMemberCodes.add(spec);
      } else {
        // Code, Extension, Enum, Class, Library, etc.
        topLevelSpecs.add(spec);
      }
    }

    // 2. Build the Library.
    final library = Library((b) {
      // Add plugin-accumulated imports.
      if (pluginImports != null) {
        for (final directive in pluginImports) {
          b.directives.add(directive);
        }
      }

      // Add primary class with member specs merged in.
      if (primaryClass != null) {
        final rebuiltClass = _mergeMembersIntoClass(
          primaryClass,
          memberSpecs,
          classMemberCodes: classMemberCodes,
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

  /// Merges member specs into a [Class] spec.
  ///
  /// Methods are appended to the class methods list.
  /// [ClassMemberCode] entries are unwrapped: constructors go to
  /// the constructors list, methods go to the methods list.
  static Spec _mergeMembersIntoClass(
    Class cls,
    List<Method> memberSpecs, {
    List<ClassMemberCode> classMemberCodes = const [],
  }) {
    if (memberSpecs.isEmpty && classMemberCodes.isEmpty) return cls;

    // Rebuild the class with additional members.
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
      // Unwrap ClassMemberCode entries into the class.
      for (final memberCode in classMemberCodes) {
        if (memberCode.constructor != null) {
          c.constructors.add(memberCode.constructor!);
        }
        if (memberCode.method != null) {
          c.methods.add(memberCode.method!);
        }
      }
    });
  }
}