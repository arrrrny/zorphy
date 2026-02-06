#!/usr/bin/env dart

/// Zorphy CLI - A command-line tool for generating and managing Zorphy entities
///
/// This CLI is designed to make it easy for AI agents and developers to create
/// Zorphy entity classes with proper structure and organization.

import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const String _version = '1.3.0';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'version',
      abbr: 'v',
      help: 'Show version information',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    )
    ..addCommand('create', _createCommandParser())
    ..addCommand('build', _buildCommandParser())
    ..addCommand('new', _newCommandParser())
    ..addCommand('list', _listCommandParser())
    ..addCommand('enum', _createEnumCommandParser())
    ..addCommand('add-field', _addFieldCommandParser())
    ..addCommand('from-json', _fromJsonCommandParser())
    ..addCommand('watch', _watchCommandParser());

  ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    print('Error: $e');
    print('\n${parser.usage}');
    exit(1);
  }

  if (results['help'] as bool) {
    print(_getFullUsage(parser));
    exit(0);
  }

  if (results['version'] as bool) {
    print('Zorphy CLI version $_version');
    exit(0);
  }

  final command = results.command;
  if (command == null) {
    print('No command specified.\n');
    print(parser.usage);
    exit(1);
  }

  switch (command.name) {
    case 'create':
      await _handleCreate(command);
      break;
    case 'build':
      await _handleBuild(command);
      break;
    case 'new':
      await _handleNew(command);
      break;
    case 'list':
      await _handleList(command);
      break;
    case 'enum':
      await _handleCreateEnum(command);
      break;
    case 'add-field':
      await _handleAddField(command);
      break;
    case 'from-json':
      await _handleFromJson(command);
      break;
    case 'watch':
      await _handleWatch(command);
      break;
  }
}

ArgParser _createCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the entity class (required)')
    ..addOption(
      'output',
      abbr: 'o',
      help: r'Output base directory (default: lib/src/domain/entities)',
    )
    ..addOption(
      'package',
      abbr: 'p',
      help: 'Package name for imports (default: uses pubspec.yaml)',
    )
    ..addFlag('json', help: 'Enable JSON serialization', defaultsTo: true)
    ..addFlag(
      'copywith-fn',
      help: 'Enable function-based copyWith',
      defaultsTo: false,
    )
    ..addFlag('compare', help: 'Enable compareTo generation', defaultsTo: true)
    ..addFlag(
      'sealed',
      help: r'Create a sealed abstract class (use $$ prefix)',
      defaultsTo: false,
    )
    ..addFlag(
      'non-sealed',
      help: 'Create non-sealed abstract class',
      defaultsTo: false,
    )
    ..addFlag(
      'fields',
      abbr: 'f',
      help: 'Interactive field prompts',
      defaultsTo: true,
    )
    ..addMultiOption(
      'field',
      help: r'Add fields in format: "name:type" or "name:type?" for nullable',
    )
    ..addOption('extends', help: r'Interface to extend (e.g., "\$BaseEntity")')
    ..addMultiOption(
      'subtypes',
      help: r'Explicit subtypes for polymorphism (e.g., "\$Dog,\$Cat")',
    )
    ..addFlag(
      'dry-run',
      help: 'Preview generated code without writing files',
      negatable: false,
    )
    ..addFlag(
      'generate-subs',
      help: 'Automatically generate subtype entities (use with --subtypes)',
      negatable: false,
    );
}

ArgParser _createEnumCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the enum (required)')
    ..addOption(
      'output',
      abbr: 'o',
      help: r'Output base directory (default: lib/src/domain/entities)',
    )
    ..addMultiOption(
      'value',
      help: 'Enum values (e.g., "active,inactive,pending")',
    )
    ..addFlag(
      'dry-run',
      help: 'Preview generated code without writing files',
      negatable: false,
    );
}

ArgParser _buildCommandParser() {
  return ArgParser()
    ..addFlag('watch', abbr: 'w', help: 'Watch for changes', defaultsTo: false)
    ..addFlag('clean', abbr: 'c', help: 'Clean before build', defaultsTo: false)
    ..addOption('output', abbr: 'o', help: 'Specify build output directory');
}

ArgParser _watchCommandParser() {
  return ArgParser()
    ..addFlag('clean', abbr: 'c', help: 'Clean before build', defaultsTo: false)
    ..addOption('output', abbr: 'o', help: 'Specify build output directory');
}

ArgParser _newCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the entity class (required)')
    ..addOption(
      'output',
      abbr: 'o',
      help: r'Output base directory (default: lib/src/domain/entities)',
    )
    ..addFlag('json', help: 'Enable JSON serialization', defaultsTo: true)
    ..addFlag(
      'dry-run',
      help: 'Preview generated code without writing files',
      negatable: false,
    );
}

ArgParser _listCommandParser() {
  return ArgParser()..addOption(
    'output',
    abbr: 'o',
    help: r'Directory to search (default: lib/src/domain/entities)',
  );
}

ArgParser _addFieldCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the entity (required)')
    ..addOption(
      'output',
      abbr: 'o',
      help: r'Output base directory (default: lib/src/domain/entities)',
    )
    ..addMultiOption(
      'field',
      help: r'Fields to add in format: "name:type" or "name:type?"',
    )
    ..addFlag(
      'dry-run',
      help: 'Preview generated code without writing files',
      negatable: false,
    );
}

ArgParser _fromJsonCommandParser() {
  return ArgParser()
    ..addOption(
      'name',
      abbr: 'n',
      help: 'Entity name (inferred from file if not provided)',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: r'Output base directory (default: lib/src/domain/entities)',
    )
    ..addFlag('json', help: 'Enable JSON serialization', defaultsTo: true)
    ..addFlag(
      'prefix-nested',
      help: 'Prefix nested entities with parent name',
      defaultsTo: true,
    )
    ..addFlag(
      'dry-run',
      help: 'Preview generated code without writing files',
      negatable: false,
    );
}

