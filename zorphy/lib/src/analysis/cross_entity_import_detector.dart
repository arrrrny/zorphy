/// Detects missing cross-entity imports in `@Zorphy` source files.
///
/// Issue #117 — when a `@Zorphy` entity references another entity as a
/// field type (e.g. `$ArtifactRef get ref;`), the generated
/// `<name>.zorphy.dart` part file inherits its imports from the parent
/// `<name>.dart` library. Part files CANNOT carry their own `import`
/// directives (Dart language constraint), so if the parent library
/// forgets to import the sibling entity file, the type does not
/// resolve and the analyzer reports `argument_type_not_assignable`
/// or `InvalidType`.
///
/// This detector scans the source text of a `@Zorphy` library for
/// cross-entity field references and checks whether the parent library
/// imports the sibling. If any are missing, it returns a structured
/// guidance comment listing the required imports — emitted at the top
/// of the generated `.zorphy.dart` part file.
///
/// The detector is pure (no I/O, no analyzer dependency) so it can be
/// unit-tested directly with any source string.
library;

/// Result of a cross-entity import detection pass.
class CrossEntityImportDetectorResult {
  /// Builds a detection result.
  CrossEntityImportDetectorResult({
    required this.missingImports,
    required this.detectedTypes,
  });

  /// The set of `// $Type -> import '...';` comment lines, one per
  /// missing import. Empty when every cross-entity reference is
  /// already imported by the parent library.
  final List<String> missingImports;

  /// The full set of cross-entity type references detected in the
  /// source (whether or not their imports are present). Useful for
  /// diagnostics and tests.
  final Set<String> detectedTypes;

  /// True when there are missing imports — the caller should emit
  /// the guidance comment.
  bool get hasMissing => missingImports.isNotEmpty;

  /// Renders the full guidance comment (header + missing-import lines),
  /// or `null` when there are no missing imports.
  String? toGuidanceComment() {
    if (!hasMissing) return null;
    return [
      '// Cross-entity references detected. The parent <name>.dart '
          'library is missing',
      '// imports for the following entity types. Part files inherit '
          'imports from their',
      '// parent library, so add these imports to <name>.dart to make '
          'the types resolve:',
      ...missingImports,
    ].join('\n');
  }
}

/// Detects missing cross-entity imports in the given [source].
///
/// [source] is the source text of a `@Zorphy` library file. The
/// detector scans for cross-entity field references (types whose
/// declared name starts with `$`, the canonical shape emitted by the
/// CLI `FieldNormalizer`) and checks whether the parent library
/// already imports the corresponding sibling entity file.
///
/// [importUris] is an optional pre-collected set of import URIs
/// declared in the source file. When `null`, the detector scans the
/// source text for `import '...';` statements itself.
///
/// Returns a [CrossEntityImportDetectorResult] describing the
/// detection outcome. Use [CrossEntityImportDetectorResult.toGuidanceComment]
/// to render the comment, or check `hasMissing` directly.
///
/// ## What counts as a cross-entity reference?
///
/// A cross-entity reference is a field (or getter) whose declared type
/// starts with `$`:
///
/// ```dart
/// $ArtifactRef get ref;            // matches $ArtifactRef
/// $ArtifactRef? get ref;           // matches $ArtifactRef
/// final $ArtifactRef ref;          // matches $ArtifactRef
/// List<$ArtifactRef> get refs;     // matches $ArtifactRef
/// Map<String, $ArtifactRef> m;     // matches $ArtifactRef
/// ```
///
/// Self-references (where the `$Type` matches a `@Zorphy` class
/// declared in the same file) are NOT reported — a class is always
/// visible inside its own library.
///
/// ## Why regex and not the analyzer API?
///
/// We scan source text rather than walking `FieldElement.type`
/// because the resolved `FieldElement.type` returns `InvalidType`
/// or `dynamic` precisely when the import is missing — the exact
/// situation this detector is built to flag. Source-text scanning
/// catches the type name even when the analyzer cannot resolve it.
///
/// The import-URI scan also uses regex (rather than
/// `library.element.libraryImports` / `.imports`) because that API
/// differs between analyzer 13.x and 14.x. The regex approach is
/// version-independent.
class CrossEntityImportDetector {
  /// Private constructor — this class is a namespace of static helpers.
  CrossEntityImportDetector._();

  /// Pre-filter regex for `@Zorphy` / `@Zorphy2` class declarations.
  ///
  /// Captures the class name (with leading `$`s) so we can skip
  /// self-references.
  static final _classDeclRegex = RegExp(
    r'@(?:Zorphy2?)\b[^{]*\bclass\s+(\$+\w+)',
  );

  /// Regex for cross-entity field references.
  ///
  /// Matches any identifier starting with `$` followed by an uppercase
  /// letter and more word characters. The optional leading `final ` is
  /// consumed (and stripped) when present.
  static final _fieldTypeRegex = RegExp(
    r'(?:final\s+)?\$[A-Z][a-zA-Z0-9_]*',
  );

