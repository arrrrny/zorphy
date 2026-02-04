#!/usr/bin/env dart

/// Zorphy MCP Server
///
/// This MCP server enables AI agents (like Claude) to create and manage
/// Zorphy entity classes programmatically. It's designed for seamless
/// agentic integration.

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

const String _version = '1.0.0';

/// Main entry point for the MCP server
Future<void> main(List<String> args) async {
  print('Zorphy MCP Server v$_version starting...');

  // Use stdin/stdout for MCP communication
  stdin.listen((data) async {
    try {
      final message = jsonDecode(utf8.decode(data));
      final response = await _handleMessage(message);
      print(jsonEncode(response));
    } catch (e) {
      print(jsonEncode({
        'jsonrpc': '2.0',
        'id': null,
        'error': {
          'code': -32603,
          'message': 'Internal error: $e',
        },
      }));
    }
  });
}

/// Handle incoming MCP messages
Future<Map<String, dynamic>> _handleMessage(Map<String, dynamic> message) async {
  final method = message['method'] as String?;
  final id = message['id'];

  if (method == null) {
    return _errorResponse(id, -32600, 'Invalid Request');
  }

  switch (method) {
    case 'initialize':
      return _successResponse(id, {
        'protocolVersion': '2024-11-05',
        'serverInfo': {
          'name': 'zorphy-mcp-server',
          'version': _version,
        },
        'capabilities': {
          'tools': {},
        },
      });

    case 'tools/list':
      return _successResponse(id, {
        'tools': [
          {
            'name': 'create_entity',
            'description': 'Create a new Zorphy entity class with specified fields and options',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'name': {
                  'type': 'string',
                  'description': 'Name of the entity class (e.g., "User", "Product")',
                },
                'output_dir': {
                  'type': 'string',
                  'description': 'Output directory (default: "lib/entities")',
                  'default': 'lib/entities',
                },
                'fields': {
                  'type': 'array',
                  'description': 'List of field definitions',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'name': {'type': 'string'},
                      'type': {'type': 'string'},
                      'nullable': {'type': 'boolean', 'default': false},
                    },
                    'required': ['name', 'type'],
                  },
                },
                'options': {
                  'type': 'object',
                  'description': 'Zorphy annotation options',
                  'properties': {
                    'generateJson': {'type': 'boolean', 'default': true},
                    'generateCopyWithFn': {'type': 'boolean', 'default': false},
                    'generateCompareTo': {'type': 'boolean', 'default': true},
                    'sealed': {'type': 'boolean', 'default': false},
                    'nonSealed': {'type': 'boolean', 'default': false},
                  },
                },
                'extends': {
                  'type': 'string',
                  'description': 'Interface to extend (e.g., "\$BaseEntity")',
                },
                'explicit_subtypes': {
                  'type': 'array',
                  'description': 'Explicit subtypes for polymorphism',
                  'items': {'type': 'string'},
                },
              },
              'required': ['name'],
            },
          },
          {
            'name': 'list_entities',
            'description': 'List all Zorphy entities in a directory',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'directory': {
                  'type': 'string',
                  'description': 'Directory to search (default: "lib/entities")',
                  'default': 'lib/entities',
                },
              },
            },
          },
          {
            'name': 'generate_entity_code',
            'description': 'Generate entity code without writing to file (preview mode)',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'name': {
                  'type': 'string',
                  'description': 'Name of the entity class',
                },
                'fields': {
                  'type': 'array',
                  'description': 'List of field definitions',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'name': {'type': 'string'},
                      'type': {'type': 'string'},
                      'nullable': {'type': 'boolean'},
                    },
                    'required': ['name', 'type'],
                  },
                },
                'options': {
                  'type': 'object',
                  'properties': {
                    'generateJson': {'type': 'boolean'},
                    'generateCopyWithFn': {'type': 'boolean'},
                    'generateCompareTo': {'type': 'boolean'},
                    'sealed': {'type': 'boolean'},
                    'nonSealed': {'type': 'boolean'},
                  },
                },
                'extends': {'type': 'string'},
                'explicit_subtypes': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
              },
              'required': ['name'],
            },
          },
          {
            'name': 'build_entities',
            'description': 'Run build_runner to generate Zorphy code',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'clean': {
                  'type': 'boolean',
                  'description': 'Clean before building',
                  'default': false,
                },
                'watch': {
                  'type': 'boolean',
                  'description': 'Watch for changes',
                  'default': false,
                },
              },
            },
          },
          {
            'name': 'analyze_entity',
            'description': 'Analyze an existing entity file and return its structure',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'file_path': {
                  'type': 'string',
                  'description': 'Path to the entity file',
                },
              },
              'required': ['file_path'],
            },
          },
          {
            'name': 'create_sealed_hierarchy',
            'description': 'Create a sealed class hierarchy with multiple variants',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'base_name': {
                  'type': 'string',
                  'description': 'Name of the base sealed class (e.g., "Result", "Payment")',
                },
                'variants': {
                  'type': 'array',
                  'description': 'List of variant definitions',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'name': {'type': 'string'},
                      'fields': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'name': {'type': 'string'},
                            'type': {'type': 'string'},
                            'nullable': {'type': 'boolean'},
                          },
                          'required': ['name', 'type'],
                        },
                      },
                    },
                    'required': ['name'],
                  },
                },
                'output_dir': {
                  'type': 'string',
                  'default': 'lib/entities',
                },
                'generate_json': {
                  'type': 'boolean',
                  'default': true,
                },
              },
              'required': ['base_name', 'variants'],
            },
          },
        ],
      });

    case 'tools/call':
      return await _handleToolCall(id, message['params'] as Map<String, dynamic>?);

    case 'shutdown':
      exit(0);

    default:
      return _errorResponse(id, -32601, 'Method not found: $method');
  }
}