String _getFullUsage(ArgParser parser) {
  return '''
Zorphy CLI - Entity Generator for AI Agents & Developers

Version: $_version

USAGE:
  zorphy_cli <command> [options]

AVAILABLE COMMANDS:
  create      Create a new Zorphy entity with fields
  new         Quick-create a simple entity (basic defaults)
  build       Run code generation for Zorphy entities
  watch       Run code generation in watch mode (alias for build --watch)
  list        List all Zorphy entities in a directory
  enum        Create a new enum
  add-field   Add field(s) to an existing entity

GLOBAL OPTIONS:
  -h, --help       Show this help message
  -v, --version    Show version information

CREATE COMMAND:
  zorphy_cli create [options]
  Options:
    -n, --name              Entity name (required)
    -o, --output            Output base directory (default: lib/src/domain/entities)
    -p, --package           Package name for imports
    --json                  Enable JSON serialization (default: true)
    --copywith-fn           Enable function-based copyWith (default: false)
    --compare               Enable compareTo (default: true)
    --sealed                Create sealed class (default: false)
    --non-sealed            Create non-sealed class (default: false)
    -f, --fields            Interactive field prompts (default: true)
    --field                 Add fields directly ("name:type" or "name:type?")
    --extends               Interface to extend
    --subtypes              Explicit subtypes

ENUM COMMAND:
  zorphy_cli enum [options]
  Options:
    -n, --name              Enum name (required)
    -o, --output            Output base directory (default: lib/src/domain/entities)
    --value                 Enum values (comma-separated)

NEW COMMAND:
  zorphy_cli new [options]
  Options:
    -n, --name              Entity name (required)
    -o, --output            Output base directory (default: lib/src/domain/entities)
    --json                  Enable JSON (default: true)

BUILD COMMAND:
  zorphy_cli build [options]
  Options:
    -w, --watch             Watch for changes (default: false)
    -c, --clean             Clean before build (default: false)
    -o, --output            Build output directory

WATCH COMMAND:
  zorphy_cli watch [options]
  Options:
    -c, --clean             Clean before build (default: false)
    -o, --output            Build output directory

LIST COMMAND:
  zorphy_cli list [options]
  Options:
    -o, --output            Directory to search (default: lib/src/domain/entities)

ADD-FIELD COMMAND:
  zorphy_cli add-field [options]
  Options:
    -n, --name              Entity name (required)
    -o, --output            Output base directory (default: lib/src/domain/entities)
    --field                 Fields to add ("name:type" or "name:type?")

EXAMPLES:
  # Interactive entity creation
  zorphy_cli create -n User

  # Create with fields
  zorphy_cli create -n User --field name:String --field age:int --field email:String?

  # Create enum
  zorphy_cli enum -n Status --value active,inactive,pending

  # Quick create simple entity
  zorphy_cli new -n Product

  # Build all entities
  zorphy_cli build

  # Watch for changes
  zorphy_cli watch

  # List entities
  zorphy_cli list

  # Add field to existing entity
  zorphy_cli add-field -n User --field phone:String?

FIELD TYPES:
  Basic types: String, int, double, bool, num, DateTime
  Nullable types: Add ? after type (e.g., String?, int?)
  Generic types: List<Type>, Set<Type>, Map<KeyType, ValueType>
  Custom types: Any other class name
  Zorphy Objects: TypeName (e.g., User, Address). The CLI now automatically detects entities.
  Enums: TypeName (will be imported from enums/index.dart)

DIRECTORY STRUCTURE:
  Entities:     lib/src/domain/entities/entity_name/entity_name.dart
  Enums:        lib/src/domain/entities/enums/enum_name.dart
  Enum Barrel:  lib/src/domain/entities/enums/index.dart

  Imports:     Entities auto-import referenced entities
               Enums are imported from enums/index.dart

For more information, visit: https://github.com/arrrrny/zorphy
''';
}

