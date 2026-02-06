import '../helpers.dart' as helpers;

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

    // Don't add @JsonSerializable if:
    // 1. There are factory methods (abstract parent handles JSON)
    if (config.generateJson && config.factoryMethods.isEmpty) {
      sb.writeln('@JsonSerializable(explicitToJson: ${config.explicitToJson})');
    }

    sb.writeln('class $className$genericsStr$extendsStr$implementsStr {');

    // Determine if class extends abstract parent
    final hasExtendsParam = extendsStr.isNotEmpty;
    final extendsAbstractClass = _determineExtendsAbstractClass(
      metadata,
      extendsStr,
    );

    // Determine if we're extending a concrete parent
    final parentConcreteClassName = _getConcreteParentName(metadata);
    final hasConcreteParent = parentConcreteClassName != null;

    // When extending a concrete parent, we still generate all fields
    // but we need to track which ones belong to the parent for the super call
    final fieldsToGenerate = metadata.allFields;

    // Get parent fields that need to be passed to super constructor
    final parentFields = hasConcreteParent
        ? _getParentFieldsForSuper(metadata, metadata.ownFieldNames)
        : <String>{};

    // All fields from parent interfaces (for @override detection)
    final allParentInterfaceFields = <String>{};
    for (final iface in metadata.interfaces) {
      allParentInterfaceFields.addAll(iface.fields.map((f) => f.name));
    }

    // Generate properties and constructor
    sb.writeln(
      helpers.getProperties(
        fieldsToGenerate,
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
    final parts = metadata.generics
        .map((g) {
          if (g.bound != null && g.bound!.isNotEmpty) {
            return '${g.name} extends ${g.bound}';
          }
          return g.name;
        })
        .join(', ');
    return '<$parts>';
  }

  String _buildImplementsClause(
    ClassMetadata metadata, {
    required bool isAbstract,
  }) {
    final interfaces = metadata.interfaces;

    if (isAbstract) {
      // Abstract class implements its interfaces
      final clause = interfaces
          .map((i) => i.interfaceName)
          .where((name) => name.isNotEmpty)
          .join(', ');
      return clause.isNotEmpty ? ' implements $clause' : '';
    } else {
      // Concrete class - exclude the extended parent from implements
      final extendedParent = _getExtendedParentName(metadata);
      final clause = interfaces
          .map((i) => _trimInterfaceName(i.interfaceName))
          .where((name) => name.isNotEmpty && name != extendedParent)
          .join(', ');
      return clause.isNotEmpty ? ' implements $clause' : '';
    }
  }

  String _getExtendedParentName(ClassMetadata metadata) {
    // Check what we're extending
    for (final iface in metadata.interfaces) {
      final name = iface.interfaceName;
      if (name.startsWith(r'$$') && !iface.isSealed) {
        return _trimInterfaceName(name);
      }
      if (name.startsWith(r'$') && !name.startsWith(r'$$')) {
        return _trimInterfaceName(name);
      }
    }
    return '';
  }

  String _buildExtendsClause(ClassMetadata metadata, GenerationConfig config) {
    // If there are factory methods, extend the abstract parent class
    if (config.factoryMethods.isNotEmpty) {
      // Find the abstract parent (the class being defined, e.g., $AssistantMessage)
      final abstractName = metadata.originalName; // e.g., $AssistantMessage
      return ' extends $abstractName';
    }

    // No factory methods - check if we should extend a parent interface
    for (final iface in metadata.interfaces) {
      final name = iface.interfaceName;
      if (name.startsWith(r'$$') && !iface.isSealed) {
        // Non-sealed abstract parent - extend it
        return ' extends ${_trimInterfaceName(name)}';
      }
      if (name.startsWith(r'$') && !name.startsWith(r'$$')) {
        // Single-$ parent - extend it (could be abstract or concrete)
        return ' extends ${_trimInterfaceName(name)}';
      }
    }

    return '';
  }

  /// Check if the class extends a concrete parent (not just an abstract interface)
  String? _getConcreteParentName(ClassMetadata metadata) {
    // Find the concrete parent we're extending
    for (final iface in metadata.interfaces) {
      final name = iface.interfaceName;
      // Check if this is a single-$ prefix (concrete class marker)
      if (name.startsWith(r'$') && !name.startsWith(r'$$')) {
        final trimmedName = _trimInterfaceName(name);
        // Check if the parent class name doesn't start with $$ (i.e., it's concrete, not abstract)
        // We need to look up the parent's metadata
        final parentElement = metadata.allAnnotatedClasses[trimmedName];
        if (parentElement != null) {
          final parentIsAbstract =
              parentElement.name?.startsWith(r'$$') ?? false;
          if (!parentIsAbstract) {
            return trimmedName;
          }
        }
        // If we can't determine, assume it could be concrete
        return trimmedName;
      }
    }
    return null;
  }

  String _trimInterfaceName(String name) {
    if (name.startsWith(r'$$')) return name.substring(2);
    if (name.startsWith(r'$')) return name.substring(1);
    return name;
  }

  bool _determineExtendsAbstractClass(
    ClassMetadata metadata,
    String extendsStr,
  ) {
    // If we have factory methods, we're extending the abstract parent
    return extendsStr.contains(r'$');
  }

  Set<String> _getParentFieldsForSuper(
    ClassMetadata metadata,
    Set<String> ownFieldNames,
  ) {
    // Get parent fields that need to be passed to super constructor
    // These are fields in allFields that are NOT own fields
    final parentFields = <String>{};

    for (final field in metadata.allFields) {
      if (!ownFieldNames.contains(field.name)) {
        parentFields.add(field.name);
      }
    }

    return parentFields;
  }
}
