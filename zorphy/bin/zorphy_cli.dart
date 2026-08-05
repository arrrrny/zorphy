#!/usr/bin/env dart

/// Zorphy CLI - A command-line tool for generating and managing Zorphy entities
///
/// This CLI is designed to make it easy for AI agents and developers to create
/// Zorphy entity classes with proper structure and organization.

import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:zorphy/zorphy_cli.dart';

const String _version = '2.0.0';

Future<void> main(List<String> args) async {
  var showVersion = false;

  if (args.contains('-v') || args.contains('--version')) {
    showVersion = true;
  }

  final runner =
      CommandRunner<void>(
          'zorphy_cli',
          'Zorphy Entity Generator for AI Agents & Developers',
        )
        ..addCommand(_CreateCommand())
        ..addCommand(_NewCommand())
        ..addCommand(_EnumCommand())
        ..addCommand(_AddFieldCommand())
        ..addCommand(_ListCommand())
        ..addCommand(_BuildCommand())
        ..addCommand(_WatchCommand())
        ..addCommand(_FromJsonCommand())
        ..addCommand(_ValidateCommand())
        ..addCommand(_SelfUpdateCommand());

  try {
    if (showVersion) {
      print('Zorphy CLI version $_version');
      exit(0);
    }
    await runner.run(args);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

class _CreateCommand extends Command<void> {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Zorphy entity with fields';

  _CreateCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      mandatory: true,
      help: 'Entity name',
    );
    argParser.addOption('output', abbr: 'o', help: 'Output directory');
    argParser.addOption('package', abbr: 'p', help: 'Package name');
    argParser.addFlag(
      'json',
      defaultsTo: true,
      help: 'Enable JSON serialization',
    );
    argParser.addFlag('copywith-fn', help: 'Function-based copyWith');
    argParser.addFlag('compare', defaultsTo: true, help: 'Enable compareTo');
    argParser.addFlag('sealed', help: 'Create sealed class');
    argParser.addFlag('non-sealed', help: 'Create non-sealed class');
    argParser.addFlag('filter', help: 'Enable type-safe filters');
    argParser.addMultiOption('field', help: 'Add field: "name:type"');
    argParser.addOption('extends', help: 'Interface to extend');
    argParser.addMultiOption('subtypes', help: 'Explicit subtypes');
    argParser.addFlag('generate-subs', help: 'Generate subtype files');
    argParser.addFlag('dry-run', help: 'Preview without writing');
  }

  @override
  Future<void> run() async {
    final name = argResults!['name'] as String;
    final output = argResults!['output'] as String?;
    final fields = (argResults!['field'] as List<String>)
        .expand((f) => _parseFields(f))
        .map((f) => FieldDefinition.parse(f))
        .toList();

    final config = EntityConfig(
      name: name,
      outputDir: output,
      packageName: argResults!['package'] as String?,
      fields: fields,
      generateJson: argResults!['json'] as bool,
      generateCopyWithFn: argResults!['copywith-fn'] as bool,
      generateCompareTo: argResults!['compare'] as bool,
      isSealed: argResults!['sealed'] as bool,
      isNonSealed: argResults!['non-sealed'] as bool,
      generateFilter: argResults!['filter'] as bool,
      extendsInterface: argResults!['extends'] as String?,
      explicitSubtypes: argResults!['subtypes'] as List<String>,
      generateSubtypes: argResults!['generate-subs'] as bool,
      dryRun: argResults!['dry-run'] as bool,
    );

    final creator = EntityCreator(baseOutputDir: output);
    final result = await creator.create(config);

    if (result.isSuccess) {
      print('✓ Created entity: ${result.filePath}');
      print('\n📋 Next steps:');
      print('  1. Run: dart run build_runner build');
      print('  2. Import and use your ${config.className} class');
    } else {
      print('❌ ${result.error}');
      exit(1);
    }
  }

  List<String> _parseFields(String input) {
    var depth = 0;
    final fields = <String>[];
    var current = StringBuffer();

    for (final char in input.split('')) {
      if (char == '<') depth++;
      if (char == '>') depth--;
      if (char == ',' && depth == 0) {
        if (current.toString().trim().isNotEmpty) {
          fields.add(current.toString().trim());
        }
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    if (current.toString().trim().isNotEmpty) {
      fields.add(current.toString().trim());
    }
    return fields;
  }
}

class _NewCommand extends Command<void> {
  @override
  String get name => 'new';

  @override
  String get description => 'Quick-create a simple entity';

  _NewCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      mandatory: true,
      help: 'Entity name',
    );
    argParser.addOption('output', abbr: 'o', help: 'Output directory');
    argParser.addFlag('json', defaultsTo: true, help: 'Enable JSON');
    argParser.addFlag('filter', help: 'Enable filters');
    argParser.addFlag('dry-run', help: 'Preview without writing');
  }

  @override
  Future<void> run() async {
    final config = EntityConfig(
      name: argResults!['name'] as String,
      outputDir: argResults!['output'] as String?,
      generateJson: argResults!['json'] as bool,
      generateFilter: argResults!['filter'] as bool,
      dryRun: argResults!['dry-run'] as bool,
    );

    final creator = EntityCreator(
      baseOutputDir: argResults!['output'] as String?,
    );
    final result = await creator.create(config);

    if (result.isSuccess) {
      print('✓ Created entity: ${result.filePath}');
    } else {
      print('❌ ${result.error}');
      exit(1);
    }
  }
}

