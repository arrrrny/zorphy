import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/entity_config.dart';
import '../utils/naming_utils.dart';

/// Resolves imports for entity files
class ImportResolver {
  final String baseOutputDir;

  ImportResolver({required this.baseOutputDir});

  /// Resolve all imports needed for the given fields
  Set<String> resolveImports(
    String className,
    List<FieldDefinition> fields, {
    String? extendsInterface,
    List<String>? explicitSubtypes,
    bool generateSubtypes = false,
    bool isSealed = false,
  }) {
    final imports = <String>{};
    bool needsEnumImport = false;

    for (final field in fields) {
      // External types (`!Type` marker): the import is normally provided by
      // the user. BUT if the referenced type is a sibling Zorphy entity on
      // disk, resolve the relative import automatically — otherwise the
      // generated file references an unresolved identifier (analyzer error,
      // json_serializable InvalidType). Cross-entity references are the
      // primary use of `!Type`, and the sibling almost always exists.
      final typeRefs = NamingUtils.extractTypeReferences(field.type);

      for (final typeRef in typeRefs) {
        if (NamingUtils.isPrimitiveType(typeRef)) continue;

        final cleanTypeRef = typeRef.replaceAll(RegExp(r'^\$+'), '');
        if (cleanTypeRef == className) continue;

        final typeSnakeName = NamingUtils.toSnakeCase(cleanTypeRef);
        final potentialEntityPath = p.join(baseOutputDir, typeSnakeName);

        if (!field.isExternal &&
            (typeRef.startsWith(r'$') ||
                Directory(potentialEntityPath).existsSync())) {
          imports.add("import '../$typeSnakeName/$typeSnakeName.dart';");
        } else if (field.isExternal &&
            Directory(potentialEntityPath).existsSync()) {
          // External type that IS a local sibling entity: import it.
          imports.add("import '../$typeSnakeName/$typeSnakeName.dart';");
        } else if (!field.isExternal) {
          needsEnumImport = true;
        }
      }
    }

    if (needsEnumImport) {
      imports.add("import '../enums/index.dart';");
    }

    if (extendsInterface != null) {
      final cleanExtends = extendsInterface.replaceAll(RegExp(r'^\$+'), '');
      if (cleanExtends != className) {
        final extendsSnakeName = NamingUtils.toSnakeCase(cleanExtends);
        imports.add("import '../$extendsSnakeName/$extendsSnakeName.dart';");
      }
    }

    if (explicitSubtypes != null) {
      for (final subtype in explicitSubtypes) {
        final cleanSubtype = subtype.replaceAll(RegExp(r'^\$+'), '').split(':').first;
        if (cleanSubtype != className) {
          if (!(generateSubtypes && isSealed)) {
            final subtypeSnakeName = NamingUtils.toSnakeCase(cleanSubtype);
            imports.add(
              "import '../$subtypeSnakeName/$subtypeSnakeName.dart';",
            );
          }
        }
      }
    }

    return imports;
  }

  /// Resolve imports for subtype fields
  Set<String> resolveSubtypeImports(
    String className,
    String parentClassName,
    List<FieldDefinition> fields,
  ) {
    final imports = <String>{};
    bool needsEnumImport = false;

    for (final field in fields) {
      // External types: import sibling entities on disk (cross-entity refs);
      // truly external types remain user-imported.
      final typeRefs = NamingUtils.extractTypeReferences(field.type);

      for (final typeRef in typeRefs) {
        if (NamingUtils.isPrimitiveType(typeRef)) continue;

        final cleanTypeRef = typeRef.replaceAll(RegExp(r'^\$+'), '');
        if (cleanTypeRef == className) continue;

        final typeSnakeName = NamingUtils.toSnakeCase(cleanTypeRef);
        final potentialEntityPath = p.join(baseOutputDir, typeSnakeName);

        if (!field.isExternal &&
            (typeRef.startsWith(r'\$') ||
                Directory(potentialEntityPath).existsSync())) {
          imports.add("import '../$typeSnakeName/$typeSnakeName.dart';");
        } else if (field.isExternal &&
            Directory(potentialEntityPath).existsSync()) {
          // External type that IS a local sibling entity: import it.
          imports.add("import '../$typeSnakeName/$typeSnakeName.dart';");
        } else if (!field.isExternal) {
          needsEnumImport = true;
        }
      }
    }

    if (needsEnumImport) {
      imports.add("import '../enums/index.dart';");
    }

    return imports;
  }
}