/// Handle the create command
Future<void> _handleCreate(ArgResults args) async {
  final name = args['name'] as String?;
  if (name == null || name.isEmpty) {
    print('Error: Entity name is required. Use -n or --name to specify.');
    exit(1);
  }

  final baseOutputDir = args['output'] as String? ?? 'lib/src/domain/entities';
  final useJson = args['json'] as bool? ?? true;
  final useCopyWithFn = args['copywith-fn'] as bool? ?? false;
  final useCompare = args['compare'] as bool? ?? true;
  final isSealed = args['sealed'] as bool? ?? false;
  final isNonSealed = args['non-sealed'] as bool? ?? false;
  final useInteractiveFields = args['fields'] as bool? ?? true;
  final isDryRun = args['dry-run'] as bool? ?? false;
  final extendsInterface = args['extends'] as String?;
  final explicitSubtypes = args['subtypes'] as List<String>?;
  final generateSubs = args['generate-subs'] as bool? ?? false;

  // Get package name
  // String packageName = _getPackageName();
  // if (args['package'] != null) {
  //   packageName = args['package'] as String;
  // }

  // Collect fields from command line
  final providedFields = args['field'] as List<String>?;
  final fields = <_FieldInfo>[];

  if (providedFields != null && providedFields.isNotEmpty) {
    for (var fieldDef in providedFields) {
      final parts = fieldDef.split(':');
      if (parts.length != 2) {
        print(
          'Warning: Invalid field format "$fieldDef". Expected "name:type"',
        );
        continue;
      }
      final fieldName = parts[0].trim();
      final fieldType = _normalizeFieldType(
        parts[1].trim(),
        baseOutputDir: baseOutputDir,
      );
      fields.add(_FieldInfo(name: fieldName, type: fieldType));
    }
  }

  if (useInteractiveFields && fields.isEmpty) {
    print('\n📝 Creating Zorphy Entity: $name');
    print('Enter fields one by one. Press Enter without input to finish.\n');

    while (true) {
      stdout.write('Field name (or press Enter to finish): ');
      final fieldName = stdin.readLineSync()?.trim();
      if (fieldName == null || fieldName.isEmpty) break;

      stdout.write('Field type (e.g., String, int, List<String>, Status): ');
      final fieldType = _normalizeFieldType(
        stdin.readLineSync()?.trim() ?? 'String',
        baseOutputDir: baseOutputDir,
      );

      fields.add(_FieldInfo(name: fieldName, type: fieldType));
      print('✓ Added field: $fieldName ($fieldType)\n');
    }
  }

  if (fields.isEmpty) {
    print('Warning: No fields specified. Creating empty entity.');
  }

  // Collect subtypes and their fields IF they will be in the same file
  final subtypesWithFields = <String, List<_FieldInfo>>{};
  if (generateSubs && isSealed && explicitSubtypes != null) {
    print(
      '\n🔄 Collecting information for ${explicitSubtypes.length} subtype(s)...\n',
    );
    for (final subtype in explicitSubtypes) {
      final subtypeName = subtype.replaceAll('\$', '');
      final subtypeClassName = _formatClassName(subtypeName);
      final fieldsList = <_FieldInfo>[];

      if (useInteractiveFields && !isDryRun) {
        print('📝 Additional fields for $subtypeClassName:');
        while (true) {
          stdout.write('  Field name (or Enter to finish): ');
          final fieldName = stdin.readLineSync()?.trim();
          if (fieldName == null || fieldName.isEmpty) break;

          stdout.write('  Field type: ');
          final fieldType = _normalizeFieldType(
            stdin.readLineSync()?.trim() ?? 'String',
            baseOutputDir: baseOutputDir,
          );
          fieldsList.add(_FieldInfo(name: fieldName, type: fieldType));
        }
      }
      subtypesWithFields[subtype] = fieldsList;
    }
  }

  // Class name formatting
  final className = _formatClassName(name);
  final entityDirName = _toSnakeCase(className);

  // Create directory structure: lib/src/domain/entities/entity_name/
  final entityDir = p.join(baseOutputDir, entityDirName);
  final dir = Directory(entityDir);
  if (!isDryRun && !await dir.exists()) {
    await dir.create(recursive: true);
    print('✓ Created entity directory: $entityDir');
  }

  // File path: lib/src/domain/entities/entity_name/entity_name.dart
  final filePath = p.join(entityDir, '$entityDirName.dart');
  final file = File(filePath);

  final buffer = StringBuffer();

  // File header
  buffer.writeln('/// Auto-generated by Zorphy CLI');
  buffer.writeln('/// Generated at: ${DateTime.now().toIso8601String()}');
  buffer.writeln();
  buffer.writeln("import 'package:zorphy_annotation/zorphy_annotation.dart';");

  // Add imports for nested Zorphy objects and enums
  final entityImports = <String>{};
  bool needsEnumImport = false;

  final allFieldsForImports = [...fields];
  for (final subFields in subtypesWithFields.values) {
    allFieldsForImports.addAll(subFields);
  }

  for (final field in allFieldsForImports) {
    final type = field.type;

    // Extract all type references (including generics)
    final typeRefs = _extractTypeReferences(type);

    for (final typeRef in typeRefs) {
      // Skip primitive types
      if (_isPrimitiveType(typeRef)) continue;

      // Skip self-reference
      final cleanTypeRef = typeRef.replaceAll(RegExp(r'^\$+'), '');
      if (cleanTypeRef == className) continue;

      // Check if it's a Zorphy entity (starts with $ or $$ or directory exists)
      final typeSnakeName = _toSnakeCase(cleanTypeRef);
      final potentialEntityPath = p.join(baseOutputDir, typeSnakeName);

      if (typeRef.startsWith(r'$') ||
          (!isDryRun && Directory(potentialEntityPath).existsSync())) {
        entityImports.add("import '../$typeSnakeName/$typeSnakeName.dart';");
      } else {
        needsEnumImport = true;
        // Assume it's an enum - will be imported from enums/index.dart
      }
    }
  }
  if (needsEnumImport) {
    entityImports.add("import '../enums/index.dart';");
  }

  // Add extends interface import if specified
  if (extendsInterface != null) {
    final cleanExtends = extendsInterface.replaceAll(RegExp(r'^\$+'), '');
    if (cleanExtends != className) {
      final extendsSnakeName = _toSnakeCase(cleanExtends);
      entityImports.add(
        "import '../$extendsSnakeName/$extendsSnakeName.dart';",
      );
    }
  }

  // Add subtype imports if specified
  if (explicitSubtypes != null) {
    for (final subtype in explicitSubtypes) {
      final cleanSubtype = subtype.replaceAll(RegExp(r'^\$+'), '');
      if (cleanSubtype != className) {
        // If we're generating subs for a sealed class, they'll be in the same file
        if (!(generateSubs && isSealed)) {
          final subtypeSnakeName = _toSnakeCase(cleanSubtype);
          entityImports.add(
            "import '../$subtypeSnakeName/$subtypeSnakeName.dart';",
          );
        }
      }
    }
  }

  // Add imports if any
  if (entityImports.isNotEmpty) {
    // Deduplicate and sort
    final uniqueImports = entityImports.toList()..sort();
    for (final import in uniqueImports) {
      buffer.writeln(import);
    }
    buffer.writeln();
  }

  // Add part directives - zorphy first, then g
  buffer.writeln("part '$entityDirName.zorphy.dart';");
  final hasExplicitSubtypes =
      explicitSubtypes != null && explicitSubtypes.isNotEmpty;
  if (useJson && (!isSealed && !isNonSealed || hasExplicitSubtypes)) {
    buffer.writeln("part '$entityDirName.g.dart';");
  }
  buffer.writeln();

  // Annotation options
  final annotationOptions = <String>[];
  if (useJson) annotationOptions.add('generateJson: true');
  if (useCopyWithFn) annotationOptions.add('generateCopyWithFn: true');
  if (useCompare) annotationOptions.add('generateCompareTo: true');
  if (isNonSealed) annotationOptions.add('nonSealed: true');

  // Add explicitSubTypes if provided
  if (explicitSubtypes != null && explicitSubtypes.isNotEmpty) {
    final subtypes = explicitSubtypes.map((s) => '\$$s').join(', ');
    annotationOptions.add("explicitSubTypes: [$subtypes]");
  }

  // Class definition - Use raw string to avoid interpolation
  final abstractClassName = isSealed ? r'$$' + className : r'$' + className;

  buffer.writeln('/// $className entity');
  buffer.writeln('@Zorphy(${annotationOptions.join(', ')})');
  if (extendsInterface != null) {
    buffer.writeln(
      'abstract class $abstractClassName implements $extendsInterface {',
    );
  } else {
    buffer.writeln('abstract class $abstractClassName {');
  }
  buffer.writeln();

  // Fields
  for (final field in fields) {
    buffer.writeln('  ${field.type} get ${field.name};');
  }

  buffer.writeln('}');
  buffer.writeln();

  // Generate subtypes in the same file if it's a sealed class
  if (generateSubs && isSealed && explicitSubtypes != null) {
    print('\n🔄 Generating ${explicitSubtypes.length} subtype(s) in $filePath...');

    for (final subtype in explicitSubtypes) {
      final subtypeName = subtype.replaceAll('\$', '');
      final subtypeClassName = _formatClassName(subtypeName);
      final subtypeFields = subtypesWithFields[subtype] ?? [];

      // Add subtype definition to the main buffer
      final subtypeAnnotationOptions = <String>[];
      if (useJson) subtypeAnnotationOptions.add('generateJson: true');
      if (useCopyWithFn) {
        subtypeAnnotationOptions.add('generateCopyWithFn: true');
      }
      if (useCompare) subtypeAnnotationOptions.add('generateCompareTo: true');

      buffer.writeln('/// $subtypeClassName entity (subtype of $className)');
      buffer.writeln('@Zorphy(${subtypeAnnotationOptions.join(', ')})');
      final parentRef = isSealed ? '\$\$$className' : '\$$className';
      buffer.writeln(
        'abstract class \$$subtypeClassName implements $parentRef {',
      );
      if (subtypeFields.isNotEmpty) {
        buffer.writeln();
        for (final field in subtypeFields) {
          buffer.writeln('  ${field.type} get ${field.name};');
        }
      }
      buffer.writeln('}');
      buffer.writeln();
    }
  }

  // Write file
  if (isDryRun) {
    print('\n🚀 [DRY RUN] Would create $filePath with content:\n');
    print(buffer.toString());
  } else {
    await file.writeAsString(buffer.toString());
    print('✓ Created entity file: $filePath');
  }

  // Print instructions
  print('\n📋 Next steps:');
  print('  1. Run: zorphy_cli build');
  print('  2. Or run: dart run build_runner build');
  print('  3. Import and use your $className class');

  if (fields.isNotEmpty) {
    print('\n✨ Generated ${fields.length} fields:');
    for (final field in fields) {
      print('  - ${field.name}: ${field.type}');
    }
  }

  if (entityImports.isNotEmpty) {
    print('\n📦 Auto-imported:');
    for (final import in entityImports) {
      print('  - $import');
    }
  }

  // Generate subtypes in separate files if NOT a sealed class
  if (generateSubs && !isSealed && explicitSubtypes != null && explicitSubtypes.isNotEmpty) {
    print('\n🔄 Generating ${explicitSubtypes.length} subtype(s) in separate files...\n');

    for (final subtype in explicitSubtypes) {
      final subtypeName = subtype.replaceAll(
        '\$',
        '',
      ); // Remove $ prefix if present
      print('📝 Creating subtype: $subtypeName');

      // Collect additional fields for this subtype
      final subtypeFields = <_FieldInfo>[];

      if (useInteractiveFields && !isDryRun) {
        print(
          '  Add additional fields for $subtypeName (inherited fields from $className will be included automatically)',
        );
        print('  Press Enter without input to skip.\n');

        while (true) {
          stdout.write('  Field name (or press Enter to finish): ');
          final fieldName = stdin.readLineSync()?.trim();
          if (fieldName == null || fieldName.isEmpty) break;

          stdout.write('  Field type (e.g., String, int, List<String>): ');
          final fieldType = _normalizeFieldType(
            stdin.readLineSync()?.trim() ?? 'String',
            baseOutputDir: baseOutputDir,
          );

          subtypeFields.add(_FieldInfo(name: fieldName, type: fieldType));
          print('  ✓ Added field: $fieldName ($fieldType)\n');
        }
      }

      // Create the subtype entity with extends
      final subtypeClassName = _formatClassName(subtypeName);
      final subtypeEntityDirName = _toSnakeCase(subtypeClassName);
      final subtypeEntityDir = p.join(baseOutputDir, subtypeEntityDirName);
      final subtypeDir = Directory(subtypeEntityDir);

      if (!isDryRun && !await subtypeDir.exists()) {
        await subtypeDir.create(recursive: true);
      }

      final subtypeFilePath = p.join(
        subtypeEntityDir,
        '$subtypeEntityDirName.dart',
      );
      final subtypeFile = File(subtypeFilePath);
      final subtypeBuffer = StringBuffer();

      // File header
      subtypeBuffer.writeln('/// Auto-generated by Zorphy CLI');
      subtypeBuffer.writeln('/// Generated at: ${DateTime.now()}');
      subtypeBuffer.writeln();

      // Imports
      subtypeBuffer.writeln(
        "import 'package:zorphy_annotation/zorphy_annotation.dart';",
      );
      subtypeBuffer.writeln("import '../$entityDirName/$entityDirName.dart';");

      // Add imports for additional field types
      for (final field in subtypeFields) {
        for (final typeRef in _extractTypeReferences(field.type)) {
          if (_isPrimitiveType(typeRef)) continue;

          final typeSnakeName = _toSnakeCase(typeRef.replaceAll('\$', ''));
          final potentialEntityPath = p.join(baseOutputDir, typeSnakeName);

          if (typeRef.startsWith(r'\$') ||
              (!isDryRun && Directory(potentialEntityPath).existsSync())) {
            subtypeBuffer.writeln(
              "import '../$typeSnakeName/$typeSnakeName.dart';",
            );
          }
        }
      }

      subtypeBuffer.writeln();

      // Part directives
      subtypeBuffer.writeln("part '$subtypeEntityDirName.zorphy.dart';");
      if (useJson) {
        subtypeBuffer.writeln("part '$subtypeEntityDirName.g.dart';");
      }
      subtypeBuffer.writeln();

      // Annotation
      final subtypeAnnotationOptions = <String>[];
      if (useJson) subtypeAnnotationOptions.add('generateJson: true');
      if (useCopyWithFn)
        subtypeAnnotationOptions.add('generateCopyWithFn: true');
      if (useCompare) subtypeAnnotationOptions.add('generateCompareTo: true');

      subtypeBuffer.writeln(
        '/// $subtypeClassName entity (subtype of $className)',
      );
      subtypeBuffer.writeln('@Zorphy(${subtypeAnnotationOptions.join(', ')})');

      // Class definition - implements parent
      final parentRef = isSealed ? '\$\$$className' : '\$$className';
      subtypeBuffer.writeln(
        'abstract class \$$subtypeClassName implements $parentRef {',
      );
      subtypeBuffer.writeln();

      // Additional fields only (parent fields are inherited)
      for (final field in subtypeFields) {
        subtypeBuffer.writeln('  ${field.type} get ${field.name};');
      }

      subtypeBuffer.writeln('}');
      subtypeBuffer.writeln();

      // Write file
      if (isDryRun) {
        print('  🚀 [DRY RUN] Would create $subtypeFilePath');
        if (subtypeFields.isNotEmpty) {
          print(
            '  ✨ Additional fields: ${subtypeFields.map((f) => '${f.name}: ${f.type}').join(', ')}',
          );
        }
      } else {
        await subtypeFile.writeAsString(subtypeBuffer.toString());
        print('  ✓ Created: $subtypeFilePath');
        if (subtypeFields.isNotEmpty) {
          print(
            '  ✨ Additional fields: ${subtypeFields.map((f) => '${f.name}: ${f.type}').join(', ')}',
          );
        }
      }
      print('');
    }

    print('✅ Generated ${explicitSubtypes.length} subtype(s) successfully!');
  }
}

