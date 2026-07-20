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
      _generateFromJson(sb, metadata, config);
      if (!metadata.nonSealed) {
        sb.writeln(_generateToJsonLean(metadata, config));
      }
    }

    if (metadata.nonSealed && !metadata.isAbstract) {
      sb.writeln(_generateToJsonLean(metadata, config));
    }

    // For concrete classes in a parent's explicitSubTypes, also generate toJson with __typename
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

  /// Generates fromJson deserialization code.
  void _generateFromJson(StringBuffer sb, ClassMetadata metadata, GenerationConfig config) {
    final className = metadata.cleanName;

    if (metadata.explicitSubtypes.isEmpty && metadata.generics.isEmpty) {
      // Simple case - no generics, no explicit subtypes
      // Generate inline fromJson with ZorphyJsonHelper.cast<T>() safe casts
      sb.writeln(_generateInlineFromJsonBody(className, metadata.allFields));
    } else if (metadata.explicitSubtypes.isNotEmpty) {
      // Abstract class with explicit subtypes - polymorphic JSON
      _generatePolymorphicFromJson(sb, metadata, config);
    } else {
      // Generics without explicit subtypes
      _generateGenericFromJson(sb, metadata, config);
    }
  }

  void _generatePolymorphicFromJson(
    StringBuffer sb,
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
    final className = metadata.cleanName;

    sb.writeln('');
    sb.writeln('  /// Creates a [$className] instance from JSON');
    sb.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');

    // For concrete classes, check if __typename is null or matches self first
    // This handles: (1) classes in parent's explicitSubTypes, and
    // (2) concrete classes that define their own explicitSubTypes (nonSealed base classes)
    final hasSelfCase =
        !metadata.isAbstract &&
        (metadata.isInParentExplicitSubtypes || metadata.nonSealed);
    final totalCases = metadata.explicitSubtypes.length + (hasSelfCase ? 1 : 0);
    var caseIndex = 0;

    if (hasSelfCase) {
      // Inline fromJson body since createFactory: false means _$FooFromJson won't exist
      sb.writeln(
        '    if (json[\'__typename\'] == null || json[\'__typename\'] == "$className") {',
      );
      sb.writeln('      return $className(');
      for (var f in metadata.allFields) {
        // Skip ignored/excluded fields
        if (f.jsonKeyInfo?.ignore == true) continue;
        if (f.jsonKeyInfo?.includeFromJson == false &&
            f.jsonKeyInfo?.fromJson == null &&
            f.jsonKeyInfo?.converter == null) continue;
        final expr = _fieldFromJsonExpression(f);
        sb.writeln('        ${f.name}: $expr,');
      }
      sb.writeln('      );');
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
        sb.writeln('    $prefix (json[\'__typename\'] == "$interfaceName") {');
        sb.writeln('      var fn_fromJson = getFromJsonToGenericFn(');
        sb.writeln('        ${interfaceName}_Generics_Sing().fns,');
        sb.writeln('        json,');
        sb.writeln('        [$genericTypes],');
        sb.writeln('      );');
        sb.writeln('      return fn_fromJson(json);');
      } else {
        sb.writeln('    $prefix (json[\'__typename\'] == "$interfaceName") {');
        sb.writeln('      return $interfaceName.fromJson(json);');
      }

      if (isLast) {
        sb.writeln('    }');
      }
      caseIndex++;
    }

    sb.writeln(
      '    throw UnsupportedError("The __typename \' + '
              r"${json['__typename']}" +
          '\' is not supported by the $className.fromJson constructor.");',
    );
    sb.writeln('  }');

    // For nonSealed classes with explicitSubTypes, generate toJson dispatcher
    if (metadata.nonSealed) {
      sb.writeln('');
      sb.writeln('  Map<String, dynamic> toJson() {');
      for (var i = 0; i < metadata.explicitSubtypes.length; i++) {
        final subtype = metadata.explicitSubtypes[i].interfaceName.replaceAll(
          r'$',
          '',
        );
        final keyword = i == 0 ? 'if' : '} else if';
        sb.writeln('    $keyword (this is $subtype) {');
        sb.writeln('      final json = (this as $subtype).toJsonLean();');
        sb.writeln('      json[\'__typename\'] = "$subtype";');
        sb.writeln('      return json;');
      }

      if (metadata.explicitSubtypes.isNotEmpty) {
        sb.writeln('    }');
      }

      if (metadata.isAbstract) {
        sb.writeln(
          '    throw UnsupportedError("Unknown subtype: \$runtimeType");',
        );
      } else {
        // Concrete base class — serialize itself with discriminator
        sb.writeln('    final json = toJsonLean();');
        sb.writeln("    json['__typename'] = '$className';");
        sb.writeln('    return json;');
      }
      sb.writeln('  }');
    }
  }

  void _generateGenericFromJson(
    StringBuffer sb,
    ClassMetadata metadata,
    GenerationConfig config,
  ) {
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
  }

  String _generateToJsonLean(ClassMetadata metadata, GenerationConfig config) {
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Don't generate toJsonLean for sealed classes or abstract classes with subtypes
    // UNLESS it's a nonSealed class (where we need toJsonLean for polymorphic toJson)
    if (metadata.isAbstract &&
        metadata.explicitSubtypes.isNotEmpty &&
        !metadata.nonSealed) {
      return '';
    }

    // Don't generate toJsonLean in the class body for generic classes that extend
    // a non-generic parent — the parent already defines toJsonLean() with no params,
    // and adding params would be an invalid override. The extension handles it instead.
    if (metadata.generics.isNotEmpty && _hasNonGenericJsonParent(metadata)) {
      return '';
    }

    final manualToJsonFields = _getManualToJsonFields(metadata);

    sb.writeln('');
    if (metadata.generics.isEmpty) {
      sb.writeln('  Map<String, dynamic> toJsonLean() {');
      if (metadata.isAbstract) {
        sb.writeln('    final Map<String, dynamic> data = {};');
      } else {
        sb.writeln(
          '    final Map<String, dynamic> data = _\$$className' +
              'ToJson(this);',
        );
      }
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
      if (metadata.isAbstract) {
        sb.writeln('    final Map<String, dynamic> data = {};');
      } else {
        sb.writeln(
          '    final Map<String, dynamic> data = _\$$className' +
              'ToJson(this, $toJsonArgs);',
        );
      }
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
    sb.writeln('      json.remove(\'__typename\');');
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

  /// Generate toJson method with __typename discriminator for classes in parent's explicitSubTypes
  String _generateToJsonWithDiscriminator(ClassMetadata metadata) {
    final sb = StringBuffer();
    final className = metadata.cleanName;

    // Generate toJson method with __typename discriminator
    sb.writeln('');
    sb.writeln('  Map<String, dynamic> toJson() {');
    sb.writeln('    final json = _\$$className' + 'ToJson(this);');
    sb.writeln('    json[\'__typename\'] = \'$className\';');
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

  /// Generates an inline fromJson factory constructor body with _zc<T> safe casts.
  /// Used for non-generic classes (direct) and for concrete self-cases in polymorphic hierarchies.
  String _generateInlineFromJsonBody(
    String className,
    List<NameTypeClassComment> fields,
  ) {
    final sb = StringBuffer();
    sb.writeln('');
    sb.writeln('  /// Creates a [$className] instance from JSON');
    sb.writeln(
      '  factory $className.fromJson(Map<String, dynamic> json) {',
    );
    sb.writeln('    return $className(');
    for (var f in fields) {
      // Skip ignored fields
      if (f.jsonKeyInfo?.ignore == true) continue;
      if (f.jsonKeyInfo?.includeFromJson == false &&
          f.jsonKeyInfo?.fromJson == null &&
          f.jsonKeyInfo?.converter == null) {
        // Excluded from JSON without custom converter/fromJson — rely on default value
        continue;
      }
      final expr = _fieldFromJsonExpression(f);
      sb.writeln('      ${f.name}: $expr,');
    }
    sb.writeln('    );');
    sb.writeln('  }');
    return sb.toString();
  }

  /// Generate a fromJson expression for a single field using ZorphyJsonHelper.cast safe casts.
  /// Produces expressions like:
  ///   ZorphyJsonHelper.cast<String>(json, 'name')
  ///   (ZorphyJsonHelper.cast<num>(json, 'price')).toDouble()
  ///   DateTime.parse(ZorphyJsonHelper.cast<String>(json, 'createdAt'))
  String _fieldFromJsonExpression(NameTypeClassComment f) {
    final jsonKeyName = f.jsonKeyInfo?.name ?? f.name;
    final rawType = f.type ?? 'dynamic';

    // Check for custom converter (manual fromJson)
    final info = f.jsonKeyInfo;
    if (info != null && info.fromJson != null &&
        info.includeFromJson == false) {
      final jsonFieldName = info.name ?? f.name;
      final isNullable = rawType.endsWith('?');
      if (isNullable) {
        return "json['$jsonFieldName'] != null ? "
            "${info.fromJson}(json['$jsonFieldName'] as Map<String, dynamic>) "
            "as $rawType : null";
      }
      return "${info.fromJson}(json['$jsonFieldName'] "
          "as Map<String, dynamic>) as $rawType";
    }

    // Check for @JsonKey(converter: SomeConverter()) — uses SomeConverter.fromJson(...)
    if (info?.converter != null) {
      final converterName = info!.converter!;
      // Strip trailing () if present (e.g. "LocaleConverter()" -> "LocaleConverter")
      final converterBase = converterName.endsWith('()')
          ? converterName.substring(0, converterName.length - 2)
          : converterName;
      final isNullable = rawType.endsWith('?');
      if (isNullable) {
        return "$converterBase.fromJson(json['$jsonKeyName'] as Map<String, dynamic>?)";
      }
      return "$converterBase.fromJson(json['$jsonKeyName'] as Map<String, dynamic>)";
    }

    // Clean $ prefixes from type for analysis
    final cleanType = rawType.replaceAll(r'$', '');
    final isNullable = cleanType.endsWith('?');
    final baseType = isNullable
        ? cleanType.substring(0, cleanType.length - 1)
        : cleanType;

    // Determine if there's a default value (forces nullable expression + ?? fallback)
    final hasDefault = info?.defaultValue != null;

    var expr = _typeToFromJsonExpr(baseType, isNullable, jsonKeyName, f);

    // Handle default value: use nullable expression + ?? fallback
    if (hasDefault) {
      // Force nullable variant and append default
      final nullableExpr = _typeToFromJsonExpr(baseType, true, jsonKeyName, f);
      return '$nullableExpr ?? ${info!.defaultValue}';
    }

    return expr;
  }

  /// Core type-to-expression mapping for a single field value.
  /// Returns the expression to get and cast json['jsonKeyName'] to the target type.
  String _typeToFromJsonExpr(
    String baseType,
    bool isNullable,
    String jsonKeyName,
    NameTypeClassComment f,
  ) {
    // Simple types
    if (baseType == 'String') {
      return isNullable
          ? "ZorphyJsonHelper.cast<String?>(json, '$jsonKeyName')"
          : "ZorphyJsonHelper.cast<String>(json, '$jsonKeyName')";
    }
    if (baseType == 'int') {
      return isNullable
          ? "(ZorphyJsonHelper.cast<num?>(json, '$jsonKeyName'))?.toInt()"
          : "(ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')).toInt()";
    }
    if (baseType == 'double') {
      return isNullable
          ? "(ZorphyJsonHelper.cast<num?>(json, '$jsonKeyName'))?.toDouble()"
          : "(ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')).toDouble()";
    }
    if (baseType == 'num') {
      return isNullable
          ? "ZorphyJsonHelper.cast<num?>(json, '$jsonKeyName')"
          : "ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')";
    }
    if (baseType == 'bool') {
      return isNullable
          ? "ZorphyJsonHelper.cast<bool?>(json, '$jsonKeyName')"
          : "ZorphyJsonHelper.cast<bool>(json, '$jsonKeyName')";
    }

    // DateTime - parse from string
    if (baseType == 'DateTime') {
      if (isNullable) {
        return "json['$jsonKeyName'] == null"
            " ? null"
            " : DateTime.parse(ZorphyJsonHelper.cast<String>(json, '$jsonKeyName'))";
      }
      return "DateTime.parse(ZorphyJsonHelper.cast<String>(json, '$jsonKeyName'))";
    }

    // Duration - parse from microseconds (num)
    if (baseType == 'Duration') {
      if (isNullable) {
        return "json['$jsonKeyName'] == null"
            " ? null"
            " : Duration(microseconds:"
            " (ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')).toInt())";
      }
      return "Duration(microseconds:"
          " (ZorphyJsonHelper.cast<num>(json, '$jsonKeyName')).toInt())";
    }

    // Enum - use $enumDecode with ZorphyJsonHelper.cast<string> for field-name in error
    if (f.isEnum && f.enumValues.isNotEmpty) {
      final enumMapName = "_\$${baseType}EnumMap";
      if (isNullable) {
        return "\$enumDecodeNullable($enumMapName,"
            " ZorphyJsonHelper.cast<String?>(json, '$jsonKeyName'))";
      }
      return "\$enumDecode($enumMapName,"
          " ZorphyJsonHelper.cast<String>(json, '$jsonKeyName'))";
    }

    // List<E> - cast to List<dynamic>, then map elements
    if (baseType.startsWith('List<')) {
      final innerContent = _extractGenericArg(baseType);
      final innerExpr = _elementCastExpression(innerContent);

      if (isNullable) {
        return "(ZorphyJsonHelper.cast<List<dynamic>?>(json, '$jsonKeyName'))"
            "?.map((e) => $innerExpr).toList()";
      }
      return "(ZorphyJsonHelper.cast<List<dynamic>>(json, '$jsonKeyName'))"
          ".map((e) => $innerExpr).toList()";
    }

    // Map<K,V> - pass through with ZorphyJsonHelper.cast
    if (baseType.startsWith('Map<')) {
      return isNullable
          ? "ZorphyJsonHelper.cast<$baseType?>(json, '$jsonKeyName')"
          : "ZorphyJsonHelper.cast<$baseType>(json, '$jsonKeyName')";
    }

    // dynamic / Object / never
    if (baseType == 'dynamic' || baseType == 'Object' ||
        baseType == 'Never' || baseType == 'void') {
      return "json['$jsonKeyName']";
    }

    // Custom object - assume has fromJson(Map<String, dynamic>)
    // For nullable, use null guard to avoid calling fromJson on null
    if (isNullable) {
      return "json['$jsonKeyName'] == null"
          " ? null"
          " : ${baseType}.fromJson("
          "ZorphyJsonHelper.cast<Map<String, dynamic>>(json, '$jsonKeyName'))";
    }
    return "${baseType}.fromJson("
        "ZorphyJsonHelper.cast<Map<String, dynamic>>(json, '$jsonKeyName'))";
  }

  /// Generate a cast expression for a list element inside a .map() call.
  String _elementCastExpression(String innerType) {
    final trimmed = innerType.trim();
    final isNullable = trimmed.endsWith('?');
    final baseType = isNullable
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;

    switch (baseType) {
      case 'String':
        return 'e as String';
      case 'int':
        return '(e as num).toInt()';
      case 'double':
        return '(e as num).toDouble()';
      case 'num':
        return 'e as num';
      case 'bool':
        return 'e as bool';
      case 'dynamic':
      case 'Object':
        return 'e';
      case 'DateTime':
        return 'DateTime.parse(e as String)';
    }

    if (baseType.startsWith('List<') || baseType.startsWith('Map<')) {
      return 'e as $trimmed';
    }

    // Custom object
    return '$baseType.fromJson(e as Map<String, dynamic>)';
  }

  /// Extract the generic type argument from a type string like List<String> -> String
  String _extractGenericArg(String type) {
    final start = type.indexOf('<');
    final end = type.lastIndexOf('>');
    if (start == -1 || end == -1) return type;
    return type.substring(start + 1, end).trim();
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
    sb.writeln('      json.remove(\'__typename\');');
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
