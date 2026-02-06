import '../models/class_metadata.dart';
import '../models/generation_config.dart';
import 'base_generator.dart';

/// Generates JSON serialization methods
/// This is complex and handles both toJson/fromJson and polymorphic JSON
/// Wraps the logic from createZorphy lines 346-488
class JsonGenerator extends UniversalGenerator {
  JsonGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (!config.generateJson) {
      return '';
    }

    final sb = StringBuffer();

    // Determine if we should generate JSON
    final shouldGenerateJson =
        !metadata.isAbstract && metadata.explicitSubtypes.isEmpty;
    final shouldGeneratePolymorphicJson = metadata.explicitSubtypes.isNotEmpty;

    if (shouldGenerateJson || shouldGeneratePolymorphicJson) {
      // Generate fromJson factory constructor
      sb.writeln(_generateFromJson(metadata, config));
      sb.writeln(_generateToJsonLean(metadata, config));
    }

    // For concrete classes in a parent's explicitSubTypes, also generate toJson with _className_
    // This is needed even if the class has its own explicitSubTypes (polymorphic)
    if (!metadata.isAbstract && metadata.isInParentExplicitSubtypes) {
      sb.writeln(_generateToJsonWithDiscriminator(metadata));
    }

    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateJson;
  }

  String _generateFromJson(ClassMetadata metadata, GenerationConfig config) {
    final sb = StringBuffer();
    final className = metadata.cleanName;
    //final genericsStr = _buildGenericsString(metadata);

    if (metadata.explicitSubtypes.isEmpty && metadata.generics.isEmpty) {
      // Simple case - no generics, no explicit subtypes
      sb.writeln('');
      sb.writeln('  /// Creates a [$className] instance from JSON');
      sb.writeln(
        '  factory $className.fromJson(Map<String, dynamic> json) => _\$$className' +
            'FromJson(json);',
      );
    } else if (metadata.explicitSubtypes.isNotEmpty) {
      // Abstract class with explicit subtypes - polymorphic JSON
      sb.writeln(_generatePolymorphicFromJson(metadata, config));
    } else {
      // Generics without explicit subtypes
      sb.writeln(_generateGenericFromJson(metadata, config));
    }

    return sb.toString();
  }

  String _generatePolymorphicFromJson(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final sb = StringBuffer();
    final className = metadata.cleanName;

    sb.writeln('');
    sb.writeln('  /// Creates a [$className] instance from JSON');
    sb.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');

    // For concrete classes in parent's explicitSubTypes, check if _className_ is null first
    // This handles parsing the class itself when there's no discriminator
    final hasSelfCase =
        !metadata.isAbstract && metadata.isInParentExplicitSubtypes;
    final totalCases = metadata.explicitSubtypes.length + (hasSelfCase ? 1 : 0);
    var caseIndex = 0;

    if (hasSelfCase) {
      sb.writeln(
        '    if (json[\'_className_\'] == null || json[\'_className_\'] == "$className") {',
      );
      sb.writeln('      return _\$${className}FromJson(json);');
      caseIndex++;
    }

    for (var i = 0; i < metadata.explicitSubtypes.length; i++) {
      final subtype = metadata.explicitSubtypes[i];
      final interfaceName = subtype.interfaceName.replaceAll(r'$', '');
      final genericTypes = subtype.typeParams
          .map((e) => "'_${e.name}_'")
          .join(',');
      final isLast = caseIndex == totalCases - 1;
      final prefix = caseIndex == 0 ? 'if' : '} else if';

      if (subtype.typeParams.isNotEmpty) {
        sb.writeln('    $prefix (json[\'_className_\'] == "$interfaceName") {');
        sb.writeln('      var fn_fromJson = getFromJsonToGenericFn(');
        sb.writeln('        ${interfaceName}_Generics_Sing().fns,');
        sb.writeln('        json,');
        sb.writeln('        [$genericTypes],');
        sb.writeln('      );');
        sb.writeln('      return fn_fromJson(json);');
      } else {
        sb.writeln('    $prefix (json[\'_className_\'] == "$interfaceName") {');
        sb.writeln('      return $interfaceName.fromJson(json);');
      }

      if (isLast) {
        sb.writeln('    }');
      }
      caseIndex++;
    }

    sb.writeln(
      '    throw UnsupportedError("The _className_ \' + '
              r"${json['_className_']}" +
          '\' is not supported by the $className.fromJson constructor.");',
    );
    sb.writeln('  }');

    // For non-sealed abstract classes, also generate toJson
    if (metadata.nonSealed) {
      sb.writeln('');
      sb.writeln('  Map<String, dynamic> toJson() {');
      sb.writeln(
        '    if (this is ${metadata.explicitSubtypes[0].interfaceName.replaceAll(r'$', '')}) {',
      );
      sb.writeln(
        '      return (this as ${metadata.explicitSubtypes[0].interfaceName.replaceAll(r'$', '')}).toJson();',
      );

      for (var i = 1; i < metadata.explicitSubtypes.length; i++) {
        final subtype = metadata.explicitSubtypes[i].interfaceName.replaceAll(
          r'$',
          '',
        );
        sb.writeln('    } else if (this is $subtype) {');
        sb.writeln('      return (this as $subtype).toJson();');
      }

      sb.writeln('    }');
      sb.writeln(
        '    throw UnsupportedError("Unknown subtype: \$runtimeType");',
      );
      sb.writeln('  }');
    }

    return sb.toString();
  }

  String _generateGenericFromJson(
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final sb = StringBuffer();
    final className = metadata.cleanName;

    final fromJsonParams = metadata.generics
        .map(
          (g) => 'T Function(Object? json) fromJson${g.name}'.replaceAll(
            'T',
            g.name,
          ),
        )
        .join(', ');
    final fromJsonArgs = metadata.generics
        .map((g) => 'fromJson${g.name}')
        .join(', ');

    sb.writeln('');
    sb.writeln('  /// Creates a [$className] instance from JSON');
    sb.writeln(
      '  factory $className.fromJson(Map<String, dynamic> json, $fromJsonParams) => _\$$className' +
          'FromJson(json, $fromJsonArgs);',
    );

    return sb.toString();
  }

  String _generateToJsonLean(ClassMetadata metadata, GenerationConfig config) {
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Don't generate toJsonLean for sealed classes or abstract classes with subtypes
    if (metadata.isAbstract && metadata.explicitSubtypes.isNotEmpty) {
      return '';
    }

    if (!metadata.isAbstract) {
      sb.writeln('');
      if (metadata.generics.isEmpty) {
        sb.writeln('  Map<String, dynamic> toJsonLean() {');
        sb.writeln(
          '    final Map<String, dynamic> data = _\$$className' +
              'ToJson(this);',
        );
      } else {
        final toJsonParams = metadata.generics
            .map(
              (g) => 'Object? Function(T value) toJson${g.name}'.replaceAll(
                'T',
                g.name,
              ),
            )
            .join(', ');
        final toJsonArgs = metadata.generics
            .map((g) => 'toJson${g.name}')
            .join(', ');
        sb.writeln('  Map<String, dynamic> toJsonLean($toJsonParams) {');
        sb.writeln(
          '    final Map<String, dynamic> data = _\$$className' +
              'ToJson(this, $toJsonArgs);',
        );
      }
      sb.writeln('    return _sanitizeJson(data);');
      sb.writeln('  }');
      sb.writeln('');
      sb.writeln('  dynamic _sanitizeJson(dynamic json) {');
      sb.writeln('    if (json is Map<String, dynamic>) {');
      sb.writeln('      json.remove(\'_className_\');');
      sb.writeln('      return json..forEach((key, value) {');
      sb.writeln('        json[key] = _sanitizeJson(value);');
      sb.writeln('      });');
      sb.writeln('    } else if (json is List) {');
      sb.writeln('      return json.map((e) => _sanitizeJson(e)).toList();');
      sb.writeln('    }');
      sb.writeln('    return json;');
      sb.writeln('  }');
    }

    return sb.toString();
  }

  /// Generate toJson method with _className_ discriminator for classes in parent's explicitSubTypes
  String _generateToJsonWithDiscriminator(ClassMetadata metadata) {
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Generate toJson method with _className_ discriminator
    sb.writeln('');
    sb.writeln('  Map<String, dynamic> toJson() {');
    sb.writeln('    final json = _\$$className' + 'ToJson(this);');
    sb.writeln('    json[\'_className_\'] = \'$className\';');
    sb.writeln('    return json;');
    sb.writeln('  }');

    return sb.toString();
  }

  // String _buildGenericsString(ClassMetadata metadata) {
  //   if (metadata.generics.isEmpty) return '';
  //   return '<${metadata.generics.map((g) => g.toString()).join(', ')}>';
  // }
}

