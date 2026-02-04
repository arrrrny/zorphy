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
    ..addCommand('list', _listCommandParser());

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
  }
}

ArgParser _createCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the entity class (required)')
    ..addOption('output', abbr: 'o', help: 'Output directory (default: lib/entities)')
    ..addOption('package', abbr: 'p', help: 'Package name for imports (default: uses pubspec.yaml)')
    ..addFlag('json', help: 'Enable JSON serialization', defaultsTo: true)
    ..addFlag('copywith-fn', help: 'Enable function-based copyWith', defaultsTo: false)
    ..addFlag('compare', help: 'Enable compareTo generation', defaultsTo: true)
    ..addFlag('sealed', help: 'Create a sealed abstract class (use $$ prefix)', defaultsTo: false)
    ..addFlag('non-sealed', help: 'Create non-sealed abstract class', defaultsTo: false)
    ..addFlag('fields', abbr: 'f', help: 'Interactive field prompts', defaultsTo: true)
    ..addMultiOption('field', help: 'Add fields in format: "name:type" or "name:type?" for nullable')
    ..addOption('extends', help: 'Interface to extend (e.g., "$BaseEntity")')
    ..addMultiOption('subtype', help: 'Explicit subtypes for polymorphism (e.g., "$Dog,$Cat")');
}

ArgParser _buildCommandParser() {
  return ArgParser()
    ..addFlag('watch', abbr: 'w', help: 'Watch for changes', defaultsTo: false)
    ..addFlag('clean', abbr: 'c', help: 'Clean before build', defaultsTo: false)
    ..addOption('output', abbr: 'o', help='Specify build output directory');
}

ArgParser _newCommandParser() {
  return ArgParser()
    ..addOption('name', abbr: 'n', help: 'Name of the entity class (required)')
    ..addOption('output', abbr: 'o', help: 'Output directory (default: lib/entities)')
    ..addFlag('json', help: 'Enable JSON serialization', defaultsTo: true);
}

ArgParser _listCommandParser() {
  return ArgParser()
    ..addOption('output', abbr: 'o', help: 'Directory to search (default: lib/entities)');
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

GLOBAL OPTIONS:
  -h, --help       Show this help message
  -v, --version    Show version information

CREATE COMMAND:
  zorphy_cli create [options]
  Options:
    -n, --name              Entity name (required)
    -o, --output            Output directory (default: lib/entities)
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

NEW COMMAND:
  zorphy_cli new [options]
  Options:
    -n, --name              Entity name (required)
    -o, --output            Output directory (default: lib/entities)
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
    -o, --output            Directory to search (default: lib/entities)

EXAMPLES:
  # Interactive entity creation
  zorphy_cli create -n User

  # Create with fields
  zorphy_cli create -n User --field name:String --field age:int --field email:String?

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

  final outputDir = args['output'] as String? ?? 'lib/entities';
  final useJson = args['json'] as bool? ?? true;
  final useCopyWithFn = args['copywith-fn'] as bool? ?? false;
  final useCompare = args['compare'] as bool? ?? true;
  final isSealed = args['sealed'] as bool? ?? false;
  final isNonSealed = args['non-sealed'] as bool? ?? false;
  final useInteractiveFields = args['fields'] as bool? ?? true;
  final extendsInterface = args['extends'] as String?;
  final explicitSubtypes = args['subtype'] as List<String>?;
  final providedFields = args['field'] as List<String>?;

  // Get package name
  String packageName = _getPackageName();
  if (args['package'] != null) {
    packageName = args['package'] as String;
  }

  // Class name formatting
  final className = _formatClassName(name);
  final abstractClassName = isSealed ? '$$className' : '\$$className';

  // Collect fields
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
    print('\n📝 Creating Zorphy Entity: $className');
    print('Enter fields one by one. Press Enter without input to finish.\n');

    while (true) {
      stdout.write('Field name (or press Enter to finish): ');
      final fieldName = stdin.readLineSync()?.trim();
      if (fieldName == null || fieldName.isEmpty) break;

      stdout.write('Field type (e.g., String, int, List<String>): ');
      final fieldType = stdin.readLineSync()?.trim() ?? 'String';

      fields.add(_FieldInfo(name: fieldName, type: fieldType));
      print('✓ Added field: $fieldName ($fieldType)\n');
    }
  }

  if (fields.isEmpty) {
    print('Warning: No fields specified. Creating empty entity.');
  }

  // Create output directory
  final dir = Directory(outputDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
    print('✓ Created output directory: $outputDir');
  }

  // Generate file content
  final filePath = p.join(outputDir, '${className.toLowerCase()}.dart');
  final file = File(filePath);

  final buffer = StringBuffer();

  // File header
  buffer.writeln('/// Auto-generated by Zorphy CLI');
  buffer.writeln('/// Generated at: ${DateTime.now().toIso8601String()}');
  buffer.writeln();
  buffer.writeln("import 'package:zorphy_annotation/zorphy_annotation.dart';");
  buffer.writeln();
  buffer.writeln("part '${className.toLowerCase()}.zorphy.dart';");
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

  // Class definition
  buffer.writeln('/// $className entity');
  if (extendsInterface != null) {
    buffer.writeln('@Zorphy(${annotationOptions.join(', ')})');
    buffer.writeln('abstract class $abstractClassName implements $extendsInterface {');
  } else {
    buffer.writeln('@Zorphy(${annotationOptions.join(', ')})');
    buffer.writeln('abstract class $abstractClassName {');
  }
  buffer.writeln();

  // Fields
  for (final field in fields) {
    final nullable = field.type.endsWith('?');
    final type = nullable ? field.type.substring(0, field.type.length - 1) : field.type;
    final formattedType = nullable ? '$type?' : type;
    buffer.writeln('  $formattedType get ${field.name};');
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
}

