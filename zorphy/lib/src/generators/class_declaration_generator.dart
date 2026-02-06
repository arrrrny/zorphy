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
    final implementsStr = _buildImplementsClause(metadata, config, isAbstract: true);

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
    final implementsStr =
        _buildImplementsClause(metadata, config, isAbstract: false);

    final sb = StringBuffer();

    // Add @JsonSerializable to concrete classes that need JSON serialization
    // Skip only for abstract classes (starts with $$) that have factory methods
    // because those abstract classes handle instantiation via factories
    final hasFactoryMethods = config.factoryMethods.isNotEmpty;
    final isAbstractClass = metadata.originalName.startsWith(r'$$');
    final shouldSkipJsonAnnotation = hasFactoryMethods && isAbstractClass;

    if (config.generateJson && !shouldSkipJsonAnnotation) {
      sb.writeln('@JsonSerializable(explicitToJson: ${config.explicitToJson})');
    }

    sb.writeln('class $className$genericsStr$extendsStr$implementsStr {');

    // Determine if class extends abstract parent
    final hasExtendsParam = extendsStr.isNotEmpty;
    final extendsAbstractClass = _determineExtendsAbstractClass(
      metadata,
      config,
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
    ClassMetadata metadata,
    GenerationConfig config, {
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
      final extendedParent = _getExtendedParentName(metadata, config);
      final clauseParts = interfaces
          .map((i) => _trimInterfaceName(i.interfaceName))
          .where(
            (name) => name.isNotEmpty && name != _trimInterfaceName(extendedParent),
          )
          .toList();

      // If we have factory methods and we didn't extend the annotated class, we should implement it
      if (config.factoryMethods.isNotEmpty &&
          metadata.originalName != extendedParent) {
        clauseParts.add(metadata.originalName);
      }

      final clause = clauseParts.join(', ');
      return clause.isNotEmpty ? ' implements $clause' : '';
    }
  }

  String _getExtendedParentName(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    // 1. Try to find a base class from interfaces (prioritize hierarchy)
    for (final iface in metadata.interfaces) {
      final name = iface.interfaceName;
      if (name.startsWith(r'$$') && !iface.isSealed) {
        return name;
      }
      if (name.startsWith(r'$') && !name.startsWith(r'$$')) {
        return name;
      }
    }

    // 2. If no parent interface to extend, check factory methods
    if (config.factoryMethods.isNotEmpty) {
      return metadata.originalName;
    }

    return '';
  }

  String _buildExtendsClause(ClassMetadata metadata, GenerationConfig config) {
    final parent = _getExtendedParentName(metadata, config);
    if (parent.isEmpty) return '';

    if (parent == metadata.originalName) {
      return ' extends $parent';
    }
    return ' extends ${_trimInterfaceName(parent)}';
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
    GenerationConfig config,
  ) {
    final parent = _getExtendedParentName(metadata, config);
    if (parent.isEmpty) return false;

    // $$ classes are always abstract base classes
    if (parent.startsWith(r'$$')) return true;

    // The annotated class itself ($Current) is always abstract in source
    if (parent == metadata.originalName) return true;

    // Single $ parents are concrete generated classes
    return false;
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
