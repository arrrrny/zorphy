/// Project validation service for zorphy.
///
/// Scans a Dart project for common Zorphy-related issues:
/// - Missing generated files (.zorphy.dart, .g.dart)
/// - Source files newer than generated counterparts (stale output)
/// - Missing part directives in source files
/// - Pub dependencies presence check
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import '../models/validation_result.dart';

/// Runs all validation checks against a project directory and returns
/// an aggregated [ValidationResult].
class ProjectValidator {
  /// Root directory of the Dart project to validate.
  final String projectDir;

  /// Glob pattern for source directories to scan (relative to [projectDir]).
  final List<String> sourceDirs;

  ProjectValidator({
    required this.projectDir,
    List<String>? sourceDirs,
  }) : sourceDirs = sourceDirs ?? const ['lib'];

  /// Check if the file content has actual @Zorphy or @zorphy annotations
  /// (not in comments or string literals).
  bool _hasZorphyAnnotation(String content) {
    try {
      final parsed = parseString(content: content);
      final unit = parsed.unit;

      for (final declaration in unit.declarations) {
        if (declaration is ClassDeclaration) {
          for (final metadata in declaration.metadata) {
            final name = metadata.name.name;
            if (name == 'Zorphy' || name == 'zorphy') {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      // If parsing fails, fall back to string search to avoid missing files
      return content.contains('@Zorphy(') || content.contains('@zorphy(');
    }
  }

  /// Run all validation checks and return the result.
  ValidationResult validate() {
    final findings = <ValidationFinding>[];
    var filesScanned = 0;

    // 1. Pub dependencies check
    findings.addAll(_checkPubDependencies());

    // 2. Scan source files for @Zorphy annotations
    final annotatedFiles = <String>[];
    for (final dir in sourceDirs) {
      final absDir = p.join(projectDir, dir);
      final dirEntity = Directory(absDir);
      if (!dirEntity.existsSync()) continue;

      for (final file in dirEntity.listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        // Skip generated files
        if (file.path.endsWith('.zorphy.dart') ||
            file.path.endsWith('.g.dart') ||
            file.path.endsWith('.freezed.dart')) continue;

        filesScanned++;
        final content = file.readAsStringSync();
        if (_hasZorphyAnnotation(content)) {
          annotatedFiles.add(file.path);
          // Check part directives
          findings.addAll(_checkPartDirectives(file.path, content));
        }
      }
    }

    // 3. Check generated files for each annotated source
    for (final sourcePath in annotatedFiles) {
      findings.addAll(_checkGeneratedFiles(sourcePath));
    }

    return ValidationResult(
      findings: findings,
      validatedDir: projectDir,
      filesScanned: filesScanned,
    );
  }

  /// Check that zorphy and zorphy_annotation are in pubspec.yaml.
  ///
  /// Uses simple line-based scanning rather than a YAML parser to avoid
  /// adding a dependency on the `yaml` package.
  List<ValidationFinding> _checkPubDependencies() {
    final findings = <ValidationFinding>[];
    final pubspecPath = p.join(projectDir, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      findings.add(
        ValidationFinding(
          message: 'pubspec.yaml not found',
          severity: ValidationSeverity.error,
          filePath: projectDir,
          fixSuggestion: 'Ensure you are in a Dart/Flutter project root.',
        ),
      );
      return findings;
    }

    try {
      final lines = pubspecFile.readAsLinesSync();
      final depsSection = _yamlSectionLines(lines, 'dependencies');
      final devDepsSection = _yamlSectionLines(lines, 'dev_dependencies');

      if (depsSection == null) {
        findings.add(
          ValidationFinding(
            message: 'No dependencies section found in pubspec.yaml',
            severity: ValidationSeverity.error,
            filePath: pubspecPath,
          ),
        );
        return findings;
      }

      final depsText = depsSection.join('\n');
      final devDepsText = devDepsSection?.join('\n') ?? '';

      // Check zorphy
      if (!_yamlKeyExists(depsText, 'zorphy')) {
        findings.add(
          ValidationFinding(
            message: "'zorphy' not found in dependencies",
            severity: ValidationSeverity.error,
            filePath: pubspecPath,
            fixSuggestion:
                "Add 'zorphy: ^2.0.0' to dependencies in pubspec.yaml",
          ),
        );
      }

      // Check zorphy_annotation
      if (!_yamlKeyExists(depsText, 'zorphy_annotation')) {
        findings.add(
          ValidationFinding(
            message: "'zorphy_annotation' not found in dependencies",
            severity: ValidationSeverity.error,
            filePath: pubspecPath,
            fixSuggestion:
                "Add 'zorphy_annotation: ^2.0.0' to dependencies in pubspec.yaml",
          ),
        );
      }

      // Check build_runner in dev_dependencies
      if (!_yamlKeyExists(devDepsText, 'build_runner')) {
        findings.add(
          ValidationFinding(
            message:
                "'build_runner' not found in dev_dependencies (required for code generation)",
            severity: ValidationSeverity.warning,
            filePath: pubspecPath,
            fixSuggestion:
                'Add dev dependency: dart pub add dev:build_runner',
          ),
        );
      }
    } catch (e) {
      findings.add(
        ValidationFinding(
          message: 'Failed to parse pubspec.yaml: $e',
          severity: ValidationSeverity.error,
          filePath: pubspecPath,
          ),
      );
    }

    return findings;
  }

  /// Extract lines belonging to a YAML section (e.g. 'dependencies:').
  /// Returns the lines indented below the section header, or null if the
  /// section is not found.
  List<String>? _yamlSectionLines(List<String> allLines, String sectionName) {
    final header = '$sectionName:';
    final headerIdx = allLines.indexWhere((l) => l.trim() == header);
    if (headerIdx < 0) return null;

    final result = <String>[];
    final headerIndent = _leadingSpaces(allLines[headerIdx]);

    for (var i = headerIdx + 1; i < allLines.length; i++) {
      final line = allLines[i];
      if (line.trim().isEmpty) {
        result.add(line);
        continue;
      }
      final indent = _leadingSpaces(line);
      // A line at the same or lesser indentation ends the section
      if (indent <= headerIndent) break;
      result.add(line);
    }
    return result;
  }

  /// Returns the number of leading spaces in [line].
  int _leadingSpaces(String line) {
    var count = 0;
    for (final ch in line.runes) {
      if (ch == 0x20) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Check whether a YAML key exists at the start of any line.
  bool _yamlKeyExists(String yamlText, String key) {
    // Match a YAML key at the start of a line (with leading whitespace).
    // The key must be followed by ':' or whitespace+':' to avoid matching
    // 'zorphy_annotation' when looking for 'zorphy'.
    final pattern = RegExp(
      '^\\s*' + RegExp.escape(key) + '\\s*:',
      multiLine: true,
    );
    return pattern.hasMatch(yamlText);
  }

  /// Verify that a source file annotated with @Zorphy has the correct
  /// part directives for its expected generated outputs.
  List<ValidationFinding> _checkPartDirectives(
    String filePath,
    String content,
  ) {
    final findings = <ValidationFinding>[];
    final base = p.basenameWithoutExtension(filePath);
    final zorphyPart = "$base.zorphy.dart";
    final gPart = "$base.g.dart";

    bool hasZorphyPart = false;
    bool hasGPart = false;

    try {
      final parsed = parseString(content: content);
      final unit = parsed.unit;

      for (final directive in unit.directives) {
        if (directive is PartDirective) {
          final uri = directive.uri.stringValue;
          if (uri == zorphyPart) {
            hasZorphyPart = true;
          } else if (uri == gPart) {
            hasGPart = true;
          }
        }
      }
    } catch (e) {
      // Fall back to string search if parsing fails
      hasZorphyPart = content.contains("part '$zorphyPart'") ||
          content.contains('part "$zorphyPart"');
      hasGPart = content.contains("part '$gPart'") ||
          content.contains('part "$gPart"');
    }

    if (!hasZorphyPart) {
      findings.add(
        ValidationFinding(
          message: "Missing part directive for '$zorphyPart'",
          severity: ValidationSeverity.error,
          filePath: filePath,
          fixSuggestion: "Add: part '$zorphyPart';",
        ),
      );
    }

    if (!hasGPart) {
      findings.add(
        ValidationFinding(
          message: "Missing part directive for '$gPart'",
          severity: ValidationSeverity.error,
          filePath: filePath,
          fixSuggestion: "Add: part '$gPart';",
        ),
      );
    }

    return findings;
  }

  /// Check that generated files (.zorphy.dart and .g.dart) exist and are
  /// not stale relative to the source file.
  List<ValidationFinding> _checkGeneratedFiles(String sourcePath) {
    final findings = <ValidationFinding>[];
    final dir = p.dirname(sourcePath);
    final base = p.basenameWithoutExtension(sourcePath);
    final sourceFile = File(sourcePath);
    final sourceModTime = sourceFile.lastModifiedSync();

    // Check .zorphy.dart
    final zorphyPath = p.join(dir, '$base.zorphy.dart');
    final zorphyFile = File(zorphyPath);
    if (!zorphyFile.existsSync()) {
      findings.add(
        ValidationFinding(
          message: "Generated file '$base.zorphy.dart' does not exist",
          severity: ValidationSeverity.error,
          filePath: sourcePath,
          fixSuggestion: 'Run: dart run build_runner build --delete-conflicting-outputs',
        ),
      );
    } else {
      final zorphyMod = zorphyFile.lastModifiedSync();
      if (sourceModTime.isAfter(zorphyMod)) {
        findings.add(
          ValidationFinding(
            message:
                "'$base.zorphy.dart' is stale (source is newer than generated)",
            severity: ValidationSeverity.warning,
            filePath: sourcePath,
            fixSuggestion: 'Run: dart run build_runner build',
          ),
        );
      }
    }

    // Check .g.dart
    final gPath = p.join(dir, '$base.g.dart');
    final gFile = File(gPath);
    if (!gFile.existsSync()) {
      findings.add(
        ValidationFinding(
          message: "Generated file '$base.g.dart' does not exist",
          severity: ValidationSeverity.error,
          filePath: sourcePath,
          fixSuggestion: 'Run: dart run build_runner build --delete-conflicting-outputs',
        ),
      );
    } else {
      final gMod = gFile.lastModifiedSync();
      if (sourceModTime.isAfter(gMod)) {
        findings.add(
          ValidationFinding(
            message:
                "'$base.g.dart' is stale (source is newer than generated)",
            severity: ValidationSeverity.warning,
            filePath: sourcePath,
            fixSuggestion: 'Run: dart run build_runner build',
          ),
        );
      }
    }

    return findings;
  }
}