class _EnumCommand extends Command<void> {
  @override
  String get name => 'enum';

  @override
  String get description => 'Create a new enum';

  _EnumCommand() {
    argParser.addOption('name', abbr: 'n', mandatory: true, help: 'Enum name');
    argParser.addOption('output', abbr: 'o', help: 'Output directory');
    argParser.addMultiOption('value', help: 'Enum values');
    argParser.addFlag('dry-run', help: 'Preview without writing');
  }

  @override
  Future<void> run() async {
    final config = EnumConfig(
      name: argResults!['name'] as String,
      outputDir: argResults!['output'] as String?,
      values: argResults!['value'] as List<String>,
      dryRun: argResults!['dry-run'] as bool,
    );

    final creator = EntityCreator(
      baseOutputDir: argResults!['output'] as String?,
    );
    final result = await creator.createEnum(config);

    if (result.isSuccess) {
      print('✓ Created enum: ${result.filePath}');
    } else {
      print('❌ ${result.error}');
      exit(1);
    }
  }
}

class _AddFieldCommand extends Command<void> {
  @override
  String get name => 'add-field';

  @override
  String get description => 'Add field(s) to an existing entity';

  _AddFieldCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      mandatory: true,
      help: 'Entity name',
    );
    argParser.addOption('output', abbr: 'o', help: 'Output directory');
    argParser.addMultiOption('field', help: 'Field: "name:type"');
    argParser.addFlag('dry-run', help: 'Preview without writing');
  }

  @override
  Future<void> run() async {
    final fields = (argResults!['field'] as List<String>)
        .map((f) => FieldDefinition.parse(f))
        .toList();

    final creator = EntityCreator(
      baseOutputDir: argResults!['output'] as String?,
    );
    final result = await creator.addFields(
      argResults!['name'] as String,
      fields,
      outputDir: argResults!['output'] as String?,
      dryRun: argResults!['dry-run'] as bool,
    );

    if (result.isSuccess) {
      print('✓ Added ${fields.length} field(s) to ${result.className}');
    } else {
      print('❌ ${result.error}');
      exit(1);
    }
  }
}

class _ListCommand extends Command<void> {
  @override
  String get name => 'list';

  @override
  String get description => 'List all Zorphy entities';

  _ListCommand() {
    argParser.addOption('output', abbr: 'o', help: 'Directory to search');
  }

  @override
  Future<void> run() async {
    final dir = argResults!['output'] as String? ?? 'lib/src/domain/entities';
    final entityDir = Directory(dir);

    if (!await entityDir.exists()) {
      print('No entities found. Directory does not exist: $dir');
      return;
    }

    print('📂 Zorphy Entities in $dir:\n');

    await for (final entity in entityDir.list()) {
      if (entity is Directory) {
        final entityName = p.basename(entity.path);
        final dartFile = File(p.join(entity.path, '$entityName.dart'));
        if (await dartFile.exists()) {
          final content = await dartFile.readAsString();
          print('  📄 $entityName');
          if (content.contains('generateJson: true'))
            print('     ✓ JSON support');
          if (content.contains('abstract class \$\$'))
            print('     🔒 Sealed class');
        }
      }
    }
  }
}

class _BuildCommand extends Command<void> {
  @override
  String get name => 'build';

  @override
  String get description => 'Run code generation (with optional smart merge)';