  /// Regex for `import 'uri';` / `import "uri";` statements.
  static final _importUriRegex = RegExp(
    r"""import\s+['"]([^'"]+)['"]""",
  );

  /// Detects missing cross-entity imports in [source].
  ///
  /// Pass [importUris] to bypass the regex scan of `import` statements
  /// (useful when the caller already has the URIs from another source,
  /// e.g. the analyzer API). When `null`, the detector scans [source]
  /// itself.
  static CrossEntityImportDetectorResult detect(
    String source, {
    Set<String>? importUris,
  }) {
    // Cheap pre-filter: only scan files that mention `@Zorphy`.
    // This avoids running the field-type regex on every Dart file
    // touched by build_runner (which would be expensive on large
    // projects with many non-@Zorphy files).
    if (!source.contains('@Zorphy')) {
      return CrossEntityImportDetectorResult(
        missingImports: const [],
        detectedTypes: const {},
      );
    }

    // Collect the set of @Zorphy / @Zorphy2 class names declared in
    // this file (so we can skip self-references). Each name is added
    // in both its abstract (`$Type`) and concrete (`Type`) forms.
    final declaredClassNames = <String>{};
    for (final match in _classDeclRegex.allMatches(source)) {
      final name = match.group(1);
      if (name == null || name.isEmpty) continue;
      declaredClassNames.add(name);
      declaredClassNames.add(name.replaceAll(RegExp(r'^\$+'), ''));
    }

    // Scan for cross-entity field references — types whose declared
    // name starts with `$`.
    //
    // The regex matches every `\$Type` substring in the source, including
    // occurrences inside class declarations (e.g. `abstract class \$Foo {`).
    // We filter those out below using `declaredClassNames` so that
    // `detectedTypes` only contains TRUE cross-entity references — i.e.
    // types referenced as field types that point at ANOTHER entity.
    final rawDetectedTypes = <String>{};
    for (final match in _fieldTypeRegex.allMatches(source)) {
      final typeName = match.group(0);
      if (typeName == null) continue;
      // Strip leading `final ` if the optional prefix matched.
      final cleanName = typeName.replaceFirst(RegExp(r'^final\s+'), '');
      if (cleanName.isNotEmpty && cleanName.startsWith(r'$')) {
        rawDetectedTypes.add(cleanName);
      }
    }

    // Filter out self-references — types declared in THIS file. They are
    // always visible inside their own library and so cannot be "missing".
    final detectedTypes = rawDetectedTypes.where((typeName) {
      final concreteName = typeName.replaceAll(RegExp(r'^\$+'), '');
      if (concreteName.isEmpty) return false;
      if (declaredClassNames.contains(concreteName)) return false;
      if (declaredClassNames.contains(typeName)) return false;
      return true;
    }).toSet();

    // Collect import URIs (caller-supplied or scanned from source).
    final uris = importUris ?? _scanImportUris(source);

    // For each detected cross-entity type, check whether the source
    // library imports a file matching the type's snake_case name.
    final missing = <String>[];
    for (final typeName in detectedTypes) {
      // Strip leading `$`s to get the concrete name.
      final concreteName = typeName.replaceAll(RegExp(r'^\$+'), '');
      if (concreteName.isEmpty) continue;

      final snakeName = toSnakeCase(concreteName);

      // Match either relative (`../snake/snake.dart`) or package
      // (`package:pkg/snake/snake.dart`) import forms.
      final importRegex = RegExp(
        r'(?:[/:])' + RegExp.escape(snakeName) + r'\.dart$',
      );

      final isImported = uris.any((uri) => importRegex.hasMatch(uri));

      if (!isImported) {
        missing.add(
          "//   $typeName -> import '../$snakeName/$snakeName.dart';",
        );
      }
    }

    return CrossEntityImportDetectorResult(
      missingImports: missing,
      detectedTypes: detectedTypes,
    );
  }

  /// Scans [source] for `import 'uri';` / `import "uri";` statements
  /// and returns the set of import URIs.
  ///
  /// Exposed publicly so callers (and tests) can reuse the same
  /// regex the detector uses.
  static Set<String> scanImportUris(String source) =>
      _scanImportUris(source);

  static Set<String> _scanImportUris(String source) {
    final uris = <String>{};
    for (final match in _importUriRegex.allMatches(source)) {
      final uri = match.group(1);
      if (uri != null && uri.isNotEmpty) {
        uris.add(uri);
      }
    }
    return uris;
  }

  /// Converts a PascalCase / camelCase name to snake_case.
  ///
  /// Mirrors the CLI `NamingUtils.toSnakeCase` for the common cases:
  /// `ArtifactRef` -> `artifact_ref`, `Issue117Ref` -> `issue117_ref`.
  ///
  /// Edge cases (acronyms like `HTTPServer`, leading underscores, etc.)
  /// are NOT specifically handled because the CLI FieldNormalizer
  /// already restricts the input character set to PascalCase entity
  /// names — the input here is already well-formed.
  static String toSnakeCase(String name) {
    final withSeparators = name.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
      (m) => '_',
    );
    return withSeparators.toLowerCase();
  }
}
