#!/usr/bin/env dart

/// Zorphy CLI - A command-line tool for generating and managing Zorphy entities
///
/// This CLI is designed to make it easy for AI agents and developers to create
/// Zorphy entity classes with proper structure and organization.

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const String _version = '1.0.0';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('version', abbr: 'v', help: 'Show version information', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show this help message', negatable: false)
    ..addCommand('create', _createCommandParser())
    ..addCommand('build', _buildCommandParser())
    ..addCommand('new', _newCommandParser())
    ..addCommand('list', _listCommandParser())
    ..addCommand('enum', _createEnumCommandParser());

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
  }
}

ArgParser _createCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the entity class (required)')
    ..addOption('output', abbr: 'o', help: r'Output base directory (default: lib/src/domain/entities)')
    ..addOption('package', abbr: 'p', help: 'Package name for imports (default: uses pubspec.yaml)')
    ..addFlag('json', help: 'Enable JSON serialization', defaultsTo: true)
    ..addFlag('copywith-fn', help: 'Enable function-based copyWith', defaultsTo: false)
    ..addFlag('compare', help: 'Enable compareTo generation', defaultsTo: true)
    ..addFlag('sealed', help: r'Create a sealed abstract class (use $$ prefix)', defaultsTo: false)
    ..addFlag('non-sealed', help: 'Create non-sealed abstract class', defaultsTo: false)
    ..addFlag('fields', abbr: 'f', help: 'Interactive field prompts', defaultsTo: true)
    ..addMultiOption('field', help: r'Add fields in format: "name:type" or "name:type?" for nullable')
    ..addOption('extends', help: r'Interface to extend (e.g., "\$BaseEntity")')
    ..addMultiOption('subtype', help: r'Explicit subtypes for polymorphism (e.g., "\$Dog,\$Cat")');
}

ArgParser _createEnumCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the enum (required)')
    ..addOption('output', abbr: 'o', help: r'Output base directory (default: lib/src/domain/entities)')
    ..addMultiOption('value', help: 'Enum values (e.g., "active,inactive,pending")');
}

ArgParser _buildCommandParser() {
  return ArgParser()
    ..addFlag('watch', abbr: 'w', help: 'Watch for changes', defaultsTo: false)
    ..addFlag('clean', abbr: 'c', help: 'Clean before build', defaultsTo: false)
    ..addOption('output', abbr: 'o', help: 'Specify build output directory');
}

ArgParser _newCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the entity class (required)')
    ..addOption('output', abbr: 'o', help: r'Output base directory (default: lib/src/domain/entities)')
    ..addFlag('json', help: 'Enable JSON serialization', defaultsTo: true);
}

ArgParser _listCommandParser() {
  return ArgParser()
    ..addOption('output', abbr: 'o', help: r'Directory to search (default: lib/src/domain/entities)');
}

