import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

String _versionOf(String pubspecPath) {
  final yaml = loadYaml(File(pubspecPath).readAsStringSync()) as YamlMap;
  return yaml['version'] as String;
}

/// The repository root: this test runs with the `zorphy` package as cwd (the
/// documented `dart test` invocation) and the package sits directly under the
/// root. Running from the repo root instead would resolve the wrong root.
final Directory _packageDir = Directory('${Directory.current.path}/..');
final String _repoRoot = _packageDir.resolveSymbolicLinksSync();

String _read(String relative) =>
    File('$_repoRoot/$relative').readAsStringSync();

/// Writes [files] (relative path to content) under [root], creating parents.
void _writeLayout(Directory root, Map<String, String> files) {
  for (final entry in files.entries) {
    File('${root.path}/${entry.key}')
      ..createSync(recursive: true)
      ..writeAsStringSync(entry.value);
  }
}

/// Every file under [root] as relative path to bytes, for before/after diffs.
Map<String, List<int>> _snapshot(Directory root) => {
  for (final entity in root.listSync(recursive: true, followLinks: false))
    if (entity is File)
      entity.path.substring(root.path.length + 1): entity.readAsBytesSync(),
};

void main() {
  group('version sync (3.0.0 and 3.0.0-dev.2 sync across 3 packages)', () {
    test('zorphy, zorphy_annotation, and zorphy_migrator versions match', () {
      final zorphyVer = _versionOf('pubspec.yaml');
      final annotationVer = _versionOf('../zorphy_annotation/pubspec.yaml');
      final migratorVer = _versionOf('../zorphy_migrator/pubspec.yaml');

      expect(zorphyVer, annotationVer);
      expect(zorphyVer, migratorVer);
    });

    test(
      'publish.sh version regex accepts SemVer prerelease like 3.0.0-dev.2',
      () {
        final regex = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$');
        expect(regex.hasMatch('3.0.0'), isTrue);
        expect(regex.hasMatch('3.0.0-dev.2'), isTrue);
        expect(regex.hasMatch('3.0.0-rc.1'), isTrue);
        expect(regex.hasMatch('invalid'), isFalse);
      },
    );
  });

  // Both scripts are run against a COPY of the release layout, never against
  // the checkout: a regression in the dry run would otherwise rewrite or
  // delete files in whatever tree the test happens to run in.
  group('publish.sh --dry-run', () {
    const version = '9.9.9-dev.1';
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('zorphy_publish_dry_run_');
      _writeLayout(root, {
        'scripts/publish.sh': _read('scripts/publish.sh'),
        'README.md': _read('README.md'),
        'zorphy_annotation/pubspec.yaml': _read(
          'zorphy_annotation/pubspec.yaml',
        ),
        'zorphy_annotation/CHANGELOG.md': _read(
          'zorphy_annotation/CHANGELOG.md',
        ),
        'zorphy/pubspec.yaml': _read('zorphy/pubspec.yaml'),
        'zorphy/CHANGELOG.md': _read('zorphy/CHANGELOG.md'),
        // Synthetic overrides file: the fixture asserts the dry-run cleans
        // it, but the file itself is local-only (to_path.sh, gitignored) —
        // synthesize it so the test runs on any clean checkout.
        'zorphy/pubspec_overrides.yaml': 'dependency_overrides:\n  zorphy_annotation:\n    path: ../zorphy_annotation\n',
        'zorphy_migrator/pubspec.yaml': _read('zorphy_migrator/pubspec.yaml'),
        // No release heading: the note the script would insert carries the
        // description, which is what these tests read back.
        'zorphy_migrator/CHANGELOG.md': '# Changelog\n',
      });
    });

    tearDown(() => root.deleteSync(recursive: true));

    Future<ProcessResult> publish(List<String> args) => Process.run('bash', [
      'scripts/publish.sh',
      ...args,
    ], workingDirectory: root.path);

    test('prints every step and leaves the tree byte-identical', () async {
      final before = _snapshot(root);
      final result = await publish([version, 'dry run probe', '--dry-run']);
      final out = '${result.stdout}\n${result.stderr}';

      expect(result.exitCode, 0, reason: out);
      expect(_snapshot(root), before);

      final dryRunSteps = RegExp(r'\[dry-run\] (.*)').allMatches(out);
      final commands = dryRunSteps.map((m) => m.group(1)!).toList();

      expect(
        commands.where((c) => c == 'dart pub publish --force'),
        hasLength(3),
        reason: out,
      );
      expect(
        commands,
        containsAll(<Matcher>[
          contains('version: $version/ zorphy_annotation/pubspec.yaml'),
          contains('version: $version/ zorphy/pubspec.yaml'),
          contains('version: $version/ zorphy_migrator/pubspec.yaml'),
          contains('git commit -m chore: release v$version'),
          contains('git tag -a annotation-v$version '),
          contains('git tag -a v$version '),
          contains('git tag -a migrator-v$version '),
          contains('git push origin <current branch>'),
          contains('git push origin --tags'),
        ]),
        reason: out,
      );
      expect(out, contains('rm -f zorphy/pubspec_overrides.yaml'));
      expect(out, contains('- dry run probe'));
      expect(result.stderr, isEmpty);
    });

    test(
      '--dry-run in the description position is a flag, not the text',
      () async {
        final before = _snapshot(root);
        final result = await publish([version, '--dry-run']);
        final out = '${result.stdout}\n${result.stderr}';

        expect(result.exitCode, 0, reason: out);
        expect(_snapshot(root), before);
        expect(out, contains('- Release $version'));
        expect(out, isNot(contains('- --dry-run')));
      },
    );

    test('rejects an unknown option', () async {
      final before = _snapshot(root);
      final result = await publish([version, 'notes', '--feat']);

      expect(result.exitCode, 1);
      expect('${result.stdout}\n${result.stderr}', contains('Unknown option'));
      expect(_snapshot(root), before);
    });

    test('rejects a malformed version before planning anything', () async {
      final before = _snapshot(root);
      final result = await publish(['not-a-version', '--dry-run']);

      expect(result.exitCode, 1);
      expect('${result.stdout}\n${result.stderr}', contains('Invalid version'));
      expect(_snapshot(root), before);
    });
  });

  group('check_version_sync.sh', () {
    const version = '3.0.0-dev.3';
    late Directory root;

    String pubspec(String name, {String? dependency}) =>
        'name: $name\n'
        'version: $version\n'
        '${dependency == null ? '' : 'dependencies:\n  zorphy_annotation: $dependency\n'}';

    setUp(() {
      root = Directory.systemTemp.createTempSync('zorphy_version_sync_');
      _writeLayout(root, {
        'scripts/check_version_sync.sh': _read('scripts/check_version_sync.sh'),
        'zorphy_annotation/pubspec.yaml': pubspec('zorphy_annotation'),
        'zorphy/pubspec.yaml': pubspec('zorphy', dependency: '^$version'),
        'zorphy_migrator/pubspec.yaml': pubspec(
          'zorphy_migrator',
          dependency: '^$version',
        ),
      });
    });

    tearDown(() => root.deleteSync(recursive: true));

    Future<ProcessResult> check() => Process.run('bash', [
      'scripts/check_version_sync.sh',
    ], workingDirectory: root.path);

    void write(String relative, String content) =>
        File('${root.path}/$relative').writeAsStringSync(content);

    test(
      'passes when versions and dependency constraints are in sync',
      () async {
        final result = await check();

        expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
        expect(
          result.stdout,
          contains('OK: all 3 packages at version $version'),
        );
      },
    );

    test('accepts a local path dependency', () async {
      write(
        'zorphy/pubspec.yaml',
        'name: zorphy\n'
            'version: $version\n'
            'dependencies:\n'
            '  zorphy_annotation:\n'
            '    path: ../zorphy_annotation\n',
      );

      final result = await check();

      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    });

    test('fails on a version drift', () async {
      write(
        'zorphy_migrator/pubspec.yaml',
        pubspec(
          'zorphy_migrator',
          dependency: '^$version',
        ).replaceFirst('version: $version', 'version: 3.0.0-dev.2'),
      );

      final result = await check();

      expect(result.exitCode, 1);
      expect(result.stdout, contains('version mismatch'));
    });

    test('fails on a constraint that is not the locked version', () async {
      write(
        'zorphy_migrator/pubspec.yaml',
        pubspec('zorphy_migrator', dependency: '^3.0.0-dev.2'),
      );

      final result = await check();

      expect(result.exitCode, 1);
      expect(
        result.stdout,
        contains(
          'zorphy_migrator/pubspec.yaml must depend on zorphy_annotation: '
          '^$version (found: ^3.0.0-dev.2)',
        ),
      );
    });

    test('fails when the dependency is missing', () async {
      write('zorphy/pubspec.yaml', pubspec('zorphy'));

      final result = await check();

      expect(result.exitCode, 1);
      expect(
        result.stdout,
        contains('zorphy/pubspec.yaml must depend on zorphy_annotation'),
      );
      expect(result.stdout, contains('(found: none)'));
    });
  });
}
