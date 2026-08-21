import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/analysis/analysis.dart';
import 'package:zorphy/src/models/models.dart';
import 'package:zorphy/src/orchestrator.dart';
import 'package:zorphy/src/plugins/plugin_registry.dart';

/// Unified single-pass generator for `@Zorphy` and `@Zorphy2` classes.
///
/// Since zorphy 2.0 this is the ONLY generator: it handles both
/// annotations, resolves polymorphic ordering internally (topological
/// order over the `implements $$Base` graph, computed per library), and
/// keeps NO process-global mutable state — the annotated-class graph is
/// rebuilt from the library's class list on every pass.
///
/// When [pluginUris] are provided (via `build.yaml` options), they are
/// stored for deferred resolution. When [pluginRegistry] is provided
/// (programmatic registration), those plugins are used directly.
///
/// Issue #117 — cross-entity import guidance:
/// When a `@Zorphy` entity references another entity as a field type
/// (e.g. `$ArtifactRef get ref;`), the generated `<name>.zorphy.dart`
/// part file inherits its imports from the parent `<name>.dart`
/// library. Part files CANNOT carry their own `import` directives
/// (Dart language constraint), so if the parent library forgets to
/// import the sibling entity file, the type does not resolve and the
/// analyzer reports `argument_type_not_assignable` / `InvalidType`.
///
/// This generator delegates to [CrossEntityImportDetector] to scan
/// each `@Zorphy` library for cross-entity field references and check
/// whether the parent library imports the sibling. If any are missing,
/// it emits a guidance comment at the top of the `.zorphy.dart` part
/// file listing the required imports. The comment is purely
/// informational — the user must add the imports to the parent
/// `<name>.dart` file (parts cannot have their own imports).
class ZorphyGenerator extends Generator {
  /// Creates the unified generator.
  ///
  /// [pluginRegistry] is an optional pre-populated registry of
  /// [ZorphyPlugin] instances. If non-null, the orchestrator runs
  /// the plugin transform pass after spec collection.
  ///
  /// [pluginUris] are import-URI strings from `build.yaml` options.
  /// They are stored but not resolved at construction time;
  /// dynamic URI-based plugin loading is a v2.1 feature.
  ///
  /// [isDryRun] when true, prevents file changes (preview mode).
  /// [isForce] when true, bypasses smart merge and regenerates from scratch.
  const ZorphyGenerator({
    this.pluginRegistry,
    this.pluginUris = const [],
    this.isDryRun = false,
    this.isForce = false,
  });

  /// Optional pre-populated plugin registry.
  final PluginRegistry? pluginRegistry;

  /// Plugin import URIs from build.yaml (deferred resolution).
  final List<String> pluginUris;

  /// Dry-run mode: preview changes without writing.
  final bool isDryRun;

  /// Force mode: bypass merge and regenerate from scratch.
  final bool isForce;

  static const _zorphyChecker = TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy',
  );
  static const _zorphy2Checker = TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy2',
  );

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final allClasses = library.allElements.whereType<ClassElement>().toList();
    final graph = ClassGraph.fromLibraryClasses(
      allClasses,
      library: library.element,
    );

    // Collect annotated elements from BOTH annotation types.
    final annotated = <_AnnotatedClass>[];
    for (final cls in allClasses) {
      final isZorphy2 = _zorphy2Checker.hasAnnotationOf(cls);
      final isZorphy = _zorphyChecker.hasAnnotationOf(cls);
      if (!isZorphy && !isZorphy2) continue;
      final annotation = isZorphy
          ? _zorphyChecker.firstAnnotationOf(cls)!
          : _zorphy2Checker.firstAnnotationOf(cls)!;
      annotated.add(
        _AnnotatedClass(
          cls,
          ConstantReader(annotation),
          isZorphy2: isZorphy2 && !isZorphy,
        ),
      );
    }

    // Topological order: base interfaces ($$Base) before implementors.
    final ordered = graph.topological(annotated.map((a) => a.element));
    final byElement = {for (final a in annotated) a.element: a};

    final values = <String>[];
    for (final cls in ordered) {
      final entry = byElement[cls]!;
      final generated = _generateForClass(
        entry.element,
        entry.annotation,
        graph,
        outputExtension: entry.isZorphy2 ? '.zorphy2.dart' : '.zorphy.dart',
      );
      if (generated.isNotEmpty) values.add(generated);
    }

    // Issue #117: detect missing cross-entity imports and emit a guidance
    // comment at the top of the generated output. The comment is only
    // emitted when there are actually missing imports — when all
    // cross-entity references are properly imported, the output is clean.
    //
    // The detection is delegated to [CrossEntityImportDetector], which
    // is a pure function over the source text (no I/O, no analyzer
    // dependency) so it can be unit-tested directly.
    final source = await buildStep.readAsString(buildStep.inputId);
    final guidance = CrossEntityImportDetector.detect(source).toGuidanceComment();
    if (guidance != null) {
      values.insert(0, guidance);
    }

    return values.join('\n\n');
  }

  String _generateForClass(
    ClassElement classElement,
    ConstantReader annotation,
    ClassGraph graph, {
    required String outputExtension,
  }) {
    if (classElement.supertype?.element.name != "Object") {
      throw Exception("you must use implements, not extends");
    }

    // Collect factory methods using the unified analyzer
    final metadata = ClassAnalyzer.analyze(
      classElement,
      annotation,
      graph.annotated,
      graph.classesInExplicitSubtypes,
    );
    final factoryMethods = metadata.factoryMethods;

    // Get own fields (defined directly on this class, not inherited)
    final ownFields = classElement.children
        .whereType<FieldElement>()
        .where((f) => f.name != "hashCode" && f.name != "runtimeType")
        .map((f) => f.name ?? "")
        .toSet();

    // Resolve ALL flags through the single resolution point.
    final options = AnnotationParser.parse(annotation);
    final config = GenerationConfig.fromAnnotationOptions(
      options,
      outputExtension: outputExtension,
      factoryMethods: factoryMethods,
      ownFields: ownFields,
    );

    // Use the orchestrator pipeline (with optional plugin registry)
    return Orchestrator.generate(
      classElement,
      annotation,
      graph.annotated,
      config,
      graph.classesInExplicitSubtypes,
      pluginRegistry: pluginRegistry,
    );
  }
}

class _AnnotatedClass {
  final ClassElement element;
  final ConstantReader annotation;
  final bool isZorphy2;

  _AnnotatedClass(this.element, this.annotation, {required this.isZorphy2});
}