String _getFullUsage(ArgParser parser) {
  return '''
Zorphy CLI - Entity Generator for AI Agents & Developers

Version: $_version

USAGE:
  zorphy_cli <command> [options]

AVAILABLE COMMANDS:
  create    Create a new Zorphy entity with fields
  new       Quick-create a simple entity (basic defaults)
  build     Run code generation for Zorphy entities
  list      List all Zorphy entities in a directory
  enum      Create a new enum

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
    --subtype               Explicit subtypes

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

LIST COMMAND:
  zorphy_cli list [options]
  Options:
    -o, --output            Directory to search (default: lib/src/domain/entities)

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
  zorphy_cli build --watch

  # List entities
  zorphy_cli list

FIELD TYPES:
  Basic types: String, int, double, bool, num, DateTime
  Nullable types: Add ? after type (e.g., String?, int?)
  Generic types: List<Type>, Set<Type>, Map<KeyType, ValueType>
  Custom types: Any other class name
  Zorphy Objects: \$TypeName (concrete), \$\$TypeName (sealed/polymorphic)
  Enums: TypeName (will be imported from enums/index.dart)

  Note: In shell, use --field address:\$Address (escape the $)

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
  final extendsInterface = args['extends'] as String?;
  final explicitSubtypes = args['subtype'] as List<String>?;

  // Get package name
  String packageName = _getPackageName();
  if (args['package'] != null) {
    packageName = args['package'] as String;
  }

  // Collect fields from command line
  final providedFields = args['field'] as List<String>?;
  final fields = <_FieldInfo>[];

  if (providedFields != null && providedFields.isNotEmpty) {
    for (var fieldDef in providedFields) {
      final parts = fieldDef.split(':');
      if (parts.length != 2) {
        print('Warning: Invalid field format "$fieldDef". Expected "name:type"');
        continue;
      }
      final fieldName = parts[0].trim();
      final fieldType = parts[1].trim();
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
      final fieldType = stdin.readLineSync()?.trim() ?? 'String';

      fields.add(_FieldInfo(name: fieldName, type: fieldType));
      print('✓ Added field: $fieldName ($fieldType)\n');
    }
  }

  if (fields.isEmpty) {
    print('Warning: No fields specified. Creating empty entity.');
  }

  // Class name formatting
  final className = _formatClassName(name);
  final entityDirName = _toSnakeCase(className);

  // Create directory structure: lib/src/domain/entities/entity_name/
  final entityDir = p.join(baseOutputDir, entityDirName);
  final dir = Directory(entityDir);
  if (!await dir.exists()) {
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
  final importedTypes = <String>{};
  final importedEnums = false;

  for (final field in fields) {
    final type = field.type;

    // Extract Zorphy type references ($TypeName or $$TypeName)
    final zorphyTypes = RegExp(r'\$\$?[A-Z][a-zA-Z0-9]*').allMatches(type).map((m) => m.group(0)!).toSet();
    for (final zorphyType in zorphyTypes) {
      final typeClassName = zorphyType.replaceAll(r'\$', '');
      final typeSnakeName = _toSnakeCase(typeClassName);
      // Don't import self
      if (typeClassName != className) {
        // Check if it's an enum (starts with uppercase, no $ prefix, not in current entities)
        if (!zorphyType.contains(r'\$')) {
          // Assume it's an enum
          importedTypes.add("import '../../enums/index.dart';");
        } else {
          // It's a Zorphy entity
          importedTypes.add("import '../$typeSnakeName/$typeSnakeName.dart';");
        }
      }
    }
  }

  // Add imports if any
  if (importedTypes.isNotEmpty) {
    final uniqueImports = importedTypes.toSet();
    for (final import in uniqueImports) {
      buffer.writeln(import);
    }
    buffer.writeln();
  }

  // Add json_serializable part if JSON is enabled
  if (useJson) {
    buffer.writeln("part '${entityDirName}.g.dart';");
  }

  buffer.writeln("part '${entityDirName}.zorphy.dart';");
  buffer.writeln();

  // Annotation options
  final annotationOptions = <String>[];
  if (useJson) annotationOptions.add('generateJson: true');
  if (useCopyWithFn) annotationOptions.add('generateCopyWithFn: true');
  if (useCompare) annotationOptions.add('generateCompareTo: true');
  if (isNonSealed) annotationOptions.add('nonSealed: true');

  if (extendsInterface != null) {
    // Add explicitSubTypes if provided
    if (explicitSubtypes != null && explicitSubtypes.isNotEmpty) {
      final subtypes = explicitSubtypes.map((s) => '\$$s').join(', ');
      annotationOptions.add("explicitSubTypes: [$subtypes]");
    }
  }

  // Class definition - Use raw string to avoid interpolation
  final abstractClassName = isSealed ? r'$$' + className : r'$' + className;

  buffer.writeln('/// $className entity');
  buffer.writeln('@Zorphy(${annotationOptions.join(', ')})');
  buffer.writeln('abstract class $abstractClassName {');
  buffer.writeln();

  // Fields
  for (final field in fields) {
    buffer.writeln('  ${field.type} get ${field.name};');
  }

  buffer.writeln('}');
  buffer.writeln();

  // Write file
  await file.writeAsString(buffer.toString());
  print('✓ Created entity file: $filePath');

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

  if (importedTypes.isNotEmpty) {
    print('\n📦 Auto-imported:');
    final uniqueImports = importedTypes.toSet();
    for (final import in uniqueImports) {
      print('  - $import');
    }
  }
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

  if (values.isEmpty) {
    print('Error: Enum values are required. Use --value with comma-separated values.');
    exit(1);
  }

  // Create enums directory
  final enumsDir = p.join(baseOutputDir, 'enums');
  final dir = Directory(enumsDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
    print('✓ Created enums directory: $enumsDir');
  }

  // Check if enum file already exists
  final enumName = _formatClassName(name);
  final filePath = p.join(enumsDir, '$enumName.dart');
  final file = File(filePath);

  // Read existing enums to check for duplicates
  final existingEnums = <String>[];
  final indexFile = File(p.join(enumsDir, 'index.dart'));
  if (await indexFile.exists()) {
    final indexContent = await indexFile.readAsString();
    // Extract existing enum names from exports
    final exportMatches = RegExp(r"export '([^']+)\.dart';").allMatches(indexContent);
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

  await file.writeAsString(buffer.toString());
  print('✓ Created enum file: $filePath');

  // Update the index.dart barrel file
  await _updateEnumIndexFile(enumsDir, existingEnums);

  print('\n📋 Enum exported to: lib/src/domain/entities/enums/index.dart');
  print('   Import in entities: import \'../../enums/index.dart\';');
}

/// Update the enum barrel file
Future<void> _updateEnumIndexFile(String enumsDir, List<String> existingEnums) async {
  final indexFile = File(p.join(enumsDir, 'index.dart'));

  // Get all enum files in the directory
  final allEnums = <String>[];
  await for (final entity in Directory(enumsDir).list()) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('index.dart')) {
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
  final process = await Process.start(
    'dart',
    ['run', 'build_runner', if (clean) 'clean', 'build', if (watch) '--watch'],
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode == 0) {
    print('\n✅ Build complete!');
  } else {
    print('\n❌ Build failed with exit code $exitCode');
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

  print('📝 Creating quick entity: $name');

  // Create entity directly (simplified)
  final className = _formatClassName(name);
  final entityDirName = _toSnakeCase(className);

  // Create directory structure
  final entityDir = p.join(baseOutputDir, entityDirName);
  final dir = Directory(entityDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final filePath = p.join(entityDir, '$entityDirName.dart');
  final file = File(filePath);
  final buffer = StringBuffer();

  buffer.writeln('/// Auto-generated by Zorphy CLI');
  buffer.writeln("import 'package:zorphy_annotation/zorphy_annotation.dart';");

  if (useJson) {
    buffer.writeln("part '${entityDirName}.g.dart';");
  }

  buffer.writeln();
  buffer.writeln("part '${entityDirName}.zorphy.dart';");
  buffer.writeln();
  buffer.writeln('@Zorphy(generateJson: $useJson)');
  buffer.writeln('abstract class \$$className {');
  buffer.writeln('}');

  await file.writeAsString(buffer.toString());
  print('✓ Created entity file: $filePath');
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
      if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('index.dart')) {
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

/// Get package name from pubspec.yaml
String _getPackageName() {
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final contents = pubspecFile.readAsStringSync();
    final nameMatch = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(contents);
    if (nameMatch != null) {
      return nameMatch.group(1)!.trim();
    }
  }
  return 'my_app';
}

/// Format class name (PascalCase)
String _formatClassName(String name) {
  // Remove leading $ if present
  name = name.replaceAll(r'^$', '');

  // Convert to PascalCase
  final parts = name.split(RegExp(r'[_\s\-]+'));
  return parts.map((part) {
    if (part.isEmpty) return '';
    return part[0].toUpperCase() + part.substring(1);
  }).join('');
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
