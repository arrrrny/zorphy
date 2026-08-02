import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import '../common/NameType.dart';
import '../models/class_metadata.dart';
import '../models/generation_config.dart';
import 'base_generator.dart';

/// Generates JSON serialization methods.
///
/// Produces [Code] specs wrapping the string output. fromJson is a factory
/// constructor which cannot be represented as a native [Spec] object
/// (code_builder's [Constructor] does not implement [Spec]).
class JsonGenerator extends UniversalGenerator {
  JsonGenerator();

  @override
  bool shouldGenerate(GenerationContext context) => context.config.generateJson;

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;
    if (!config.generateJson) return [];

    final sb = StringBuffer();
    final shouldGenerateJson = !metadata.isAbstract && metadata.explicitSubtypes.isEmpty;
    final shouldGeneratePolymorphicJson = metadata.explicitSubtypes.isNotEmpty;

    if (shouldGenerateJson || shouldGeneratePolymorphicJson) {
      sb.writeln(_generateFromJson(metadata, config));
      if (!metadata.nonSealed) {
        sb.writeln(_generateToJsonLean(metadata, config));
      }
    }
    if (metadata.nonSealed && !metadata.isAbstract) {
      sb.writeln(_generateToJsonLean(metadata, config));
    }
    if (!metadata.isAbstract && metadata.isInParentExplicitSubtypes) {
      sb.writeln(_generateToJsonWithDiscriminator(metadata));
    }
    final code = sb.toString();
    if (code.trim().isEmpty) return [];
    return [Code(code)];
  }

  // ── Private string builders ──────────────────────────────────

  String _generateFromJson(ClassMetadata metadata, GenerationConfig config) {
    final sb = StringBuffer();
    final className = metadata.cleanName;

    if (metadata.explicitSubtypes.isEmpty && metadata.generics.isEmpty) {
      final manualFromJsonFields = _getManualFromJsonFields(metadata);
      sb.writeln('');
      sb.writeln('  /// Creates a [$className] instance from JSON');
      if (manualFromJsonFields.isEmpty) {
        sb.writeln(
          '  factory $className.fromJson(Map<String, dynamic> json) => _\$$className' + 'FromJson(json);',
        );
      } else {
        sb.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
        sb.writeln('    final instance = _\$$className' + 'FromJson(json);');
        sb.writeln('    return $className(');
        for (var f in metadata.allFields) {
          final manualField = manualFromJsonFields.where((m) => m.name == f.name);
          if (manualField.isNotEmpty) {
            final info = manualField.first.jsonKeyInfo!;
            final jsonFieldName = info.name ?? f.name;
            sb.writeln("      ${f.name}: json['$jsonFieldName'] != null ? ${info.fromJson}(json['$jsonFieldName'] as Map<String, dynamic>) as ${f.type} : null,");
          } else {
            sb.writeln('      ${f.name}: instance.${f.name},');
          }
        }
        sb.writeln('    );');
        sb.writeln('  }');
      }
    } else if (metadata.explicitSubtypes.isNotEmpty) {
      sb.writeln(_generatePolymorphicFromJson(metadata, config));
    } else {
      sb.writeln(_generateGenericFromJson(metadata, config));
    }
    return sb.toString();
  }

  String _generatePolymorphicFromJson(ClassMetadata metadata, GenerationConfig config) {
    final sb = StringBuffer();
    final className = metadata.cleanName;
    sb.writeln('');
    sb.writeln('  /// Creates a [$className] instance from JSON');
    sb.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');

    final hasSelfCase = !metadata.isAbstract && (metadata.isInParentExplicitSubtypes || metadata.nonSealed);
    final totalCases = metadata.explicitSubtypes.length + (hasSelfCase ? 1 : 0);
    var caseIndex = 0;

    if (hasSelfCase) {
      sb.writeln("    if (json['__typename'] == null || json['__typename'] == \"$className\") {");
      sb.writeln('      return _\$${className}FromJson(json);');
      caseIndex++;
    }

    for (var i = 0; i < metadata.explicitSubtypes.length; i++) {
      final subtype = metadata.explicitSubtypes[i];
      final interfaceName = subtype.interfaceName.replaceAll(r'$', '');
      final isLast = caseIndex == totalCases - 1;
      final prefix = caseIndex == 0 ? 'if' : '} else if';

      if (subtype.typeParams.isNotEmpty) {
        final genericTypes = subtype.typeParams.map((e) => "'\_\${e.name}\_'").join(',');
        sb.writeln("    $prefix (json['__typename'] == \"$interfaceName\") {");
        sb.writeln('      var fn_fromJson = getFromJsonToGenericFn(');
        sb.writeln('        ${interfaceName}_Generics_Sing().fns,');
        sb.writeln('        json,');
        sb.writeln('        [$genericTypes],');
        sb.writeln('      );');
        sb.writeln('      return fn_fromJson(json);');
      } else {
        sb.writeln("    $prefix (json['__typename'] == \"$interfaceName\") {");
        sb.writeln('      return $interfaceName.fromJson(json);');
      }
      if (isLast) sb.writeln('    }');
      caseIndex++;
    }

    sb.writeln("    throw UnsupportedError(\"The __typename '\${json['__typename']}' is not supported by the $className.fromJson constructor.\");");
    sb.writeln('  }');

    if (metadata.nonSealed) {
      sb.writeln('');
      sb.writeln('  Map<String, dynamic> toJson() {');
      for (var i = 0; i < metadata.explicitSubtypes.length; i++) {
        final subtype = metadata.explicitSubtypes[i].interfaceName.replaceAll(r'$', '');
        final keyword = i == 0 ? 'if' : '} else if';
        sb.writeln('    $keyword (this is $subtype) {');
        sb.writeln('      final json = (this as $subtype).toJsonLean();');
        sb.writeln("      json['__typename'] = \"$subtype\";");
        sb.writeln('      return json;');
      }
      if (metadata.explicitSubtypes.isNotEmpty) sb.writeln('    }');
      if (metadata.isAbstract) {
        sb.writeln('    throw UnsupportedError("Unknown subtype: \\$runtimeType");');
      } else {
        sb.writeln('    final json = toJsonLean();');
        sb.writeln("    json['__typename'] = '$className';");
        sb.writeln('    return json;');
      }
      sb.writeln('  }');
    }
    return sb.toString();
  }

  String _generateGenericFromJson(ClassMetadata metadata, GenerationConfig config) {
    final sb = StringBuffer();
    final className = metadata.cleanName;
    final fromJsonParams = metadata.generics.map((g) => '${g.name} Function(Object? json) fromJson${g.name}').join(', ');
    final fromJsonArgs = metadata.generics.map((g) => 'fromJson${g.name}').join(', ');
    final manualFromJsonFields = _getManualFromJsonFields(metadata);

    sb.writeln('');
    sb.writeln('  /// Creates a [$className] instance from JSON');
    if (manualFromJsonFields.isEmpty) {
      sb.writeln('  factory $className.fromJson(Map<String, dynamic> json, $fromJsonParams) => _\$$className' + 'FromJson(json, $fromJsonArgs);');
    } else {
      sb.writeln('  factory $className.fromJson(Map<String, dynamic> json, $fromJsonParams) {');
      sb.writeln('    final instance = _\$$className' + 'FromJson(json, $fromJsonArgs);');
      sb.writeln('    return $className(');
      for (var f in metadata.allFields) {
        final manualField = manualFromJsonFields.where((m) => m.name == f.name);
        if (manualField.isNotEmpty) {
          final info = manualField.first.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          sb.writeln("      ${f.name}: json['$jsonFieldName'] != null ? ${info.fromJson}(json['$jsonFieldName'] as Map<String, dynamic>) as ${f.type} : null,");
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
    if (metadata.isAbstract && metadata.explicitSubtypes.isNotEmpty && !metadata.nonSealed) return '';
    if (metadata.generics.isNotEmpty && _hasNonGenericJsonParent(metadata)) return '';

    final manualToJsonFields = _getManualToJsonFields(metadata);
    sb.writeln('');
    if (metadata.generics.isEmpty) {
      sb.writeln('  Map<String, dynamic> toJsonLean() {');
      if (metadata.isAbstract) {
        sb.writeln('    final Map<String, dynamic> data = {};');
      } else {
        sb.writeln('    final Map<String, dynamic> data = _\$$className' + 'ToJson(this);');
      }
    } else {
      final toJsonParams = metadata.generics.map((g) => 'Object? Function(${g.name} value) toJson${g.name}').join(', ');
      final toJsonArgs = metadata.generics.map((g) => 'toJson${g.name}').join(', ');
      sb.writeln('  Map<String, dynamic> toJsonLean($toJsonParams) {');
      if (metadata.isAbstract) {
        sb.writeln('    final Map<String, dynamic> data = {};');
      } else {
        sb.writeln('    final Map<String, dynamic> data = _\$$className' + 'ToJson(this, $toJsonArgs);');
      }
    }
    for (var f in manualToJsonFields) {
      final info = f.jsonKeyInfo!;
      final jsonFieldName = info.name ?? f.name;
      sb.writeln("    if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
    }
    sb.writeln('    return _sanitizeJson(data);');
    sb.writeln('  }');
    sb.writeln('');
    sb.writeln('  dynamic _sanitizeJson(dynamic json) {');
    sb.writeln('    if (json is Map<String, dynamic>) {');
    sb.writeln("      json.remove('__typename');");
    sb.writeln('      return json..forEach((key, value) {');
    sb.writeln('        json[key] = _sanitizeJson(value);');
    sb.writeln('      });');
    sb.writeln('    } else if (json is List) {');
    sb.writeln('      return json.map((e) => _sanitizeJson(e)).toList();');
    sb.writeln('    }');
    sb.writeln('    return json;');
    sb.writeln('  }');
    return sb.toString();
  }

  String _generateToJsonWithDiscriminator(ClassMetadata metadata) {
    final sb = StringBuffer();
    final className = metadata.cleanName;
    sb.writeln('');
    sb.writeln('  Map<String, dynamic> toJson() {');
    sb.writeln('    final json = _\$$className' + 'ToJson(this);');
    sb.writeln("    json['__typename'] = '$className';");
    sb.writeln('    return json;');
    sb.writeln('  }');
    return sb.toString();
  }

  bool _hasNonGenericJsonParent(ClassMetadata metadata) {
    for (final iface in metadata.interfaces) {
      if (iface.typeParams.isEmpty) return true;
    }
    return false;
  }

  List<NameTypeClassComment> _getManualFromJsonFields(ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      return info != null && info.includeFromJson == false && info.fromJson != null;
    }).toList();
  }

  List<NameTypeClassComment> _getManualToJsonFields(ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      return info != null && info.includeToJson == false && info.toJson != null;
    }).toList();
  }
}