/// Handle tool call requests
Future<Map<String, dynamic>> _handleToolCall(dynamic id, Map<String, dynamic>? params) async {
  if (params == null) {
    return _errorResponse(id, -32602, 'Invalid params: null');
  }

  final toolName = params['name'] as String?;
  final arguments = params['arguments'] as Map<String, dynamic>?;

  if (toolName == null || arguments == null) {
    return _errorResponse(id, -32602, 'Invalid tool call');
  }

  try {
    final result = await _executeTool(toolName, arguments);
    return _successResponse(id, {
      'content': [
        {
          'type': 'text',
          'text': result,
        },
      ],
    });
  } catch (e) {
    return _errorResponse(id, -32000, 'Tool execution error: $e');
  }
}

/// Execute a tool and return the result
Future<String> _executeTool(String toolName, Map<String, dynamic> arguments) async {
  switch (toolName) {
    case 'create_entity':
      return await _createEntity(arguments);

    case 'list_entities':
      return await _listEntities(arguments);

    case 'generate_entity_code':
      return await _generateEntityCode(arguments);

    case 'build_entities':
      return await _buildEntities(arguments);

    case 'analyze_entity':
      return await _analyzeEntity(arguments);

    case 'create_sealed_hierarchy':
      return await _createSealedHierarchy(arguments);

    default:
      throw UnimplementedError('Unknown tool: $toolName');
  }
}

