import 'base_generator.dart';

/// Generates semantic property helpers (hasField, isSubtype, etc.)
class PropertyHelperGenerator extends UniversalGenerator {
  PropertyHelperGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();

    // 1. Field-specific helpers (hasField, noField, Required, isEnumValue)
    final fields = metadata.allFields;
    if (fields.isNotEmpty) {
      if (!metadata.isAbstract) {
        sb.writeln('  // Property helpers');
      }

      for (final field in fields) {
        var type = field.type ?? 'dynamic';
        type = type.replaceAll('\$', '');
        
        final fieldName = field.name;
        final isNullable = type.endsWith('?');
        final isCollection = type.startsWith('List<') || type.startsWith('Map<') || type.startsWith('Set<');
        
        final baseName = fieldName.startsWith('_') ? fieldName.substring(1) : fieldName;
        final capitalized = baseName[0].toUpperCase() + baseName.substring(1);

        if (metadata.isAbstract) {
          // In abstract classes, we generate abstract getters
          if (isNullable && !isCollection) {
            sb.writeln('  bool get has$capitalized;');
            sb.writeln('  bool get no$capitalized;');
            final nonNullableType = type.substring(0, type.length - 1);
            sb.writeln('  $nonNullableType get ${baseName}Required;');
          } else if (isNullable && isCollection) {
            final nonNullableType = type.substring(0, type.length - 1);
            sb.writeln('  $nonNullableType get ${baseName}Required;');
          }

          if (isCollection) {
            sb.writeln('  bool get has$capitalized;');
            sb.writeln('  bool get no$capitalized;');
          }
        } else {
          // In concrete classes, we generate implementations
          if (isNullable && !isCollection) {
             sb.writeln('  bool get has$capitalized => $fieldName != null;');
             sb.writeln('  bool get no$capitalized => $fieldName == null;');
             final nonNullableType = type.substring(0, type.length - 1);
             sb.writeln('  $nonNullableType get ${baseName}Required => $fieldName ?? (throw StateError(\'$fieldName is required but was null\'));');
          } else if (isNullable && isCollection) {
             final nonNullableType = type.substring(0, type.length - 1);
             sb.writeln('  $nonNullableType get ${baseName}Required => $fieldName ?? (throw StateError(\'$fieldName is required but was null\'));');
          }

          if (isCollection) {
            if (!isNullable) {
              sb.writeln('  bool get has$capitalized => $fieldName.isNotEmpty;');
              sb.writeln('  bool get no$capitalized => $fieldName.isEmpty;');
            } else {
              sb.writeln('  bool get has$capitalized => $fieldName?.isNotEmpty ?? false;');
              sb.writeln('  bool get no$capitalized => $fieldName?.isEmpty ?? true;');
            }
          }

          if (field.isEnum && field.enumValues.isNotEmpty) {
            final baseEnumName = type.replaceAll('?', '');
            for (final value in field.enumValues) {
              final capitalizedValue = value[0].toUpperCase() + value.substring(1);
              sb.writeln('  bool get is$capitalized$capitalizedValue => $fieldName == $baseEnumName.$value;');
            }
          }
        }
      }
    }

    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    // Generate if there are fields or subtypes
    return context.metadata.allFields.isNotEmpty || 
           context.metadata.explicitSubtypes.isNotEmpty;
  }
}