/// Generates JSON extension for concrete classes
class JsonExtensionGenerator extends ConcreteClassGenerator {
  JsonExtensionGenerator();

  @override
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (!config.generateJson) {
      return '';
    }

    final className = metadata.cleanName;
    final genericsStr = _buildGenericsString(metadata);
    final sb = StringBuffer();

    sb.writeln('');
    sb.writeln(
      'extension ${className}Serialization$genericsStr on $className$genericsStr {',
    );

    if (metadata.generics.isEmpty) {
      sb.writeln(
        '  Map<String, dynamic> toJson() => _\$$className' + 'ToJson(this);',
      );
    } else {
      final toJsonParams = metadata.generics
          .map((g) => 'Object? Function(${g.name} value) toJson${g.name}')
          .join(', ');
      final toJsonArgs = metadata.generics
          .map((g) => 'toJson${g.name}')
          .join(', ');
      sb.writeln(
        '  Map<String, dynamic> toJson($toJsonParams) => _\$$className' +
            'ToJson(this, $toJsonArgs);',
      );
    }
    if (metadata.generics.isEmpty) {
      sb.writeln('  Map<String, dynamic> toJsonLean() {');
      sb.writeln(
        '    final Map<String, dynamic> data = _\$$className' + 'ToJson(this);',
      );
    } else {
      final toJsonParams = metadata.generics
          .map((g) => 'Object? Function(${g.name} value) toJson${g.name}')
          .join(', ');
      final toJsonArgs = metadata.generics
          .map((g) => 'toJson${g.name}')
          .join(', ');
      sb.writeln('  Map<String, dynamic> toJsonLean($toJsonParams) {');
      sb.writeln(
        '    final Map<String, dynamic> data = _\$$className' +
            'ToJson(this, $toJsonArgs);',
      );
    }
    sb.writeln('    return _sanitizeJson(data);');
    sb.writeln('  }');
    sb.writeln('');
    sb.writeln('  dynamic _sanitizeJson(dynamic json) {');
    sb.writeln('    if (json is Map<String, dynamic>) {');
    sb.writeln('      json.remove(\'_className_\');');
    sb.writeln('      return json..forEach((key, value) {');
    sb.writeln('        json[key] = _sanitizeJson(value);');
    sb.writeln('      });');
    sb.writeln('    } else if (json is List) {');
    sb.writeln('      return json.map((e) => _sanitizeJson(e)).toList();');
    sb.writeln('    }');
    sb.writeln('    return json;');
    sb.writeln('  }');
    sb.writeln('}');

    return sb.toString();
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    // Don't generate extension if class has explicitSubTypes (polymorphic toJson is in the class itself)
    // Classes in parent's explicitSubTypes are now handled by JsonGenerator, not this extension
    return context.config.generateJson &&
        context.metadata.explicitSubtypes.isEmpty;
  }

  String _buildGenericsString(ClassMetadata metadata) {
    if (metadata.generics.isEmpty) return '';
    return '<${metadata.generics.map((g) => g.toString()).join(', ')}>';
  }
}