/// Extract all type references from a type string (including generics)
Set<String> _extractTypeReferences(String type) {
  final refs = <String>{};

  // Remove nullable marker
  type = type.replaceAll('?', '');

  // Extract all identifiers (including those with $ prefix)
  final pattern = RegExp(r'\$*[A-Z][a-zA-Z0-9]*');
  final matches = pattern.allMatches(type);

  for (final match in matches) {
    refs.add(match.group(0)!);
  }

  return refs;
}

/// Check if a type is a primitive Dart type
bool _isPrimitiveType(String type) {
  const primitives = {
    'String',
    'int',
    'double',
    'bool',
    'num',
    'DateTime',
    'List',
    'Set',
    'Map',
    'dynamic',
    'Object',
    'Iterable',
    'Future',
    'Stream',
  };
  return primitives.contains(type);
}

/// Handle the enum command
Future<void> _handleCreateEnum(ArgResults args) async {
  final name = args['name'] as String?;
  if (name == null || name.isEmpty) {
    print('Error: Enum name is required. Use -n or --name to specify.');
    exit(1);
  }

  final baseOutputDir = args['output'] as String? ?? 'lib/src/domain/entities';
  final providedValues = args['value'] as List<String>?;
  final values = providedValues ?? <String>[];
  final isDryRun = args['dry-run'] as bool? ?? false;

  if (values.isEmpty) {
    print(
      'Error: Enum values are required. Use --value with comma-separated values.',
    );
    exit(1);
  }

  // Create enums directory
  final enumsDir = p.join(baseOutputDir, 'enums');
  final dir = Directory(enumsDir);
  if (!isDryRun && !await dir.exists()) {
    await dir.create(recursive: true);
    print('✓ Created enums directory: $enumsDir');
  }

  // Check if enum file already exists
  final enumName = _formatClassName(name);
  final enumSnakeName = _toSnakeCase(enumName);
  final filePath = p.join(enumsDir, '$enumSnakeName.dart');
  final file = File(filePath);

  // Read existing enums to check for duplicates
  final existingEnums = <String>[];
  final indexFile = File(p.join(enumsDir, 'index.dart'));
  if (!isDryRun && await indexFile.exists()) {
    final indexContent = await indexFile.readAsString();
    // Extract existing enum names from exports
    final exportMatches = RegExp(
      r"export '([^']+)\.dart';",
    ).allMatches(indexContent);
    for (final match in exportMatches) {
      existingEnums.add(match.group(1)!);
    }
  }

  if (existingEnums.contains(enumName)) {
    print('Warning: Enum $enumName already exists at $filePath');
    print('Use a different name or manually edit the file.');
    return;
  }

  // Create/update the enum file
  final buffer = StringBuffer();
  buffer.writeln('/// Auto-generated by Zorphy CLI');
  buffer.writeln('/// Generated at: ${DateTime.now().toIso8601String()}');
  buffer.writeln();
  buffer.writeln('enum $enumName {');

  for (var i = 0; i < values.length; i++) {
    final value = values[i].trim();
    if (value.isNotEmpty) {
      buffer.writeln('  ${i == 0 ? '' : ','} $value');
    }
  }

  buffer.writeln('}');
  buffer.writeln();

  if (isDryRun) {
    print('\n🚀 [DRY RUN] Would create $filePath with content:\n');
    print(buffer.toString());
  } else {
    await file.writeAsString(buffer.toString());
    print('✓ Created enum file: $filePath');

    // Update the index.dart barrel file
    await _updateEnumIndexFile(enumsDir, existingEnums);
  }

  print('\n📋 Enum exported to: lib/src/domain/entities/enums/index.dart');
  print('   Import in entities: import \'../../enums/index.dart\';');
}

