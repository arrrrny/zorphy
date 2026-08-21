import 'package:zorphy_annotation/zorphy_annotation.dart';

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

  /// Whether the entity owns an auto-generated uuid `id` field. When true
  /// the generated template declares `String get id;`, adds
  /// `autoId: true` to the annotation and imports
  /// `package:uuid/uuid.dart`.
  final bool autoId;

  /// The semantic kind of this class — [ZorphyKind.entity] (default) or
  /// [ZorphyKind.valueObject].
  final ZorphyKind kind;

  /// Custom JSON key for polymorphic dispatch (default: __typename)
  final String? typeKey;

  /// Custom wire value for this subtype in polymorphic JSON
  final String? subtypeWireValue;

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
    this.autoId = false,
    this.kind = ZorphyKind.entity,
    this.typeKey,
    this.subtypeWireValue,
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
    bool? autoId,
    ZorphyKind? kind,
    String? typeKey,
    String? subtypeWireValue,
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
      autoId: autoId ?? this.autoId,
      kind: kind ?? this.kind,
      typeKey: typeKey ?? this.typeKey,
      subtypeWireValue: subtypeWireValue ?? this.subtypeWireValue,
    );
  }
}

/// Field definition for an entity
class FieldDefinition {
  final String name;
  final String type;
  final bool nullable;

  /// Optional JSON wire name for the field, when it differs from the Dart
  /// [name]. Needed for GraphQL fields whose wire name is a Dart-reserved
  /// keyword (`in`, `required`) or that legitimately differ on the wire
  /// (Vendure's `_and` / `_or` filter operators). When set, the generated
  /// source getter carries `@JsonKey(name: '<jsonName>')`, which the zorphy
  /// builder already propagates into the concrete class and json_serializable
  /// output.
  final String? jsonName;

  /// True when the type was written with the `!` prefix (e.g. `url:!WebUri?`),
  /// marking it as EXTERNAL — a type that lives outside the entity tree
  /// (plugin wrappers like `WebUri`, SDK classes, ...). External types are
  /// kept as-is: no `$` prefix is added by `FieldNormalizer`, no entity/enum
  /// import is resolved by `ImportResolver`, and on-disk validation is
  /// skipped. The user is responsible for importing the type in the
  /// generated entity source.
  final bool isExternal;

  const FieldDefinition({
    required this.name,
    required this.type,
    this.nullable = false,
    this.jsonName,
    this.isExternal = false,
  });

  String get fullType => nullable && !type.endsWith('?') ? '$type?' : type;

  /// Parses a field definition in one of three forms:
  ///
  /// - `name:type` (e.g. `id:String`, `note:String?`, `countries:List<Country>`)
  /// - `name:!type` (e.g. `url:!WebUri?`) — external (non-entity, non-enum)
  ///   type, kept as-is with no `$` prefix, no import resolution, no
  ///   on-disk validation (see [isExternal]).
  /// - `name:type:json=<wireName>` (e.g. `in_:String:json=in`,
  ///   `and:ProductFilterParameter:json=_and`)
  factory FieldDefinition.parse(String definition) {
    final parts = definition.split(':');
    if (parts.length < 2 || parts.length > 3) {
      throw ArgumentError(
        'Invalid field format: "$definition". '
        'Expected "name:type" or "name:type:json=<wireName>"',
      );
    }
    final fieldName = parts[0].trim();
    var fieldType = parts[1].trim();
    final isExternal = fieldType.startsWith('!');
    if (isExternal) {
      fieldType = fieldType.substring(1);
      if (fieldType.isEmpty) {
        throw ArgumentError(
          'Invalid field format: "$definition". '
          'The "!" prefix requires a type name after it.',
        );
      }
    }
    final isNullable = fieldType.endsWith('?');
    if (isNullable) {
      fieldType = fieldType.substring(0, fieldType.length - 1);
    }
    String? jsonName;
    if (parts.length == 3) {
      final meta = parts[2].trim();
      const prefix = 'json=';
      if (!meta.startsWith(prefix)) {
        throw ArgumentError(
          'Invalid field meta: "$meta". Expected "json=<wireName>"',
        );
      }
      jsonName = meta.substring(prefix.length).trim();
      if (jsonName.isEmpty) {
        throw ArgumentError(
          'Invalid field meta: "$meta". "json=" requires a wire name',
        );
      }
    }
    return FieldDefinition(
      name: fieldName,
      type: fieldType,
      nullable: isNullable,
      jsonName: jsonName,
      isExternal: isExternal,
    );
  }

  FieldDefinition copyWith({
    String? name,
    String? type,
    bool? nullable,
    String? jsonName,
    bool? isExternal,
  }) {
    return FieldDefinition(
      name: name ?? this.name,
      type: type ?? this.type,
      nullable: nullable ?? this.nullable,
      jsonName: jsonName ?? this.jsonName,
      isExternal: isExternal ?? this.isExternal,
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
