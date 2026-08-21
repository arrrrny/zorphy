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
/// This generator scans each `@Zorphy` class for cross-entity field
/// references and checks whether the parent library imports the
/// sibling. If any are missing, it emits a guidance comment at the top
/// of the `.zorphy.dart` part file listing the required imports. The
/// comment is purely informational — the user must add the imports to
/// the parent `<name>.dart` file (parts cannot have their own imports).
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
    final guidance = await _detectMissingImportGuidance(library, buildStep);
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

  /// Detects cross-entity field references in `@Zorphy` / `@Zorphy2`
  /// classes and checks whether the parent library imports the
  /// corresponding sibling entity files.
  ///
  /// Returns a guidance comment string if any imports are missing,
  /// or `null` if all cross-entity references are properly imported
  /// (or there are no cross-entity references at all).
  ///
  /// The guidance comment is emitted at the top of the `.zorphy.dart`
  /// part file. It does NOT modify the source file — part files cannot
  /// carry imports, and builders cannot overwrite their input. The user
  /// must add the listed imports to the parent `<name>.dart` library.
  ///
  /// Implementation note: this uses a regex-based scan of the source
  /// text rather than the analyzer AST, because the AST API differs
  /// between analyzer 13.x (`ClassDeclaration.body.members`,
  /// `ClassDeclaration.namePart`) and 14.x (`ClassDeclaration.members`,
  /// `ClassDeclaration.name`). The regex approach is compatible with
  /// both versions and is sufficient for detecting `$Type` references
  /// in field declarations.
  Future<String?> _detectMissingImportGuidance(
    LibraryReader library,
    BuildStep buildStep,
  ) async {
    // Read the source file to extract field type names as written in
    // source (handles unresolved types — the resolved `FieldElement.type`
    // returns `InvalidType` / `dynamic` when the import is missing).
    final source = await buildStep.readAsString(buildStep.inputId);

    // Cheap pre-filter: only scan files that mention `@Zorphy`.
    if (!source.contains('@Zorphy')) return null;

    // Collect the set of @Zorphy / @Zorphy2 class names declared in
    // this file (so we can skip self-references).
    final zorphyClassNames = <String>{};
    final classDeclRegex = RegExp(
      r'@(?:Zorphy2?)\b[^{]*\bclass\s+(\$+\w+)',
    );
    for (final match in classDeclRegex.allMatches(source)) {
      final name = match.group(1);
      if (name != null && name.isNotEmpty) {
        zorphyClassNames.add(name);
        zorphyClassNames.add(name.replaceAll(RegExp(r'^\$+'), ''));
      }
    }

    // Scan for cross-entity field references. A cross-entity reference
    // is a field (or getter) whose declared type starts with `$` —
    // the canonical shape emitted by the CLI `FieldNormalizer`.
    //
    // Examples matched:
    //   $ArtifactRef get ref;
    //   $ArtifactRef? get ref;
    //   final $ArtifactRef ref;
    //   List<$ArtifactRef> get refs;
    final crossEntityTypes = <String>{};
    final fieldRegex = RegExp(
      r'(?:final\s+)?\$[A-Z][a-zA-Z0-9_]*',
    );
    for (final match in fieldRegex.allMatches(source)) {
      final typeName = match.group(0);
      if (typeName == null) continue;
      // Strip leading `final ` if present.
      final cleanName = typeName.replaceFirst(RegExp(r'^final\s+'), '');
      if (cleanName.isNotEmpty && cleanName.startsWith(r'$')) {
        crossEntityTypes.add(cleanName);
      }
    }

    if (crossEntityTypes.isEmpty) return null;

    // Collect the set of import URIs declared in the source file.
    //
    // We scan the source text directly (rather than `library.element
    // .libraryImports` / `.imports`) because the `LibraryElement` API
    // differs between analyzer 13.x (`libraryImports` returning
    // `List<LibraryImport>` with `DirectiveUri` subtypes) and 14.x
    // (`imports` returning `List<ImportElement>` with `ImportElement.uri`
    // as a `String?`). The regex approach is version-independent and
    // sufficient for our needs here.
    final importUriRegex = RegExp(
      r"""import\s+['"]([^'"]+)['"]""",
    );
    final importUris = <String>{};
    for (final match in importUriRegex.allMatches(source)) {
      final uri = match.group(1);
      if (uri != null && uri.isNotEmpty) {
        importUris.add(uri);
      }
    }

    final missingImports = <String>[];
    for (final typeName in crossEntityTypes) {
      // Strip leading `$`s to get the concrete name.
      final concreteName = typeName.replaceAll(RegExp(r'^\$+'), '');
      if (concreteName.isEmpty) continue;

      // Skip the class itself (self-reference).
      if (zorphyClassNames.contains(concreteName)) continue;
      if (zorphyClassNames.contains(typeName)) continue;

      final snakeName = _toSnakeCase(concreteName);

      // Check if the source library imports a file matching this type.
      // Matches both relative (`../snake/snake.dart`) and package
      // (`package:pkg/snake/snake.dart`) import forms.
      final importRegex = RegExp(
        r"(?:[/:])" + RegExp.escape(snakeName) + r"\.dart$",
      );

      final isImported = importUris.any((uri) => importRegex.hasMatch(uri));

      if (!isImported) {
        missingImports.add(
          '//   $typeName -> import \'../$snakeName/$snakeName.dart\';',
        );
      }
    }

    if (missingImports.isEmpty) return null;

    return '// Cross-entity references detected. The parent <name>.dart '
        'library is missing\n'
        '// imports for the following entity types. Part files inherit '
        'imports from their\n'
        '// parent library, so add these imports to <name>.dart to make '
        'the types resolve:\n'
        '${missingImports.join('\n')}';
  }

  /// Converts a PascalCase / camelCase name to snake_case.
  ///
  /// Mirrors the CLI `NamingUtils.toSnakeCase` for the common cases:
  /// `ArtifactRef` -> `artifact_ref`, `Issue117Ref` -> `issue117_ref`.
  String _toSnakeCase(String name) {
    final withSeparators = name.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
      (m) => '_',
    );
    return withSeparators.toLowerCase();
  }
}

class _AnnotatedClass {
  final ClassElement element;
  final ConstantReader annotation;
  final bool isZorphy2;

  _AnnotatedClass(this.element, this.annotation, {required this.isZorphy2});
}