/// Handle the build command
Future<void> _handleBuild(ArgResults args) async {
  final watch = args['watch'] as bool? ?? false;
  final clean = args['clean'] as bool? ?? false;

  print('🔨 Building Zorphy entities...');

  if (clean) {
    print('🧹 Cleaning generated files...');
    // Would run: dart run build_runner clean
  }

  if (watch) {
    print('👀 Watching for changes...');
    print('Press Ctrl+C to stop');
    // Would run: dart run build_runner watch
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

  final outputDir = args['output'] as String? ?? 'lib/entities';
  final useJson = args['json'] as bool? ?? true;

  print('📝 Creating quick entity: $name');

  // Reuse create command with simplified options
  final createArgs = [
    'create',
    '-n', name,
    '-o', outputDir,
    if (useJson) '--json',
    '--no-fields',  // Skip interactive prompts
  ];

  await _handleCreate(ArgParser()..addOption('name')..addOption('output')..addFlag('json')..addFlag('fields').parse(createArgs));
}

/// Handle the list command
Future<void> _handleList(ArgResults args) async {
  final outputDir = args['output'] as String? ?? 'lib/entities';

  final dir = Directory(outputDir);
  if (!await dir.exists()) {
    print('No entities found. Directory does not exist: $outputDir');
    return;
  }

  print('📂 Zorphy Entities in $outputDir:\n');

  final entities = <String>[];
  await for (final entity in dir.list()) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('.zorphy.dart')) {
      final name = p.basenameWithoutExtension(entity.path);
      entities.add(name);

      // Read file to extract class info
      final contents = await entity.readAsString();
      final hasJson = contents.contains('generateJson: true');
      final hasCopyWithFn = contents.contains('generateCopyWithFn: true');
      final isSealed = contents.contains('abstract class \$\$');

      print('  📄 $name');
      print('     Path: ${entity.path}');
      if (hasJson) print('     ✓ JSON support');
      if (hasCopyWithFn) print('     ✓ Function-based copyWith');
      if (isSealed) print('     🔒 Sealed class');
      print('');
    }
  }

  if (entities.isEmpty) {
    print('  No Zorphy entities found.');
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

/// Field information
class _FieldInfo {
  final String name;
  final String type;

  _FieldInfo({required this.name, required this.type});
}
