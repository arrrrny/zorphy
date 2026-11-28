import 'dart:io';

import 'package:test/test.dart';

Directory _repositoryRoot() {
  var directory = Directory.current;
  while (true) {
    if (File('${directory.path}/zorphy/pubspec.yaml').existsSync() &&
        Directory('${directory.path}/scripts').existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      fail('could not locate repository root from ${Directory.current}');
    }
    directory = parent;
  }
}

String _classSource(String name) => 'class $name {}\n';

Future<Directory> _fixtureRepository(Map<String, String> files) async {
  final root = await Directory.systemTemp.createTemp('zorphy-337-names-');
  addTearDown(() => root.delete(recursive: true));
  final initialized = await Process.run('git', [
    'init',
    '-q',
  ], workingDirectory: root.path);
  expect(initialized.exitCode, 0, reason: '${initialized.stderr}');
  for (final entry in files.entries) {
    final file = File('${root.path}/${entry.key}');
    await file.create(recursive: true);
    await file.writeAsString(entry.value);
  }
  final staged = await Process.run('git', [
    'add',
    '.',
  ], workingDirectory: root.path);
  expect(staged.exitCode, 0, reason: '${staged.stderr}');
  return root;
}

Future<ProcessResult> _runGate(Directory root) {
  final script = '${_repositoryRoot().path}/scripts/check_class_names.sh';
  return Process.run('bash', [script, root.path]);
}

void main() {
  group('class and file naming gate (#337)', () {
    test('allows role names and excludes generated outputs', () async {
      final root = await _fixtureRepository({
        'fixture/pubspec.yaml': 'name: fixture\n',
        'fixture/lib/good.dart': _classSource('GoodName'),
        'fixture/lib/good.zorphy.dart': _classSource(
          'Bad'
          'Impl',
        ),
        'fixture/lib/good.g.dart': _classSource(
          'Bad'
          'Impl',
        ),
        'notes_impl.md': 'outside the Dart package scan\n',
      });

      final result = await _runGate(root);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });

    test('rejects a class name containing Impl', () async {
      final root = await _fixtureRepository({
        'fixture/pubspec.yaml': 'name: fixture\n',
        'fixture/lib/bad.dart': _classSource(
          'Bad'
          'Impl',
        ),
      });

      final result = await _runGate(root);
      expect(result.exitCode, 1);
      expect(result.stdout, contains('CLASS_NAME'));
      expect(result.stdout, contains('fixture/lib/bad.dart'));
    });

    test('rejects Impl as an infix, not only a suffix', () async {
      final root = await _fixtureRepository({
        'fixture/pubspec.yaml': 'name: fixture\n',
        'fixture/lib/bad.dart': _classSource(
          'Bad'
          'Impl'
          'Helper',
        ),
      });

      final result = await _runGate(root);
      expect(result.exitCode, 1);
      expect(result.stdout, contains('CLASS_NAME'));
    });

    test('rejects an impl basename case-insensitively', () async {
      final root = await _fixtureRepository({
        'fixture/pubspec.yaml': 'name: fixture\n',
        'fixture/benchmark/COST_IMPL.dart': 'void main() {}\n',
      });

      final result = await _runGate(root);
      expect(result.exitCode, 1);
      expect(result.stdout, contains('FILE_NAME'));
      expect(result.stdout, contains('fixture/benchmark/COST_IMPL.dart'));
    });

    test('allows a name that merely contains the letters impl', () async {
      final root = await _fixtureRepository({
        'fixture/pubspec.yaml': 'name: fixture\n',
        'fixture/lib/simple.dart': _classSource('Simple'),
        'fixture/lib/simply.dart': _classSource('Simply'),
      });

      final result = await _runGate(root);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });

    test('does not ban non-Dart files under the scan roots', () async {
      final root = await _fixtureRepository({
        'fixture/pubspec.yaml': 'name: fixture\n',
        'fixture/lib/good.dart': _classSource('GoodName'),
        'fixture/test/impl_input.json': '{}\n',
      });

      final result = await _runGate(root);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });

    test('rejects Impl on every type identifier, case-insensitively', () async {
      for (final decl in [
        'enum ColorImpl { a }',
        'mixin WalkerImpl {}',
        'extension HelperImpl on int {}',
        'class lowerimpl {}',
      ]) {
        final root = await _fixtureRepository({
          'fixture/pubspec.yaml': 'name: fixture\n',
          'fixture/lib/bad.dart': '$decl\n',
        });

        final result = await _runGate(root);
        expect(
          result.exitCode,
          1,
          reason: 'expected rejection for `$decl`: ${result.stdout}',
        );
        expect(result.stdout, contains('CLASS_NAME'));
      }
    });

    test('scans Dart files outside the package source roots', () async {
      final root = await _fixtureRepository({
        'fixture/pubspec.yaml': 'name: fixture\n',
        'fixture/lib/good.dart': _classSource('GoodName'),
        'tool/bad_impl.dart': 'void main() {}\n',
      });

      final result = await _runGate(root);
      expect(result.exitCode, 1);
      expect(result.stdout, contains('FILE_NAME'));
      expect(result.stdout, contains('tool/bad_impl.dart'));
    });

    test('detects a declaration split across lines', () async {
      final root = await _fixtureRepository({
        'fixture/pubspec.yaml': 'name: fixture\n',
        'fixture/lib/split.dart': 'class\nBadImpl {}\n',
      });

      final result = await _runGate(root);
      expect(result.exitCode, 1);
      expect(result.stdout, contains('CLASS_NAME'));
      expect(result.stdout, contains('fixture/lib/split.dart'));
    });

    test(
      'ignores declarations mentioned only in comments or strings',
      () async {
        final root = await _fixtureRepository({
          'fixture/pubspec.yaml': 'name: fixture\n',
          'fixture/lib/ok.dart':
              '/// class BadImpl {}\n'
              '// enum EImpl { a }\n'
              "const s = 'class StringImpl {}';\n"
              'class GoodName {}\n',
        });

        final result = await _runGate(root);
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
      },
    );

    test('PR and push workflows both run the root gate', () {
      final root = _repositoryRoot();
      for (final workflow in ['ci.yaml', 'dart.yml']) {
        final path = '${root.path}/.github/workflows/$workflow';
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains('bash scripts/check_class_names.sh'),
          reason: '$workflow must enforce the monorepo naming policy',
        );
      }
    });

    test('the monorepo currently has no violating names', () async {
      final result = await _runGate(_repositoryRoot());
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    });
  });
}
