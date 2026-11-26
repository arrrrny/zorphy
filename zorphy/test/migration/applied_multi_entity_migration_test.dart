// TDD acceptance for #249: the applied v2 -> v3 migration must leave the
// consumer tree 100% compilable.
//
// The §2.3 applied fixture test: a 15-entity v2 package mirroring
// `arrrrny/zuraffa`'s 15 tracked `.zorphy.dart` files (10 `core/params`
// entities with both `part '*.zorphy.dart'` and `part '*.g.dart'` directives
// plus tracked `.g.dart` siblings, a single-part `feature_contract` with a
// `library;` directive, and three entity/value files) is copied into a temp
// directory, `dart run zorphy:migrate_v3 <fixture> --apply` runs as a real
// CLI subprocess, and the migrated tree must carry zero `.zorphy.dart` files,
// zero `part '*.zorphy.dart';` directives, the v3 archetypes, and a green
// `dart analyze --fatal-infos`.
//
// The fixture entities are declaration-only (no codec call sites), mirroring
// zuraffa's own params/entity sources, so `dart analyze` resolves against the
// path-overridden `zorphy` / `zorphy_annotation` packages without needing a
// build_runner pass — the codemod is the unit under test.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The zorphy package root (resolved once, shared by every test).
late String zorphyPkg;

/// The zorphy_annotation package root, sibling of [zorphyPkg].
late String annotationPkg;

/// The fixture the `--apply` tests assert against.
late Directory appliedFixture;

/// Result of the applied `migrate_v3 --apply` run.
late ProcessResult applyResult;

/// Result of `dart analyze --fatal-infos` on the migrated fixture.
late ProcessResult analyzeResult;

void main() {
  setUpAll(() async {
    final roots = _resolvePackageRoots();
    zorphyPkg = roots.$1;
    annotationPkg = roots.$2;
    appliedFixture = await _writeFixture('apply', zorphyPkg, annotationPkg);
    final pubGet = await _dart([
      'pub',
      'get',
    ], workingDirectory: appliedFixture.path);
    assertExit(pubGet, 'dart pub get (fixture)');
    applyResult = await _dart([
      'run',
      'zorphy:migrate_v3',
      appliedFixture.path,
      '--apply',
    ], workingDirectory: zorphyPkg);
    assertExit(applyResult, 'dart run zorphy:migrate_v3 --apply');
    analyzeResult = await _dart([
      'analyze',
      '--fatal-infos',
    ], workingDirectory: appliedFixture.path);
  });

  tearDownAll(() async {
    if (await appliedFixture.exists()) {
      await appliedFixture.delete(recursive: true);
    }
  });

  test('migrate_v3 --apply deletes every stale .zorphy.dart file', () async {
    assertExit(applyResult, 'dart run zorphy:migrate_v3 --apply');
    expect(
      applyResult.stdout,
      contains('Deleted 15 stale .zorphy.dart file(s).'),
      reason: 'the CLI must report the deletions it performed',
    );
    final remaining = await _zorphyPartFiles(appliedFixture);
    expect(
      remaining,
      isEmpty,
      reason:
          '#249: zero .zorphy.dart files may '
          'survive --apply; found ${remaining.take(5).join(', ')}',
    );
  });

  test('migrate_v3 --apply strips part *.zorphy.dart directives and rewrites '
      'annotations', () async {
    final sources = await _dartSources(appliedFixture);
    for (final file in sources) {
      final source = await file.readAsString();
      expect(
        source,
        isNot(contains('.zorphy.dart')),
        reason:
            '${p.relative(file.path, from: appliedFixture.path)} still '
            'carries a stale v2 part directive',
      );
    }
    final createParams = await File(
      p.join(
        appliedFixture.path,
        'lib',
        'src',
        'core',
        'params',
        'create_params.dart',
      ),
    ).readAsString();
    expect(createParams, contains('@ZorphyValue()'));
    expect(createParams, isNot(contains('generateJson')));
    expect(createParams, isNot(contains("part '")));
    final todo = await File(
      p.join(
        appliedFixture.path,
        'lib',
        'src',
        'domain',
        'entities',
        'todo',
        'todo.dart',
      ),
    ).readAsString();
    expect(todo, contains('@ZorphyEntity(principalKey: #id)'));
    final featureContract = await File(
      p.join(
        appliedFixture.path,
        'lib',
        'src',
        'domain',
        'entities',
        'feature_contract',
        'feature_contract.dart',
      ),
    ).readAsString();
    expect(featureContract, contains('@ZorphyEntity(principalKey: #id)'));
    expect(featureContract, contains('library;'));
  });

  test('the applied fixture passes dart analyze --fatal-infos', () async {
    expect(
      analyzeResult.exitCode,
      0,
      reason:
          '#249: the migrated tree '
          'must stay 100% compilable\n'
          '${analyzeResult.stdout}\n${analyzeResult.stderr}',
    );
  });

  test('migrate_v3 dry-run lists the stale .zorphy.dart files without deleting '
      'them', () async {
    final fixture = await _writeFixture('dry', zorphyPkg, annotationPkg);
    addTearDown(() => fixture.delete(recursive: true));
    final dryRun = await _dart([
      'run',
      'zorphy:migrate_v3',
      fixture.path,
    ], workingDirectory: zorphyPkg);
    assertExit(dryRun, 'dart run zorphy:migrate_v3 (dry run)');
    final listed = RegExp(
      r'^would delete: .+\.zorphy\.dart$',
      multiLine: true,
    ).allMatches(dryRun.stdout as String).length;
    expect(listed, 15, reason: 'dry-run must list every stale part file');
    final remaining = await _zorphyPartFiles(fixture);
    expect(remaining, hasLength(15), reason: 'a dry run deletes nothing');
  });
}