/// Update the enum barrel file
Future<void> _updateEnumIndexFile(
  String enumsDir,
  List<String> existingEnums,
) async {
  final indexFile = File(p.join(enumsDir, 'index.dart'));

  // Get all enum files in the directory
  final allEnums = <String>[];
  await for (final entity in Directory(enumsDir).list()) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('index.dart')) {
      final enumName = p.basenameWithoutExtension(entity.path);
      allEnums.add(enumName);
    }
  }

  // Sort alphabetically
  allEnums.sort();

  // Create index.dart content
  final buffer = StringBuffer();
  buffer.writeln('/// Auto-generated enum barrel file');
  buffer.writeln('/// Exports all enums for easy importing');
  buffer.writeln('/// Generated at: ${DateTime.now().toIso8601String()}');
  buffer.writeln();
  buffer.writeln('library enums;');
  buffer.writeln();

  for (final enumName in allEnums) {
    buffer.writeln("export '$enumName.dart';");
  }

  await indexFile.writeAsString(buffer.toString());
  print('✓ Updated enum barrel file: ${indexFile.path}');
  print('   Total enums: ${allEnums.length}');
}

/// Handle the build command
Future<void> _handleBuild(ArgResults args) async {
  final watch = args['watch'] as bool? ?? false;
  final clean = args['clean'] as bool? ?? false;

  print('🔨 Building Zorphy entities...');

  if (clean) {
    print('🧹 Cleaning generated files...');
  }

  if (watch) {
    print('👀 Watching for changes...');
    print('Press Ctrl+C to stop');
  }

  // Check if build_runner is available
  final process = await Process.start('dart', [
    'run',
    'build_runner',
    if (clean) 'clean',
    'build',
    if (watch) '--watch',
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await process.exitCode;
  if (exitCode == 0) {
    print('\n✅ Build complete!');
  } else {
    print('\n❌ Build failed with exit code $exitCode');
    exit(exitCode);
  }
}

/// Handle the watch command
Future<void> _handleWatch(ArgResults args) async {
  final clean = args['clean'] as bool? ?? false;

  print('👀 Starting Zorphy watch mode...');

  if (clean) {
    print('🧹 Cleaning generated files...');
  }

  print('Press Ctrl+C to stop');

  // Check if build_runner is available
  final process = await Process.start('dart', [
    'run',
    'build_runner',
    if (clean) 'clean',
    'watch',
    '--delete-conflicting-outputs',
  ], mode: ProcessStartMode.inheritStdio);

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('\n❌ Watch failed with exit code $exitCode');
    exit(exitCode);
  }
}

/// Handle the new command (quick create)
Future<void> _handleNew(ArgResults args) async {
  final name = args['name'] as String?;
  if (name == null || name.isEmpty) {
    print('Error: Entity name is required. Use -n or --name to specify.');
    exit(1);
  }

  final baseOutputDir = args['output'] as String? ?? 'lib/src/domain/entities';
  final useJson = args['json'] as bool? ?? true;
  final isDryRun = args['dry-run'] as bool? ?? false;

  print('📝 Creating quick entity: $name');

  // Create entity directly (simplified)
  final className = _formatClassName(name);
  final entityDirName = _toSnakeCase(className);

  // Create directory structure
  final entityDir = p.join(baseOutputDir, entityDirName);
  final dir = Directory(entityDir);
  if (!isDryRun && !await dir.exists()) {
    await dir.create(recursive: true);
  }

  final filePath = p.join(entityDir, '$entityDirName.dart');
  final file = File(filePath);
  final buffer = StringBuffer();

  buffer.writeln('/// Auto-generated by Zorphy CLI');
  buffer.writeln("import 'package:zorphy_annotation/zorphy_annotation.dart';");
  buffer.writeln();
  buffer.writeln("part '$entityDirName.zorphy.dart';");
  if (useJson) {
    buffer.writeln("part '$entityDirName.g.dart';");
  }
  buffer.writeln();
  buffer.writeln('@Zorphy(generateJson: $useJson)');
  buffer.writeln('abstract class \$$className {');
  buffer.writeln('}');

  if (isDryRun) {
    print('\n🚀 [DRY RUN] Would create $filePath with content:\n');
    print(buffer.toString());
  } else {
    await file.writeAsString(buffer.toString());
    print('✓ Created entity file: $filePath');
  }
  print('\n📋 Next steps:');
  print('   1. Run: dart run build_runner build');
}

/// Handle the list command
Future<void> _handleList(ArgResults args) async {
  final outputDir = args['output'] as String? ?? 'lib/src/domain/entities';

  final dir = Directory(outputDir);
  if (!await dir.exists()) {
    print('No entities found. Directory does not exist: $outputDir');
    return;
  }

  print('📂 Zorphy Entities in $outputDir:\n');

  final entities = <String>[];
  await for (final entity in dir.list()) {
    if (entity is Directory) {
      final entityName = p.basename(entity.path);
      final dartFile = File(p.join(entity.path, '$entityName.dart'));

      if (await dartFile.exists()) {
        entities.add(entityName);

        // Read file to extract class info
        final contents = await dartFile.readAsString();
        final hasJson = contents.contains('generateJson: true');
        final hasCopyWithFn = contents.contains('generateCopyWithFn: true');
        final isSealed = contents.contains('abstract class \$\$');

        print('  📄 $entityName');
        print('     Path: ${entity.path}');
        if (hasJson) print('     ✓ JSON support');
        if (hasCopyWithFn) print('     ✓ Function-based copyWith');
        if (isSealed) print('     🔒 Sealed class');
        print('');
      }
    }
  }

  // List enums
  final enumsDir = Directory(p.join(outputDir, 'enums'));
  if (await enumsDir.exists()) {
    print('📂 Enums:\n');
    await for (final entity in enumsDir.list()) {
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.contains('index.dart')) {
        final enumName = p.basenameWithoutExtension(entity.path);
        print('  📋 $enumName');
        print('     Path: ${entity.path}');
        print('');
      }
    }

    print('📦 Barrel file: lib/src/domain/entities/enums/index.dart');
    print('   Import: import \'../../enums/index.dart\';');
    print('');
  }

  if (entities.isEmpty && !await enumsDir.exists()) {
    print('  No Zorphy entities or enums found.');
  } else {
    print('  Total: ${entities.length} entity/entities');
  }
}

