/// Configuration for entity creation
class EntityConfig {
  final String name;
  final String? outputDir;
  final String? packageName;
  final List<FieldDefinition> fields;
  final bool generateJson;
  final bool generateCopyWithFn;
  final bool generateCompareTo;
  final bool isSealed;
  final bool isNonSealed;
  final bool generateFilter;
  final String? extendsInterface;
  final List<String> explicitSubtypes;
  final bool generateSubtypes;
  final bool dryRun;
  final bool prefixNested;

  const EntityConfig({
    required this.name,
    this.outputDir,
    this.packageName,
    this.fields = const [],
    this.generateJson = true,
    this.generateCopyWithFn = false,
    this.generateCompareTo = true,
    this.isSealed = false,
    this.isNonSealed = false,
    this.generateFilter = false,
    this.extendsInterface,
    this.explicitSubtypes = const [],
    this.generateSubtypes = false,
    this.dryRun = false,
    this.prefixNested = true,
  });

  String get defaultOutputDir => 'lib/src/domain/entities';

  String get className {
    var n = name.replaceAll('\$', '');
    final parts = n.split(RegExp(r'[_\s\-]+'));
    return parts
        .map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1);
        })
        .join('');
  }

  String get snakeName {
    final camel = className;
    return camel.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
      final char = match.group(0)!;
      final index = match.start;
      return (index == 0) ? char.toLowerCase() : '_${char.toLowerCase()}';
    });
  }

  EntityConfig copyWith({
    String? name,
    String? outputDir,
    String? packageName,
    List<FieldDefinition>? fields,
    bool? generateJson,
    bool? generateCopyWithFn,
    bool? generateCompareTo,
    bool? isSealed,
    bool? isNonSealed,
    bool? generateFilter,
    String? extendsInterface,
    List<String>? explicitSubtypes,
    bool? generateSubtypes,
    bool? dryRun,
    bool? prefixNested,
  }) {
    return EntityConfig(
      name: name ?? this.name,
      outputDir: outputDir ?? this.outputDir,
      packageName: packageName ?? this.packageName,
      fields: fields ?? this.fields,
      generateJson: generateJson ?? this.generateJson,
      generateCopyWithFn: generateCopyWithFn ?? this.generateCopyWithFn,
      generateCompareTo: generateCompareTo ?? this.generateCompareTo,
      isSealed: isSealed ?? this.isSealed,
      isNonSealed: isNonSealed ?? this.isNonSealed,
      generateFilter: generateFilter ?? this.generateFilter,
      extendsInterface: extendsInterface ?? this.extendsInterface,
      explicitSubtypes: explicitSubtypes ?? this.explicitSubtypes,
      generateSubtypes: generateSubtypes ?? this.generateSubtypes,
      dryRun: dryRun ?? this.dryRun,
      prefixNested: prefixNested ?? this.prefixNested,
    );
  }
}

/// Field definition for an entity
class FieldDefinition {
  final String name;
  final String type;
  final bool nullable;

  const FieldDefinition({
    required this.name,
    required this.type,
    this.nullable = false,
  });

  String get fullType => nullable && !type.endsWith('?') ? '$type?' : type;

  factory FieldDefinition.parse(String definition) {
    final parts = definition.split(':');
    if (parts.length != 2) {
      throw ArgumentError(
        'Invalid field format: "$definition". Expected "name:type"',
      );
    }
    final fieldName = parts[0].trim();
    var fieldType = parts[1].trim();
    final isNullable = fieldType.endsWith('?');
    if (isNullable) {
      fieldType = fieldType.substring(0, fieldType.length - 1);
    }
    return FieldDefinition(
      name: fieldName,
      type: fieldType,
      nullable: isNullable,
    );
  }

  FieldDefinition copyWith({String? name, String? type, bool? nullable}) {
    return FieldDefinition(
      name: name ?? this.name,
      type: type ?? this.type,
      nullable: nullable ?? this.nullable,
    );
  }
}

/// Result of entity creation
class EntityResult {
  final String className;
  final String filePath;
  final String content;
  final List<String> imports;
  final List<FieldDefinition> fields;
  final bool created;
  final String? error;

  const EntityResult({
    required this.className,
    required this.filePath,
    required this.content,
    this.imports = const [],
    this.fields = const [],
    this.created = true,
    this.error,
  });

  const EntityResult.failure(this.error)
    : className = '',
      filePath = '',
      content = '',
      imports = const [],
      fields = const [],
      created = false;

  bool get isSuccess => error == null && created;
}

/// Configuration for enum creation
class EnumConfig {
  final String name;
  final String? outputDir;
  final List<String> values;
  final bool dryRun;

  const EnumConfig({
    required this.name,
    this.outputDir,
    this.values = const [],
    this.dryRun = false,
  });

  String get defaultOutputDir => 'lib/src/domain/entities';

  String get className {
    var n = name.replaceAll('\$', '');
    final parts = n.split(RegExp(r'[_\s\-]+'));
    return parts
        .map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1);
        })
        .join('');
  }

  String get snakeName {
    final camel = className;
    return camel.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
      final char = match.group(0)!;
      final index = match.start;
      return (index == 0) ? char.toLowerCase() : '_${char.toLowerCase()}';
    });
  }
}

/// Result of enum creation
class EnumResult {
  final String enumName;
  final String filePath;
  final String content;
  final bool created;
  final String? error;

  const EnumResult({
    required this.enumName,
    required this.filePath,
    required this.content,
    this.created = true,
    this.error,
  });

  const EnumResult.failure(this.error)
    : enumName = '',
      filePath = '',
      content = '',
      created = false;

  bool get isSuccess => error == null && created;
}