/// Create a new entity
Future<String> _createEntity(Map<String, dynamic> args) async {
  final name = args['name'] as String;
  final outputDir = args['output_dir'] as String? ?? 'lib/entities';
  final fields = args['fields'] as List<dynamic>? ?? [];
  final options = args['options'] as Map<String, dynamic>? ?? {};
  final extendsInterface = args['extends'] as String?;
  final explicitSubtypes = args['explicit_subtypes'] as List<dynamic>?;

  // Generate the code
  final code = _generateEntityCodeString(
    name: name,
    fields: fields.map((f) => f as Map<String, dynamic>).toList(),
    options: options,
    extendsInterface: extendsInterface,
    explicitSubtypes: explicitSubtypes?.map((s) => s as String).toList(),
  );

  // Create output directory
  final dir = Directory(outputDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  // Write file
  final className = _formatClassName(name);
  final filePath = p.join(outputDir, '${className.toLowerCase()}.dart');
  final file = File(filePath);
  await file.writeAsString(code);

  return '✅ Created entity: $className\n'
      '   File: $filePath\n'
      '   Fields: ${fields.length}\n'
      '\n'
      'Next steps:\n'
      '  1. Run: dart run build_runner build\n'
      '  2. Import and use your $className class';
}

/// List all entities in a directory
Future<String> _listEntities(Map<String, dynamic> args) async {
  final directory = args['directory'] as String? ?? 'lib/entities';
  final dir = Directory(directory);

  if (!await dir.exists()) {
    return '❌ Directory not found: $directory';
  }

  final entities = <Map<String, dynamic>>[];
  await for (final entity in dir.list()) {
    if (entity is File && entity.path.endsWith('.dart') && !entity.path.contains('.zorphy.dart')) {
      final analysis = await _analyzeFile(entity);
      entities.add(analysis);
    }
  }

  if (entities.isEmpty) {
    return '📭 No entities found in $directory';
  }

  final buffer = StringBuffer();
  buffer.writeln('📂 Zorphy Entities in $directory:');
  buffer.writeln('');

  for (final entity in entities) {
    buffer.writeln('📄 ${entity['name']}');
    buffer.writeln('   File: ${entity['path']}');
    if (entity['hasJson'] == true) buffer.writeln('   ✓ JSON support');
    if (entity['hasCopyWithFn'] == true) buffer.writeln('   ✓ Function-based copyWith');
    if (entity['isSealed'] == true) buffer.writeln('   🔒 Sealed class');
    if (entity['fields'] != null) {
      buffer.writeln('   Fields: ${entity['fields']}');
    }
    buffer.writeln('');
  }

  buffer.writeln('Total: ${entities.length} entity/entities');
  return buffer.toString();
}

/// Generate entity code (preview mode)
Future<String> _generateEntityCode(Map<String, dynamic> args) async {
  final name = args['name'] as String;
  final fields = args['fields'] as List<dynamic>? ?? [];
  final options = args['options'] as Map<String, dynamic>? ?? {};
  final extendsInterface = args['extends'] as String?;
  final explicitSubtypes = args['explicit_subtypes'] as List<dynamic>?;

  final code = _generateEntityCodeString(
    name: name,
    fields: fields.map((f) => f as Map<String, dynamic>).toList(),
    options: options,
    extendsInterface: extendsInterface,
    explicitSubtypes: explicitSubtypes?.map((s) => s as String).toList(),
  );

  return '📝 Generated code for ${_formatClassName(name)}:\n'
      '${'=' * 60}\n'
      '$code\n'
      '${'=' * 60}\n'
      '\n'
      '💡 Use create_entity to write this to a file';
}

/// Build entities
Future<String> _buildEntities(Map<String, dynamic> args) async {
  final clean = args['clean'] as bool? ?? false;
  final watch = args['watch'] as bool? ?? false;

  final commands = <String>['run', 'build_runner'];
  if (clean) commands.add('clean');
  commands.add('build');
  if (watch) commands.add('--watch');

  final process = await Process.start('dart', commands);
  final output = await process.stdout.transform(utf8.decoder).join();
  final error = await process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;

  if (exitCode == 0) {
    return '✅ Build successful!\n\n$output';
  } else {
    return '❌ Build failed (exit code: $exitCode)\n\n$error';
  }
}

/// Analyze an existing entity
Future<String> _analyzeEntity(Map<String, dynamic> args) async {
  final filePath = args['file_path'] as String;
  final file = File(filePath);

  if (!await file.exists()) {
    return '❌ File not found: $filePath';
  }

  final analysis = await _analyzeFile(file);
  return jsonEncode({
    'name': analysis['name'],
    'path': analysis['path'],
    'hasJson': analysis['hasJson'],
    'hasCopyWithFn': analysis['hasCopyWithFn'],
    'isSealed': analysis['isSealed'],
    'fields': analysis['fields'],
    'extends': analysis['extends'],
  });
}

/// Create a sealed class hierarchy
Future<String> _createSealedHierarchy(Map<String, dynamic> args) async {
  final baseName = args['base_name'] as String;
  final variants = args['variants'] as List<dynamic>;
  final outputDir = args['output_dir'] as String? ?? 'lib/entities';
  final generateJson = args['generate_json'] as bool? ?? true;

  final dir = Directory(outputDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final createdFiles = <String>[];

  // Create base sealed class
  final baseClassName = _formatClassName(baseName);
  final baseCode = _generateSealedBaseCode(baseClassName, generateJson);
  final basePath = p.join(outputDir, '${baseClassName.toLowerCase()}.dart');
  await File(basePath).writeAsString(baseCode);
  createdFiles.add(basePath);

  // Create variants
  for (final variant in variants) {
    final v = variant as Map<String, dynamic>;
    final vName = v['name'] as String;
    final vFields = v['fields'] as List<dynamic>? ?? [];

    final vCode = _generateSealedVariantCode(
      baseClassName,
      vName,
      vFields.map((f) => f as Map<String, dynamic>).toList(),
      generateJson,
    );
    final vPath = p.join(outputDir, '${baseClassName.toLowerCase()}_${vName.toLowerCase()}.dart');
    await File(vPath).writeAsString(vCode);
    createdFiles.add(vPath);
  }

  return '✅ Created sealed hierarchy: $baseClassName\n'
      '   Base: $basePath\n'
      '   Variants: ${variants.length}\n'
      '   Files created: ${createdFiles.length}\n'
      '\n'
      'Files:\n'
      '${createdFiles.map((f) => '  - $f').join('\n')}\n'
      '\n'
      'Next steps:\n'
      '  1. Run: dart run build_runner build\n'
      '  2. Use the sealed class with exhaustiveness checking';
}

/// Analyze a Zorphy file
Future<Map<String, dynamic>> _analyzeFile(File file) async {
  final contents = await file.readAsString();
  final name = p.basenameWithoutExtension(file.path);

  // Check for features
  final hasJson = contents.contains('generateJson: true');
  final hasCopyWithFn = contents.contains('generateCopyWithFn: true');
  final isSealed = contents.contains('abstract class \$\$');
  final extendsInterface = RegExp(r'implements\s+(\$\$?\w+)').firstMatch(contents)?.group(1);

  // Extract fields
  final fields = <String>[];
  final fieldMatches = RegExp(r'^\s+(\w+)\s+get\s+(\w+)', multiLine: true).allMatches(contents);
  for (final match in fieldMatches) {
    fields.add('${match.group(2)}: ${match.group(1)}');
  }

  return {
    'name': name,
    'path': file.path,
    'hasJson': hasJson,
    'hasCopyWithFn': hasCopyWithFn,
    'isSealed': isSealed,
    'fields': fields,
    'extends': extendsInterface,
  };
}

/// Generate entity code string
String _generateEntityCodeString({
  required String name,
  required List<Map<String, dynamic>> fields,
  Map<String, dynamic>? options,
  String? extendsInterface,
  List<String>? explicitSubtypes,
}) {
  final buffer = StringBuffer();

  // Header
  buffer.writeln('/// Auto-generated by Zorphy MCP Server');
  buffer.writeln('/// Generated at: ${DateTime.now().toIso8601String()}');
  buffer.writeln();
  buffer.writeln("import 'package:zorphy_annotation/zorphy_annotation.dart';");
  buffer.writeln();
  buffer.writeln("part '${_formatClassName(name).toLowerCase()}.zorphy.dart';");
  buffer.writeln();

  // Annotation options
  final annotationOptions = <String>[];
  if (options?['generateJson'] == true) annotationOptions.add('generateJson: true');
  if (options?['generateCopyWithFn'] == true) annotationOptions.add('generateCopyWithFn: true');
  if (options?['generateCompareTo'] != false) annotationOptions.add('generateCompareTo: true');
  if (options?['sealed'] == true) annotationOptions.add('nonSealed: false');
  if (options?['nonSealed'] == true) annotationOptions.add('nonSealed: true');

  final className = _formatClassName(name);
  final abstractClassName = options?['sealed'] == true ? '$$className' : '\$$className';

  // Class definition
  buffer.writeln('/// $className entity');
  if (annotationOptions.isNotEmpty || extendsInterface != null || explicitSubtypes != null) {
    buffer.write('@Zorphy(');
    final allOptions = [
      ...annotationOptions,
      if (extendsInterface != null) 'extends: \'$extendsInterface\'',
      if (explicitSubtypes != null && explicitSubtypes.isNotEmpty)
        'explicitSubTypes: [${explicitSubtypes.map((s) => '\$$s').join(', ')}]',
    ];
    buffer.write(allOptions.join(', '));
    buffer.writeln(')');
  } else {
    buffer.writeln('@Zorphy()');
  }

  buffer.writeln('abstract class $abstractClassName${extendsInterface != null ? ' implements $extendsInterface' : ''} {');
  buffer.writeln();

  // Fields
  for (final field in fields) {
    final fieldName = field['name'] as String;
    final fieldType = field['type'] as String;
    final nullable = field['nullable'] as bool? ?? false;
    final formattedType = nullable ? '$fieldType?' : fieldType;
    buffer.writeln('  $formattedType get $fieldName;');
  }

  buffer.writeln('}');

  return buffer.toString();
}

/// Generate sealed base class
String _generateSealedBaseCode(String name, bool generateJson) {
  return '''/// Sealed base class for $name
import 'package:zorphy_annotation/zorphy_annotation.dart';

part '${name.toLowerCase()}.zorphy.dart';

@Zorphy(${generateJson ? 'generateJson: true' : ''})
abstract class $$${name} {
  /// Display name for this ${name.toLowerCase()}
  String get displayName;
}
''';
}

/// Generate sealed variant class
String _generateSealedVariantCode(
  String baseName,
  String variantName,
  List<Map<String, dynamic>> fields,
  bool generateJson,
) {
  final buffer = StringBuffer();

  buffer.writeln('/// $variantName variant of $baseName');
  buffer.writeln("import 'package:zorphy_annotation/zorphy_annotation.dart';");
  buffer.writeln();
  buffer.writeln("part '${baseName.toLowerCase()}_${variantName.toLowerCase()}.zorphy.dart';");
  buffer.writeln();

  final className = _formatClassName(variantName);
  buffer.writeln('@Zorphy(${generateJson ? 'generateJson: true' : ''})');
  buffer.writeln('abstract class \$$className implements $$${baseName} {');
  buffer.writeln();

  // Add fields
  for (final field in fields) {
    final fieldName = field['name'] as String;
    final fieldType = field['type'] as String;
    final nullable = field['nullable'] as bool? ?? false;
    final formattedType = nullable ? '$fieldType?' : fieldType;
    buffer.writeln('  $formattedType get $fieldName;');
  }

  buffer.writeln();
  buffer.writeln('  @override');
  buffer.writeln('  String get displayName => \'$className\';');
  buffer.writeln('}');

  return buffer.toString();
}

/// Format class name to PascalCase
String _formatClassName(String name) {
  name = name.replaceAll(r'^$', '');
  final parts = name.split(RegExp(r'[_\s\-]+'));
  return parts.map((part) {
    if (part.isEmpty) return '';
    return part[0].toUpperCase() + part.substring(1);
  }).join();
}

/// Create success response
Map<String, dynamic> _successResponse(dynamic id, dynamic result) {
  return {
    'jsonrpc': '2.0',
    'id': id,
    'result': result,
  };
}

/// Create error response
Map<String, dynamic> _errorResponse(dynamic id, int code, String message) {
  return {
    'jsonrpc': '2.0',
    'id': id,
    'error': {
      'code': code,
      'message': message,
    },
  };
}