/// Resolves the zorphy and zorphy_annotation package roots, whether `dart
/// test` was started from the zorphy package or the repository root.
(String, String) _resolvePackageRoots() {
  var dir = Directory.current.path;
  for (var i = 0; i < 6; i++) {
    final nested = p.join(dir, 'zorphy');
    for (final candidate in [dir, nested]) {
      final pubspec = File(p.join(candidate, 'pubspec.yaml'));
      if (pubspec.existsSync() &&
          pubspec.readAsStringSync().contains('name: zorphy')) {
        final annotation = candidate == dir
            ? p.join(p.dirname(dir), 'zorphy_annotation')
            : p.join(dir, 'zorphy_annotation');
        if (Directory(annotation).existsSync()) {
          return (candidate, annotation);
        }
      }
    }
    final parent = p.dirname(dir);
    if (parent == dir) break;
    dir = parent;
  }
  throw StateError(
    'could not locate the zorphy / zorphy_annotation packages from '
    '${Directory.current.path}',
  );
}

Future<ProcessResult> _dart(
  List<String> args, {
  required String workingDirectory,
}) async {
  return Process.run(
    Platform.resolvedExecutable,
    args,
    workingDirectory: workingDirectory,
  );
}

void assertExit(ProcessResult result, String step) {
  if (result.exitCode != 0) {
    fail(
      '$step exited ${result.exitCode}\n'
      'stdout: ${result.stdout}\n'
      'stderr: ${result.stderr}',
    );
  }
}

Future<List<File>> _zorphyPartFiles(Directory dir) async =>
    (await _dartFiles(dir))
        .where((f) => f.path.endsWith('.zorphy.dart'))
        .toList();

Future<List<File>> _dartSources(Directory dir) async => (await _dartFiles(dir))
    .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.zorphy.dart'))
    .toList();

Future<List<File>> _dartFiles(Directory dir) async =>
    Directory(p.join(dir.path, 'lib'))
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