/// Handle the add-field command
Future<void> _handleAddField(ArgResults args) async {
  final name = args['name'] as String?;
  if (name == null || name.isEmpty) {
    print('Error: Entity name is required. Use -n or --name to specify.');
    exit(1);
  }

  final baseOutputDir = args['output'] as String? ?? 'lib/src/domain/entities';
  final providedFields = args['field'] as List<String>?;
  final isDryRun = args['dry-run'] as bool? ?? false;

  if (providedFields == null || providedFields.isEmpty) {
    print('Error: At least one field is required. Use --field to specify.');
    exit(1);
  }

  // Parse fields
  final fields = <_FieldInfo>[];
  for (var fieldDef in providedFields) {
    final parts = fieldDef.split(':');
    if (parts.length != 2) {
      print('Warning: Invalid field format "$fieldDef". Expected "name:type"');
      continue;
    }
    final fieldName = parts[0].trim();
    final fieldType = _normalizeFieldType(
      parts[1].trim(),
      baseOutputDir: baseOutputDir,
    );
    fields.add(_FieldInfo(name: fieldName, type: fieldType));
  }

  if (fields.isEmpty) {
    print('Error: No valid fields provided.');
    exit(1);
  }

  // Find entity file
  final className = _formatClassName(name);
  final entityDirName = _toSnakeCase(className);
  final entityDir = p.join(baseOutputDir, entityDirName);
  final filePath = p.join(entityDir, '$entityDirName.dart');
  final file = File(filePath);

  if (!isDryRun && !await file.exists()) {
    print('Error: Entity not found at $filePath');
    print('Use "zorphy_cli create -n $name" to create it first.');
    exit(1);
  }

  // Read existing file
  final content = isDryRun && !await file.exists()
      ? 'abstract class \$$className {}'
      : await file.readAsString();

  // Find the closing brace of the class
  final classPattern = RegExp(r'abstract class \$+' + className + r'\s*\{');
  final classMatch = classPattern.firstMatch(content);

  if (classMatch == null) {
    print('Error: Could not find class definition in $filePath');
    exit(1);
  }

  // Find last field or class opening brace
  final lastFieldPattern = RegExp(r'^\s*\S+\s+get\s+\w+;', multiLine: true);
  final allMatches = lastFieldPattern.allMatches(content).toList();

  int insertPosition;
  if (allMatches.isEmpty) {
    // No fields yet, insert after class opening brace
    insertPosition = content.indexOf('{', classMatch.end) + 1;
  } else {
    // Insert after last field
    insertPosition = allMatches.last.end;
  }

  // Collect new imports
  final newImports = <String>{};
  for (final field in fields) {
    final typeRefs = _extractTypeReferences(field.type);
    for (final typeRef in typeRefs) {
      if (_isPrimitiveType(typeRef)) continue;
      final cleanTypeRef = typeRef.replaceAll(RegExp(r'^\$+'), '');
      if (cleanTypeRef == className) continue;

      final typeSnakeName = _toSnakeCase(cleanTypeRef);
      final potentialEntityPath = p.join(baseOutputDir, typeSnakeName);

      if (typeRef.startsWith(r'$') ||
          (!isDryRun && Directory(potentialEntityPath).existsSync())) {
        newImports.add("import '../$typeSnakeName/$typeSnakeName.dart';");
      } else {
        newImports.add("import '../enums/index.dart';");
      }
    }
  }

  // Add imports if needed
  String updatedContent = content;
  if (newImports.isNotEmpty) {
    // Find where to insert imports (after existing imports, before part directives)
    final partPattern = RegExp(r"^part\s+'", multiLine: true);
    final partMatch = partPattern.firstMatch(content);

    if (partMatch != null) {
      final existingImports = content.substring(0, partMatch.start);
      final newImportLines =
          newImports.where((imp) => !existingImports.contains(imp)).toList()
            ..sort();

      if (newImportLines.isNotEmpty) {
        final importInsertPos = partMatch.start;
        updatedContent =
            content.substring(0, importInsertPos) +
            newImportLines.join('\n') +
            '\n' +
            content.substring(importInsertPos);

        // Recalculate insert position after adding imports
        insertPosition += newImportLines.join('\n').length + 1;
      }
    }
  }

  // Build field definitions
  final fieldBuffer = StringBuffer();
  for (final field in fields) {
    fieldBuffer.writeln();
    fieldBuffer.writeln('  ${field.type} get ${field.name};');
  }

  // Insert fields
  final finalContent =
      updatedContent.substring(0, insertPosition) +
      fieldBuffer.toString() +
      updatedContent.substring(insertPosition);

  // Write back
  if (isDryRun) {
    print('\n🚀 [DRY RUN] Would update $filePath with content:\n');
    print(finalContent);
  } else {
    await file.writeAsString(finalContent);
  }

  print('✓ Added ${fields.length} field(s) to $className');
  print('  File: $filePath');
  for (final field in fields) {
    print('  + ${field.name}: ${field.type}');
  }

  if (newImports.isNotEmpty) {
    print('\n📦 Added imports:');
    for (final imp in newImports) {
      print('  - $imp');
    }
  }

  print('\n📋 Next step: Run build to regenerate code');
}

