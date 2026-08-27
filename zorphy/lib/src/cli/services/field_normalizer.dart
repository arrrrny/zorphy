import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/entity_config.dart';
import '../utils/naming_utils.dart';

/// Service for normalizing field types
class FieldNormalizer {
  final String baseOutputDir;

  FieldNormalizer({required this.baseOutputDir});

  /// Normalize a field type by adding $ prefix for entity types
  String normalize(String type) {
    // External types (`!Type` marker) are kept as-is with no `$` prefix —
    // they live outside the entity tree and are imported by the user.
    if (type.startsWith('!')) {
      return type.substring(1);
    }

    final isNullable = type.endsWith('?');
    final cleanType = isNullable ? type.substring(0, type.length - 1) : type;

    if (cleanType.startsWith('\$')) {
      return type;
    }

    final genericMatch = RegExp(r'^([^<]+)(<.+>)?$').firstMatch(cleanType);
    if (genericMatch == null) return type;

    final baseType = genericMatch.group(1)!.trim();
    final generics = genericMatch.group(2);

    if (NamingUtils.isPrimitiveType(baseType)) {
      if (generics != null && NamingUtils.isContainerType(baseType)) {
        final normalizedGenerics = _normalizeGenerics(generics);
        return '$baseType$normalizedGenerics${isNullable ? '?' : ''}';
      }
      return type;
    }

    if (_isEnum(baseType)) {
      return type;
    }

    final prefix = _determinePrefix(baseType);
    final normalizedBase = '$prefix$baseType';
    final normalizedGenerics = generics != null
        ? _normalizeGenerics(generics)
        : '';
    return '$normalizedBase$normalizedGenerics${isNullable ? '?' : ''}';
  }

  /// Normalize a FieldDefinition
  FieldDefinition normalizeField(FieldDefinition field) {
    // External types (`!Type` marker) are never entity/enum: the type was
    // already stripped of the `!` by [FieldDefinition.parse] and must NOT
    // receive a `$` prefix or nullable-stripping.
    if (field.isExternal) {
      return field;
    }
    final normalizedType = normalize(field.type);
    return field.copyWith(type: normalizedType.replaceAll('?', ''));
  }

  String _normalizeGenerics(String generics) {
    final inner = generics.substring(1, generics.length - 1);
    final parts = NamingUtils.smartSplit(inner);
    final normalized = parts.map((part) => normalize(part)).join(', ');
    return '<$normalized>';
  }

  bool _isEnum(String typeName) {
    final enumsDir = Directory(p.join(baseOutputDir, 'enums'));
    if (!enumsDir.existsSync()) return false;
    final enumSnakeName = NamingUtils.toSnakeCase(typeName);
    final enumFile = File(p.join(enumsDir.path, '$enumSnakeName.dart'));
    return enumFile.existsSync();
  }

  /// Determines the Zorphy prefix (`$$`, `$`, or `''`) for a referenced type
  /// by inspecting its on-disk declaration.
  ///
  /// Returns:
  /// - `$$` when the target file declares `abstract class $$X` (a Zorphy
  ///   second-order abstract, used for shared base entities).
  /// - `$` when the target file declares `abstract class $X` (a Zorphy
  ///   first-order abstract entity).
  /// - `''` (empty) when the file exists but declares NEITHER — e.g. a
  ///   hand-written plain or sealed class (issue #310). The plain type is
  ///   emitted so the concrete class and `json_serializable` resolve it via
  ///   the entity import added by `ImportResolver`.
  /// - `$` when the file does NOT exist yet — a forward reference (created
  ///   later in the same batch, #308) or the entity being created itself
  ///   (self-reference, #315). We assume a Zorphy entity so the builder can
  ///   map `$X` to the concrete class once it exists.
  ///
  /// Comment-safety (issue #310 hardening): the regex is run against the
  /// file content with `//` line comments and `/* ... */` block comments
  /// stripped. Without this, a doc comment in a hand-written class file
  /// that mentions the literal text `abstract class $X` (very common —
  /// e.g. `/// Plain class, NO abstract class $X here.`) would falsely
  /// match and emit the `$` prefix, reproducing the `InvalidType` symptom.
  String _determinePrefix(String typeName) {
    final entitySnakeName = NamingUtils.toSnakeCase(typeName);
    final entityDir = Directory(p.join(baseOutputDir, entitySnakeName));
    final entityFile = File(p.join(entityDir.path, '$entitySnakeName.dart'));

    if (!entityFile.existsSync()) {
      // Forward reference (created later in the same batch, #308) or the
      // entity being created itself — assume a Zorphy entity so the builder
      // can map `$X` to the concrete class once it exists.
      return '\$';
    }

    try {
      final raw = entityFile.readAsStringSync();
      // Strip comments before pattern-matching so doc comments mentioning
      // `abstract class $X` (common in hand-written class files) do not
      // produce false positives (issue #310 hardening).
      final content = _stripComments(raw);

      if (RegExp(
        r'abstract\s+class\s+\$\$' + typeName + r'\b',
      ).hasMatch(content)) {
        return '\$\$';
      }
      if (RegExp(
        r'abstract\s+class\s+\$' + typeName + r'\b',
      ).hasMatch(content)) {
        return '\$';
      }
    } catch (_) {}

    // The referenced file exists but declares no Zorphy abstract — e.g. a
    // hand-written plain/sealed class (issue #310). Emit the plain type so
    // the concrete class and json_serializable resolve it via the import.
    return '';
  }

  /// Strips `//` line comments and `/* ... */` block comments from [source].
  ///
  /// This is a best-effort, regex-based stripper sufficient for the prefix
  /// detection use case. It does NOT parse Dart string literals — a string
  /// containing `//` or `/*` would have those substrings removed too. That
  /// is acceptable here because:
  ///   1. The result is only used to detect `abstract class $X` declarations,
  ///      which are never inside string literals in practice.
  ///   2. A false negative (missing a real declaration inside a string) is
  ///      impossible because declarations cannot appear inside strings.
  ///   3. A false positive (matching a declaration that was inside a
  ///      comment) is exactly what we are preventing.
  ///
  /// Block comments are stripped first (non-greedy, multi-line) so that a
  /// `//` inside a block comment does not leave a dangling line comment
  /// marker. Line comments are then stripped to end-of-line.
  static String _stripComments(String source) {
    // Remove /* ... */ block comments (non-greedy, multi-line).
    var result = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    // Remove // line comments (to end of line).
    result = result.replaceAll(RegExp(r'//[^\n]*'), '');
    return result;
  }
}
