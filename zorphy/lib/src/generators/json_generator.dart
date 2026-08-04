import 'package:code_builder/code_builder.dart';

import '../ast/ast.dart';
import '../common/NameType.dart';
import '../models/class_metadata.dart';
import '../models/generation_config.dart';
import 'base_generator.dart';

/// Generates JSON serialization members.
///
/// - `fromJson` (factory constructor) is returned as
///   [ClassMemberCode.constructor] because [Constructor] does not
///   implement [Spec].
/// - `toJsonLean()` and `_sanitizeJson()` are returned as native
///   [Method] specs which the orchestrator merges into the class.
/// - `toJson()` for polymorphic/nonSealed classes is returned as
///   [ClassMemberCode.method].
class JsonGenerator extends UniversalGenerator {
  JsonGenerator();

  @override
  bool shouldGenerate(GenerationContext context) =>
      context.config.generateJson;

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final config = context.config;
    if (!config.generateJson) return [];

    final specs = <Spec>[];
    final shouldGenerateJson =
        !metadata.isAbstract && metadata.explicitSubtypes.isEmpty;
    final shouldGeneratePolymorphicJson =
        metadata.explicitSubtypes.isNotEmpty;

    if (shouldGenerateJson || shouldGeneratePolymorphicJson) {
      // fromJson as Constructor
      _addFromJson(specs, metadata, config);

      if (!metadata.nonSealed) {
        _addToJsonLeanMethods(specs, metadata, config);
      }
    }
    if (metadata.nonSealed && !metadata.isAbstract) {
      _addToJsonLeanMethods(specs, metadata, config);
    }
    if (!metadata.isAbstract && metadata.isInParentExplicitSubtypes) {
      _addToJsonWithDiscriminator(specs, metadata);
    }
    return specs;
  }

  // ── fromJson as Constructor spec ────────────────────────────

  void _addFromJson(
    List<Spec> specs,
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.cleanName;

    if (metadata.explicitSubtypes.isEmpty && metadata.generics.isEmpty) {
      final manualFromJsonFields = _getManualFromJsonFields(metadata);
      if (manualFromJsonFields.isEmpty) {
        specs.add(ClassMemberCode.constructor(Constructor((c) {
          c.factory = true;
          c.name = 'fromJson';
          c.requiredParameters.add(Parameter((p) {
            p.name = 'json';
            p.type = referType('Map<String, dynamic>');
          }));
          c.lambda = true;
          c.body = Code('_\$$className' + 'FromJson(json)');
        })));
      } else {
        final bodyLines = <String>[
          'final instance = _\$$className' + 'FromJson(json);',
          'return $className(',
        ];
        for (final f in metadata.allFields) {
          final manualField =
              manualFromJsonFields.where((m) => m.name == f.name);
          if (manualField.isNotEmpty) {
            final info = manualField.first.jsonKeyInfo!;
            final jsonFieldName = info.name ?? f.name;
            bodyLines.add(
                "      ${f.name}: json['$jsonFieldName'] != null ? ${info.fromJson}(json['$jsonFieldName'] as Map<String, dynamic>) as ${f.type} : null,");
          } else {
            bodyLines.add('      ${f.name}: instance.${f.name},');
          }
        }
        bodyLines.add('    );');

        specs.add(ClassMemberCode.constructor(Constructor((c) {
          c.factory = true;
          c.name = 'fromJson';
          c.requiredParameters.add(Parameter((p) {
            p.name = 'json';
            p.type = referType('Map<String, dynamic>');
          }));
          c.body = Code(bodyLines.join('\n'));
        })));
      }
    } else if (metadata.explicitSubtypes.isNotEmpty) {
      _addPolymorphicFromJson(specs, metadata, config);
    } else {
      _addGenericFromJson(specs, metadata, config);
    }
  }

  void _addPolymorphicFromJson(
    List<Spec> specs,
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.cleanName;
    final bodyLines = <String>[];

    final hasSelfCase = !metadata.isAbstract &&
        (metadata.isInParentExplicitSubtypes || metadata.nonSealed);
    final totalCases =
        metadata.explicitSubtypes.length + (hasSelfCase ? 1 : 0);
    var caseIndex = 0;

    if (hasSelfCase) {
      bodyLines.add(
          "if (json['__typename'] == null || json['__typename'] == '$className') {");
      bodyLines.add('  return _\$${className}FromJson(json);');
      caseIndex++;
    }

    for (var i = 0; i < metadata.explicitSubtypes.length; i++) {
      final subtype = metadata.explicitSubtypes[i];
      // Strip leading `$` from interface names (e.g. `$CreditCard` → `CreditCard`)
      // so the generated code references valid Dart identifiers.
      final interfaceName = subtype.interfaceName.replaceAll('\$', '');
      final isLast = caseIndex == totalCases - 1;
      final prefix = caseIndex == 0 ? 'if' : '} else if';

      if (subtype.typeParams.isNotEmpty) {
        final genericTypes =
            subtype.typeParams.map((e) => "'\$\${e.name}\$'").join(',');
        bodyLines.add(
            "$prefix (json['__typename'] == '$interfaceName') {");
        bodyLines.add('  var fn_fromJson = getFromJsonToGenericFn(');
        bodyLines.add('    ${interfaceName}_Generics_Sing().fns,');
        bodyLines.add('    json,');
        bodyLines.add('    [$genericTypes],');
        bodyLines.add('  );');
        bodyLines.add('  return fn_fromJson(json);');
      } else {
        bodyLines.add(
            "$prefix (json['__typename'] == '$interfaceName') {");
        bodyLines.add('  return $interfaceName.fromJson(json);');
      }
      if (isLast) bodyLines.add('}');
      caseIndex++;
    }

    bodyLines.add(
        "throw UnsupportedError(\"The __typename '\${json['__typename']}' is not supported by the $className.fromJson constructor.\");");

    specs.add(ClassMemberCode.constructor(Constructor((c) {
      c.factory = true;
      c.name = 'fromJson';
      c.requiredParameters.add(Parameter((p) {
        p.name = 'json';
        p.type = referType('Map<String, dynamic>');
      }));
      c.body = Code(bodyLines.join('\n'));
    })));

    if (metadata.nonSealed) {
      // toJson method for non-sealed polymorphic
      final toJsonBody = <String>[];
      for (var i = 0; i < metadata.explicitSubtypes.length; i++) {
        final subtype =
            metadata.explicitSubtypes[i];
        // Strip leading `$` from interface names.
        final subtypeName = subtype.interfaceName.replaceAll('\$', '');
        final keyword = i == 0 ? 'if' : '} else if';
        toJsonBody.add('  $keyword (this is $subtypeName) {');
        toJsonBody.add('    final json = (this as $subtypeName).toJsonLean();');
        toJsonBody.add("    json['__typename'] = '$subtypeName';");
        toJsonBody.add('    return json;');
      }
      if (metadata.explicitSubtypes.isNotEmpty) toJsonBody.add('  }');
      if (metadata.isAbstract) {
        toJsonBody.add(
            '  throw UnsupportedError("Unknown subtype: \\\$runtimeType");');
      } else {
        toJsonBody.add('  final json = toJsonLean();');
        toJsonBody.add("  json['__typename'] = '$className';");
        toJsonBody.add('  return json;');
      }

      specs.add(ClassMemberCode.method(Method((m) {
        m.name = 'toJson';
        m.returns = referType('Map<String, dynamic>');
        m.body = Code(toJsonBody.join('\n'));
      })));
    }
  }

  void _addGenericFromJson(
    List<Spec> specs,
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.cleanName;
    final fromJsonArgs =
        metadata.generics.map((g) => 'fromJson${g.name}').join(', ');
    final manualFromJsonFields = _getManualFromJsonFields(metadata);

    if (manualFromJsonFields.isEmpty) {
      specs.add(ClassMemberCode.constructor(Constructor((c) {
        c.factory = true;
        c.name = 'fromJson';
        c.requiredParameters.add(Parameter((p) {
          p.name = 'json';
          p.type = referType('Map<String, dynamic>');
        }));
        for (final g in metadata.generics) {
          c.requiredParameters.add(Parameter((p) {
            p.name = 'fromJson${g.name}';
            p.type =
                referType('${g.name} Function(Object? json)');
          }));
        }
        c.lambda = true;
        c.body = Code('_\$$className' + 'FromJson(json, $fromJsonArgs)');
      })));
    } else {
      final bodyLines = <String>[
        '  final instance = _\$$className' +
            'FromJson(json, $fromJsonArgs);',
        '  return $className(',
      ];
      for (final f in metadata.allFields) {
        final manualField =
            manualFromJsonFields.where((m) => m.name == f.name);
        if (manualField.isNotEmpty) {
          final info = manualField.first.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          bodyLines.add(
              "      ${f.name}: json['$jsonFieldName'] != null ? ${info.fromJson}(json['$jsonFieldName'] as Map<String, dynamic>) as ${f.type} : null,");
        } else {
          bodyLines.add('      ${f.name}: instance.${f.name},');
        }
      }
      bodyLines.add('    );');

      specs.add(ClassMemberCode.constructor(Constructor((c) {
        c.factory = true;
        c.name = 'fromJson';
        c.requiredParameters.add(Parameter((p) {
          p.name = 'json';
          p.type = referType('Map<String, dynamic>');
        }));
        for (final g in metadata.generics) {
          c.requiredParameters.add(Parameter((p) {
            p.name = 'fromJson${g.name}';
            p.type =
                referType('${g.name} Function(Object? json)');
          }));
        }
        c.body = Code(bodyLines.join('\n'));
      })));
    }
  }

  // ── toJsonLean + _sanitizeJson as Method specs ─────────────

  void _addToJsonLeanMethods(
    List<Spec> specs,
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    if (metadata.isAbstract &&
        metadata.explicitSubtypes.isNotEmpty &&
        !metadata.nonSealed) {
      return;
    }
    if (metadata.generics.isNotEmpty &&
        _hasNonGenericJsonParent(metadata)) {
      return;
    }

    final className = metadata.cleanName;
    final manualToJsonFields = _getManualToJsonFields(metadata);

    // toJsonLean method
    if (metadata.generics.isEmpty) {
      final body = StringBuffer();
      body.writeln(
          'final Map<String, dynamic> data = _\$$className' +
              'ToJson(this);');
      for (final f in manualToJsonFields) {
        final info = f.jsonKeyInfo!;
        final jsonFieldName = info.name ?? f.name;
        body.writeln(
            "if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
      }
      body.writeln('return _sanitizeJson(data);');
      specs.add(Method((m) {
        m.name = 'toJsonLean';
        m.returns = referType('Map<String, dynamic>');
        m.body = Code(body.toString());
      }));
    } else {
      final toJsonArgs =
          metadata.generics.map((g) => 'toJson${g.name}').join(', ');
      final body = StringBuffer();
      body.writeln(
          'final Map<String, dynamic> data = _\$$className' +
              'ToJson(this, $toJsonArgs);');
      for (final f in manualToJsonFields) {
        final info = f.jsonKeyInfo!;
        final jsonFieldName = info.name ?? f.name;
        body.writeln(
            "if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
      }
      body.writeln('return _sanitizeJson(data);');
      specs.add(Method((m) {
        m.name = 'toJsonLean';
        m.returns = referType('Map<String, dynamic>');
        for (final g in metadata.generics) {
          m.requiredParameters.add(Parameter((p) {
            p.name = 'toJson${g.name}';
            p.type =
                referType('Object? Function(${g.name} value)');
          }));
        }
        m.body = Code(body.toString());
      }));
    }

    // _sanitizeJson method
    specs.add(Method((m) {
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
  }

  // ── toJson with discriminator ────────────────────────────────

  void _addToJsonWithDiscriminator(
      List<Spec> specs, ClassMetadata metadata) {
    final className = metadata.cleanName;
    final body = StringBuffer();
    body.writeln('final json = _\$$className' + 'ToJson(this);');
    body.writeln("json['__typename'] = '$className';");
    body.writeln('return json;');
    specs.add(ClassMemberCode.method(Method((m) {
      m.name = 'toJson';
      m.returns = referType('Map<String, dynamic>');
      m.body = Code(body.toString());
    })));
  }

  bool _hasNonGenericJsonParent(ClassMetadata metadata) {
    for (final iface in metadata.interfaces) {
      if (iface.typeParams.isEmpty) return true;
    }
    return false;
  }

  List<NameTypeClassComment> _getManualFromJsonFields(
      ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      return info != null &&
          info.includeFromJson == false &&
          info.fromJson != null;
    }).toList();
  }

  List<NameTypeClassComment> _getManualToJsonFields(
      ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      return info != null &&
          info.includeToJson == false &&
          info.toJson != null;
    }).toList();
  }
}

