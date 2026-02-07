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
      // Get the type string. Note that field.type might include nullability derived from analysis
      // We generally trust it.
      var fieldType = field.type;

      // If type is missing (dynamic), default to dynamic
      if (fieldType == null) fieldType = 'dynamic';

      // We use the clean class name for the TEntity parameter
      sb.writeln(
        '  static const $fieldName = Field<$className, $fieldType>(\'$fieldName\');',
      );
    }

    sb.writeln('}');

    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateFilter &&
        context.metadata.allFields.isNotEmpty;
  }
}
