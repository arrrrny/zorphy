import '../helpers.dart' as helpers;
import '../common/NameType.dart';
import '../models/class_metadata.dart';
import '../models/generation_config.dart';
import 'base_generator.dart';

/// Generates class declaration, properties, and constructor
/// This wraps the existing getProperties and getPropertiesAbstract functions
class ClassDeclarationGenerator extends UniversalGenerator {
  ClassDeclarationGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (metadata.isAbstract) {
      return _generateAbstractClass(metadata, config);
    } else {
      return _generateConcreteClass(metadata, config);
    }
  }

  String _generateAbstractClass(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.originalName.startsWith(r'$$')
        ? metadata.cleanName
        : '\$${metadata.cleanName}';

    final sealedModifier = metadata.nonSealed ? '' : 'sealed ';
    final abstractModifier = metadata.nonSealed ? 'abstract ' : '';

    // Build implements clause
    final implementsStr = _buildImplementsClause(metadata, isAbstract: true);

    final genericsStr = _buildGenericsString(metadata);

    final sb = StringBuffer();

    // For sealed classes with explicit subtypes, don't generate constructor
    final isSealedWithSubtypes =
        metadata.isSealed && metadata.explicitSubtypes.isNotEmpty;

    sb.writeln(
      '${sealedModifier}${abstractModifier}class $className$genericsStr$implementsStr {',
    );

    // Generate properties
    sb.writeln(
      helpers.getPropertiesAbstract(
        metadata.allFields,
        className,
        config.generateCopyWithFn,
        isSealedWithSubtypes: isSealedWithSubtypes,
      ),
    );

    return sb.toString();
  }

  String _generateConcreteClass(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.cleanName;
    final genericsStr = _buildGenericsString(metadata);

    // Determine extends and implements
    final extendsStr = _buildExtendsClause(metadata, config);
    final implementsStr = _buildImplementsClause(metadata, isAbstract: false);

    final sb = StringBuffer();
    sb.writeln('class $className$genericsStr$extendsStr$implementsStr {');

    // Determine if class extends abstract parent
    final hasExtendsParam = extendsStr.isNotEmpty;
    final extendsAbstractClass = _determineExtendsAbstractClass(metadata, extendsStr);

    // Get parent fields if extending a concrete parent
    final parentFields = _getParentFields(metadata, extendsStr, extendsAbstractClass);

    // All fields from parent interfaces (for @override detection)
    final allParentInterfaceFields = <String>{};
    for (final iface in metadata.interfaces) {
      allParentInterfaceFields.addAll(iface.fields.map((f) => f.name));
    }

    // Generate properties and constructor
    sb.writeln(
      helpers.getProperties(
        metadata.allFields,
        className,
        false,
        config.hidePublicConstructor,
        config.generateCopyWithFn,
        config.generateJson,
        hasExtendsParam,
        extendsAbstractClass: extendsAbstractClass,
        parentFields: parentFields,
        ownFields: metadata.ownFieldNames,
        allInheritedFields: allParentInterfaceFields,
      ),
    );

    return sb.toString();
  }

  String _buildGenericsString(ClassMetadata metadata) {
    if (metadata.generics.isEmpty) return '';
    // Convert GenericParameterMetadata to NameTypeClassComment format
    final genericsAsNameType = metadata.generics.map((g) {
      return NameTypeClassComment(g.name, g.bound, null);
    }).toList();
    return '<${genericsAsNameType.map((g) => g.toString()).join(', ')}>';
  }

  String _buildImplementsClause(ClassMetadata metadata, {required bool isAbstract}) {
    final interfaces = metadata.interfaces;

    if (isAbstract) {
      // Abstract class implements its interfaces
      final clause = interfaces
          .map((i) => i.interfaceName)
          .where((name) => name.isNotEmpty)
          .join(', ');
      return clause.isNotEmpty ? ' implements $clause' : '';
    } else {
      // Concrete class logic - simplified version
      // This will need to be expanded to handle factory methods and sealed parents
      final clause = interfaces
          .map((i) => _trimInterfaceName(i.interfaceName))
          .where((name) => name.isNotEmpty)
          .join(', ');
      return clause.isNotEmpty ? ' implements $clause' : '';
    }
  }

  String _buildExtendsClause(ClassMetadata metadata, GenerationConfig config) {
    // For concrete classes, determine what to extend
    // This is complex logic from createZorphy that handles:
    // - Factory methods
    // - Sealed parents
    // - Abstract parents
    // - Multiple interfaces

    // For now, return empty string and will be filled in properly
    // when we integrate the full logic from createZorphy
    return '';
  }

  String _trimInterfaceName(String name) {
    if (name.startsWith(r'$$')) return name.substring(2);
    if (name.startsWith(r'$')) return name.substring(1);
    return name;
  }

  bool _determineExtendsAbstractClass(ClassMetadata metadata, String extendsStr) {
    // Check if we're extending an abstract parent
    // This logic will be expanded when integrating with createZorphy
    return false;
  }

  Set<String> _getParentFields(
    ClassMetadata metadata,
    String extendsStr,
    bool extendsAbstractClass,
  ) {
    // Get parent fields if extending a concrete parent
    // This logic will be expanded when integrating with createZorphy
    return {};
  }
}
