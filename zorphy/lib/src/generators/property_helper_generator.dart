import 'base_generator.dart';

/// Generates semantic property helpers (hasField, isSubtype, etc.)
class PropertyHelperGenerator extends UniversalGenerator {
  /// Creates a generator for property helper extensions.
  PropertyHelperGenerator();

  @override
  /// Generates property helper extensions for the class.
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final sb = StringBuffer();

    // 1. Polymorphic helpers (isSubtype, asSubtype)
    // ONLY for the class that defines the explicit subtypes (to avoid duplicates and import issues)
    if (metadata.explicitSubtypes.isNotEmpty) {
      final genericsStr = metadata.generics.isEmpty
          ? ''
          : '<${metadata.generics.map((g) => g.name).join(', ')}>';
      final genericsDefStr = metadata.generics.isEmpty
          ? ''
          : '<${metadata.generics.map((g) => g.bound != null ? '${g.name} extends ${g.bound}' : g.name).join(', ')}>';

      sb.writeln(
        'extension ${metadata.cleanName}PolymorphicE$genericsDefStr on ${metadata.cleanName}$genericsStr {',
      );
      for (final subtype in metadata.explicitSubtypes) {
        final subtypeName = subtype.interfaceName.replaceAll(r'$', '');
        if (metadata.cleanName != subtypeName) {
          sb.writeln('  bool get is$subtypeName => this is $subtypeName;');
          sb.writeln(
            '  $subtypeName? get as$subtypeName => this is $subtypeName ? this as $subtypeName : null;',
          );
        }
      }
      sb.writeln('}');
      sb.writeln('');
    }

    // 2. Field-specific helpers (hasField, noField, Required, isEnumValue)
    // Wrap these in an extension so they are available on the class without pollulting it or requiring implementation
    final ownFields = metadata.allFields
        .where((f) => metadata.ownFieldNames.contains(f.name))
        .toList();
    if (ownFields.isNotEmpty) {
      final genericsStr = metadata.generics.isEmpty
          ? ''
          : '<${metadata.generics.map((g) => g.name).join(', ')}>';
      final genericsDefStr = metadata.generics.isEmpty
          ? ''
          : '<${metadata.generics.map((g) => g.bound != null ? '${g.name} extends ${g.bound}' : g.name).join(', ')}>';

      sb.writeln(
        'extension ${metadata.cleanName}PropertyHelpers$genericsDefStr on ${metadata.cleanName}$genericsStr {',
      );

      for (final field in ownFields) {
        var type = field.type ?? 'dynamic';
        type = type.replaceAll(r'$', '');

        final fieldName = field.name;
        final isNullable = type.endsWith('?');
        final isCollection =
            type.startsWith('List<') ||
            type.startsWith('Map<') ||
            type.startsWith('Set<');

        final baseName = fieldName.startsWith('_')
            ? fieldName.substring(1)
            : fieldName;
        final capitalized = baseName[0].toUpperCase() + baseName.substring(1);

        final isString = type.replaceAll('?', '') == 'String';

        if (isNullable && !isCollection && !isString) {
          sb.writeln('  bool get has$capitalized => $fieldName != null;');
          sb.writeln('  bool get no$capitalized => $fieldName == null;');
          final nonNullableType = type.substring(0, type.length - 1);
          sb.writeln(
            '  $nonNullableType get ${baseName}Required => $fieldName ?? (throw StateError(\'$fieldName is required but was null\'));',
          );
        } else if (isNullable && isCollection) {
          final nonNullableType = type.substring(0, type.length - 1);
          sb.writeln(
            '  $nonNullableType get ${baseName}Required => $fieldName ?? (throw StateError(\'$fieldName is required but was null\'));',
          );
        }

        if (isString) {
          if (isNullable) {
            sb.writeln(
              '  bool get has$capitalized => $fieldName?.isNotEmpty == true;',
            );
            sb.writeln(
              '  bool get no$capitalized => $fieldName?.isEmpty ?? true;',
            );
            final nonNullableType = type.substring(0, type.length - 1);
            sb.writeln(
              '  $nonNullableType get ${baseName}Required => $fieldName ?? (throw StateError(\'$fieldName is required but was null\'));',
            );
          } else {
            sb.writeln('  bool get has$capitalized => $fieldName.isNotEmpty;');
            sb.writeln('  bool get no$capitalized => $fieldName.isEmpty;');
          }
        }

        if (isCollection) {
          if (!isNullable) {
            sb.writeln('  bool get has$capitalized => $fieldName.isNotEmpty;');
            sb.writeln('  bool get no$capitalized => $fieldName.isEmpty;');
          } else {
            sb.writeln(
              '  bool get has$capitalized => $fieldName?.isNotEmpty ?? false;',
            );
            sb.writeln(
              '  bool get no$capitalized => $fieldName?.isEmpty ?? true;',
            );
          }
        }

        if (field.isEnum && field.enumValues.isNotEmpty) {
          final baseEnumName = type.replaceAll('?', '');
          for (final value in field.enumValues) {
            final capitalizedValue =
                value[0].toUpperCase() + value.substring(1);
            sb.writeln(
              '  bool get is$capitalized$capitalizedValue => $fieldName == $baseEnumName.$value;',
            );
          }
        }
      }
      sb.writeln('}');
    }

    return sb.toString();
  }

  @override
  /// Returns true when property helpers are enabled and there are fields
  /// or subtypes to support.
  bool shouldGenerate(GenerationContext context) {
    if (!context.config.generatePropertyHelpers) return false;
    // Generate if there are fields or subtypes
    return context.metadata.allFields.isNotEmpty ||
        context.metadata.polymorphicSubtypes.isNotEmpty;
  }
}
