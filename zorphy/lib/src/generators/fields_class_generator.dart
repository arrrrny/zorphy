import 'base_generator.dart';

/// Generates the static Fields class containing Field descriptors for the entity
class FieldsClassGenerator extends UniversalGenerator {
  /// Creates a generator for field descriptor classes.
  FieldsClassGenerator();

  @override
  /// Generates a Fields helper class for query construction.
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final className = metadata.cleanName;

    // Check if we should generate fields class
    // We only generate for concrete classes or abstract classes that serve as entities
    // But maybe for all? The user requirement E says "Zorphy generates only field descriptors per entity"

    if (metadata.allFields.isEmpty) return '';

    final hasGenerics = metadata.generics.isNotEmpty;
    final genericsArgsStr = hasGenerics
        ? '<${metadata.generics.map((g) => g.name).join(', ')}>'
        : '';
    final genericsDefStr = hasGenerics
        ? '<${metadata.generics.map((g) => g.bound != null ? '${g.name} extends ${g.bound}' : g.name).join(', ')}>'
        : '';
    final classType = '$className$genericsArgsStr';

    final sb = StringBuffer();
    sb.writeln('');
    sb.writeln('/// Field descriptors for [$className] query construction');
    sb.writeln('abstract final class ${className}Fields {');

    for (final field in metadata.allFields) {
      final fieldName = field.name;
      var fieldType = field.type;
      if (fieldType == null) {
        fieldType = 'dynamic';
      } else {
        fieldType = _cleanType(fieldType);
      }

      if (hasGenerics) {
        sb.writeln(
          '  static $fieldType _\$get$fieldName$genericsDefStr($classType e) => e.$fieldName;',
        );
        sb.writeln(
          '  static Field<$classType, $fieldType> $fieldName$genericsDefStr() => Field<$classType, $fieldType>(\'$fieldName\', _\$get$fieldName$genericsArgsStr);',
        );
      } else {
        sb.writeln(
          '  static $fieldType _\$get$fieldName($className e) => e.$fieldName;',
        );
        sb.writeln(
          '  static const $fieldName = Field<$className, $fieldType>(\'$fieldName\', _\$get$fieldName);',
        );
      }
    }

    sb.writeln('}');

    return sb.toString();
  }

  /// Removes $ and $$ prefixes from Zorphy entity types while preserving library prefixes
  String _cleanType(String type) {
    if (type.contains('<')) {
      // For generics, use a more robust approach (or just delegate if we had the helper)
      // Since this is a simple generator, let's just use the same logic as _replaceDollarTypesWithConcrete
      // but without the full recursive implementation for now, or just use a regex
      // Actually, replaceAll('$', '') is mostly fine UNLESS prefix has $.
      // Let's at least preserve prefix dots.
      if (!type.contains('.')) return type.replaceAll('\$', '');

      return type
          .split('.')
          .map((part) {
            if (part.contains('<')) {
              final base = part.substring(0, part.indexOf('<'));
              final rest = part.substring(part.indexOf('<'));
              return base.replaceAll('\$', '') + rest.replaceAll('\$', '');
            }
            return part.replaceAll('\$', '');
          })
          .join('.');
    }

    if (type.contains('.')) {
      final lastDot = type.lastIndexOf('.');
      final prefix = type.substring(0, lastDot + 1);
      final name = type.substring(lastDot + 1);
      return prefix + name.replaceAll('\$', '');
    }

    return type.replaceAll('\$', '');
  }

  @override
  /// Returns true when filter descriptors should be generated.
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateFilter &&
        context.metadata.allFields.isNotEmpty;
  }
}