/// Handle the from-json command
Future<void> _handleFromJson(ArgResults args) async {
  if (args.rest.isEmpty) {
    print('Error: JSON file path is required.');
    exit(1);
  }

  final jsonFile = File(args.rest.first);
  if (!await jsonFile.exists()) {
    print('Error: JSON file not found: ${jsonFile.path}');
    exit(1);
  }

  final content = await jsonFile.readAsString();
  final json = jsonDecode(content) as Map<String, dynamic>;

  final name =
      args['name'] as String? ?? p.basenameWithoutExtension(jsonFile.path);
  final baseOutputDir = args['output'] as String? ?? 'lib/src/domain/entities';
  final useJson = args['json'] as bool? ?? true;
  final prefixNested = args['prefix-nested'] as bool? ?? true;
  final isDryRun = args['dry-run'] as bool? ?? false;

  // Parse JSON
  final result = _parseJson(
    json,
    _formatClassName(name),
    prefixNested: prefixNested,
  );

  // Create all entities (main + nested)
  final allEntities = [result, ...result.nested];

  for (final entity in allEntities) {
    await _createEntityFromResult(
      entity,
      baseOutputDir,
      useJson,
      isDryRun: isDryRun,
    );
  }

  print('\n✓ Created ${allEntities.length} entity/entities from JSON');
  print('  Main: ${result.name}');
  if (result.nested.isNotEmpty) {
    print('  Nested: ${result.nested.map((e) => e.name).join(', ')}');
  }
}

Future<void> _createEntityFromResult(
  _EntityResult entity,
  String baseDir,
  bool useJson, {
  bool isDryRun = false,
}) async {
  final snakeName = _toSnakeCase(entity.name);
  final entityDir = p.join(baseDir, snakeName);
  if (!isDryRun) {
    await Directory(entityDir).create(recursive: true);
  }

  final imports = <String>{};
  for (final field in entity.fields) {
    final refs = _extractTypeReferences(field.fullType);
    for (final ref in refs) {
      if (_isPrimitiveType(ref)) continue;
      if (ref.replaceAll(RegExp(r'^\$+'), '') == entity.name) continue;

      if (ref.startsWith(r'$')) {
        final refSnake = _toSnakeCase(ref.replaceAll(RegExp(r'^\$+'), ''));
        imports.add("import '../$refSnake/$refSnake.dart';");
      } else {
        imports.add("import '../enums/index.dart';");
      }
    }
  }

  final buf = StringBuffer();
  buf.writeln("import 'package:zorphy_annotation/zorphy_annotation.dart';");
  if (imports.isNotEmpty) {
    final sorted = imports.toList()..sort();
    for (final imp in sorted) {
      buf.writeln(imp);
    }
  }
  buf.writeln();
  buf.writeln("part '$snakeName.zorphy.dart';");
  if (useJson) {
    buf.writeln("part '$snakeName.g.dart';");
  }
  buf.writeln();
  buf.writeln('@Zorphy(generateJson: $useJson, generateCompareTo: true)');
  buf.writeln('abstract class \$${entity.name} {');
  for (final field in entity.fields) {
    buf.writeln('  ${field.fullType} get ${field.name};');
  }
  buf.writeln('}');

  if (isDryRun) {
    print(
      '\n🚀 [DRY RUN] Would create ${p.join(entityDir, '$snakeName.dart')} with content:\n',
    );
    print(buf.toString());
  } else {
    await File(
      p.join(entityDir, '$snakeName.dart'),
    ).writeAsString(buf.toString());
  }
}

_EntityResult _parseJson(
  Map<String, dynamic> json,
  String name, {
  bool prefixNested = true,
  String? parentPrefix,
}) {
  final fullName = prefixNested && parentPrefix != null
      ? '$parentPrefix$name'
      : name;
  final fields = <_Field>[];
  final nested = <_EntityResult>[];

  for (final entry in json.entries) {
    final key = entry.key;
    final value = entry.value;

    final isNullable = key.endsWith('?');
    final fieldName = isNullable ? key.substring(0, key.length - 1) : key;

    if (value is Map<String, dynamic>) {
      final nestedName = _formatClassName(fieldName);
      final nestedResult = _parseJson(
        value,
        nestedName,
        prefixNested: prefixNested,
        parentPrefix: prefixNested ? fullName : null,
      );
      nested.add(nestedResult);
      fields.add(_Field(fieldName, '\$${nestedResult.name}', isNullable));
    } else if (value is List && value.isNotEmpty && value.first is Map) {
      final nestedName = _formatClassName(_singularize(fieldName));
      final nestedResult = _parseJson(
        value.first as Map<String, dynamic>,
        nestedName,
        prefixNested: prefixNested,
        parentPrefix: prefixNested ? fullName : null,
      );
      nested.add(nestedResult);
      fields.add(_Field(fieldName, 'List<\$${nestedResult.name}>', isNullable));
    } else {
      final type = _inferJsonType(value);
      fields.add(_Field(fieldName, type, isNullable || value == null));
    }
  }

  return _EntityResult(fullName, fields, nested);
}

