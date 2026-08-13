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

  String _determinePrefix(String typeName) {
    final entitySnakeName = NamingUtils.toSnakeCase(typeName);
    final entityDir = Directory(p.join(baseOutputDir, entitySnakeName));
    final entityFile = File(p.join(entityDir.path, '$entitySnakeName.dart'));

    if (!entityFile.existsSync()) return '';

    try {
      final content = entityFile.readAsStringSync();
      if (RegExp('abstract class \\\$\\\$$typeName\\b').hasMatch(content)) {
        return '\$\$';
      }
      if (RegExp('abstract class \\\$' + typeName + r'\b').hasMatch(content)) {
        return '\$';
      }
    } catch (_) {}

    // The referenced file exists but declares no Zorphy abstract — e.g. a
    // hand-written plain/sealed class (issue #310). Emit the plain type so
    // the concrete class and json_serializable resolve it via the import.
    return '';
  }
}