/// Generates JSON extension for concrete classes.
///
/// Produces a native [Extension] spec with [Method] specs for toJson,
/// toJsonLean, and _sanitizeJson.
class JsonExtensionGenerator extends ConcreteClassGenerator {
  JsonExtensionGenerator();

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.config.generateJson &&
           !context.metadata.isAbstract &&
           context.metadata.explicitSubtypes.isEmpty;
  }

  String _buildGenericsString(ClassMetadata metadata) {
    if (metadata.generics.isEmpty) return '';
    return '<${metadata.generics.map((g) => g.toString()).join(', ')}>';
  }

  List<NameTypeClassComment> _getManualToJsonFields(ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      return info != null && info.includeToJson == false && info.toJson != null;
    }).toList();
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;
    if (!config.generateJson) return [];
    if (metadata.isAbstract) return [];
    if (metadata.explicitSubtypes.isNotEmpty) return [];

    final className = metadata.cleanName;
    final genericsStr = _buildGenericsString(metadata);
    final manualToJsonFields = _getManualToJsonFields(metadata);
    final methods = <Method>[];

    // toJson method
    if (metadata.generics.isEmpty) {
      if (manualToJsonFields.isEmpty) {
        methods.add(Method((m) {
          m.name = 'toJson';
          m.returns = referType('Map<String, dynamic>');
          m.body = Code('return _\$$className' + 'ToJson(this);');
        }));
      } else {
        final body = StringBuffer();
        body.writeln('final data = _\$$className' + 'ToJson(this);');
        for (var f in manualToJsonFields) {
          final info = f.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          body.writeln("if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
        }
        body.writeln('return data;');
        methods.add(Method((m) {
          m.name = 'toJson';
          m.returns = referType('Map<String, dynamic>');
          m.body = Code(body.toString());
        }));
      }
    } else {
      final toJsonArgs = metadata.generics.map((g) => 'toJson${g.name}').join(', ');
      if (manualToJsonFields.isEmpty) {
        methods.add(Method((m) {
          m.name = 'toJson';
          m.returns = referType('Map<String, dynamic>');
          for (final g in metadata.generics) {
            m.requiredParameters.add(Parameter((p) {
              p.name = 'toJson${g.name}';
              p.type = referType('Object? Function(${g.name} value)');
            }));
          }
          m.lambda = true;
          m.body = Code('_\$$className' + 'ToJson(this, $toJsonArgs)');
        }));
      } else {
        final body = StringBuffer();
        body.writeln('final data = _\$$className' + 'ToJson(this, $toJsonArgs);');
        for (var f in manualToJsonFields) {
          final info = f.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          body.writeln("if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
        }
        body.writeln('return data;');
        methods.add(Method((m) {
          m.name = 'toJson';
          m.returns = referType('Map<String, dynamic>');
          for (final g in metadata.generics) {
            m.requiredParameters.add(Parameter((p) {
              p.name = 'toJson${g.name}';
              p.type = referType('Object? Function(${g.name} value)');
            }));
          }
          m.body = Code(body.toString());
        }));
      }
    }

    // toJsonLean method
    if (metadata.generics.isEmpty) {
      final body = StringBuffer();
      body.writeln('final Map<String, dynamic> data = _\$$className' + 'ToJson(this);');
      for (var f in manualToJsonFields) {
        final info = f.jsonKeyInfo!;
        final jsonFieldName = info.name ?? f.name;
        body.writeln("if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
      }
      body.writeln('return _sanitizeJson(data);');
      methods.add(Method((m) {
        m.name = 'toJsonLean';
        m.returns = referType('Map<String, dynamic>');
        m.body = Code(body.toString());
      }));
    } else {
      final toJsonArgs = metadata.generics.map((g) => 'toJson${g.name}').join(', ');
      final body = StringBuffer();
      body.writeln('final Map<String, dynamic> data = _\$$className' + 'ToJson(this, $toJsonArgs);');
      for (var f in manualToJsonFields) {
        final info = f.jsonKeyInfo!;
        final jsonFieldName = info.name ?? f.name;
        body.writeln("if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
      }
      body.writeln('return _sanitizeJson(data);');
      methods.add(Method((m) {
        m.name = 'toJsonLean';
        m.returns = referType('Map<String, dynamic>');
        for (final g in metadata.generics) {
          m.requiredParameters.add(Parameter((p) {
            p.name = 'toJson${g.name}';
            p.type = referType('Object? Function(${g.name} value)');
          }));
        }
        m.body = Code(body.toString());
      }));
    }

    // _sanitizeJson method
    methods.add(Method((m) {
      m.name = '_sanitizeJson';
      m.returns = referType('dynamic');
      m.requiredParameters.add(Parameter((p) {
        p.name = 'json';
        p.type = referType('dynamic');
      }));
      m.body = Code('''if (json is Map<String, dynamic>) {
  json.remove('__typename');
  return json..forEach((key, value) {
    json[key] = _sanitizeJson(value);
  });
} else if (json is List) {
  return json.map((e) => _sanitizeJson(e)).toList();
}
return json;''');
    }));

    return [
      Extension((e) {
        e.name = '${className}Serialization$genericsStr';
        e.on = referType('$className$genericsStr');
        e.methods.addAll(methods);
      }),
    ];
  }
}