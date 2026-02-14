import '../common/NameType.dart';
import '../models/class_metadata.dart';
import '../models/generation_config.dart';
import 'base_generator.dart';

/// Generates JSON serialization methods
/// This is complex and handles both toJson/fromJson and polymorphic JSON
/// Wraps the logic from createZorphy lines 346-488
class JsonGenerator extends UniversalGenerator {
  /// Creates a generator for JSON serialization members.
  JsonGenerator();

  @override
  /// Generates fromJson/toJson-related members for the class.
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
  /// Returns true when JSON generation is enabled.
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateJson;
  }

  String _generateFromJson(ClassMetadata metadata, GenerationConfig config) {
    final sb = StringBuffer();
    final className = metadata.cleanName;
    //final genericsStr = _buildGenericsString(metadata);

    if (metadata.explicitSubtypes.isEmpty && metadata.generics.isEmpty) {
      // Simple case - no generics, no explicit subtypes
      final manualFromJsonFields = _getManualFromJsonFields(metadata);
      sb.writeln('');
      sb.writeln('  /// Creates a [$className] instance from JSON');
      if (manualFromJsonFields.isEmpty) {
        sb.writeln(
          '  factory $className.fromJson(Map<String, dynamic> json) => _\$$className' +
              'FromJson(json);',
        );
      } else {
        sb.writeln(
          '  factory $className.fromJson(Map<String, dynamic> json) {',
        );
        sb.writeln('    final instance = _\$$className' + 'FromJson(json);');
        sb.writeln('    return $className(');
        for (var f in metadata.allFields) {
          final manualField = manualFromJsonFields.where(
            (m) => m.name == f.name,
          );
          if (manualField.isNotEmpty) {
            final info = manualField.first.jsonKeyInfo!;
            final jsonFieldName = info.name ?? f.name;
            sb.writeln(
              '      ${f.name}: json[\'$jsonFieldName\'] != null ? ${info.fromJson}(json[\'$jsonFieldName\'] as Map<String, dynamic>) as ${f.type} : null,',
            );
          } else {
            sb.writeln('      ${f.name}: instance.${f.name},');
          }
        }
        sb.writeln('    );');
        sb.writeln('  }');
      }
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

    // For concrete classes, check if _className_ is null or matches self first
    // This handles: (1) classes in parent's explicitSubTypes, and
    // (2) concrete classes that define their own explicitSubTypes (nonSealed base classes)
    final hasSelfCase =
        !metadata.isAbstract &&
        (metadata.isInParentExplicitSubtypes || metadata.nonSealed);
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

    // For nonSealed classes with explicitSubTypes, generate toJson dispatcher
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

      if (metadata.isAbstract) {
        sb.writeln(
          '    throw UnsupportedError("Unknown subtype: \$runtimeType");',
        );
      } else {
        // Concrete base class — serialize itself with discriminator
        sb.writeln(
          '    final json = _\$${className}ToJson(this);',
        );
        sb.writeln("    json['_className_'] = '$className';");
        sb.writeln('    return json;');
      }
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

    // Check for fields excluded from json_serializable that have manual converters
    final manualFromJsonFields = _getManualFromJsonFields(metadata);

    sb.writeln('');
    sb.writeln('  /// Creates a [$className] instance from JSON');
    if (manualFromJsonFields.isEmpty) {
      sb.writeln(
        '  factory $className.fromJson(Map<String, dynamic> json, $fromJsonParams) => _\$$className' +
            'FromJson(json, $fromJsonArgs);',
      );
    } else {
      sb.writeln(
        '  factory $className.fromJson(Map<String, dynamic> json, $fromJsonParams) {',
      );
      sb.writeln(
        '    final instance = _\$$className' + 'FromJson(json, $fromJsonArgs);',
      );
      sb.writeln('    return $className(');
      for (var f in metadata.allFields) {
        final manualField = manualFromJsonFields.where((m) => m.name == f.name);
        if (manualField.isNotEmpty) {
          final info = manualField.first.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          sb.writeln(
            '      ${f.name}: json[\'$jsonFieldName\'] != null ? ${info.fromJson}(json[\'$jsonFieldName\'] as Map<String, dynamic>) as ${f.type} : null,',
          );
        } else {
          sb.writeln('      ${f.name}: instance.${f.name},');
        }
      }
      sb.writeln('    );');
      sb.writeln('  }');
    }

    return sb.toString();
  }

  String _generateToJsonLean(ClassMetadata metadata, GenerationConfig config) {
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Don't generate toJsonLean for sealed classes or abstract classes with subtypes
    if (metadata.isAbstract && metadata.explicitSubtypes.isNotEmpty) {
      return '';
    }

    // Don't generate toJsonLean in the class body for generic classes that extend
    // a non-generic parent — the parent already defines toJsonLean() with no params,
    // and adding params would be an invalid override. The extension handles it instead.
    if (metadata.generics.isNotEmpty && _hasNonGenericJsonParent(metadata)) {
      return '';
    }

    final manualToJsonFields = _getManualToJsonFields(metadata);

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
      // Add manual toJson fields
      for (var f in manualToJsonFields) {
        final info = f.jsonKeyInfo!;
        final jsonFieldName = info.name ?? f.name;
        sb.writeln(
          '    if (${f.name} != null) data[\'$jsonFieldName\'] = ${info.toJson}(${f.name}!);',
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

  /// Whether this generic class extends a non-generic parent that would have
  /// toJsonLean()/toJson() with no generic params (causing override conflicts).
  bool _hasNonGenericJsonParent(ClassMetadata metadata) {
    for (final iface in metadata.interfaces) {
      if (iface.typeParams.isEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Fields excluded from json_serializable but having manual fromJson converters
  List<NameTypeClassComment> _getManualFromJsonFields(ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      if (info == null) return false;
      return info.includeFromJson == false && info.fromJson != null;
    }).toList();
  }

  /// Fields excluded from json_serializable but having manual toJson converters
  List<NameTypeClassComment> _getManualToJsonFields(ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      if (info == null) return false;
      return info.includeToJson == false && info.toJson != null;
    }).toList();
  }
}

/// Generates JSON extension for concrete classes
class JsonExtensionGenerator extends ConcreteClassGenerator {
  /// Creates a generator for JSON extension helpers.
  JsonExtensionGenerator();

  @override
  /// Generates JSON helper extensions for the class.
  String generate(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;

    if (!config.generateJson) {
      return '';
    }

    final className = metadata.cleanName;
    final genericsStr = _buildGenericsString(metadata);
    final sb = StringBuffer();

    final manualToJsonFields = _getManualToJsonFields(metadata);

    sb.writeln('');
    sb.writeln(
      'extension ${className}Serialization$genericsStr on $className$genericsStr {',
    );

    if (metadata.generics.isEmpty) {
      if (manualToJsonFields.isEmpty) {
        sb.writeln(
          '  Map<String, dynamic> toJson() => _\$$className' + 'ToJson(this);',
        );
      } else {
        sb.writeln('  Map<String, dynamic> toJson() {');
        sb.writeln('    final data = _\$$className' + 'ToJson(this);');
        for (var f in manualToJsonFields) {
          final info = f.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          sb.writeln(
            '    if (${f.name} != null) data[\'$jsonFieldName\'] = ${info.toJson}(${f.name}!);',
          );
        }
        sb.writeln('    return data;');
        sb.writeln('  }');
      }
    } else {
      final toJsonParams = metadata.generics
          .map((g) => 'Object? Function(${g.name} value) toJson${g.name}')
          .join(', ');
      final toJsonArgs = metadata.generics
          .map((g) => 'toJson${g.name}')
          .join(', ');
      if (manualToJsonFields.isEmpty) {
        sb.writeln(
          '  Map<String, dynamic> toJson($toJsonParams) => _\$$className' +
              'ToJson(this, $toJsonArgs);',
        );
      } else {
        sb.writeln('  Map<String, dynamic> toJson($toJsonParams) {');
        sb.writeln(
          '    final data = _\$$className' + 'ToJson(this, $toJsonArgs);',
        );
        for (var f in manualToJsonFields) {
          final info = f.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          sb.writeln(
            '    if (${f.name} != null) data[\'$jsonFieldName\'] = ${info.toJson}(${f.name}!);',
          );
        }
        sb.writeln('    return data;');
        sb.writeln('  }');
      }
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
    // Add manual toJson fields
    for (var f in manualToJsonFields) {
      final info = f.jsonKeyInfo!;
      final jsonFieldName = info.name ?? f.name;
      sb.writeln(
        '    if (${f.name} != null) data[\'$jsonFieldName\'] = ${info.toJson}(${f.name}!);',
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

  List<NameTypeClassComment> _getManualToJsonFields(ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      if (info == null) return false;
      return info.includeToJson == false && info.toJson != null;
    }).toList();
  }
}
