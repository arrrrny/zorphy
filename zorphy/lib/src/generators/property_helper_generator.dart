import 'base_generator.dart';

/// Generates semantic property helpers (hasField, isSubtype, etc.)
class PropertyHelperGenerator extends UniversalGenerator {
  PropertyHelperGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();

    // 1. Polymorphic helpers (Pattern 2)
    // Common for both abstract and concrete classes if they have subtypes
    if (metadata.explicitSubtypes.isNotEmpty) {
      sb.writeln('  // Polymorphic helpers');
      for (final subtype in metadata.explicitSubtypes) {
        final subtypeName = subtype.interfaceName.replaceAll(r'$', '');
        sb.writeln('  bool get is$subtypeName => this is $subtypeName;');
        sb.writeln(
          '  $subtypeName? get as$subtypeName => this is $subtypeName ? this as $subtypeName : null;',
        );
      }
      sb.writeln('');
    }

    // 2. Field-specific helpers (Patterns 1, 3, 4)
    // These are typically for concrete classes where fields have values
    if (!metadata.isAbstract) {
      final nullableFields = metadata.allFields.where((f) => f.type?.endsWith('?') ?? false);
      final collectionFields = metadata.allFields.where((f) => 
        f.type != null && (
          f.type!.startsWith('List<') || 
          f.type!.startsWith('Map<') || 
          f.type!.startsWith('Set<')
        )
      );

      if (nullableFields.isNotEmpty || collectionFields.isNotEmpty) {
        sb.writeln('  // Property helpers');
      }

      for (final field in metadata.allFields) {
        var type = field.type ?? 'dynamic';
        
        // Strip Zorphy prefixes ($ and $$) to get the public type name
        type = type.replaceAll('\$', '');
        
        final fieldName = field.name;
        final isNullable = type.endsWith('?');
        final isCollection = type.startsWith('List<') || type.startsWith('Map<') || type.startsWith('Set<');
        
        final baseName = fieldName.startsWith('_') ? fieldName.substring(1) : fieldName;
        final capitalized = baseName[0].toUpperCase() + baseName.substring(1);

        if (isNullable && !isCollection) {
           // Pattern 1 & 4 (Only if NOT a collection, collections use Pattern 3 below)
           sb.writeln('  bool get has$capitalized => $fieldName != null;');
           sb.writeln('  bool get no$capitalized => $fieldName == null;');
           
           final nonNullableType = type.substring(0, type.length - 1);
           sb.writeln('  $nonNullableType get ${baseName}Required => $fieldName ?? (throw StateError(\'$fieldName is required but was null\'));');
        } else if (isNullable && isCollection) {
           // Pattern 4 still useful for collections
           final nonNullableType = type.substring(0, type.length - 1);
           sb.writeln('  $nonNullableType get ${baseName}Required => $fieldName ?? (throw StateError(\'$fieldName is required but was null\'));');
        }

        if (isCollection) {
          // Pattern 3
          if (!isNullable) {
            sb.writeln('  bool get has$capitalized => $fieldName.isNotEmpty;');
            sb.writeln('  bool get no$capitalized => $fieldName.isEmpty;');
          } else {
            // If nullable list/map/set
            sb.writeln('  bool get has$capitalized => $fieldName?.isNotEmpty ?? false;');
            sb.writeln('  bool get no$capitalized => $fieldName?.isEmpty ?? true;');
          }
        }

        if (field.isEnum && field.enumValues.isNotEmpty) {
          final baseEnumName = type.replaceAll('?', '');
          for (final value in field.enumValues) {
            final capitalizedValue = value[0].toUpperCase() + value.substring(1);
            sb.writeln(
              '  bool get is$capitalized$capitalizedValue => $fieldName == $baseEnumName.$value;',
            );
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