/// Generates JSON extension for concrete classes.
///
/// Produces a native [Extension] spec with a [Method] spec for toJson only.
/// toJsonLean and _sanitizeJson are now emitted inside the class body
/// by [JsonGenerator] (no duplication).
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

  List<NameTypeClassComment> _getManualToJsonFields(
      ClassMetadata metadata) {
    return metadata.allFields.where((f) {
      final info = f.jsonKeyInfo;
      return info != null &&
          info.includeToJson == false &&
          info.toJson != null;
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

    // toJson method only — toJsonLean and _sanitizeJson are now
    // generated inside the class by JsonGenerator.
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
        for (final f in manualToJsonFields) {
          final info = f.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          body.writeln(
              "if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
        }
        body.writeln('return data;');
        methods.add(Method((m) {
          m.name = 'toJson';
          m.returns = referType('Map<String, dynamic>');
          m.body = Code(body.toString());
        }));
      }
    } else {
      final toJsonArgs =
          metadata.generics.map((g) => 'toJson${g.name}').join(', ');
      if (manualToJsonFields.isEmpty) {
        methods.add(Method((m) {
          m.name = 'toJson';
          m.returns = referType('Map<String, dynamic>');
          for (final g in metadata.generics) {
            m.requiredParameters.add(Parameter((p) {
              p.name = 'toJson${g.name}';
              p.type =
                  referType('Object? Function(${g.name} value)');
            }));
          }
          m.lambda = true;
          m.body = Code('_\$$className' + 'ToJson(this, $toJsonArgs)');
        }));
      } else {
        final body = StringBuffer();
        body.writeln(
            'final data = _\$$className' + 'ToJson(this, $toJsonArgs);');
        for (final f in manualToJsonFields) {
          final info = f.jsonKeyInfo!;
          final jsonFieldName = info.name ?? f.name;
          body.writeln(
              "if (${f.name} != null) data['$jsonFieldName'] = ${info.toJson}(${f.name}!);");
        }
        body.writeln('return data;');
        methods.add(Method((m) {
          m.name = 'toJson';
          m.returns = referType('Map<String, dynamic>');
          for (final g in metadata.generics) {
            m.requiredParameters.add(Parameter((p) {
              p.name = 'toJson${g.name}';
              p.type =
                  referType('Object? Function(${g.name} value)');
            }));
          }
          m.body = Code(body.toString());
        }));
      }
    }

    return [
      Extension((e) {
        e.name = '${className}Serialization$genericsStr';
        e.on = referType('$className$genericsStr');
        e.methods.addAll(methods);
      }),
    ];
  }
}