  _BuildCommand() {
    argParser.addFlag('watch', abbr: 'w', help: 'Watch for changes');
    argParser.addFlag('clean', abbr: 'c', help: 'Clean before build');
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Preview what would change without writing files',
    );
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Bypass AST merge and regenerate from scratch',
    );
  }

  @override
  Future<void> run() async {
    final isDryRun = argResults!['dry-run'] as bool;
    final isForce = argResults!['force'] as bool;
    final isClean = argResults!['clean'] as bool;

    if (isDryRun) {
      print('Dry-run mode: previewing changes...');
    }

    if (isForce) {
      print('Force mode: regenerating from scratch...');
    }

    final args = [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ];
    if (isClean) args.insert(2, 'clean');

    // Pass dry-run and force flags to the builder via --define
    if (isDryRun) {
      args.add('--define');
      args.add('zorphy:zorphy=dry_run=true');
    }
    if (isForce) {
      args.add('--define');
      args.add('zorphy:zorphy=force=true');
    }

    final process = await Process.start(
      'dart',
      args,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await process.exitCode;
    if (code != 0) exit(code);
  }
}

class _WatchCommand extends Command<void> {
  @override
  String get name => 'watch';

  @override
  String get description => 'Watch for changes and rebuild';

  @override
  Future<void> run() async {
    final process = await Process.start('dart', [
      'run',
      'build_runner',
      'watch',
      '--delete-conflicting-outputs',
    ], mode: ProcessStartMode.inheritStdio);
    final code = await process.exitCode;
    if (code != 0) exit(code);
  }
}

class _FromJsonCommand extends Command<void> {
  @override
  String get name => 'from-json';

  @override
  String get description => 'Create entity from JSON file';

  _FromJsonCommand() {
    argParser.addOption('name', abbr: 'n', help: 'Entity name');
    argParser.addOption('output', abbr: 'o', help: 'Output directory');
    argParser.addFlag('json', defaultsTo: true, help: 'Enable JSON');
    argParser.addFlag(
      'prefix-nested',
      defaultsTo: true,
      help: 'Prefix nested entities',
    );
    argParser.addFlag('filter', help: 'Enable filters');
    argParser.addFlag('dry-run', help: 'Preview without writing');
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      print('Error: JSON file path required');
      exit(1);
    }

    final file = File(argResults!.rest.first);
    if (!await file.exists()) {
      print('Error: File not found: ${file.path}');
      exit(1);
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final name =
        argResults!['name'] as String? ?? p.basenameWithoutExtension(file.path);

    final fields = <FieldDefinition>[];
    final nested = <Map<String, dynamic>>[];

    _parseJsonFields(json, fields, nested, prefix: name);

    final config = EntityConfig(
      name: name,
      outputDir: argResults!['output'] as String?,
      fields: fields,
      generateJson: argResults!['json'] as bool,
      generateFilter: argResults!['filter'] as bool,
      prefixNested: argResults!['prefix-nested'] as bool,
      dryRun: argResults!['dry-run'] as bool,
    );

    final creator = EntityCreator(
      baseOutputDir: argResults!['output'] as String?,
    );
    final result = await creator.create(config);

    if (result.isSuccess) {
      print('✓ Created entity: ${result.filePath}');
    } else {
      print('❌ ${result.error}');
      exit(1);
    }
  }

  void _parseJsonFields(
    Map<String, dynamic> json,
    List<FieldDefinition> fields,
    List<Map<String, dynamic>> nested, {
    required String prefix,
  }) {
    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;

      final isNullable = key.endsWith('?');
      final fieldName = isNullable ? key.substring(0, key.length - 1) : key;

      if (value is Map<String, dynamic>) {
        final nestedName = NamingUtils.toPascalCase(fieldName);
        nested.add({'name': '$prefix$nestedName', 'json': value});
        fields.add(
          FieldDefinition(
            name: fieldName,
            type: '\$$prefix$nestedName',
            nullable: isNullable,
          ),
        );
      } else if (value is List && value.isNotEmpty && value.first is Map) {
        final nestedName = NamingUtils.toPascalCase(_singularize(fieldName));
        nested.add({
          'name': '$prefix$nestedName',
          'json': value.first as Map<String, dynamic>,
        });
        fields.add(
          FieldDefinition(
            name: fieldName,
            type: 'List<\$$prefix$nestedName>',
            nullable: isNullable,
          ),
        );
      } else {
        final type = _inferType(value);
        fields.add(
          FieldDefinition(
            name: fieldName,
            type: type,
            nullable: isNullable || value == null,
          ),
        );
      }
    }
  }

  String _inferType(dynamic value) {
    if (value == null) return 'dynamic';
    if (value is String)
      return DateTime.tryParse(value) != null ? 'DateTime' : 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List<dynamic>';
    return 'dynamic';
  }

  String _singularize(String s) {
    if (s.endsWith('ies')) return '${s.substring(0, s.length - 3)}y';
    if (s.endsWith('es')) return s.substring(0, s.length - 2);
    if (s.endsWith('s')) return s.substring(0, s.length - 1);
    return s;
  }
}