String _inferJsonType(dynamic value) {
  if (value == null) return 'dynamic';
  if (value is String) {
    if (DateTime.tryParse(value) != null) return 'DateTime';
    return 'String';
  }
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is bool) return 'bool';
  if (value is List) {
    if (value.isEmpty) return 'List<dynamic>';
    return 'List<${_inferJsonType(value.first)}>';
  }
  return 'dynamic';
}

String _singularize(String s) {
  if (s.endsWith('ies')) return s.substring(0, s.length - 3) + 'y';
  if (s.endsWith('es')) return s.substring(0, s.length - 2);
  if (s.endsWith('s')) return s.substring(0, s.length - 1);
  return s;
}

class _EntityResult {
  final String name;
  final List<_Field> fields;
  final List<_EntityResult> nested;
  _EntityResult(this.name, this.fields, this.nested);
}

class _Field {
  final String name;
  final String type;
  final bool nullable;
  _Field(this.name, this.type, this.nullable);
  String get fullType => nullable && !type.endsWith('?') ? '$type?' : type;
}

// /// Get package name from pubspec.yaml
// String _getPackageName() {
//   final pubspecFile = File('pubspec.yaml');
//   if (pubspecFile.existsSync()) {
//     final contents = pubspecFile.readAsStringSync();
//     final nameMatch = RegExp(
//       r'^name:\s*(.+)$',
//       multiLine: true,
//     ).firstMatch(contents);
//     if (nameMatch != null) {
//       return nameMatch.group(1)!.trim();
//     }
//   }
//   return 'my_app';
// }

/// Normalize field type by adding $ prefix for entity types (non-primitives, non-enums)
/// Examples:
///   "String" -> "String"
///   "Address" -> "$Address"
///   "$Address" -> "$Address" (already prefixed)
///   "List<User>" -> "List<$User>"
///   "Animal" -> "$$Animal" (if Animal is sealed)
///   "Map<String, Product>" -> "Map<String, $Product>"
String _normalizeFieldType(String type, {required String baseOutputDir}) {
  // Remove nullable marker temporarily
  final isNullable = type.endsWith('?');
  final cleanType = isNullable ? type.substring(0, type.length - 1) : type;

  // Check if already has $ or $$ prefix
  if (cleanType.startsWith('\$')) {
    return type; // Already normalized
  }

  // Extract base type and generic arguments
  final genericMatch = RegExp(r'^([^<]+)(<.+>)?$').firstMatch(cleanType);
  if (genericMatch == null) return type;

  final baseType = genericMatch.group(1)!.trim();
  final generics = genericMatch.group(2);

  // Check if it's a primitive or container type
  if (_isPrimitiveType(baseType)) {
    // For container types, normalize the generic arguments
    if (generics != null &&
        (baseType == 'List' || baseType == 'Set' || baseType == 'Map')) {
      final normalizedGenerics = _normalizeGenerics(
        generics,
        baseOutputDir: baseOutputDir,
      );
      return '$baseType$normalizedGenerics${isNullable ? '?' : ''}';
    }
    return type; // Primitive type, return as-is
  }

  // Check if it's an enum by looking for the file in enums directory
  final enumsDir = Directory(p.join(baseOutputDir, 'enums'));
  if (enumsDir.existsSync()) {
    final enumSnakeName = _toSnakeCase(baseType);
    final enumFile = File(p.join(enumsDir.path, '$enumSnakeName.dart'));
    if (enumFile.existsSync()) {
      return type; // It's an enum, don't add $
    }
  }

  // Check if it's a sealed class by reading the entity file
  final entitySnakeName = _toSnakeCase(baseType);
  final entityDir = Directory(p.join(baseOutputDir, entitySnakeName));
  final entityFile = File(p.join(entityDir.path, '$entitySnakeName.dart'));

  String prefix = '\$'; // Default to single $
  if (entityFile.existsSync()) {
    try {
      final content = entityFile.readAsStringSync();
      // Check if it's a sealed class (abstract class $$ClassName)
      if (content.contains('abstract class \$\$$baseType')) {
        prefix = '\$\$'; // It's sealed, use $$
      }
    } catch (_) {
      // If we can't read the file, default to single $
    }
  }

  // It's an entity type, add appropriate prefix
  final normalizedBase = '$prefix$baseType';
  final normalizedGenerics = generics != null
      ? _normalizeGenerics(generics, baseOutputDir: baseOutputDir)
      : '';
  return '$normalizedBase$normalizedGenerics${isNullable ? '?' : ''}';
}

/// Normalize generic type arguments
String _normalizeGenerics(String generics, {required String baseOutputDir}) {
  // Remove outer < and >
  final inner = generics.substring(1, generics.length - 1);

  // Split by comma, but respect nested generics
  final parts = <String>[];
  var depth = 0;
  var current = StringBuffer();

  for (var i = 0; i < inner.length; i++) {
    final char = inner[i];
    if (char == '<') {
      depth++;
      current.write(char);
    } else if (char == '>') {
      depth--;
      current.write(char);
    } else if (char == ',' && depth == 0) {
      parts.add(current.toString().trim());
      current = StringBuffer();
    } else {
      current.write(char);
    }
  }
  if (current.isNotEmpty) {
    parts.add(current.toString().trim());
  }

  // Normalize each part
  final normalized = parts
      .map((part) => _normalizeFieldType(part, baseOutputDir: baseOutputDir))
      .join(', ');
  return '<$normalized>';
}

/// Format class name (PascalCase)
String _formatClassName(String name) {
  // Remove leading $ if present
  name = name.replaceAll(r'^$', '');

  // Convert to PascalCase
  final parts = name.split(RegExp(r'[_\s\-]+'));
  return parts
      .map((part) {
        if (part.isEmpty) return '';
        return part[0].toUpperCase() + part.substring(1);
      })
      .join('');
}

/// Convert PascalCase to snake_case
String _toSnakeCase(String text) {
  // Add underscore before each uppercase letter (except first), convert to lowercase
  final snake = text.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
    final char = match.group(0)!;
    final index = match.start;
    return (index == 0) ? char.toLowerCase() : '_${char.toLowerCase()}';
  });
  return snake;
}

/// Field information
class _FieldInfo {
  final String name;
  final String type;

  _FieldInfo({required this.name, required this.type});
}
