#!/usr/bin/env dart

/// Zorphy MCP Server
///
/// Model Context Protocol server for AI agents to create and manage Zorphy entities.
/// Follows conventions: lib/src/domain/entities/entity_snake/entity_snake.dart

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

const String _version = '1.1.1';

void main() {
  stderr.writeln('Zorphy MCP Server v$_version starting...');

  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((
    line,
  ) async {
    if (line.trim().isEmpty) return;

    try {
      final request = jsonDecode(line);
      final response = await _handleRequest(request);
      stdout.writeln(jsonEncode(response));
    } catch (e, stack) {
      stderr.writeln('Error: $e\n$stack');
      stdout.writeln(
        jsonEncode({
          'jsonrpc': '2.0',
          'error': {'code': -32603, 'message': 'Internal error: $e'},
        }),
      );
    }
  });
}

Future<Map<String, dynamic>> _handleRequest(Map<String, dynamic> req) async {
  final method = req['method'] as String?;
  final id = req['id'];
  final params = req['params'] as Map<String, dynamic>?;

  switch (method) {
    case 'initialize':
      return _success(id, {
        'protocolVersion': '2024-11-05',
        'serverInfo': {'name': 'zorphy', 'version': _version},
        'capabilities': {'tools': {}},
      });

    case 'tools/list':
      return _success(id, {'tools': _getTools()});

    case 'tools/call':
      final toolName = params?['name'] as String?;
      final args = params?['arguments'] as Map<String, dynamic>?;
      return _success(id, await _callTool(toolName, args));

    default:
      return _error(id, -32601, 'Method not found: $method');
  }
}

List<Map<String, dynamic>> _getTools() {
  return [
    {
      'name': 'create_entity',
      'description':
          'Create a Zorphy entity in lib/src/domain/entities/entity_snake/entity_snake.dart',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'description': 'Entity name (PascalCase)'},
          'fields': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'type': {'type': 'string'},
              },
              'required': ['name', 'type'],
            },
          },
          'generateJson': {'type': 'boolean', 'default': true},
          'generateCompareTo': {'type': 'boolean', 'default': true},
          'sealed': {'type': 'boolean', 'default': false},
          'nonSealed': {'type': 'boolean', 'default': false},
          'extends': {'type': 'string'},
          'explicitSubTypes': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'required': ['name'],
      },
    },
    {
      'name': 'create_enum',
      'description':
          'Create an enum in lib/src/domain/entities/enums/enum_snake.dart',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'description': 'Enum name (PascalCase)'},
          'values': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Enum values',
          },
        },
        'required': ['name', 'values'],
      },
    },
    {
      'name': 'add_field',
      'description': 'Add field(s) to an existing entity',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'description': 'Entity name'},
          'fields': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'type': {'type': 'string'},
              },
              'required': ['name', 'type'],
            },
          },
        },
        'required': ['name', 'fields'],
      },
    },
    {
      'name': 'list_entities',
      'description': 'List all Zorphy entities and enums',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
  ];
}

Future<Map<String, dynamic>> _callTool(
  String? name,
  Map<String, dynamic>? args,
) async {
  try {
    switch (name) {
      case 'create_entity':
        return await _createEntity(args!);
      case 'create_enum':
        return await _createEnum(args!);
      case 'add_field':
        return await _addField(args!);
      case 'list_entities':
        return await _listEntities();
      default:
        throw 'Unknown tool: $name';
    }
  } catch (e) {
    return {
      'content': [
        {'type': 'text', 'text': 'Error: $e'},
      ],
    };
  }
}