class _ValidateCommand extends Command<void> {
  @override
  String get name => 'validate';

  @override
  String get description =>
      'Validate a Zorphy project for common issues (missing generated files, stale output, missing part directives)';

  _ValidateCommand() {
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project directory to validate (default: current directory)',
    );
    argParser.addMultiOption(
      'source',
      help: 'Additional source directories to scan (default: lib)',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output results as JSON',
    );
  }

  @override
  Future<void> run() async {
    final dir = argResults!['dir'] as String? ?? Directory.current.path;
    final extraSources = (argResults!['source'] as List<String>?) ?? [];
    final sourceDirs = ['lib', ...extraSources];
    final asJson = argResults!['json'] as bool;

    final projectDir = Directory(dir);
    if (!projectDir.existsSync()) {
      if (asJson) {
        final errorOutput = {
          'directory': dir,
          'filesScanned': 0,
          'errorCount': 1,
          'warningCount': 0,
          'infoCount': 0,
          'findings': [
            {
              'message': 'Directory not found: $dir',
              'severity': 'error',
              'filePath': dir,
            }
          ],
        };
        print(const JsonEncoder.withIndent('  ').convert(errorOutput));
      } else {
        print('Error: Directory not found: $dir');
      }
      exit(1);
    }

    final validator = ProjectValidator(
      projectDir: dir,
      sourceDirs: sourceDirs,
    );
    final result = validator.validate();

    if (asJson) {
      _printJsonResult(result);
    } else {
      print(result);
    }

    if (result.hasErrors) {
      exit(1);
    }
  }

  void _printJsonResult(ValidationResult result) {
    final findingsJson = result.findings.map((f) => {
      'message': f.message,
      'severity': f.severity.name,
      if (f.filePath != null) 'filePath': f.filePath,
      if (f.lineNumber != null) 'lineNumber': f.lineNumber,
      if (f.fixSuggestion != null) 'fixSuggestion': f.fixSuggestion,
    }).toList();

    final output = {
      'directory': result.validatedDir,
      'filesScanned': result.filesScanned,
      'errorCount': result.errorCount,
      'warningCount': result.warningCount,
      'infoCount': result.infoCount,
      'findings': findingsJson,
    };

    print(const JsonEncoder.withIndent('  ').convert(output));
  }
}


class _SelfUpdateCommand extends Command<void> {
  @override
  String get name => 'self-update';

  @override
  String get description =>
      'Check for the latest zorphy version and update the CLI in place';

  _SelfUpdateCommand() {
    argParser.addFlag(
      'check',
      abbr: 'c',
      negatable: false,
      help: 'Only check for updates, do not install',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output results as JSON',
    );
  }

  @override
  Future<void> run() async {
    final checkOnly = argResults!['check'] as bool;
    final asJson = argResults!['json'] as bool;

    final checker = VersionChecker(currentVersion: _version);

    // Reuse a single checkForUpdate result
    final checkResult = await checker.checkForUpdate();

    if (asJson) {
      final output = <String, dynamic>{
        'currentVersion': checkResult.currentVersion,
        'latestVersion': checkResult.latestVersion,
        'updateAvailable': checkResult.updateAvailable,
        'message': checkResult.message,
      };
      if (!checkOnly && checkResult.updateAvailable) {
        final updateResult = await checker.performUpdateAndVerify();
        output['update'] = {
          'success': updateResult.success,
          'message': updateResult.message,
          if (updateResult.newVersion != null)
            'newVersion': updateResult.newVersion,
        };
        if (!updateResult.success) {
          print(const JsonEncoder.withIndent('  ').convert(output));
          exit(1);
        }
      }
      if (checkResult.latestVersion == null) {
        print(const JsonEncoder.withIndent('  ').convert(output));
        exit(1);
      }
      print(const JsonEncoder.withIndent('  ').convert(output));
      return;
    }

    // Human-readable output
    print(checkResult);

    if (checkResult.latestVersion == null) {
      exit(1);
    }

    if (checkOnly || !checkResult.updateAvailable) {
      if (checkOnly && checkResult.updateAvailable) {
        print('');
        print('Run without --check to perform the update.');
      }
      return;
    }

    print('');
    print('Updating...');
    final updateResult = await checker.performUpdateAndVerify();
    print(updateResult);
    if (!updateResult.success) {
      exit(1);
    }
  }
}
