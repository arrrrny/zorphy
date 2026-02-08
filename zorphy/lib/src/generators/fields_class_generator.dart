import 'base_generator.dart';

/// Generates the static Fields class containing Field descriptors for the entity
class FieldsClassGenerator extends UniversalGenerator {
  FieldsClassGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final className = metadata.cleanName;

    // Check if we should generate fields class
    // We only generate for concrete classes or abstract classes that serve as entities
    // But maybe for all? The user requirement E says "Zorphy generates only field descriptors per entity"

    if (metadata.allFields.isEmpty) return '';

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

      // Generate a static getter for tear-off
      sb.writeln(
        '  static $fieldType _\$get$fieldName($className e) => e.$fieldName;',
      );

      // Use the static getter as a tear-off in the Field constructor
      sb.writeln(
        '  static const $fieldName = Field<$className, $fieldType>(\'$fieldName\', _\$get$fieldName);',
      );
    }

    sb.writeln('}');

    return sb.toString();
  }

  /// Removes $ and $$ prefixes from Zorphy entity types
  String _cleanType(String type) {
    // Strips all $ characters from the type string
    return type.replaceAll('\$', '');
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateFilter &&
        context.metadata.allFields.isNotEmpty;
  }
}