Future<Map<String, dynamic>> _createEntity(Map<String, dynamic> args) async {
  final name = args['name'] as String;
  final fields = (args['fields'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  final generateJson = args['generateJson'] as bool? ?? true;
  final generateCompareTo = args['generateCompareTo'] as bool? ?? true;
  final sealed = args['sealed'] as bool? ?? false;
  final nonSealed = args['nonSealed'] as bool? ?? false;
  final extendsInterface = args['extends'] as String?;
  final explicitSubTypes = (args['explicitSubTypes'] as List?)?.cast<String>();

  final className = _formatClassName(name);
  final snakeName = _toSnakeCase(className);
  final dir = Directory('lib/src/domain/entities/$snakeName');
  await dir.create(recursive: true);

  final imports = <String>{};
  for (final field in fields) {
    final type = field['type'] as String;
    final refs = _extractTypeRefs(type);
    for (final ref in refs) {
      if (_isPrimitive(ref)) continue;
      if (ref.replaceAll(RegExp(r'^\$+'), '') == className) continue;

      if (ref.startsWith(r'$')) {
        final refSnake = _toSnakeCase(ref.replaceAll(RegExp(r'^\$+'), ''));
        imports.add("import '../$refSnake/$refSnake.dart';");
      } else {
        imports.add("import '../enums/index.dart';");
      }
    }
  }

  if (extendsInterface != null) {
    final extSnake = _toSnakeCase(
      extendsInterface.replaceAll(RegExp(r'^\$+'), ''),
    );
    imports.add("import '../$extSnake/$extSnake.dart';");
  }

  if (explicitSubTypes != null) {
    for (final sub in explicitSubTypes) {
      final subSnake = _toSnakeCase(sub.replaceAll(RegExp(r'^\$+'), ''));
      imports.add("import '../$subSnake/$subSnake.dart';");
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
  if (generateJson) {
    buf.writeln("part '$snakeName.g.dart';");
  }
  buf.writeln();

  final opts = <String>[];
  if (generateJson) opts.add('generateJson: true');
  if (generateCompareTo) opts.add('generateCompareTo: true');
  if (nonSealed) opts.add('nonSealed: true');
  if (explicitSubTypes != null && explicitSubTypes.isNotEmpty) {
    opts.add(
      'explicitSubTypes: [${explicitSubTypes.map((s) => '\$$s').join(', ')}]',
    );
  }

  buf.writeln('@Zorphy(${opts.join(', ')})');
  final prefix = sealed ? r'$$' : r'$';
  buf.write('abstract class $prefix$className');
  if (extendsInterface != null) {
    buf.write(' implements $extendsInterface');
  }
  buf.writeln(' {');

  for (final field in fields) {
    buf.writeln('  ${field['type']} get ${field['name']};');
  }

  buf.writeln('}');

  final file = File('${dir.path}/$snakeName.dart');
  await file.writeAsString(buf.toString());

  return {
    'content': [
      {
        'type': 'text',
        'text':
            '✓ Created entity: $className\n  Path: ${file.path}\n  Fields: ${fields.length}',
      },
    ],
  };
}

Future<Map<String, dynamic>> _createEnum(Map<String, dynamic> args) async {
  final name = args['name'] as String;
  final values = (args['values'] as List).cast<String>();

  final enumName = _formatClassName(name);
  final snakeName = _toSnakeCase(enumName);
  final dir = Directory('lib/src/domain/entities/enums');
  await dir.create(recursive: true);

  final buf = StringBuffer();
  buf.writeln('enum $enumName {');
  for (var i = 0; i < values.length; i++) {
    buf.write('  ${values[i]}');
    if (i < values.length - 1) buf.write(',');
    buf.writeln();
  }
  buf.writeln('}');

  final file = File('${dir.path}/$snakeName.dart');
  await file.writeAsString(buf.toString());

  // Update index.dart
  final allEnums = <String>[];
  await for (final entity in dir.list()) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.contains('index.dart')) {
      allEnums.add(p.basenameWithoutExtension(entity.path));
    }
  }
  allEnums.sort();

  final indexBuf = StringBuffer();
  indexBuf.writeln('library enums;');
  indexBuf.writeln();
  for (final e in allEnums) {
    indexBuf.writeln("export '$e.dart';");
  }

  await File('${dir.path}/index.dart').writeAsString(indexBuf.toString());

  return {
    'content': [
      {
        'type': 'text',
        'text':
            '✓ Created enum: $enumName\n  Path: ${file.path}\n  Values: ${values.join(', ')}',
      },
    ],
  };
}

Future<Map<String, dynamic>> _addField(Map<String, dynamic> args) async {
  final name = args['name'] as String;
  final fields = (args['fields'] as List).cast<Map<String, dynamic>>();

  final className = _formatClassName(name);
  final snakeName = _toSnakeCase(className);
  final file = File('lib/src/domain/entities/$snakeName/$snakeName.dart');

  if (!await file.exists()) {
    throw 'Entity not found: $className';
  }

  var content = await file.readAsString();

  // Find class definition
  final classPattern = RegExp(
    r'abstract class \$+' + className + r'\s*(?:implements[^{]*)?\{',
  );
  final match = classPattern.firstMatch(content);
  if (match == null) throw 'Could not find class definition';

  // Find insert position
  final lastFieldPattern = RegExp(r'^\s*\S+\s+get\s+\w+;', multiLine: true);
  final allMatches = lastFieldPattern.allMatches(content).toList();

  final insertPos = allMatches.isEmpty
      ? content.indexOf('{', match.end) + 1
      : allMatches.last.end;

  // Add imports
  final newImports = <String>{};
  for (final field in fields) {
    final type = field['type'] as String;
    final refs = _extractTypeRefs(type);
    for (final ref in refs) {
      if (_isPrimitive(ref)) continue;
      if (ref.replaceAll(RegExp(r'^\$+'), '') == className) continue;

      if (ref.startsWith(r'$')) {
        final refSnake = _toSnakeCase(ref.replaceAll(RegExp(r'^\$+'), ''));
        newImports.add("import '../$refSnake/$refSnake.dart';");
      } else {
        newImports.add("import '../enums/index.dart';");
      }
    }
  }

  if (newImports.isNotEmpty) {
    final partPattern = RegExp(r"^part\s+'", multiLine: true);
    final partMatch = partPattern.firstMatch(content);
    if (partMatch != null) {
      final existing = content.substring(0, partMatch.start);
      final toAdd = newImports.where((i) => !existing.contains(i)).toList()
        ..sort();
      if (toAdd.isNotEmpty) {
        content =
            content.substring(0, partMatch.start) +
            toAdd.join('\n') +
            '\n' +
            content.substring(partMatch.start);
      }
    }
  }

  // Add fields
  final fieldBuf = StringBuffer();
  for (final field in fields) {
    fieldBuf.writeln();
    fieldBuf.writeln('  ${field['type']} get ${field['name']};');
  }

  final newContent =
      content.substring(0, insertPos) +
      fieldBuf.toString() +
      content.substring(insertPos);

  await file.writeAsString(newContent);

  return {
    'content': [
      {
        'type': 'text',
        'text': '✓ Added ${fields.length} field(s) to $className',
      },
    ],
  };
}

Future<Map<String, dynamic>> _listEntities() async {
  final dir = Directory('lib/src/domain/entities');
  if (!await dir.exists()) {
    return {
      'content': [
        {'type': 'text', 'text': 'No entities found'},
      ],
    };
  }

  final entities = <String>[];
  final enums = <String>[];

  await for (final entity in dir.list()) {
    if (entity is Directory) {
      final name = p.basename(entity.path);
      if (name == 'enums') {
        await for (final enumFile in entity.list()) {
          if (enumFile is File &&
              enumFile.path.endsWith('.dart') &&
              !enumFile.path.contains('index.dart')) {
            enums.add(p.basenameWithoutExtension(enumFile.path));
          }
        }
      } else {
        final dartFile = File(p.join(entity.path, '$name.dart'));
        if (await dartFile.exists()) {
          entities.add(name);
        }
      }
    }
  }

  final buf = StringBuffer();
  buf.writeln('📂 Entities (${entities.length}):');
  for (final e in entities) {
    buf.writeln('  - $e');
  }
  buf.writeln();
  buf.writeln('📋 Enums (${enums.length}):');
  for (final e in enums) {
    buf.writeln('  - $e');
  }

  return {
    'content': [
      {'type': 'text', 'text': buf.toString()},
    ],
  };
}

Map<String, dynamic> _success(dynamic id, Map<String, dynamic> result) {
  return {'jsonrpc': '2.0', 'id': id, 'result': result};
}

Map<String, dynamic> _error(dynamic id, int code, String message) {
  return {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };
}

String _formatClassName(String name) {
  name = name.replaceAll(RegExp(r'^\$+'), '');
  final parts = name.split(RegExp(r'[_\s\-]+'));
  return parts
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
      .join('');
}

String _toSnakeCase(String text) {
  return text.replaceAllMapped(RegExp(r'[A-Z]'), (m) {
    final char = m.group(0)!;
    return m.start == 0 ? char.toLowerCase() : '_${char.toLowerCase()}';
  });
}

Set<String> _extractTypeRefs(String type) {
  type = type.replaceAll('?', '');
  return RegExp(
    r'\$*[A-Z][a-zA-Z0-9]*',
  ).allMatches(type).map((m) => m.group(0)!).toSet();
}

bool _isPrimitive(String type) {
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
  };
  return primitives.contains(type);
}