String _camel(String snake) => snake
    .split('_')
    .map(
      (word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
    )
    .join();

/// A v2 params entity mirroring zuraffa's `core/params` sources: both part
/// directives and the v2 preset arguments.
String _paramsEntity({
  required String name,
  String typeParams = '',
  bool implementsBase = true,
  String doc = '',
  String members = '',
}) =>
    '''
import 'package:zorphy/zorphy.dart';
${implementsBase ? "\nimport 'params.dart';" : ''}

part '$name.zorphy.dart';
part '$name.g.dart';
${doc.isEmpty ? '' : '\n$doc'}'''
    '''
@Zorphy(generateJson: true, generateFilter: true)
abstract class \$${_camel(name)}$typeParams${implementsBase ? ' implements \$\$Params' : ''} {
  const \$${_camel(name)}();
$members
}
''';

/// A v2 entity or value file mirroring zuraffa's domain sources.
String _entityFile({
  required String name,
  required String members,
  bool generateJson = true,
  String typeParams = '',
  String import = 'package:zorphy/zorphy.dart',
  bool bothParts = true,
  String header = '',
}) =>
    '''
${header.isEmpty ? '' : '$header\n'}import '$import';

part '$name.zorphy.dart';
${bothParts ? "part '$name.g.dart';" : ''}

@Zorphy(${generateJson ? 'generateJson: true' : ''})
abstract class \$${_camel(name)}$typeParams {
  const \$${_camel(name)}();
$members
}
''';

/// The stale 2.x generated part the codemod must delete from disk.
String _staleZorphyPart(String snakeName, String ctorFields, String decls) =>
    '''
// v2 generated code — stale under the v3 shared-part layout (#249).
part of '$snakeName.dart';

class ${_camel(snakeName)} {
  const ${_camel(snakeName)}(${ctorFields.isEmpty ? '' : '{$ctorFields}'});
$decls
}
''';

/// The stale json_serializable output: orphaned (but analyze-harmless) once
/// the migrated library drops its `part '*.g.dart';` directive.
String _staleJsonPart(String snakeName) =>
    '''
// v2 json_serializable output — stale after the migration (#249).
part of '$snakeName.dart';

class ${_camel(snakeName)}FromJson {
  Map<String, dynamic> encode() => <String, dynamic>{};
}
''';

final Map<String, String> _paramsEntityBodies = {
  'create_params': _paramsEntity(
    name: 'create_params',
    typeParams: '<T>',
    doc: '\n/// Parameters for creating a new entity of type [T].\n',
    members: '''
  /// The entity data to create.
  T get data;''',
  ),
  'credentials': _paramsEntity(name: 'credentials'),
  'delete_params': _paramsEntity(
    name: 'delete_params',
    members: '''
  String get id;''',
  ),
  'initialization_params': _paramsEntity(
    name: 'initialization_params',
    members: '''
  bool get force;''',
  ),
  'list_query_params': _paramsEntity(
    name: 'list_query_params',
    typeParams: '<T>',
    members: '''
  int? get limit;

  int? get offset;''',
  ),
  'query_params': _paramsEntity(
    name: 'query_params',
    typeParams: '<T>',
    members: '''
  String? get search;''',
  ),
  'settings': _paramsEntity(
    name: 'settings',
    implementsBase: false,
    members: '''
  String get id;

  bool get notificationsEnabled;''',
  ),
  'toggle_params': _paramsEntity(
    name: 'toggle_params',
    members: '''
  String get id;

  bool get value;''',
  ),
  'update_params': _paramsEntity(
    name: 'update_params',
    typeParams: '<T>',
    members: '''
  String get id;

  T get data;''',
  ),
};

/// The 15 v2 source files plus their stale 2.x generated siblings: 10
/// `core/params` entities, `feature_contract`, and four domain entities —
/// mirroring zuraffa's 15 tracked `.zorphy.dart` files.
Map<String, String> _fixtureFiles() {
  final files = <String, String>{
    'lib/src/core/params/params.dart': '''
import 'package:zorphy/zorphy.dart';

part 'params.zorphy.dart';

@Zorphy(nonSealed: true)
abstract class \$\$Params {
  const \$\$Params();

  Map<String, dynamic>? get params;
}
''',
    'lib/src/domain/entities/feature_contract/feature_contract.dart':
        _entityFile(
          name: 'feature_contract',
          generateJson: false,
          bothParts: false,
          header:
              '/// Mirrors zuraffa: a `library;` directive with doc comments '
              'and a\n/// single stale zorphy part.',
          members: '''
  String get id;

  String get displayName;

  List<String> get entities;''',
        ).replaceFirst(
          '/// Mirrors zuraffa: a `library;` directive with doc comments and a\n'
              '/// single stale zorphy part.\nimport',
          '/// Mirrors zuraffa: a `library;` directive with doc comments and a\n'
              '/// single stale zorphy part.\nlibrary;\n\nimport',
        ),
    'lib/src/domain/entities/todo/todo.dart': _entityFile(
      name: 'todo',
      members: '''
  String get id;

  String get title;

  bool get done;''',
    ),
    'lib/src/domain/entities/note/note.dart': _entityFile(
      name: 'note',
      members: '''
  String get id;

  String get body;''',
    ),
    'lib/src/domain/entities/todo_stats/todo_stats.dart': _entityFile(
      name: 'todo_stats',
      generateJson: false,
      bothParts: false,
      members: '''
  int get total;

  int get completed;''',
    ),
    'lib/src/domain/entities/user_prefs/user_prefs.dart': _entityFile(
      name: 'user_prefs',
      members: '''
  String get id;

  String get theme;''',
    ),
  };
  _paramsEntityBodies.forEach((name, body) {
    files['lib/src/core/params/$name.dart'] = body;
  });

  // Every source file carries a stale 2.x generated part beside it.
  for (final path in files.keys.toList()) {
    final snake = p.basenameWithoutExtension(path);
    files['${p.withoutExtension(path)}.zorphy.dart'] = _staleZorphyPart(
      snake,
      _ctorFields(snake),
      _fieldDecls(snake),
    );
  }

  // zuraffa also tracks the v2 json_serializable outputs; the migrated
  // library drops their directives and leaves the regenerable files in place.
  for (final snake in [
    'create_params',
    'credentials',
    'delete_params',
    'initialization_params',
    'list_query_params',
    'query_params',
    'settings',
    'toggle_params',
    'update_params',
    'todo',
    'note',
    'user_prefs',
  ]) {
    final dir = snake == 'todo' || snake == 'note' || snake == 'user_prefs'
        ? 'lib/src/domain/entities/$snake'
        : 'lib/src/core/params';
    files['$dir/$snake.g.dart'] = _staleJsonPart(snake);
  }
  return files;
}

String _ctorFields(String snake) {
  const byName = <String, String>{
    'todo': 'required this.id, required this.title, required this.done',
    'note': 'required this.id, required this.body',
    'user_prefs': 'required this.id, required this.theme',
    'feature_contract':
        'required this.id, required this.displayName, required this.entities',
    'settings': 'required this.id, required this.notificationsEnabled',
    'delete_params': 'required this.id',
    'toggle_params': 'required this.id, required this.value',
    'update_params': 'required this.id',
  };
  return byName[snake] ?? '';
}

String _fieldDecls(String snake) {
  const byName = <String, String>{
    'todo': '''
  final String id;
  final String title;
  final bool done;''',
    'note': '''
  final String id;
  final String body;''',
    'user_prefs': '''
  final String id;
  final String theme;''',
    'feature_contract': '''
  final String id;
  final String displayName;
  final List<String> entities;''',
    'settings': '''
  final String id;
  final bool notificationsEnabled;''',
    'delete_params': '  final String id;',
    'toggle_params': '''
  final String id;
  final bool value;''',
    'update_params': '  final String id;',
  };
  return byName[snake] ?? '';
}

Future<Directory> _writeFixture(
  String name,
  String zorphyPath,
  String annotationPath,
) async {
  final dir = await Directory.systemTemp.createTemp('issue_249_applied_$name');
  await File(p.join(dir.path, 'pubspec.yaml')).writeAsString('''
name: issue249_$name
environment:
  sdk: ^3.0.0
dependencies:
  zorphy: any
  zorphy_annotation: any
dependency_overrides:
  zorphy:
    path: $zorphyPath
  zorphy_annotation:
    path: $annotationPath
''');
  for (final entry in _fixtureFiles().entries) {
    final file = File(p.join(dir.path, entry.key));
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
  }
  return dir;
}
